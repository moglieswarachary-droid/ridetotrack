import pytest
from httpx import AsyncClient


async def get_authenticated_headers(client: AsyncClient, email: str = "bike_tester@track.com") -> dict:
    reg_res = await client.post("/api/v1/auth/register", json={
        "email": email,
        "password": "TestPassword123!",
        "full_name": "Marc Marquez"
    })
    token = reg_res.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_bike_crud_and_active_toggle(client: AsyncClient):
    headers = await get_authenticated_headers(client)

    # 1. Add first motorcycle
    bike1_payload = {
        "name": "Street Triple RS",
        "manufacturer": "Triumph",
        "model": "Street Triple",
        "variant": "RS",
        "registration_number": "KA-01-AB-1234",
        "year": 2024,
        "odometer_km": 1250.0,
        "is_active": True
    }
    create_res = await client.post("/api/v1/bikes", json=bike1_payload, headers=headers)
    assert create_res.status_code == 201
    bike1 = create_res.json()
    assert bike1["name"] == "Street Triple RS"
    assert bike1["is_active"] is True
    bike1_id = bike1["id"]

    # 2. Add second motorcycle
    bike2_payload = {
        "name": "Panigale V4",
        "manufacturer": "Ducati",
        "model": "Panigale V4",
        "registration_number": "KA-01-CD-5678",
        "year": 2023,
        "odometer_km": 3400.0,
        "is_active": True  # Setting this active should deactivate bike1
    }
    create2_res = await client.post("/api/v1/bikes", json=bike2_payload, headers=headers)
    assert create2_res.status_code == 201
    bike2 = create2_res.json()
    assert bike2["is_active"] is True
    bike2_id = bike2["id"]

    # Verify bike1 is now inactive
    get_bike1 = await client.get(f"/api/v1/bikes/{bike1_id}", headers=headers)
    assert get_bike1.json()["is_active"] is False

    # 3. List all bikes
    list_res = await client.get("/api/v1/bikes", headers=headers)
    assert list_res.status_code == 200
    assert len(list_res.json()) == 2

    # 4. Update bike specifications
    update_res = await client.put(
        f"/api/v1/bikes/{bike1_id}",
        json={"odometer_km": 1500.0, "is_active": True},
        headers=headers
    )
    assert update_res.status_code == 200
    assert update_res.json()["odometer_km"] == 1500.0
    assert update_res.json()["is_active"] is True

    # 5. Delete bike
    del_res = await client.delete(f"/api/v1/bikes/{bike2_id}", headers=headers)
    assert del_res.status_code == 200

    list_after_del = await client.get("/api/v1/bikes", headers=headers)
    assert len(list_after_del.json()) == 1
