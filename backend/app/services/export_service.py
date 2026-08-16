import json
from typing import List
from app.models.ride import Ride
from app.models.location_point import LocationPoint


def export_ride_to_gpx(ride: Ride, points: List[LocationPoint]) -> str:
    """Generate GPX 1.1 formatted XML string from a ride and its location points."""
    gpx_lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<gpx version="1.1" creator="RideTrack Smartphone Tracker" xmlns="http://www.topografix.com/GPX/1/1">',
        '  <metadata>',
        f'    <name>RideTrack Trip {ride.started_at.strftime("%Y-%m-%d %H:%M")}</name>',
        f'    <time>{ride.started_at.isoformat()}</time>',
        '  </metadata>',
        '  <trk>',
        f'    <name>Motorcycle Ride - {ride.total_distance_km} km</name>',
        '    <trkseg>'
    ]

    for pt in points:
        elev_str = f"        <ele>{pt.altitude}</ele>\n" if pt.altitude is not None else ""
        time_str = f"        <time>{pt.timestamp.isoformat()}</time>\n"
        speed_str = f"        <speed>{round(pt.speed_kmh / 3.6, 2)}</speed>\n"
        
        gpx_lines.append(
            f'      <trkpt lat="{pt.latitude}" lon="{pt.longitude}">\n'
            f'{elev_str}{time_str}{speed_str}'
            f'      </trkpt>'
        )

    gpx_lines.extend([
        '    </trkseg>',
        '  </trk>',
        '</gpx>'
    ])

    return "\n".join(gpx_lines)


def export_ride_to_geojson(ride: Ride, points: List[LocationPoint]) -> str:
    """Generate RFC 7946 GeoJSON FeatureCollection."""
    coords = []
    point_features = []

    for pt in points:
        alt = pt.altitude if pt.altitude is not None else 0.0
        coords.append([pt.longitude, pt.latitude, alt])

        point_features.append({
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [pt.longitude, pt.latitude, alt]
            },
            "properties": {
                "timestamp": pt.timestamp.isoformat(),
                "speed_kmh": pt.speed_kmh,
                "heading": pt.heading,
                "accuracy_m": pt.accuracy_m,
                "battery_pct": pt.battery_pct
            }
        })

    linestring_feature = {
        "type": "Feature",
        "geometry": {
            "type": "LineString",
            "coordinates": coords
        },
        "properties": {
            "ride_id": ride.id,
            "total_distance_km": ride.total_distance_km,
            "duration_seconds": ride.duration_seconds,
            "average_speed_kmh": ride.average_speed_kmh,
            "max_speed_kmh": ride.max_speed_kmh,
            "started_at": ride.started_at.isoformat(),
            "ended_at": ride.ended_at.isoformat(),
        }
    }

    feature_collection = {
        "type": "FeatureCollection",
        "features": [linestring_feature] + point_features
    }

    return json.dumps(feature_collection, indent=2)
