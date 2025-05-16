import os
import json
import asyncio
import httpx
import dotenv
import math
import traceback
from dataclasses import dataclass, field
from typing import Optional, List, Any, Dict

from google.genai import chats,types as genai_types # Renamed to avoid conflict
from google import genai
# Ensure your tool_schemas are correctly imported
from tool_schemas import *
# Make sure deviation module is available
import deviation
from pydantic import BaseModel


dotenv.load_dotenv()
MAP_KEY = os.getenv("GOOGLE_MAPS_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY") # Used in ChatManager

# Ensure client is initialized for use by ChatManager.
# This might be a global client if the library handles concurrency,
# or you might pass it around. For simplicity, assuming genai.GenerativeModel handles its own client needs.
MODEL_NAME = "gemini-2.0-flash" # Or your preferred model from the 'gemini-2.0-flash' family if that was intended
# Define prompts (ensure these are accessible)
idle_instruction = """
You are an AI assistant specialized in navigation for visually impaired users. Your primary goal is to help users understand their surroundings and navigate to their desired destinations safely and efficiently.

**Core Principle: Tool Call Management**
* **Authenticity and Use of Tool Data**: Your primary directive when information is needed from a tool is to issue the appropriate tool call and patiently wait for the system to return the tool's actual output. You must *never* simulate, predict, invent, or otherwise fabricate what you assume a tool will return. All decisions, user-facing statements, or subsequent actions that depend on tool-provided information must be based *solely* on the genuine data received from the tool call. If a tool's output is not yet available, you must wait for it. Do not proceed by guessing or making up data.
* **Handling Dependencies**: If one function's output is required as input for another (e.g., the result of `get_current_location` is needed for `compute_route`), you must ensure the first function has completed and its results are available before you proceed to use or call the dependent function. This often means the dependent function will be part of a subsequent step or turn after the first function's results are processed.
* **Multiple Functions in One Response**: You *can* and *should* request multiple function calls in a single response from you (i.e., in a single list of tool_calls) if they are all necessary to fulfill the user's immediate request or to complete a logical step. [...]

When a user expresses a need related to navigation, finding a location, or understanding their route:
1.  **Clarify Destination**: If the destination is unclear, use `search_places` and/or `geocode_place` to identify and confirm the target location with the user. If `search_places` is used and a selection is made or is obvious, you can follow with `geocode_place` for that selection in the same set of tool calls. **Ensure the destination's coordinates are definitively known before proceeding to route calculation.**
2.  **Determine Origin**: Silently obtain the user's current location using `get_current_location`. **Crucially, never ask the user for their current location. Wait for this function to return the current location before calculating a route.**
3.  **Calculate Route**: Once both origin (from `get_current_location`) and destination (e.g., from `geocode_place`) are known, use `compute_route`. **Wait for this calculation to complete successfully before proposing the route or starting navigation.**
4.  **Propose Route**: Present the calculated route to the user, including estimated distance and travel time. Ask if they wish to proceed.
5.  **Initiate Navigation**: If the user agrees, call `start_navigation` to begin guided navigation. **Ensure `compute_route` has successfully completed and its results are available before `start_navigation` is called.**

**Image Interpretation**:
During interactions (both idle and navigation), you will receive a sequence of images. The first image is a map overview of the user's vicinity. Subsequent images are from the user's forward-facing camera. Use these images to:
    * Answer user questions about their surroundings.
    * Provide descriptive information about what is visible.
    * Enhance your understanding of the environment for navigation purposes.

**General Interaction**:
* For non-navigation related questions, respond conversationally and directly without invoking navigation tools.
* **Output Format**: All your textual responses to the user must be clear, concise, and delivered **only as text instructions** in the language of the user's input. Do not include any other formatting, metadata, or conversational fillers beyond the direct answer or instruction.

"""

