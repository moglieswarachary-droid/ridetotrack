import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_analytics_and_settings(client: AsyncClient):
    reg_res = await client.post("/api/v1/auth/register", json={
        "email": "analytics_rider@track.com",
        "password": "RiderPassword123!",
        "full_name": "Analytics Rider"
    })
    token = reg_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Fetch summary
    summary_res = await client.get("/api/v1/analytics/summary", headers=headers)
    assert summary_res.status_code == 200
    summary = summary_res.json()
    assert "total_distance_km" in summary

    # 2. Fetch Smart Ride Intelligence
    intel_res = await client.get("/api/v1/analytics/intelligence", headers=headers)
    assert intel_res.status_code == 200
    intel = intel_res.json()
    assert "daily_trend" in intel
    assert "speed_distribution" in intel
    assert "riding_patterns" in intel

    # 3. Get and update settings
    settings_res = await client.get("/api/v1/settings", headers=headers)
    assert settings_res.status_code == 200
    assert settings_res.json()["unit_system"] == "metric"

    update_settings_res = await client.put("/api/v1/settings", json={
        "tracking_quality_mode": "high_accuracy",
        "overspeed_threshold_kmh": 140.0
    }, headers=headers)
    assert update_settings_res.status_code == 200
    assert update_settings_res.json()["tracking_quality_mode"] == "high_accuracy"
    assert update_settings_res.json()["overspeed_threshold_kmh"] == 140.0
