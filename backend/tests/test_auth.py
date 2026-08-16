import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register_and_login_flow(client: AsyncClient):
    # 1. Register rider
    reg_payload = {
        "email": "rider@track.com",
        "password": "SecureRiderPass123!",
        "full_name": "Valentino Rossi",
        "phone_number": "+14155552671"
    }
    reg_res = await client.post("/api/v1/auth/register", json=reg_payload)
    assert reg_res.status_code == 201, reg_res.text
    tokens = reg_res.json()
    assert "access_token" in tokens
    assert "refresh_token" in tokens
    access_token = tokens["access_token"]
    refresh_token = tokens["refresh_token"]

    # 2. Get profile
    headers = {"Authorization": f"Bearer {access_token}"}
    profile_res = await client.get("/api/v1/users/me", headers=headers)
    assert profile_res.status_code == 200
    user_data = profile_res.json()
    assert user_data["email"] == "rider@track.com"
    assert user_data["full_name"] == "Valentino Rossi"

    # 3. Login with credentials
    login_res = await client.post(
        "/api/v1/auth/login",
        json={"email": "rider@track.com", "password": "SecureRiderPass123!"}
    )
    assert login_res.status_code == 200
    new_tokens = login_res.json()
    assert "access_token" in new_tokens

    # 4. Refresh token
    refresh_res = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token}
    )
    assert refresh_res.status_code == 200
    refreshed_tokens = refresh_res.json()
    assert "access_token" in refreshed_tokens

    # 5. Invalid password
    bad_login = await client.post(
        "/api/v1/auth/login",
        json={"email": "rider@track.com", "password": "WrongPassword"}
    )
    assert bad_login.status_code == 401