def get_navigation_instruction(route_info: Optional[Dict]): # Added type hint
    # Basic instruction if route_info is None or empty, adapt as needed.
    if not route_info:
        return "You are in navigation mode. Please provide your current route details if available."

    return f"""
You are now in **active navigation mode**, guiding a visually impaired user. Focus on providing clear, actionable, and timely instructions.
Current route overview: {json.dumps(route_info, indent=2)[:200]}... (truncated for brevity)

**Core Principle: Tool Call Management during Navigation**
* **Handling Dependencies**: If one function's output is required as input for another (e.g., `geocode_place` for a new destination before calling `restart_navigation`), you must ensure the first function has completed and its results are available before you proceed to use or call the dependent function. This often means the dependent function will be part of a subsequent step or turn.
* **Multiple Functions in One Response**: You *can* and *should* request multiple function calls in a single response from you (i.e., in a single list of tool_calls) if they are all necessary to fulfill the user's immediate request or to complete a logical step in guidance. For example, you might need to call `get_current_step` and, if ambiguity exists, `get_current_location` in the same turn to fully assess the situation. List all tool calls you deem necessary for the current step of your reasoning. Ensure prerequisites for each are met, respecting sequential dependencies if one function's output in the list is needed by another later in the same list.

**Core Responsibilities during Active Navigation**:
1.  **Provide Step-by-Step Guidance**:
    * Use `get_current_step` *automatically* to retrieve the current instruction if you are unsure of the user's progress on the route. **Wait for this function's result before deciding on the specific next verbal instruction or action.**
    * Deliver clear, concise directions for the immediate next action (e.g., "Turn left in 20 meters at the next intersection," "Continue straight for 50 meters").
    * Verbally announce upcoming turns, landmarks, and distances.
2.  **Environmental Awareness & Safety (using camera images)**:
    * Analyze the map overview and camera images provided with each turn.
    * Proactively alert the user to potential obstacles, hazards (e.g., "Caution, uneven pavement ahead," "Low-hanging branch detected"), or changes in terrain detected in the camera feed.
    * Describe nearby points of interest or environmental features if relevant or requested.
3.  **Location Monitoring**:
    * Continuously track the user's progress.
    * Use `get_current_location` if you need to confirm the user's position (e.g., before a reroute or if `get_current_step` suggests ambiguity). **Wait for this function to return location data if it's critical for the immediate next decision or a subsequent dependent tool call.** **Never ask the user for their current location.**
4.  **Manage Route Adherence**:
    * If `get_current_step` (after waiting for its result) returns `None` (indicating deviation), or if the user is significantly off-route, inform them. Then, **after informing them,** you will likely need to call `get_current_location` (and wait for its result) and then `restart_navigation` to recalculate the route. These can be planned as a sequence.
5.  **Handle Route Changes/Requests**:
    * If the user requests to go to a **different location**:
        a. Confirm their intention to change the destination.
        b. Use tools like `search_places` and/or `geocode_place` to determine the coordinates of the new destination. If `search_places` yields a clear choice, `geocode_place` can follow in the same set of tool calls. **Wait for these tools to provide the definitive coordinates before proceeding.**
        c. **Once the new destination coordinates are confirmed and available,** call `restart_navigation` with these new coordinates.
    * If the user asks about alternative routes to the *current* destination, you may use tools to explore this, confirm with the user, and then call `restart_navigation` if a new route is chosen. **Ensure any prerequisite tool calls for exploring alternatives are completed first.**
6.  **Ending Navigation**: Call `end_navigation` and immediately cease other actions for the current turn when:
    * The user explicitly requests to stop or end navigation.
    * The user has arrived at the destination.
    * Navigation needs to be cancelled for any other critical reason (e.g., persistent inability to find a valid route).

**Interaction Guidelines**:
* **Tool Usage**: Beyond the core navigation loop, use navigation tools if the user asks specific questions about the route, locations, or their surroundings that require tool assistance, respecting the tool call management principles.
* **Instruction Style**: Keep instructions brief, direct, and focused on immediate safety and the next required maneuver.
* **"NO_UPDATE" Response**: If the user sends an empty message (e.g., only images) and there's no significant change in their location, surroundings, or route status, respond with the exact string "NO_UPDATE". This is an internal signal; do not say "NO_UPDATE" to the user.
* **Output Format**: All your textual responses to the user must be clear, concise, and delivered **only as text instructions** in the language of the user's input.

Begin by providing the relevant instructions for the first step of the current route.
"""

images_alert_prompt = """
Analyze these walking-scene images for hazards or obstacles and for each image output a brief alert with the risk and recommended action.
If there are hazards or obstacles or red light, please output the alert in the following format: Alert: <alert>
If there are no hazards or obstacles, please output: No alert.
"""

