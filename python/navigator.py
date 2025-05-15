import os
import json
import asyncio
import httpx
import dotenv
import math
import deviation
from google import genai  # v1.x import path
from google.genai import types  # FunctionCall / Content
from tool_schemas import *
from dataclasses import dataclass
from typing import Optional, List
import traceback
dotenv.load_dotenv()
MAP_KEY = os.getenv("GOOGLE_MAPS_KEY")
# Replace existing system_instruction with:
idle_instruction = """
You are an AI assistant specialized in navigation for visually impaired users. Your primary goal is to help users understand their surroundings and navigate to their desired destinations safely and efficiently.

When a user expresses a need related to navigation, finding a location, or understanding their route:
1.  **Clarify Destination**: If the destination is unclear, use `search_places` and/or `geocode_place` to identify and confirm the target location with the user.
2.  **Determine Origin**: Silently obtain the user's current location using `get_current_location`. **Crucially, never ask the user for their current location.**
3.  **Calculate Route**: Use `compute_route` to plan the path from their current location to the destination.
4.  **Propose Route**: Present the calculated route to the user, including estimated distance and travel time. Ask if they wish to proceed.
5.  **Initiate Navigation**: If the user agrees, call `start_navigation` to begin guided navigation. **Ensure `compute_route` has been successfully called before `start_navigation` so the latest route is used.**

**Image Interpretation**:
During interactions (both idle and navigation), you will receive a sequence of images. The first image is a map overview of the user's vicinity. Subsequent images are from the user's forward-facing camera. Use these images to:
    * Answer user questions about their surroundings.
    * Provide descriptive information about what is visible.
    * Enhance your understanding of the environment for navigation purposes.

**General Interaction**:
* For non-navigation related questions, respond conversationally and directly without invoking navigation tools.
* **Output Format**: All your textual responses to the user must be clear, concise, and delivered **only as text instructions** in the language of the user's input. Do not include any other formatting, metadata, or conversational fillers beyond the direct answer or instruction.

Now, greet the user and ask how you can assist them today.
"""
def get_navigation_instruction(route_info):
    return f"""
You are now in **active navigation mode**, guiding a visually impaired user. Focus on providing clear, actionable, and timely instructions.
The current route information is: {route_info}

**Core Responsibilities during Active Navigation**:
1.  **Provide Step-by-Step Guidance**:
    * Use `get_current_step` to retrieve the current instruction if you are unsure of the user's progress on the route.
    * Deliver clear, concise directions for the immediate next action (e.g., "Turn left in 20 meters at the next intersection," "Continue straight for 50 meters").
    * Verbally announce upcoming turns, landmarks, and distances.
2.  **Environmental Awareness & Safety (using camera images)**:
    * Analyze the map overview and camera images provided with each turn.
    * Proactively alert the user to potential obstacles, hazards (e.g., "Caution, uneven pavement ahead," "Low-hanging branch detected"), or changes in terrain detected in the camera feed.
    * Describe nearby points of interest or environmental features if relevant or requested.
3.  **Location Monitoring**:
    * Continuously track the user's progress.
    * Use `get_current_location` if you need to confirm the user's position. **Never ask the user for their current location.**
4.  **Manage Route Adherence**:
    * If `get_current_step` returns `None` (indicating deviation), or if the user is significantly off-route, inform them and then call `restart_navigation` to recalculate the route from their current position to the original destination.
5.  **Handle Route Changes/Requests**:
    * If the user requests to go to a **different location**:
        a. Confirm their intention to change the destination.
        b. Use tools like `search_places` and `geocode_place` to determine the coordinates of the new destination.
        c. Call `restart_navigation` with the new destination coordinates.
    * If the user asks about alternative routes to the *current* destination, you may use tools to explore this, confirm with the user, and then call `restart_navigation` if a new route is chosen.
6.  **Ending Navigation**: Call `end_navigation` and immediately cease other actions for the current turn when:
    * The user explicitly requests to stop or end navigation.
    * The user has arrived at the destination.
    * Navigation needs to be cancelled for any other critical reason (e.g., persistent inability to find a valid route).

**Interaction Guidelines**:
* **Tool Usage**: Beyond the core navigation loop, use navigation tools if the user asks specific questions about the route, locations, or their surroundings that require tool assistance.
* **Instruction Style**: Keep instructions brief, direct, and focused on immediate safety and the next required maneuver.
* **"NO_UPDATE" Response**: If the user sends an empty message (e.g., only images) and there's no significant change in their location, surroundings, or route status, respond with the exact string "NO_UPDATE". This is an internal signal; do not say "NO_UPDATE" to the user.
* **Output Format**: All your textual responses to the user must be clear, concise, and delivered **only as text instructions** in the language of the user's input.

Begin by providing the relevant instructions for the first step of the current route.
"""

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))  # v1.x client

