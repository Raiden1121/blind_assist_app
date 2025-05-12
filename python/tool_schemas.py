from google.genai import types

# tool_schemas.py －－ 交給 Gemini 的 JSON‑Schema
geocode_decl = types.FunctionDeclaration(
    name="geocode_place",
    description="Convert a place name to lat,lng, or return the given lat,lng if the query is CURRENT_LOCATION.",
    parameters={
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "要查詢的地址或地點名稱"
            },
            "current_lat": {"type": "number", "description": "latitude if query==CURRENT_LOCATION"},
            "current_lng": {"type": "number", "description": "longitude if query==CURRENT_LOCATION"},
        },
        "required": ["query"]
    }
)

# Add this alongside your existing declarations
reverse_geocode_decl = {
    "name": "reverse_geocode",
    "description": "Convert latitude and longitude coordinates into a human-readable address",
    "parameters": {
        "type": "object",
        "properties": {
            "lat": {
                "type": "number",
                "description": "Latitude coordinate"
            },
            "lng": {
                "type": "number",
                "description": "Longitude coordinate"
            }
        },
        "required": ["lat", "lng"]
    }
}

route_decl = types.FunctionDeclaration(
    name="compute_route",
    description="計算從起點到終點的路線步驟",
    parameters={
        "type": "object",
        "properties": {
            "origin": {
                "type": "string",
                "description": "起點座標，格式為 'lat,lng'"
            },
            "destination": {
                "type": "string",
                "description": "終點座標，格式為 'lat,lng'"
            },
            "mode": {
                "type": "string",
                "enum": ["WALK", "DRIVE", "TRANSIT"],
                "description": "交通方式"
            }
        },
        "required": ["origin", "destination"]
    }
)