# Tool declarations (ensure these are correctly defined in tool_schemas.py)
idle_routes_tool_declarations = [
    route_decl, geocode_decl, reverse_geocode_decl, search_places_decl,
    place_details_decl, start_navigation_decl, get_current_step_decl,
    get_current_location_decl
]
navigating_routes_tool_declarations = [
    route_decl, geocode_decl, reverse_geocode_decl, search_places_decl,
    place_details_decl, end_navigation_decl, get_current_step_decl,
    get_current_location_decl, restart_navigation_decl, get_full_route_decl
]

class NavResponse(BaseModel):
    response_text: str
    alerts: List[str]
    
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY")) 
class ChatManager:
    def __init__(self, api_key: str):
        self.api_key = api_key
        # Consider initializing the base model once if configuration is static
        # and starting chats from it, or ensure API key is used by GenerativeModel
        # self.base_model = GenerativeModel(MODEL_NAME, api_key=self.api_key) # if api_key is needed here

    def create_idle_chat_for_session(self) -> chats.Chat:
        # Using genai_types for Tool and FunctionDeclaration
        config = {
            "tools": [genai_types.Tool(function_declarations=idle_routes_tool_declarations)],
            "system_instruction": idle_instruction,
            "temperature": 0
        }
        chat = client.chats.create(
            model=MODEL_NAME,
            config=config,
        )
        return chat

    def create_navigation_chat_for_session(self, route_info: Optional[Dict]) -> chats.Chat:
        config = {
            "tools": [genai_types.Tool(function_declarations=navigating_routes_tool_declarations)],
            "system_instruction": get_navigation_instruction(route_info),
            "temperature": 0
        }
        chat = client.chats.create(
            model=MODEL_NAME,
            config=config,
        )
        return chat


@dataclass
class SessionState:
    session_id: str
    status: str = "Idle"
    current_route: Optional[Dict] = None
    current_step: Optional[Dict] = None
    chat: Optional[chats.Chat] = None
    current_loc: Optional[Dict] = None  # e.g., {"lat": 0.0, "lng": 0.0}
    new_destination: Optional[str] = None
    mode_switched: bool = False
    chat_manager: Optional[chats.Chat] = None
    history: List[Any] = field(default_factory=list)

    def __post_init__(self):
        if self.chat_manager is None and GEMINI_API_KEY:
            self.chat_manager = ChatManager(api_key=GEMINI_API_KEY)
        if self.chat is None and self.chat_manager:
            self.chat = self.chat_manager.create_idle_chat_for_session()


def set_current_location(session_state: SessionState, loc: Dict) -> None:
    session_state.current_loc = loc
    print(f"Session {session_state.session_id}: Current location set to: {session_state.current_loc}")


async def get_current_location(session_state: SessionState) -> List[float]:
    print(f"Session {session_state.session_id}: Getting current location: {session_state.current_loc}")
    if session_state.current_loc and "lat" in session_state.current_loc and "lng" in session_state.current_loc:
        return [float(session_state.current_loc["lat"]), float(session_state.current_loc["lng"])]
    # This should ideally not be reached if client always sends location.
    # If it can be reached, implement a fallback or raise a more specific error.
    print(f"Warning: Session {session_state.session_id}: Current location not available in session. Returning default or raising error.")
    # Defaulting to a known location (e.g., Zhongli, Taoyuan for testing)
    # return [24.9924, 121.4990] # Example: Taoyuan City. Replace with appropriate fallback or error.
    raise ValueError(f"Session {session_state.session_id}: Current location is not set.")


async def geocode_place(session_state: SessionState, query: str) -> Dict:
    async with httpx.AsyncClient(timeout=10) as c:
        print(f"Session {session_state.session_id}: Geocoding '{query}'")
        r = await c.get(
            "https://maps.googleapis.com/maps/api/geocode/json",
            params={"address": query, "key": MAP_KEY, "language": "zh-TW"},
        )
    r.raise_for_status()
    results = r.json().get("results")
    if not results:
        raise RuntimeError(f"No location found for query: {query}")
    loc = results[0]["geometry"]["location"]
    print(f"Session {session_state.session_id}: Geocoded location for '{query}': {loc}")
    return {"lat": loc["lat"], "lng": loc["lng"]}


