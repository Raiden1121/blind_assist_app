
import math
import polyline
from shapely.geometry import Point, LineString


def decode_google_polyline(encoded_polyline_string):
    """Decodes an encoded polyline string from Google Maps."""
    try:
        return polyline.decode(encoded_polyline_string)
    except Exception as e:
        print(f"Error decoding polyline: {e}")
        return []


def haversine_distance(lat1, lon1, lat2, lon2):
    """Calculates great-circle distance in meters between two lat/lon points."""
    R = 6371000  # Earth radius in meters
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = math.sin(delta_phi / 2)**2 + \
        math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def shortest_distance_to_route(user_lat, user_lon, route_coordinates):
    """
    Calculates the shortest distance (in meters) from a user's location
    to the route using Shapely.
    """
    if not route_coordinates:
        return float('inf')

    user_point_shapely = Point(user_lon, user_lat)  # Shapely uses (lon, lat)

    if len(route_coordinates) == 1:  # Route is a single point
        r_lat, r_lon = route_coordinates[0]
        return haversine_distance(user_lat, user_lon, r_lat, r_lon)

    # Convert route to Shapely LineString (lon, lat format)
    route_linestring_coords = [(lon, lat) for lat, lon in route_coordinates]
    route_line = LineString(route_linestring_coords)

    # Find the closest point on the line to the user's point
    closest_point_on_line = route_line.interpolate(
        route_line.project(user_point_shapely))
    closest_lon, closest_lat = closest_point_on_line.x, closest_point_on_line.y

    return haversine_distance(user_lat, user_lon, closest_lat, closest_lon)


def has_user_deviated(user_lat, user_lon, route_coordinates, deviation_tolerance_meters):
    """
    Checks if the user has deviated from the route beyond a given tolerance.
    The route_coordinates here represent the *entire* path.
    """
    if not route_coordinates:
        print("Route is empty for deviation check. Assuming deviation.")
        return True

    min_dist = shortest_distance_to_route(
        user_lat, user_lon, route_coordinates)
    print(f"Shortest distance to overall route: {min_dist:.2f} meters")

    return min_dist > deviation_tolerance_meters


def get_current_step(user_lat, user_lon, route, tolerance_meters):
    """
    Determines which step of a Google Maps route the user is currently on.

    Args:
        user_lat (float): User's current latitude.
        user_lon (float): User's current longitude.
        google_routes_response (dict): The full JSON response from Google Directions API.
        tolerance_meters (float): Maximum distance in meters to consider the user "on" a step.

    Returns:
        dict: The step object the user is on, or None if not on any step within tolerance.
              Returns a tuple (leg_index, step_index, step_object) if found.
    """

    for leg_index, leg in enumerate(route.get('legs', [])):
        for step_index, step in enumerate(leg.get('steps', [])):
            if 'polyline' in step and 'encodedPolyline' in step['polyline']:
                encoded_step_polyline = step['polyline']['encodedPolyline']
                decoded_step_path = decode_google_polyline(
                    encoded_step_polyline)

                if not decoded_step_path:
                    # print(f"Warning: Could not decode polyline for leg {leg_index}, step {step_index}")
                    continue

                distance_to_step_path = shortest_distance_to_route(
                    user_lat, user_lon, decoded_step_path)
                # print(f"Distance to leg {leg_index}, step {step_index}: {distance_to_step_path:.2f}m")

                if distance_to_step_path <= tolerance_meters:
                    print(
                        f"User is ON leg {leg_index}, step {step_index} (Distance: {distance_to_step_path:.2f}m)")
                    return {"leg_index": leg_index, "step_index": step_index, "step_info": step}
            else:
                # print(f"Warning: No polyline found for leg {leg_index}, step {step_index}")
                pass  # No polyline for this step

    print(
        f"User is not on any specific step within {tolerance_meters}m tolerance.")
    return None
