import pytest
from httpx import AsyncClient
from datetime import datetime, timezone


@pytest.mark.asyncio
async def test_live_sharing_creation_and_public_viewer(client: AsyncClient):
    # Register & add bike & start session
    reg_res = await client.post("/api/v1/auth/register", json={
        "email": "sharer@track.com",
        "password": "RiderPassword123!",
        "full_name": "Sharing Rider"
    })
    token = reg_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    bike_res = await client.post("/api/v1/bikes", json={
        "name": "Hayabusa",
        "manufacturer": "Suzuki",
        "model": "GSX-1300R",
        "registration_number": "KA-01-SU-1300",
        "year": 2024,
        "is_active": True
    }, headers=headers)
    bike = bike_res.json()

    start_res = await client.post("/api/v1/tracking/start", json={"bike_id": bike["id"]}, headers=headers)
    session_id = start_res.json()["id"]

    # Ingest a point
    await client.post(f"/api/v1/tracking/{session_id}/locations", json={
        "points": [
            {
                "latitude": 12.971598,
                "longitude": 77.594562,
                "speed_kmh": 45.0,
                "battery_pct": 88,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
        ]
    }, headers=headers)

    # 1. Create a 6-hour Live Share link
    share_res = await client.post("/api/v1/shares", json={
        "session_id": session_id,
        "duration_hours": 6,
        "recipient_label": "Family Guardian"
    }, headers=headers)
    assert share_res.status_code == 201
    share_data = share_res.json()
    share_token = share_data["share_token"]
    assert "live/" in share_data["share_url"]

    # 2. Public view test (zero authentication headers required)
    viewer_res = await client.get(f"/api/v1/shares/view/{share_token}")
    assert viewer_res.status_code == 200
    viewer_data = viewer_res.json()
    assert viewer_data["is_active"] is True
    assert viewer_data["is_expired"] is False
    assert viewer_data["bike_name"] == "Hayabusa"
    assert viewer_data["last_speed_kmh"] == 45.0
    assert viewer_data["last_battery_pct"] == 88
    assert len(viewer_data["route_points"]) >= 1

    # Ensure no sensitive user emails or password hashes leaked
    assert "email" not in viewer_data
    assert "user_id" not in viewer_data
    assert "password" not in viewer_data

    # 3. Stop/revoke share link
    stop_share = await client.post(f"/api/v1/shares/{share_data['id']}/stop", headers=headers)
    assert stop_share.status_code == 200

    # 4. View again - should show inactive
    viewer_res2 = await client.get(f"/api/v1/shares/view/{share_token}")
    assert viewer_res2.json()["is_active"] is False
