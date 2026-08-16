import pytest
from httpx import AsyncClient
from datetime import datetime, timezone, timedelta


async def setup_rider_with_bike(client: AsyncClient, email: str = "tracker@track.com"):
    reg_res = await client.post("/api/v1/auth/register", json={
        "email": email,
        "password": "RideTrackPassword1!",
        "full_name": "Rider One"
    })
    token = reg_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    bike_res = await client.post("/api/v1/bikes", json={
        "name": "KTM 390 Adventure",
        "manufacturer": "KTM",
        "model": "390 Adventure",
        "registration_number": "KA-05-AB-7788",
        "year": 2024,
        "is_active": True
    }, headers=headers)
    bike = bike_res.json()
    return headers, bike


@pytest.mark.asyncio
async def test_start_ride_ingest_points_and_stop_finalization(client: AsyncClient):
    headers, bike = await setup_rider_with_bike(client)

    # 1. Start tracking session
    start_res = await client.post("/api/v1/tracking/start", json={
        "bike_id": bike["id"],
        "tracking_mode": "balanced",
        "battery_pct": 92
    }, headers=headers)
    assert start_res.status_code == 201
    session = start_res.json()
    session_id = session["id"]
    assert session["status"] == "active"

    # 2. Check active ride
    active_res = await client.get("/api/v1/tracking/active", headers=headers)
    assert active_res.status_code == 200
    assert active_res.json()["id"] == session_id

    # 3. Ingest GPS points batch (simulating motorcycle ride through a canyon/city)
    now = datetime.now(timezone.utc)
    points_batch = {
        "points": [
            {
                "latitude": 12.971598,
                "longitude": 77.594562,
                "altitude": 920.0,
                "speed_kmh": 0.0,
                "heading": 90.0,
                "accuracy_m": 4.5,
                "battery_pct": 92,
                "timestamp": (now).isoformat()
            },
            {
                "latitude": 12.972100,
                "longitude": 77.595800,
                "altitude": 922.0,
                "speed_kmh": 38.5,
                "heading": 85.0,
                "accuracy_m": 3.8,
                "battery_pct": 91,
                "timestamp": (now + timedelta(seconds=5)).isoformat()
            },
            {
                "latitude": 12.973500,
                "longitude": 77.598200,
                "altitude": 928.0,
                "speed_kmh": 54.2,
                "heading": 80.0,
                "accuracy_m": 3.2,
                "battery_pct": 90,
                "timestamp": (now + timedelta(seconds=10)).isoformat()
            },
            {
                # Outlier to test drift rejection filter
                "latitude": 0.0001,
                "longitude": 0.0001,
                "accuracy_m": 999.0,
                "speed_kmh": 400.0,
                "timestamp": (now + timedelta(seconds=12)).isoformat()
            },
            {
                "latitude": 12.975200,
                "longitude": 77.601500,
                "altitude": 932.0,
                "speed_kmh": 62.8,
                "heading": 78.0,
                "accuracy_m": 3.0,
                "battery_pct": 90,
                "timestamp": (now + timedelta(seconds=20)).isoformat()
            }
        ]
    }
    ingest_res = await client.post(f"/api/v1/tracking/{session_id}/locations", json=points_batch, headers=headers)
    assert ingest_res.status_code == 200
    ingest_data = ingest_res.json()
    # Outlier must be rejected
    assert ingest_data["ingested_count"] == 4

    # 4. Check live telemetry
    live_res = await client.get(f"/api/v1/tracking/{session_id}/live", headers=headers)
    assert live_res.status_code == 200
    live_data = live_res.json()
    assert live_data["speed_kmh"] == 62.8
    assert live_data["distance_km"] > 0

    # 5. Pause & Resume
    pause_res = await client.post(f"/api/v1/tracking/{session_id}/pause", headers=headers)
    assert pause_res.json()["status"] == "paused"
    resume_res = await client.post(f"/api/v1/tracking/{session_id}/resume", headers=headers)
    assert resume_res.json()["status"] == "active"

    # 6. Stop and finalize ride
    stop_res = await client.post(f"/api/v1/tracking/{session_id}/stop", headers=headers)
    assert stop_res.status_code == 200
    ride = stop_res.json()
    assert ride["total_distance_km"] > 0
    assert ride["max_speed_kmh"] == 62.8
    assert ride["elevation_gain_m"] >= 10.0
    ride_id = ride["id"]

    # 7. Verify in Ride History
    history_res = await client.get("/api/v1/rides", headers=headers)
    assert len(history_res.json()) == 1

    # 8. Route Replay points
    replay_res = await client.get(f"/api/v1/rides/{ride_id}/route", headers=headers)
    assert replay_res.status_code == 200
    route_data = replay_res.json()
    assert route_data["total_points"] == 4

    # 9. GPX & GeoJSON Export
    gpx_res = await client.get(f"/api/v1/rides/{ride_id}/export/gpx", headers=headers)
    assert gpx_res.status_code == 200
    assert "<gpx" in gpx_res.text

    geojson_res = await client.get(f"/api/v1/rides/{ride_id}/export/geojson", headers=headers)
    assert geojson_res.status_code == 200
    assert "FeatureCollection" in geojson_res.text
