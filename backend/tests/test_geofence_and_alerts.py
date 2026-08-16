import pytest
from httpx import AsyncClient
from datetime import datetime, timezone


@pytest.mark.asyncio
async def test_geofence_creation_and_breach_detection(client: AsyncClient):
    # Register & add bike
    reg_res = await client.post("/api/v1/auth/register", json={
        "email": "geofence_rider@track.com",
        "password": "RiderPassword123!",
        "full_name": "Geofence Test Rider"
    })
    token = reg_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    bike_res = await client.post("/api/v1/bikes", json={
        "name": "Ninja 650",
        "manufacturer": "Kawasaki",
        "model": "Ninja 650",
        "registration_number": "KA-03-GH-9900",
        "year": 2024,
        "is_active": True
    }, headers=headers)
    bike = bike_res.json()

    # 1. Create a 50-meter Geofence around Home Parking Spot
    gf_res = await client.post("/api/v1/geofences", json={
        "bike_id": bike["id"],
        "name": "Home Parking Bay",
        "latitude": 12.971598,
        "longitude": 77.594562,
        "radius_meters": 50.0,
        "notify_on_exit": True
    }, headers=headers)
    assert gf_res.status_code == 201
    geofence = gf_res.json()
    assert geofence["radius_meters"] == 50.0

    # 2. Start ride
    start_res = await client.post("/api/v1/tracking/start", json={"bike_id": bike["id"]}, headers=headers)
    session_id = start_res.json()["id"]

    # 3. Ingest coordinate 250 meters away (breaching 50m radius)
    ingest_res = await client.post(f"/api/v1/tracking/{session_id}/locations", json={
        "points": [
            {
                "latitude": 12.974000,
                "longitude": 77.597000,
                "speed_kmh": 35.0,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
        ]
    }, headers=headers)
    assert ingest_res.status_code == 200

    # 4. Verify Alert was automatically generated
    alerts_res = await client.get("/api/v1/alerts", headers=headers)
    assert alerts_res.status_code == 200
    alerts = alerts_res.json()
    assert len(alerts) >= 1
    assert alerts[0]["alert_type"] == "geofence_exit"

    # 5. Acknowledge alert
    ack_res = await client.post(f"/api/v1/alerts/{alerts[0]['id']}/acknowledge", headers=headers)
    assert ack_res.status_code == 200
    assert ack_res.json()["is_acknowledged"] is True
