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
dotenv.load_dotenv()
MAP_KEY = os.getenv("GOOGLE_MAPS_KEY")
# Replace existing system_instruction with:
idle_instruction = """
You are a digital assistant specifically designed for visually impaired users, equipped with powerful navigation capabilities.

You should use navigation tools for the following types of requests:
1. Explicit navigation requests: e.g., "take me to XXX", "how to get to XXX", "go to XXX"
2. Phrases containing directional words: e.g., "walk to", "go over to", "get to"
3. Questions about locations or routes: e.g., "where is XXX", "how to reach XXX"

For location-related requests:
- First use geocode_place to find the destination location
- Then use compute_route to calculate the route
- Ask whether the user wants to use this route, providing the distance and estimated time
- If the user agrees, call start_navigation to begin guided navigation

For non-navigation questions, respond directly without using tool functions.

Important: Call only one function at a time and wait for its result before deciding the next step.
"""


def get_navigation_instruction(route_info):
    return f"""
You are now in navigation mode, actively guiding a visually impaired user along their route.
Current route information:
{json.dumps(route_info, indent=2)}

Your responsibilities:
1. Process user's current location and progress along the route
2. Provide clear, concise directions for the next step
3. Alert about any obstacles or hazards detected in camera images
4. Monitor arrival at waypoints or destination
5. Call end_navigation when:
   - User requests to stop navigation
   - User has arrived at destination
   - Navigation needs to be cancelled

Keep instructions brief and clear. Focus on immediate next steps and safety.
Important: Call only one function at a time and wait for its result before deciding the next step.
"""


client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))  # v1.x client

routes_tool = [types.Tool(function_declarations=[
    route_decl,
    geocode_decl,
    reverse_geocode_decl,
    search_places_decl,
    place_details_decl,
    start_navigation_decl,
    end_navigation_decl  # Add this line
])]
MODEL = "gemini-2.0-flash"


@dataclass
class NavigationState:
    status: str = "Idle"
    current_route = None
    current_step = None
    chat = None  # Add this field


class ChatManager:
    def __init__(self, api_key, tools):
        self.api_key = api_key
        self.tools = tools
        self.idle_chat = None
        self.nav_chat = None

    def create_idle_chat(self):
        config = {
            "tools": self.tools,
            "system_instruction": idle_instruction
        }
        self.idle_chat = client.chats.create(
            model=MODEL, config=config)
        return self.idle_chat

    def create_navigation_chat(self, route_info):
        config = {
            "tools": self.tools,
            "system_instruction": get_navigation_instruction(route_info)
        }
        self.nav_chat = client.chats.create(
            model=MODEL, config=config)
        return self.nav_chat


chat_manager = ChatManager(os.getenv("GEMINI_API_KEY"), routes_tool)
chat = chat_manager.create_idle_chat()  # Initialize with idle chat


navigation_state = NavigationState()


async def get_current_location() -> tuple[float, float]:
    """
    優先用 ipapi ≈ 300 毫秒；失敗再後備 geocoder.ip('me')
    回傳 (lat, lng)
    """
    current_loc = [24.970632523750954, 121.1955897039094]  # 中壢火車站
    print("Getting current location: ", current_loc)  # debug
    return current_loc
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
    if query == "CURRENT_LOCATION":
        # Use the current location from the get_current_location function
        current_lat, current_lng = await get_current_location()
        return {"lat": current_lat, "lng": current_lng}

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
        print(f"Searching places: {query}")  # debug
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


async def start_navigation() -> None:
    """
    Starts navigation with the current route and creates a new navigation-focused chat
    """
    global navigation_state, chat

    if not navigation_state.current_route:
        raise ValueError("Cannot start navigation without route")

    navigation_state.status = "Navigating"
    navigation_state.current_step = navigation_state.current_route.get("legs", [{}])[
        0].get("steps", [])[0]  # Get the first step

    # Create new chat with navigation context
    chat = chat_manager.create_navigation_chat(navigation_state.current_route)
    print("Navigation started")  # debug
    return


async def end_navigation() -> None:
    """
    Ends navigation and returns to idle chat mode
    """
    global navigation_state, chat

    if navigation_state.status != "Navigating":
        raise ValueError("No active navigation session to end")

    navigation_state.status = "Idle"
    navigation_state.current_route = None
    navigation_state.current_step = None

    # Return to idle chat
    chat = chat_manager.create_idle_chat()
    print("Navigation ended")  # debug
    return

# ───────── Recursive tool orchestration ─────────


async def ask_llm(message, image=None, images=None):
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
        elif isinstance(message, str) and (image is not None or images is not None):
            message_parts = []
            message_parts.append(message)

            if image is not None:
                print(f"Adding single image: {len(image)} bytes")
                message_parts.append(types.Part.from_bytes(
                    data=image, mime_type="image/jpeg"))
            elif images is not None:
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
        return None, f"Error in ask_llm: {str(e)}"


async def chatbot_conversation(user_input: str):
    global chat, navigation_state
    location = await get_current_location()

    info = "Current User Location: " + str(location) + "\n"
    if navigation_state.status == "Navigating":
        # If in navigation mode, use the current step for context
        navigation_state.current_step = deviation.get_current_step(
            location[0], location[1], navigation_state.current_route, 20)
        info += "\n"+"Current Step: "+str(navigation_state.current_step)+"\n"

    response = await ask_llm(info+user_input)

    # Print mode-specific status
    mode = "Navigation" if navigation_state.status == "Navigating" else "Idle"
    print(f"[Mode: {mode}]")  # debug

    return response[1]

if __name__ == "__main__":
    print("視障者助手已啟動。輸入 'exit' 結束對話。")
    print("[Mode: Idle]")

    while True:
        user_input = input("您: ")
        if user_input.lower() in ['exit', 'quit', '結束', '退出']:
            if navigation_state.status == "Navigating":
                asyncio.run(end_navigation())
            print("助手: 再見！")
            break

        response = asyncio.run(chatbot_conversation(user_input))
        print(f"助手: {response}")