idle_routes_tool = [types.Tool(function_declarations=[
    route_decl,
    geocode_decl,
    reverse_geocode_decl,
    search_places_decl,
    place_details_decl,
    start_navigation_decl,
    get_current_step_decl,     # Add this line
    get_current_location_decl  # Add this line
])]
navigating_routes_tool = [types.Tool(function_declarations=[
    route_decl,
    geocode_decl,
    reverse_geocode_decl,
    search_places_decl,
    place_details_decl,
    end_navigation_decl,
    get_current_step_decl,
    get_current_location_decl,
    restart_navigation_decl,
    get_full_route_decl
])]
MODEL = "gemini-2.0-flash"

current_loc=None

def set_current_location(loc) -> None:
    """
    Set the current location for testing purposes
    """
    global current_loc
    current_loc = loc
    print(f"Current location set to: {current_loc}")  # debug

@dataclass
class NavigationState:
    status: str = "Idle"
    current_route = None
    current_step = None
    chat = None  # Add this field


class ChatManager:
    def __init__(self, api_key,):
        self.api_key = api_key
        self.idle_chat = None
        self.nav_chat = None

    def create_idle_chat(self):
        config = {
            "tools": idle_routes_tool,
            "system_instruction": idle_instruction,
            "temperature": 0.2
        }
        self.idle_chat = client.chats.create(
            model=MODEL, config=config)
        return self.idle_chat

    def create_navigation_chat(self, route_info):
        config = {
            "tools": navigating_routes_tool,
            "system_instruction": get_navigation_instruction(route_info),
            "temperature": 0.2
        }
        self.nav_chat = client.chats.create(
            model=MODEL, config=config)
        return self.nav_chat


chat_manager = ChatManager(os.getenv("GEMINI_API_KEY"))
chat = chat_manager.create_idle_chat()  # Initialize with idle chat


navigation_state = NavigationState()

async def get_current_location() -> dict:
    """
    優先用 ipapi ≈ 300 毫秒；失敗再後備 geocoder.ip('me')
    回傳 (lat, lng)
    """
    global current_loc
    print("Getting current location: ", current_loc)  # debug
    return [current_loc["lat"], current_loc["lng"]]
    # try:
    #     async with httpx.AsyncClient(timeout=2) as c:
    #         r = await c.get("https://ipapi.co/json/")
    #     r.raise_for_status()
    #     data = r.json()
    #     if data.get("latitude") and data.get("longitude"):
    #         return data["latitude"], data["longitude"]
    # except Exception:
    #     pass

    # g = geocoder.ip("me")
    # if g.ok and g.latlng:
    #     return g.latlng[0], g.latlng[1]
    # raise RuntimeError("Unable to get current location")

# ───────── Google Maps helpers ─────────


async def geocode_place(query: str) -> dict:
    async with httpx.AsyncClient(timeout=10) as c:
        print("Geocoding", query)  # debug
        r = await c.get(
            "https://maps.googleapis.com/maps/api/geocode/json",
            params={
                "address": query,
                "key": MAP_KEY
            },
        )
    r.raise_for_status()
    loc = r.json()["results"][0]["geometry"]["location"]
    if not loc:
        raise RuntimeError("No location found")
    print("Geocoded location:", loc)  # debug
    return {"lat": loc["lat"], "lng": loc["lng"]}