async def reverse_geocode(session_state: SessionState, lat: float, lng: float) -> Dict:
    async with httpx.AsyncClient(timeout=10) as c:
        print(f"Session {session_state.session_id}: Reverse geocoding {lat},{lng}")
        r = await c.get(
            "https://maps.googleapis.com/maps/api/geocode/json",
            params={"latlng": f"{lat},{lng}", "key": MAP_KEY, "language": "zh-TW"},
        )
    r.raise_for_status()
    result = r.json()
    if not result.get("results"):
        raise RuntimeError("No address found for these coordinates")
    # Simplified response, expand as needed
    return {"formatted_address": result["results"][0].get("formatted_address", "Unknown address")}


async def compute_route(session_state: SessionState, origin: str, destination: str, mode: str = "WALK") -> Dict:
    print(f"Session {session_state.session_id}: Computing route from {origin} to {destination} via {mode}")
    lat1, lng1 = map(float, origin.split(","))
    lat2, lng2 = map(float, destination.split(","))
    hdr = {
        "Content-Type": "application/json",
        "X-Goog-FieldMask": "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.steps",
    }
    body = {
        "origin": {"location": {"latLng": {"latitude": lat1, "longitude": lng1}}},
        "destination": {"location": {"latLng": {"latitude": lat2, "longitude": lng2}}},
        "travelMode": mode.upper(), # Ensure mode is uppercase
        "languageCode": "zh-TW"
    }
    url = f"https://routes.googleapis.com/directions/v2:computeRoutes?key={MAP_KEY}"
    async with httpx.AsyncClient(timeout=20) as c:
        r = await c.post(url, headers=hdr, json=body)
    r.raise_for_status()
    data = r.json()

    if not data.get("routes"):
        raise RuntimeError("No route found by Google Maps API.")
    
    route_data = data["routes"][0]
    session_state.current_route = route_data # Store the computed route in session
    
    dist_km = route_data.get("distanceMeters", 0) / 1000
    duration_str = route_data.get("duration", "0s")
    duration_sec = int(duration_str[:-1]) # Remove 's' and convert to int
    duration_min = duration_sec / 60
    print(f"Session {session_state.session_id}: Route computed. Distance: {dist_km:.2f} km, Duration: {duration_min:.1f} mins")
    return route_data


async def search_places(session_state: SessionState, query: str, location: Optional[Dict] = None, radius: Optional[int] = None) -> List[Dict]:
    params = {"query": query, "key": MAP_KEY, "language": "zh-TW"}
    if location and "lat" in location and "lng" in location:
        params["location"] = f"{location['lat']},{location['lng']}"
        if radius:
            params["radius"] = min(radius, 50000)

    async with httpx.AsyncClient(timeout=10) as c:
        print(f"Session {session_state.session_id}: Searching places for '{query}' near {location} within {radius}m")
        r = await c.get("https://maps.googleapis.com/maps/api/place/textsearch/json", params=params)
    r.raise_for_status()
    return {"places":r.json().get("results", [])}


async def place_details(session_state: SessionState, place_id: str) -> Dict:
    fields = ["name", "formatted_address", "formatted_phone_number", "opening_hours", "rating", "website"]
    async with httpx.AsyncClient(timeout=10) as c:
        print(f"Session {session_state.session_id}: Getting details for place_id '{place_id}'")
        r = await c.get(
            "https://maps.googleapis.com/maps/api/place/details/json",
            params={"place_id": place_id, "key": MAP_KEY, "language": "zh-TW", "fields": ",".join(fields)},
        )
    r.raise_for_status()
    return r.json().get("result", {})


async def get_current_step_from_session(session_state: SessionState) -> Optional[Dict]: # Renamed to avoid clash with schema name
    # This function now just retrieves the step from the session state
    # The actual calculation of current step based on location is in chatbot_conversation
    print(f"Session {session_state.session_id}: Retrieving current step: {session_state.current_step}")
    return session_state.current_step


