import httpx
import json
import time

BASE_URL = "http://127.0.0.1:8000/api/v1"

def run_e2e_verification():
    print("=" * 60)
    print("🚀 STARTING RIDETRACK END-TO-END TELEMETRY VERIFICATION")
    print("=" * 60)

    client = httpx.Client(base_url=BASE_URL, timeout=10.0)

    # 1. Register Rider
    print("\n1. Registering rider account...")
    reg_payload = {
        "email": f"rossi_{int(time.time())}@track.com",
        "password": "ChampionRider2026!",
        "full_name": "Valentino Rossi",
        "phone_number": f"+1415{int(time.time()) % 10000000:07d}"
    }
    reg_res = client.post("/auth/register", json=reg_payload)
    assert reg_res.status_code == 201, f"Registration failed: {reg_res.text}"
    tokens = reg_res.json()
    token = tokens["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print(f"   ✅ Rider registered successfully! Access token issued.")

    # 2. Add Motorcycle to Garage
    print("\n2. Adding motorcycle to garage...")
    bike_payload = {
        "name": "Yamaha MT-09 SP",
        "manufacturer": "Yamaha",
        "model": "MT-09",
        "variant": "SP",
        "registration_number": "KA-01-MT-0909",
        "year": 2024,
        "odometer_km": 2400.0,
        "is_active": True,
        "preferred_tracking_mode": "high_accuracy"
    }
    bike_res = client.post("/bikes", json=bike_payload, headers=headers)
    assert bike_res.status_code == 201, f"Add bike failed: {bike_res.text}"
    bike = bike_res.json()
    bike_id = bike["id"]
    print(f"   ✅ Motorcycle stored: {bike['name']} ({bike['registration_number']})")

    # 3. Save Parking Spot & Query Walking Navigation
    print("\n3. Testing Parking Guard spot memory & compass...")
    park_res = client.post("/parking", json={
        "bike_id": bike_id,
        "latitude": 12.971598,
        "longitude": 77.594562,
        "address": "MG Road Motorcycle Bay #4",
        "note": "Parked in shaded bay next to pillar 2"
    }, headers=headers)
    assert park_res.status_code == 201
    print(f"   ✅ Parking spot saved at (12.971598, 77.594562)")

    dir_res = client.get("/parking/directions", params={"current_lat": 12.973000, "current_lng": 77.595000}, headers=headers)
    assert dir_res.status_code == 200
    dir_data = dir_res.json()
    print(f"   ✅ Walking direction back to bike: {dir_data['distance_meters']}m, Bearing: {dir_data['bearing_degrees']}° ({dir_data['cardinal_direction']})")

    # 4. Add Emergency Contact & SOS
    print("\n4. Adding Emergency Contact...")
    contact_res = client.post("/emergency-contacts", json={
        "name": "Francesca Rossi",
        "phone_number": "+14155557788",
        "relationship_type": "spouse",
        "notify_on_crash": True,
        "notify_on_sos": True
    }, headers=headers)
    assert contact_res.status_code == 201
    print(f"   ✅ Emergency contact verified: Francesca Rossi (+14155557788)")

    # 5. Start Motorcycle Ride Tracking Session
    print("\n5. Starting Ride Tracking Session (Smartphone GNSS Engine)...")
    start_res = client.post("/tracking/start", json={
        "bike_id": bike_id,
        "tracking_mode": "high_accuracy",
        "battery_pct": 95
    }, headers=headers)
    assert start_res.status_code == 201
    session = start_res.json()
    session_id = session["id"]
    print(f"   ✅ Tracking session started: {session_id} (Status: {session['status']})")

    # 6. Stream Live Telemetry Points (Simulating acceleration through canyon curves)
    print("\n6. Streaming GNSS coordinate points with speed & altitude deltas...")
    telemetry_points = [
        {"latitude": 12.971600, "longitude": 77.594560, "altitude": 920.0, "speed_kmh": 0.0, "heading": 90.0, "accuracy_m": 3.5, "battery_pct": 95},
        {"latitude": 12.972200, "longitude": 77.596000, "altitude": 923.0, "speed_kmh": 42.0, "heading": 85.0, "accuracy_m": 3.2, "battery_pct": 95},
        {"latitude": 12.973500, "longitude": 77.598500, "altitude": 928.0, "speed_kmh": 68.5, "heading": 80.0, "accuracy_m": 3.0, "battery_pct": 94},
        {"latitude": 12.975000, "longitude": 77.601500, "altitude": 935.0, "speed_kmh": 84.2, "heading": 75.0, "accuracy_m": 2.8, "battery_pct": 94},
        {"latitude": 12.977200, "longitude": 77.605000, "altitude": 945.0, "speed_kmh": 105.0, "heading": 70.0, "accuracy_m": 2.5, "battery_pct": 93},
    ]

    ingest_res = client.post(f"/tracking/{session_id}/locations", json={"points": telemetry_points}, headers=headers)
    assert ingest_res.status_code == 200
    print(f"   ✅ Ingested {ingest_res.json()['ingested_count']} GNSS coordinates successfully.")

    # 7. Create Ephemeral Live Share Link
    print("\n7. Creating ephemeral Live Ride Sharing link...")
    share_res = client.post("/shares", json={
        "session_id": session_id,
        "duration_hours": 6,
        "recipient_label": "Live Family Tracker"
    }, headers=headers)
    assert share_res.status_code == 201
    share = share_res.json()
    share_token = share["share_token"]
    print(f"   ✅ Public live share link: {share['share_url']}")

    # 8. Verify Public Viewer Endpoint (Zero-auth for family/friends)
    print("\n8. Verifying zero-auth public live viewer feed...")
    viewer_res = client.get(f"/shares/view/{share_token}")
    assert viewer_res.status_code == 200
    viewer_data = viewer_res.json()
    assert viewer_data["is_active"] is True
    assert viewer_data["bike_name"] == "Yamaha MT-09 SP"
    assert viewer_data["last_speed_kmh"] == 105.0
    print(f"   ✅ Viewer verified: Bike '{viewer_data['bike_name']}', Speed: {viewer_data['last_speed_kmh']} km/h, Points: {len(viewer_data['route_points'])}")

    # 9. Stop Ride and Finalize Transaction
    print("\n9. Stopping ride and calculating finalized statistics...")
    stop_res = client.post(f"/tracking/{session_id}/stop", headers=headers)
    assert stop_res.status_code == 200
    ride = stop_res.json()
    print(f"   ✅ Trip Finalized: Distance: {ride['total_distance_km']} km, Top Speed: {ride['max_speed_kmh']} km/h, Elevation Gain: +{ride['elevation_gain_m']}m")
    ride_id = ride["id"]

    # 10. Verify Route Replay & GPX Export
    print("\n10. Testing Route Replay & GPX 1.1 exporter...")
    replay_res = client.get(f"/rides/{ride_id}/route", headers=headers)
    assert replay_res.status_code == 200
    print(f"   ✅ Route Replay telemetry points available: {replay_res.json()['total_points']} points")

    gpx_res = client.get(f"/rides/{ride_id}/export/gpx", headers=headers)
    assert gpx_res.status_code == 200 and "<gpx" in gpx_res.text
    print("   ✅ GPX 1.1 file exported cleanly.")

    # 11. Query Smart Ride Intelligence
    print("\n11. Querying Smart Ride Intelligence...")
    intel_res = client.get("/analytics/intelligence", headers=headers)
    assert intel_res.status_code == 200
    intel = intel_res.json()
    print(f"   ✅ Analytics Summary: {intel['summary']['total_distance_km']} km lifetime, Efficiency Score: {intel['riding_patterns']['efficiency_score']}/100")

    print("\n" + "=" * 60)
    print("🎉 ALL 11 END-TO-END VERIFICATION STEPS PASSED PERFECTLY!")
    print("=" * 60)

if __name__ == "__main__":
    run_e2e_verification()