# Add this after the existing geocode_place function


async def reverse_geocode(lat: float, lng: float) -> dict:
    """
    Convert latitude and longitude coordinates into a human-readable address.
    Returns a dictionary containing address components.
    """
    async with httpx.AsyncClient(timeout=10) as c:
        print(f"Reverse geocoding coordinates: {lat}, {lng}")  # debug
        r = await c.get(
            "https://maps.googleapis.com/maps/api/geocode/json",
            params={
                "latlng": f"{lat},{lng}",
                "key": MAP_KEY,
                "language": "zh-TW"  # Set to Traditional Chinese to match your system
            }
        )
    r.raise_for_status()

    result = r.json()
    if not result.get("results"):
        raise RuntimeError("No address found for these coordinates")

    location_data = result["results"][0]

    # Extract useful address components
    address_components = {
        "formatted_address": location_data.get("formatted_address", ""),
        "place_id": location_data.get("place_id", ""),
        "types": location_data.get("types", []),
        "components": {}
    }

    # Process individual address components
    for component in location_data.get("address_components", []):
        for type in component["types"]:
            address_components["components"][type] = component["long_name"]

    return address_components


async def compute_route(origin: str,
                        destination: str,
                        mode: str = "WALK") -> list[dict]:
    print("Computing route", origin, destination)  # debug
    print("Mode:", mode)  # debug
    lat1, lng1 = origin.split(",")
    lat2, lng2 = destination.split(",")
    hdr = {
        "Content-Type": "application/json",
        "X-Goog-FieldMask": "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.steps"
    }
    body = {
        "origin": {
            "location": {
                "latLng": {
                    "latitude": lat1,
                    "longitude": lng1
                }
            }
        },
        "destination": {
            "location": {
                "latLng": {
                    "latitude": lat2,
                    "longitude": lng2
                }
            }
        },
        "travelMode": mode,
    }
    url = f"https://routes.googleapis.com/directions/v2:computeRoutes?key={MAP_KEY}"
    async with httpx.AsyncClient(timeout=20) as c:
        r = await c.post(url, headers=hdr, json=body)
    r.raise_for_status()
    data = r.json()

    print("Distance: ", data["routes"][0]
          ["distanceMeters"]/1000, "km")  # debug
    print("Duration: ", int(data["routes"][0]
          ["duration"][:-1])/60, "mins")  # debug

    if not data.get("routes"):
        raise RuntimeError("No route found")
    navigation_state.current_route = data["routes"][0]
    return data["routes"][0]


async def search_places(query: str,
                        location: dict | None = None,
                        radius: int | None = None) -> list[dict]:
    """
    Search for places using the Google Places API
    Args:
        query: Search text
        location: Optional dict with lat/lng
        radius: Optional search radius in meters (max 50000)
    Returns:
        List of places with details
    """
    params = {
        "query": query,
        "key": MAP_KEY,
        "language": "zh-TW"
    }

    # Add location and radius if provided
    if location and "lat" in location and "lng" in location:
        params["location"] = f"{location['lat']},{location['lng']}"
        if radius:
            params["radius"] = min(radius, 50000)  # Cap at 50km

    async with httpx.AsyncClient(timeout=10) as c:
        print(f"Searching places: {query}, {location}, {radius}")  # debug
        r = await c.get(
            "https://maps.googleapis.com/maps/api/place/textsearch/json",
            params=params
        )
    r.raise_for_status()

    results = r.json().get("results", [])
    if not results:
        return []

    places = []
    for place in results:
        places.append({
            "name": place.get("name", ""),
            "formatted_address": place.get("formatted_address", ""),
            "location": place["geometry"]["location"],
            "place_id": place.get("place_id", ""),
            "types": place.get("types", []),
            "rating": place.get("rating"),
            "user_ratings_total": place.get("user_ratings_total")
        })

    return places


