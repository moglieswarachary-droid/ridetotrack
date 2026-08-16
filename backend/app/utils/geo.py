import math
from typing import List, Tuple, Dict, Any


def haversine_distance_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate great-circle distance between two points on the Earth's surface in meters."""
    R = 6371000.0  # Earth radius in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (math.sin(delta_phi / 2.0) ** 2 +
         math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2)
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return R * c


def calculate_bearing_degrees(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate the forward azimuth (initial bearing in degrees 0-360) from point 1 to point 2."""
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_lambda = math.radians(lon2 - lon1)

    y = math.sin(delta_lambda) * math.cos(phi2)
    x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(delta_lambda)
    bearing = (math.degrees(math.atan2(y, x)) + 360.0) % 360.0
    return round(bearing, 1)


def degrees_to_cardinal(degrees: float) -> str:
    """Convert bearing in degrees to 16-point cardinal compass direction."""
    dirs = [
        "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
        "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"
    ]
    ix = int((degrees + 11.25) / 22.5) % 16
    return dirs[ix]


def simplify_points_rdp(points: List[Tuple[float, float]], epsilon: float = 0.00005) -> List[Tuple[float, float]]:
    """Ramer-Douglas-Peucker algorithm to simplify GPS coordinates for fast map rendering."""
    if len(points) <= 2:
        return points

    def perpendicular_distance(pt, line_start, line_end):
        if line_start == line_end:
            return math.hypot(pt[0] - line_start[0], pt[1] - line_start[1])
        dx = line_end[0] - line_start[0]
        dy = line_end[1] - line_start[1]
        mag = math.hypot(dx, dy)
        if mag == 0.0:
            return 0.0
        u = ((pt[0] - line_start[0]) * dx + (pt[1] - line_start[1]) * dy) / (mag * mag)
        if u < 0.0:
            return math.hypot(pt[0] - line_start[0], pt[1] - line_start[1])
        elif u > 1.0:
            return math.hypot(pt[0] - line_end[0], pt[1] - line_end[1])
        proj = (line_start[0] + u * dx, line_start[1] + u * dy)
        return math.hypot(pt[0] - proj[0], pt[1] - proj[1])

    # Find the point with the maximum distance
    dmax = 0.0
    index = 0
    for i in range(1, len(points) - 1):
        d = perpendicular_distance(points[i], points[0], points[-1])
        if d > dmax:
            index = i
            dmax = d

    if dmax > epsilon:
        rec_results1 = simplify_points_rdp(points[:index + 1], epsilon)
        rec_results2 = simplify_points_rdp(points[index:], epsilon)
        return rec_results1[:-1] + rec_results2
    else:
        return [points[0], points[-1]]


def encode_polyline(coordinates: List[Tuple[float, float]]) -> str:
    """Encode latitude/longitude coordinate pairs into Google Polyline format."""
    def _encode_value(value: int) -> str:
        value = ~(value << 1) if value < 0 else (value << 1)
        chunks = []
        while value >= 0x20:
            chunks.append(chr((0x20 | (value & 0x1f)) + 63))
            value >>= 5
        chunks.append(chr(value + 63))
        return "".join(chunks)

    result = []
    prev_lat = 0
    prev_lng = 0

    for lat, lng in coordinates:
        lat_int = int(round(lat * 1e5))
        lng_int = int(round(lng * 1e5))

        d_lat = lat_int - prev_lat
        d_lng = lng_int - prev_lng

        result.append(_encode_value(d_lat))
        result.append(_encode_value(d_lng))

        prev_lat = lat_int
        prev_lng = lng_int

    return "".join(result)


def points_to_geojson_linestring(points: List[Tuple[float, float, Any]]) -> Dict[str, Any]:
    """Convert points [(lat, lng, ...)] to a GeoJSON LineString feature."""
    # GeoJSON coordinates order is [longitude, latitude, elevation/alt]
    coords = []
    for pt in points:
        lat, lng = pt[0], pt[1]
        alt = pt[2] if len(pt) > 2 and pt[2] is not None else 0.0
        coords.append([lng, lat, alt])
    
    return {
        "type": "Feature",
        "geometry": {
            "type": "LineString",
            "coordinates": coords
        },
        "properties": {
            "total_points": len(coords)
        }
    }