async def start_navigation(session_state: SessionState) -> None:
    if not session_state.current_route:
        raise ValueError(f"Session {session_state.session_id}: Cannot start navigation, no route computed.")
    if not session_state.chat_manager:
        raise ValueError(f"Session {session_state.session_id}: ChatManager not initialized.")

    session_state.status = "Navigating"
    legs = session_state.current_route.get("legs", [])
    if legs and legs[0].get("steps"):
        session_state.current_step = legs[0]["steps"][0]
    else:
        session_state.current_step = None # Or handle as an error
        print(f"Warning: Session {session_state.session_id}: Route has no steps.")

    session_state.chat = session_state.chat_manager.create_navigation_chat_for_session(session_state.current_route)
    session_state.mode_switched = True
    print(f"Session {session_state.session_id}: Navigation started. Switched to navigation chat.")


async def end_navigation(session_state: SessionState) -> None:
    if not session_state.chat_manager:
        raise ValueError(f"Session {session_state.session_id}: ChatManager not initialized.")

    session_state.status = "Idle"
    session_state.current_route = None
    session_state.current_step = None
    session_state.chat = session_state.chat_manager.create_idle_chat_for_session()
    session_state.mode_switched = True
    print(f"Session {session_state.session_id}: Navigation ended. Switched to idle chat.")


async def restart_navigation(session_state: SessionState, new_location: str) -> None:
    print(f"Session {session_state.session_id}: Request to restart navigation to {new_location}")
    await end_navigation(session_state) # Reset current navigation state first
    session_state.new_destination = new_location # Will be picked up by chatbot_conversation
    # The actual route computation for the new destination will happen in the next turn
    # when chatbot_conversation processes the user_input triggered by this new_destination.
    print(f"Session {session_state.session_id}: Navigation restart initiated. New destination set to {new_location}.")


async def get_full_route_from_session(session_state: SessionState) -> Optional[Dict]: # Renamed to avoid clash
    if session_state.status != "Navigating":
        print(f"Session {session_state.session_id}: Not in navigation mode, no full route to return.")
        return None
    if not session_state.current_route:
        print(f"Session {session_state.session_id}: No route information available in session.")
        return None
    return session_state.current_route