async def place_details(place_id: str) -> dict:
    """
    Get detailed information about a place using Google Places API Details
    Args:
        place_id: The unique place ID from Google Places API
    Returns:
        Dictionary containing place details including name, address, contact info, etc.
    """
    fields = [
        "name", "formatted_address", "formatted_phone_number",
        "opening_hours", "rating", "user_ratings_total", "reviews",
        "website", "price_level", "wheelchair_accessible_entrance"
    ]

    async with httpx.AsyncClient(timeout=10) as c:
        print(f"Getting details for place: {place_id}")  # debug
        r = await c.get(
            "https://maps.googleapis.com/maps/api/place/details/json",
            params={
                "place_id": place_id,
                "key": MAP_KEY,
                "language": "zh-TW",
                "fields": ",".join(fields)
            }
        )
    r.raise_for_status()

    result = r.json().get("result", {})
    if not result:
        raise RuntimeError(f"No details found for place_id: {place_id}")

    # Process reviews to make them more concise
    if "reviews" in result:
        result["reviews"] = [{
            "rating": review.get("rating", 0),
            "text": review.get("text", ""),
            "time": review.get("relative_time_description", "")
        } for review in result["reviews"]]

    # Format opening hours if available
    if "opening_hours" in result:
        result["opening_hours"] = {
            "open_now": result["opening_hours"].get("open_now", False),
            "periods": result["opening_hours"].get("weekday_text", [])
        }

    return result


async def get_current_step() -> dict:
    return navigation_state.current_step

mode_swicthed = False


async def start_navigation() -> None:
    """
    Starts navigation with the current route
    """
    global navigation_state, mode_swicthed, chat

    if not navigation_state.current_route:
        raise ValueError("Cannot start navigation without route")

    navigation_state.status = "Navigating"
    navigation_state.current_step = navigation_state.current_route.get("legs", [{}])[
        0].get("steps", [])[0]  # Get the first step

    print("Navigation started")  # debug
    mode_swicthed = True
    chat = chat_manager.create_navigation_chat(
        navigation_state.current_route)
    return


async def end_navigation() -> None:
    """
    Ends navigation
    """
    global navigation_state, mode_swicthed, chat

    if navigation_state.status != "Navigating":
        raise ValueError("No active navigation session to end")

    navigation_state.status = "Idle"
    navigation_state.current_route = None
    navigation_state.current_step = None

    print("Navigation ended")  # debug
    mode_swicthed = True
    chat = chat_manager.create_idle_chat()  # Reset to idle chat
    return

new_destination = None


async def restart_navigation(new_location) -> None:
    """
    Set a new destination and abort current navigation
    """
    global new_destination, chat
    await end_navigation()
    new_destination = new_location
    print("Navigation restarted, new coordinate is "+new_destination)  # debug
    return


async def get_full_route() -> dict:
    """
    Returns the full route information for the current navigation session
    """
    if navigation_state.status != "Navigating":
        raise ValueError("No active navigation session")

    if not navigation_state.current_route:
        raise ValueError("No route information available")

    return navigation_state.current_route

# ───────── Recursive tool orchestration ─────────


