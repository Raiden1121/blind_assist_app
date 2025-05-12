import os
import json
import asyncio
import httpx
import dotenv
import math
from google import genai  # v1.x import path
from google.genai import types  # FunctionCall / Content
from tool_schemas import geocode_decl, route_decl, reverse_geocode_decl

dotenv.load_dotenv()
MAP_KEY = os.getenv("GOOGLE_MAPS_KEY")

system_instruction = """
你是一個專為視障者設計的數位助理，配備了強大的導航能力。

當用戶提出以下類型的請求時，你應該使用導航工具功能：
1. 明確的導航請求：例如「帶我去XXX」、「怎麼走到XXX」、「前往XXX」
2. 含有方向相關詞彙：例如「走去」、「過去」、「去到」
3. 詢問位置或路線的問題：例如「XXX在哪裡」、「如何前往XXX」

在導航過程中，你應該：
- 優先調用 geocode_place 來找到目的地位置
- 接著調用 compute_route 計算路線
- 最後將路線指示轉換成對視障者友好的描述

對於非導航的一般問題，請直接回答，不要使用工具函數。

請特別注意，如果用戶提到「我現在位置」或「我在這裡」，你應該使用 geocode_place 並將 query 參數設為 "CURRENT_LOCATION"。
"""

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))  # v1.x client

routes_tool = [types.Tool(function_declarations=[
    route_decl,
    geocode_decl,
    reverse_geocode_decl
])]

config = {
    "tools": routes_tool,  # FunctionCall schema
    "automatic_function_calling": {
        "disable": True
    },
    # "tool_config": {
    #     "function_calling_config": {
    #         "mode": "any"
    #     }
    # },
    "system_instruction": system_instruction
}

chat = client.chats.create(model="gemini-2.0-flash-001", config=config)


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


async def geocode_place(query: str,
                        current_lat: float | None = None,
                        current_lng: float | None = None) -> dict:
    if query == "CURRENT_LOCATION":
        if current_lat is None or current_lng is None:
            raise ValueError(
                "CURRENT_LOCATION requires current_lat & current_lng")
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
    return data["routes"][0]["legs"][0]["steps"]


# ───────── Recursive tool orchestration ─────────
async def ask_llm(message):
    """
    • message   : str  – user prompt  OR
                  types.Content – function response
    • returns   : (steps | None, str LLM_text)
    """
    # Print for debugging what's being sent to the model
    print(f"Sending to model: {type(message)}",
          message if isinstance(message, str) else "Function response")

    # Handle different message types
    if isinstance(message, types.Content):
        # Extract the parts from Content and send them individually
        parts = message.parts
        if parts and len(parts) > 0:
            resp = chat.send_message(parts[0])
        else:
            resp = chat.send_message("Empty content")
    elif isinstance(message, types.FunctionResponse):
        # Create a proper Part with function_response
        part = types.Part(function_response=message)
        resp = chat.send_message(part)
    elif isinstance(message, types.Part):
        # Send Part directly
        resp = chat.send_message(message)
    else:
        # For string input
        resp = chat.send_message(message)
    print("Response type:", type(resp))

    # Check if there are any candidates
    if not resp.candidates:
        print("No candidates in response")
        return None, "No response from model"

    part = resp.candidates[0].content.parts[0]
    print("Part type:", type(part))

    # Check for function calls
    if hasattr(part, 'function_call') and part.function_call:
        fn = part.function_call
        print(f"Function call detected: {fn.name}")

        if fn.name == "geocode_place":
            if fn.args.get("query") == "CURRENT_LOCATION":
                # 如果 LLM 沒帶經緯度 → 我們自己取
                if "current_lat" not in fn.args or "current_lng" not in fn.args:
                    lat, lng = await get_current_location()
                    fn.args["current_lat"] = lat
                    fn.args["current_lng"] = lng

            geo = await geocode_place(**fn.args)
            print("Geocode result:", geo)

            # Create a FunctionResponse
            fn_resp = types.FunctionResponse(name="geocode_place",
                                             response=geo)
            print("FunctionResponse:", fn_resp)
            # Send the function response back to model
            return await ask_llm(fn_resp)
        # Add this inside the if hasattr(part, 'function_call') block in ask_llm
        elif fn.name == "reverse_geocode":
            try:
                address_info = await reverse_geocode(**fn.args)
                print("Reverse geocode result:", address_info)

                fn_resp = types.FunctionResponse(
                    name="reverse_geocode",
                    response=address_info
                )
                return await ask_llm(fn_resp)
            except Exception as e:
                print(f"Error in reverse geocoding: {e}")
            return None, f"Error getting address: {str(e)}"
        elif fn.name == "compute_route":
            try:
                steps = await compute_route(**fn.args)
                print(f"Got route with {len(steps)} steps")

                # Create a FunctionResponse
                fn_resp = types.FunctionResponse(name="compute_route",
                                                 response={
                                                     "steps": steps
                                                 })

                # Send to model and get navigation instructions
                part = types.Part(function_response=message)
                nav = chat.send_message(part)

                # Check if there's text in the response
                if nav.candidates and nav.candidates[0].content.parts:
                    text_parts = [
                        p.text for p in nav.candidates[0].content.parts
                        if hasattr(p, 'text') and p.text
                    ]
                    nav_text = " ".join(
                        text_parts) if text_parts else "No text in response"
                else:
                    nav_text = "No response text available"

                return steps, nav_text
            except Exception as e:
                print(f"Error computing route: {e}")
                return None, f"Error computing route: {e}"

    # Check if there's text in the part
    if hasattr(part, 'text') and part.text:
        return None, part.text

    # Try to extract any text parts
    if hasattr(resp.candidates[0].content, 'parts'):
        text_parts = [
            p.text for p in resp.candidates[0].content.parts
            if hasattr(p, 'text') and p.text
        ]
        if text_parts:
            return None, " ".join(text_parts)

    # If we can't extract text, check if there's any content that can be converted to string
    try:
        return None, str(resp)
    except:
        return None, "Could not extract text from response"


async def chatbot_conversation(user_input: str):
    steps, response = await ask_llm(user_input)
    return response


# ───────── quick test ─────────
if __name__ == "__main__":
    # steps, first = asyncio.run(ask_llm("請帶我走路去中壢車站"))
    # steps, first = asyncio.run(ask_llm("幫我寫merge_sort"))
    print("視障者助手已啟動。輸入 'exit' 結束對話。")

    while True:
        user_input = input("您: ")
        if user_input.lower() in ['exit', 'quit', '結束', '退出']:
            print("助手: 再見！")
            break

        response = asyncio.run(chatbot_conversation(user_input))
        print(f"助手: {response}")
