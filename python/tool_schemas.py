from google.genai import types

# tool_schemas.py －－ 交給 Gemini 的 JSON‑Schema

geocode_decl = types.FunctionDeclaration(
    name="geocode_place",
    description="Convert a address or place name to lat,lng. if the function fail or query is not a well-known location or explicit address, you should use search_places to get a list of possible matches first",
    parameters={
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "address or place name"
            }
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
    description="Compute a route between two locations with optional transportation mode",
    parameters={
        "type": "object",
        "properties": {
            "origin": {
                "type": "string",
                "description": "starting location, formatted as 'lat,lng'"
            },
            "destination": {
                "type": "string",
                "description": "destination location, formatted as 'lat,lng'"
            },
            "mode": {
                "type": "string",
                "enum": ["WALK", "DRIVE", "TRANSIT", "BICYCLE", "TWO_WHEELER"],
                "description": "transportation mode"
            }
        },
        "required": ["origin", "destination"]
    }
)

# Add to your existing schemas
search_places_decl = {
    "name": "search_places",
    "description": "Search for places using text query, optionally filtered by location and radius",
    "parameters": {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "Search text query"
            },
            "location": {
                "type": "object",
                "properties": {
                    "lat": {"type": "number"},
                    "lng": {"type": "number"}
                },
                "description": "Optional center point for location-based search"
            },
            "radius": {
                "type": "number",
                "description": "Optional search radius in meters (max 50000)"
            }
        },
        "required": ["query"]
    }
}

place_details_decl = types.FunctionDeclaration(
    name="place_details",
    description="Get detailed information about a place including opening hours, contact info, and reviews",
    parameters={
        "type": "object",
        "properties": {
            "place_id": {
                "type": "string",
                "description": "The Google Places API place_id of the location"
            }
        },
        "required": ["place_id"]
    }
)

start_navigation_decl = types.FunctionDeclaration(
    name="start_navigation",
    description="Start navigation with the currently computed route",
    parameters={
        "type": "object",
        "properties": {},
        "required": []
    }
)

end_navigation_decl = types.FunctionDeclaration(
    name="end_navigation",
    description="End the current navigation session and reset navigation state",
    parameters={
        "type": "object",
        "properties": {},
        "required": []
    }
)


get_current_step_decl = types.FunctionDeclaration(
    name="get_current_step",
    description="Get the current navigation step that the user is on",
    parameters={
        "type": "object",
        "properties": {},
        "required": []
    }
)

get_current_location_decl = types.FunctionDeclaration(
    name="get_current_location",
    description="Get the user's current geographic location",
    parameters={
        "type": "object",
        "properties": {},
        "required": []
    }
)

# ...existing code...
restart_navigation_decl = {
    "name": "restart_navigation",
    "description": "Set a new destination and abort current navigation",
    "parameters": {
        "type": "object",
        "properties": {
            "new_location": {
                "type": "string",
                "description": "The new destination location to navigate to, formatted as 'lat,lng'"
            }
        },
        "required": ["new_location"]
    }
}