async def ask_llm(message, images=None):
    """
    Handles LLM interaction with function calling support

    Args:
        message: str | types.Content | types.FunctionResponse | types.Part
            - str: Direct user input
            - types.Content: Structured content from previous response
            - types.FunctionResponse: Result from tool function call
            - types.Part: Individual message part

    Returns:
        tuple[list[dict] | None, str]:
            - First element: Route steps if navigation, else None
            - Second element: Text response from LLM
    """
    global mode_swicthed

    # Add check at the beginning of the function
    if mode_swicthed:
        mode_swicthed = False  # Reset the flag
        return None, ""

    print(f"Sending to model: {type(message)}",
          message if isinstance(message, str) else "Function response")

    try:
        # Handle different message types
        if isinstance(message, types.Content):
            parts = message.parts
            resp = chat.send_message(parts[0] if parts else "Empty content")
        elif isinstance(message, types.FunctionResponse):
            resp = chat.send_message(types.Part(function_response=message))
        elif isinstance(message, types.Part):
            resp = chat.send_message(message)
        elif isinstance(message, str) and (images is not None):
            message_parts = []
            message_parts.append(message)
            
            if images is not None:
                if isinstance(images, bytes):
                    print(
                        f"Adding single image from images param: {len(images)} bytes")
                    message_parts.append(types.Part.from_bytes(
                        data=images, mime_type="image/jpeg"))
                else:
                    print(f"Adding {len(images)} images")
                    for i, img in enumerate(images):
                        if img:
                            print(f"  Adding image {i+1}: {len(img)} bytes")
                            message_parts.append(types.Part.from_bytes(
                                data=img, mime_type="image/jpeg"))
            resp = chat.send_message(message_parts)
        else:
            resp = chat.send_message(message)

        if not resp.candidates:
            print("No candidates in response")
            return None, "No response from model"

        part = resp.candidates[0].content.parts[0]

        # Handle function calls
        if hasattr(part, 'function_call') and part.function_call:
            fn = part.function_call
            print(f"Function call detected: {fn.name}")

            try:
                if fn.name == "geocode_place":
                    geo = await geocode_place(**fn.args)
                    fn_resp = types.FunctionResponse(
                        name="geocode_place",
                        response=geo
                    )
                    return await ask_llm(fn_resp)

                elif fn.name == "reverse_geocode":
                    address = await reverse_geocode(**fn.args)
                    fn_resp = types.FunctionResponse(
                        name="reverse_geocode",
                        response=address
                    )
                    return await ask_llm(fn_resp)

                elif fn.name == "compute_route":
                    steps = await compute_route(**fn.args)
                    fn_resp = types.FunctionResponse(
                        name="compute_route",
                        response={"steps": steps}
                    )
                    # print("Route steps:", steps)  # debug
                    nav = chat.send_message(
                        types.Part(function_response=fn_resp))

                    if nav.candidates and nav.candidates[0].content.parts:
                        text_parts = [p.text for p in nav.candidates[0].content.parts
                                      if hasattr(p, 'text') and p.text]
                        nav_text = " ".join(
                            text_parts) if text_parts else "No text in response"
                    else:
                        nav_text = "No response text available"
                    return steps, nav_text

                elif fn.name == "search_places":
                    places = await search_places(**fn.args)
                    fn_resp = types.FunctionResponse(
                        name="search_places",
                        response={"places": places}
                    )
                    return await ask_llm(fn_resp)

                # Add in the function handling section of ask_llm
                elif fn.name == "place_details":
                    try:
                        details = await place_details(**fn.args)
                        fn_resp = types.FunctionResponse(
                            name="place_details",
                            response=details
                        )
                        return await ask_llm(fn_resp)
                    except Exception as e:
                        print(f"Error getting place details: {e}")
                        return None, f"Error getting place details: {str(e)}"
                elif fn.name == "start_navigation":
                    try:
                        result = await start_navigation(**fn.args)
                        fn_resp = types.FunctionResponse(
                            name="start_navigation",
                            response=result
                        )
                        return await ask_llm(fn_resp)
                    except Exception as e:
                        print(f"Error starting navigation: {e}")
                        return None, f"Error starting navigation: {str(e)}"

                elif fn.name == "end_navigation":
                    try:
                        result = await end_navigation(**fn.args)
                        fn_resp = types.FunctionResponse(
                            name="end_navigation",
                            response=result
                        )
                        return await ask_llm(fn_resp)
                    except Exception as e:
                        print(f"Error ending navigation: {e}")
                        return None, f"Error ending navigation: {str(e)}"
                # Add in the function handling section of ask_llm:
                elif fn.name == "get_current_step":
                    step = await get_current_step()
                    fn_resp = types.FunctionResponse(
                        name="get_current_step",
                        response=step
                    )
                    return await ask_llm(fn_resp)

                elif fn.name == "get_current_location":
                    location = await get_current_location()
                    fn_resp = types.FunctionResponse(
                        name="get_current_location",
                        response={"lat": location[0], "lng": location[1]}
                    )
                    return await ask_llm(fn_resp)
                elif fn.name == "restart_navigation":
                    try:
                        result = await restart_navigation(**fn.args)
                        fn_resp = types.FunctionResponse(
                            name="restart_navigation",
                            response=result
                        )
                        return await ask_llm(fn_resp)
                    except Exception as e:
                        print(f"Error restarting navigation: {e}")
                        return None, f"Error restarting navigation: {str(e)}"
                elif fn.name == "get_full_route":
                    try:
                        route = await get_full_route()
                        fn_resp = types.FunctionResponse(
                            name="get_full_route",
                            response=route
                        )
                        return await ask_llm(fn_resp)
                    except Exception as e:
                        print(f"Error getting full route: {e}")
                        return None, f"Error getting full route: {str(e)}"
            except Exception as e:
                print(f"Error in {fn.name}: {e}")
                return None, f"Error executing {fn.name}: {str(e)}"

        # Handle text responses
        if hasattr(part, 'text') and part.text:
            return None, part.text

        # Try to extract text from parts
        if hasattr(resp.candidates[0].content, 'parts'):
            text_parts = [p.text for p in resp.candidates[0].content.parts
                          if hasattr(p, 'text') and p.text]
            if text_parts:
                return None, " ".join(text_parts)

        # Fallback to string conversion
        try:
            return None, str(resp)
        except:
            return None, "Could not extract text from response"
    except Exception as e:
        print(f"Error in ask_llm: {e}")
        print(traceback.format_exc())
        return None, f"Error in ask_llm: {str(e)}"

