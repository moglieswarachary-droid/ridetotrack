# RideTrack System Architecture

RideTrack is an end-to-end motorcycle telemetry and safety tracking system built around **smartphone-only sensor intelligence**.

---

## 1. System Pipeline Overview

```
[Smartphone Sensors (GNSS, Accelerometer, Gyroscope, Battery)]
       │
       ▼
[Mobile Telemetry Engine]
  ├─ Adaptive Location Intervals (1s High Acc / 3s Balanced / 8s Eco)
  ├─ Kalman Drift Smoothing & Outlier Rejection
  ├─ Offline SQLite Batch Sync Queue
  └─ 15-Second IMU Crash Detection Guard
       │
       ▼ (HTTPS REST Batch / WebSockets)
[FastAPI Asynchronous Gateway]
  ├─ JWT Access & Refresh Token Interceptor
  ├─ Transactional Geo Pipeline (PostGIS / Haversine)
  ├─ Geofence Exit & Overspeed Alert Evaluators
  ├─ Redis Live Session State Cache & WebSocket Channel Hub
  └─ Smart Ride Analytics Aggregations
       │
       ▼
[Consumers]
  ├─ Rider Cockpit Mobile HUD
  ├─ Public Ephemeral Live Share Web Viewer
  └─ Emergency Contact Broadcast Dispatcher
```

---

## 2. Hardware-Free Smartphone Tracking Design

1. **GNSS Accuracy & Noise Filtration**:
   - Outlier rejection removes points with accuracy worse than 80m or impossible velocity jumps (>300 km/h).
   - 1D Kalman smoothing removes micro-jitter while rider is stationary at traffic lights.
2. **Battery Optimization Profiles**:
   - **High Accuracy (Track/Twisties)**: 1-second update interval, 2m displacement filter.
   - **Balanced (Daily Street)**: 3-second update interval, 5m displacement filter.
   - **Battery Saver (Touring)**: 8-second update interval, 15m displacement filter.
3. **IMU Crash Detection**:
   - Tracks user accelerometer events for peak impact spikes (> 3.8G) combined with immediate deceleration (< 8 km/h).
   - Automatically triggers a visual/audible **15-second cancellation countdown** before dispatching SOS alerts to configured contacts.

---

## 3. Ephemeral Live Sharing Security
- When a rider generates a live share link, the system creates a 24-character cryptographically secure token with an expiration timestamp (e.g. 2h, 6h, 12h, 24h).
- Viewers accessing `/live/{token}` receive live telemetry through WebSocket or REST without any authentication required, and zero access to rider emails, passwords, or stored history.
- The owner can instantly revoke access at any time with one tap.