async def ask_llm(session_state: SessionState, message_content: Any, images: Optional[List[bytes]] = None) -> tuple[Optional[List[Dict]], str]:
    if session_state.mode_switched:
        session_state.mode_switched = False
        return None, "" # Indicates mode was just switched, no actual LLM call needed for this turn

    active_chat = session_state.chat
    if not active_chat:
        if not session_state.chat_manager:
             print(f"FATAL: Session {session_state.session_id}: ChatManager not initialized. Cannot create chat.")
             return None, "Error: Assistant not available (Chat manager missing)."
        print(f"Warning: Session {session_state.session_id}: Chat not found, reinitializing to idle chat.")
        active_chat = session_state.chat_manager.create_idle_chat_for_session()
        session_state.chat = active_chat
    
    print(f"Session {session_state.session_id}: Sending to LLM. Message type: {type(message_content)}")

    try:
        llm_parts = []
        if isinstance(message_content, str):
            llm_parts.append(genai_types.Part(text=message_content))
        elif isinstance(message_content, genai_types.FunctionResponse):
            llm_parts.append(genai_types.Part(function_response=message_content))
        elif isinstance(message_content, genai_types.Part):
            llm_parts.append(message_content)
        elif isinstance(message_content, list) and all(isinstance(p, genai_types.Part) for p in message_content):
            llm_parts.extend(message_content)
        else:
            print(f"Error: Session {session_state.session_id}: Unsupported message content type for LLM: {type(message_content)}")
            return None, "Internal error: Could not process message."

        if images:
            for img_data in images:
                llm_parts.append(genai_types.Part(inline_data=genai_types.Blob(mime_type="image/jpeg", data=img_data)))

        if not llm_parts:
            print(f"Warning: Session {session_state.session_id}: No content to send to LLM.")
            return None, "NO_UPDATE" # Or handle as appropriate, e.g., "What can I help you with?"

        # print(f"Session {session_state.session_id}: Sending parts to LLM: {llm_parts}")
        response = active_chat.send_message(llm_parts)
        
        # Process response, including function calls
        if not response.candidates:
            print(f"Session {session_state.session_id}: No candidates in LLM response.")
            return None, "I'm sorry, I couldn't process that."

        candidate_part = response.candidates[0].content.parts[0]

        if candidate_part.function_call and candidate_part.function_call.name:
            fn_call = candidate_part.function_call
            fn_name = fn_call.name
            fn_args = dict(fn_call.args) if fn_call.args else {}
            print(f"Session {session_state.session_id}: LLM requested function call: {fn_name} with args {fn_args}")

            fn_response_content = None
            try:
                if fn_name == "geocode_place":
                    fn_response_content = await geocode_place(session_state, **fn_args)
                elif fn_name == "reverse_geocode":
                    fn_response_content = await reverse_geocode(session_state, **fn_args)
                elif fn_name == "compute_route":
                    # compute_route stores result in session_state.current_route
                    route_details = await compute_route(session_state, **fn_args)
                    # We need to return something simple for the FunctionResponse,
                    # the main data (current_route) is now in session_state.
                    fn_response_content = {"status": "success", "distanceMeters": route_details.get("distanceMeters"), "duration": route_details.get("duration")}
                elif fn_name == "search_places":
                    fn_response_content = await search_places(session_state, **fn_args)
                elif fn_name == "place_details":
                    fn_response_content = await place_details(session_state, **fn_args)
                elif fn_name == "start_navigation":
                    await start_navigation(session_state) # Modifies session_state
                    fn_response_content = {"status": "navigation_started"}
                elif fn_name == "end_navigation":
                    await end_navigation(session_state) # Modifies session_state
                    fn_response_content = {"status": "navigation_ended"}
                elif fn_name == "get_current_step": # Corresponds to get_current_step_decl
                    fn_response_content = await get_current_step_from_session(session_state)
                elif fn_name == "get_current_location": # Corresponds to get_current_location_decl
                    loc = await get_current_location(session_state)
                    fn_response_content = {"lat": loc[0], "lng": loc[1]}
                elif fn_name == "restart_navigation":
                    await restart_navigation(session_state, **fn_args) # Modifies session_state
                    fn_response_content = {"status": "navigation_restart_initiated"}
                elif fn_name == "get_full_route": # Corresponds to get_full_route_decl
                    fn_response_content = await get_full_route_from_session(session_state)
                else:
                    print(f"Session {session_state.session_id}: Unknown function call {fn_name}")
                    fn_response_content = {"error": f"Unknown function: {fn_name}"}
                
                function_response_part = genai_types.FunctionResponse(name=fn_name, response=fn_response_content)
                return await ask_llm(session_state, function_response_part) # Recursive call

            except Exception as e:
                print(f"Session {session_state.session_id}: Error executing function {fn_name}: {e}")
                traceback.print_exc()
                error_response_part = genai_types.FunctionResponse(name=fn_name, response={"error": str(e)})
                return await ask_llm(session_state, error_response_part) # Inform LLM about the error

        elif candidate_part.text:
            print(f"Session {session_state.session_id}: LLM response text: {candidate_part.text}")
            return None, candidate_part.text
        
        # Fallback if no function call and no text
        print(f"Session {session_state.session_id}: LLM response had no actionable content (no function call, no text).")
        return None, "I'm not sure how to respond to that."

    except Exception as e:
        print(f"Session {session_state.session_id}: General error in ask_llm: {e}")
        traceback.print_exc()
        return None, f"An error occurred: {str(e)}"


async def get_static_map_image(session_state: SessionState, location_coords: List[float]) -> Optional[bytes]:
    try:
        async with httpx.AsyncClient(timeout=10) as c:
            map_url_params = {
                "center": f"{location_coords[0]},{location_coords[1]}",
                "zoom": "17",
                "size": "600x600",
                "markers": f"color:red|{location_coords[0]},{location_coords[1]}",
                "maptype": "roadmap",
                "key": MAP_KEY
            }
            if session_state.status == "Navigating" and session_state.current_route:
                polyline = session_state.current_route.get("polyline", {}).get("encodedPolyline")
                if polyline:
                    map_url_params["path"] = f"weight:3|color:blue|enc:{polyline}"
            
            map_url = "https://maps.googleapis.com/maps/api/staticmap"
            r = await c.get(map_url, params=map_url_params)
            r.raise_for_status()
            print(f"Session {session_state.session_id}: Static map image fetched successfully.")
            return r.content
    except Exception as e:
        print(f"Session {session_state.session_id}: Error getting static map: {e}")
        return None


