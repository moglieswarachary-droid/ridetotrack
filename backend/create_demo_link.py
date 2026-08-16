import httpx

client = httpx.Client(base_url="http://127.0.0.1:8000/api/v1")

# Register or login
login_res = client.post("/auth/login", json={"email": "demo_rider@ridetrack.com", "password": "DemoPassword123!"})
if login_res.status_code == 200:
    token = login_res.json()["access_token"]
else:
    reg_res = client.post("/auth/register", json={
        "email": "demo_rider@ridetrack.com",
        "password": "DemoPassword123!",
        "full_name": "Marc Marquez"
    })
    token = reg_res.json()["access_token"]

headers = {"Authorization": f"Bearer {token}"}

# Add bike if needed
bikes_res = client.get("/bikes", headers=headers)
bikes = bikes_res.json()
if not bikes:
    bike = client.post("/bikes", json={
        "name": "Ducati Desmosedici GP",
        "manufacturer": "Ducati",
        "model": "Desmosedici GP24",
        "registration_number": "GP-93-DU",
        "year": 2024,
        "is_active": True
    }, headers=headers).json()
    bike_id = bike["id"]
else:
    bike_id = bikes[0]["id"]

# Start tracking session
session = client.post("/tracking/start", json={"bike_id": bike_id, "battery_pct": 92}, headers=headers).json()
session_id = session["id"]

# Ingest live coordinates
client.post(f"/tracking/{session_id}/locations", json={
    "points": [
        {"latitude": 12.971600, "longitude": 77.594560, "altitude": 920.0, "speed_kmh": 42.0, "battery_pct": 92},
        {"latitude": 12.972500, "longitude": 77.596200, "altitude": 924.0, "speed_kmh": 65.5, "battery_pct": 92},
        {"latitude": 12.974200, "longitude": 77.599000, "altitude": 930.0, "speed_kmh": 88.0, "battery_pct": 91},
        {"latitude": 12.976800, "longitude": 77.603500, "altitude": 938.0, "speed_kmh": 112.4, "battery_pct": 91},
    ]
}, headers=headers)

# Create 24h live share link
share = client.post("/shares", json={
    "session_id": session_id,
    "duration_hours": 24,
    "recipient_label": "Demo Live Stream"
}, headers=headers).json()

print(f"ACTIVE_LIVE_VIEWER_URL: {share['share_url']}")