async def get_static_map_image(location, navigation_state) -> bytes:
    """
    Get a static map image from Google Maps API for the current location and route
    Returns the image as bytes
    """
    try:
        async with httpx.AsyncClient(timeout=10) as c:
            # Create static map URL with markers and appropriate zoom
            map_url = (
                "https://maps.googleapis.com/maps/api/staticmap?"
                f"center={location[0]},{location[1]}&"
                "zoom=17&"
                "size=600x600&"
                f"markers=color:red%7C{location[0]},{location[1]}&"
                "maptype=roadmap&"
                f"key={MAP_KEY}"
            )
            if navigation_state.status == "Navigating" and navigation_state.current_route:
                # Add path for navigation route if available
                polyline = navigation_state.current_route.get("polyline", {}).get("encodedPolyline", "")
                if polyline:
                    map_url += f"&path=weight:3%7Ccolor:blue%7Cenc:{polyline}"
            
            r = await c.get(map_url)
            r.raise_for_status()
            return r.content
    except Exception as e:
        print(f"Error getting static map: {e}")
        return None

async def chatbot_conversation(user_input: str, images=None) -> str:
    global chat, navigation_state, new_destination, mode_swicthed
    while True:
        location = await get_current_location()
        
        # Get static map and combine with other images
        map_image = await get_static_map_image(location, navigation_state)
        # Write the map image to a file for debugging
        if map_image:
            with open("map_image.jpg", "wb") as f:
                f.write(map_image)
            print("Map image saved as map_image.jpg")
        combined_images = []
        if map_image:
            combined_images.append(map_image)
        if images:
            if isinstance(images, bytes):
                combined_images.append(images)
            else:
                combined_images.extend(images)

        if navigation_state.status == "Navigating":
            navigation_state.current_step = deviation.get_current_step(
                location[0], location[1], navigation_state.current_route, 20)

        if new_destination:
            user_input = f"Take me to coordinate [{new_destination}]"
            new_destination = None

        response = await ask_llm(user_input, images=combined_images)
        if response[1] is not None and response[1] != "":
            break
    
    mode = "Navigation" if navigation_state.status == "Navigating" else "Idle"
    print(f"[Mode: {mode}]")  # debug

    return response[1]

if __name__ == "__main__":
    print("視障者助手已啟動。輸入 'exit' 結束對話。")
    print("[Mode: Idle]")
    set_current_location({"lat": 24.970476889286168, "lng": 121.19565504407139})  # Set initial location for testing
    while True:
        user_input = input("您: ")
        if user_input.lower() in ['exit', 'quit', '結束', '退出']:
            if navigation_state.status == "Navigating":
                asyncio.run(end_navigation())
            print("助手: 再見！")
            break

        response = asyncio.run(chatbot_conversation(user_input))
        print(f"助手: {response}")
