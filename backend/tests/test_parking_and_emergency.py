import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_parking_spot_and_emergency_sos(client: AsyncClient):
    reg_res = await client.post("/api/v1/auth/register", json={
        "email": "safety_rider@track.com",
        "password": "RiderPassword123!",
        "full_name": "Safety Rider"
    })
    token = reg_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    bike_res = await client.post("/api/v1/bikes", json={
        "name": "Tiger 900 Rally Pro",
        "manufacturer": "Triumph",
        "model": "Tiger 900",
        "registration_number": "KA-01-TR-9090",
        "year": 2024,
        "is_active": True
    }, headers=headers)
    bike = bike_res.json()

    # 1. Save parking spot
    park_res = await client.post("/api/v1/parking", json={
        "bike_id": bike["id"],
        "latitude": 12.971598,
        "longitude": 77.594562,
        "address": "MG Road Underground Parking Bay B12",
        "note": "Parked next to pillar 4"
    }, headers=headers)
    assert park_res.status_code == 201
    parking = park_res.json()
    assert parking["note"] == "Parked next to pillar 4"

    # 2. Get current parking spot
    get_park = await client.get("/api/v1/parking/current", headers=headers)
    assert get_park.status_code == 200
    assert get_park.json()["id"] == parking["id"]

    # 3. Calculate walking direction back to bike from 100m away
    dir_res = await client.get(
        "/api/v1/parking/directions",
        params={"current_lat": 12.972500, "current_lng": 77.594562},
        headers=headers
    )
    assert dir_res.status_code == 200
    directions = dir_res.json()
    assert directions["distance_meters"] > 0
    assert "cardinal_direction" in directions

    # 4. Add Emergency Contact
    contact_res = await client.post("/api/v1/emergency-contacts", json={
        "name": "Sarah Connor",
        "phone_number": "+14155558989",
        "relationship_type": "spouse",
        "notify_on_crash": True,
        "notify_on_sos": True
    }, headers=headers)
    assert contact_res.status_code == 201
    contact = contact_res.json()

    # 5. Trigger SOS Broadcast
    sos_res = await client.post("/api/v1/emergency-contacts/sos-broadcast", json={
        "latitude": 12.971598,
        "longitude": 77.594562,
        "message": "Flat tire on mountain pass",
        "battery_pct": 45
    }, headers=headers)
    assert sos_res.status_code == 200
    assert sos_res.json()["contacts_notified_count"] == 1

    # 6. Report Crash Detection Event
    crash_res = await client.post("/api/v1/alerts/crash-report", json={
        "bike_id": bike["id"],
        "latitude": 12.971598,
        "longitude": 77.594562,
        "impact_g": 4.5,
        "speed_before_impact_kmh": 65.0,
        "cancellation_timed_out": True
    }, headers=headers)
    assert crash_res.status_code == 200
    assert crash_res.json()["alert_type"] == "crash"
    assert crash_res.json()["severity"] == "emergency"