async def chatbot_conversation(session_state: SessionState, user_input: str, images: Optional[List[bytes]] = None) -> NavResponse:
    try:
        current_session_loc_list = await get_current_location(session_state)
    except ValueError as e: # Handle case where location is not set
        print(f"Session {session_state.session_id}: Cannot proceed with chatbot_conversation, {e}")
        return f"Error: Could not determine your current location for session {session_state.session_id}."

    map_image_bytes = await get_static_map_image(session_state, current_session_loc_list)

    combined_images_list = []
    if map_image_bytes:
        combined_images_list.append(map_image_bytes)
        # For debugging:
        with open(f"map_image.jpg", "wb") as f:
            f.write(map_image_bytes)
        print(f"Session {session_state.session_id}: Map image saved.")
    if images:
        combined_images_list.extend(images)

    if session_state.status == "Navigating" and session_state.current_route:
        if deviation: # Check if deviation module is imported
            current_step_info = deviation.get_current_step(
                current_session_loc_list[0], current_session_loc_list[1], session_state.current_route, 20 # 20m tolerance
            )
            session_state.current_step = current_step_info
            print(f"Session {session_state.session_id}: Updated current step: {current_step_info}")
        else:
            print(f"Warning: Session {session_state.session_id}: deviation module not available to update step.")


    effective_input = user_input
    if session_state.new_destination:
        # Prepend instruction to navigate to new destination
        effective_input = f"My new destination is {session_state.new_destination}. Please guide me there. Original request was: {user_input}"
        print(f"Session {session_state.session_id}: New destination detected: {session_state.new_destination}. Updating input.")
        session_state.new_destination = None # Consumed

    _, text_response = await ask_llm(session_state, effective_input, images=combined_images_list)
    
    mode_display = "Navigation" if session_state.status == "Navigating" else "Idle"
    print(f"[Session {session_state.session_id} Mode: {mode_display}] LLM Replied.")
    
    alert_response = "NO_ALERT" # Placeholder for actual alert response logic
    # _, alert_response = await ask_llm(session_state, "Analyze the camera images provided last turn (if any), do you see any potential hazards or obstacles? If none, please say 'NO_ALERT'.")
    # alert_response = alert_response.strip()
    response=NavResponse(response_text=text_response, alerts=[alert_response] if alert_response != "NO_ALERT" else [])
    return response


if __name__ == "__main__":
    # This main block is for local testing of navigator.py logic.
    # It will not run when server.py is the entry point.
    async def test_session():
        print("Local navigator test started.")
        # Create a dummy session for testing
        test_session_id = "local_test_session_01"
        
        # Initialize GEMINI_API_KEY if not already set for ChatManager
        if not GEMINI_API_KEY:
            print("Error: GEMINI_API_KEY not set. Cannot run local test.")
            return

        # Initialize ChatManager within SessionState
        s_state = SessionState(session_id=test_session_id)
        if not s_state.chat_manager: # Should be handled by __post_init__ if GEMINI_API_KEY is set
            print("Error: ChatManager could not be initialized in SessionState.")
            return
            
        print(f"Test Session {test_session_id} initialized with {s_state.status} status.")

        # Simulate setting current location (client would send this)
        # Using a location in Taoyuan, Taiwan
        simulated_location = {"lat": 24.9704, "lng": 121.1956}
        set_current_location(s_state, simulated_location)

        while True:
            try:
                user_text = input(f"You (Session {test_session_id}): ")
                if user_text.lower() in ['exit', 'quit']:
                    if s_state.status == "Navigating":
                        await end_navigation(s_state)
                    print("Exiting local test.")
                    break
                
                # Simulate receiving no images for this test CLI
                response = await chatbot_conversation(s_state, user_text, images=None)
                print(f"Assistant (Session {test_session_id}): {response.response_text}\n Alerts: {response.alerts}")

            except KeyboardInterrupt:
                print("\nExiting local test due to KeyboardInterrupt.")
                if s_state.status == "Navigating":
                    await end_navigation(s_state)
                break
            except Exception as e:
                print(f"Error during local test: {e}")
                traceback.print_exc()
                # continue or break, depending on desired behavior
                break
    
    try:
        asyncio.run(test_session())
    except Exception as e:
        print(f"Failed to run local test session: {e}")