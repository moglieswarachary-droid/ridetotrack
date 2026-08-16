# RideTrack API Specification

OpenAPI Swagger UI is available at: `http://localhost:8000/docs`

---

## Core Endpoints Summary

### Authentication (`/api/v1/auth`)
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/auth/register` | Register rider account, issues access & refresh tokens |
| `POST` | `/auth/login` | Authenticate email and password |
| `POST` | `/auth/refresh` | Exchange refresh token for new token pair |
| `POST` | `/auth/logout` | Revoke active refresh token |
| `POST` | `/auth/logout-all` | Revoke all sessions across all devices |

### Motorcycle Garage (`/api/v1/bikes`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/bikes` | List all motorcycles in garage |
| `POST` | `/bikes` | Add new motorcycle |
| `GET` | `/bikes/{id}` | Get motorcycle details |
| `PUT` | `/bikes/{id}` | Update specifications or set as active bike |
| `DELETE`| `/bikes/{id}` | Delete motorcycle |

### Tracking & Ingestion (`/api/v1/tracking`)
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/tracking/start` | Start tracking session |
| `GET` | `/tracking/active` | Get current active or paused session |
| `POST` | `/tracking/{id}/locations` | Ingest batch of GPS/telemetry points |
| `POST` | `/tracking/{id}/pause` | Pause tracking session |
| `POST` | `/tracking/{id}/resume`| Resume tracking session |
| `POST` | `/tracking/{id}/stop` | Stop session and compute trip summary |
| `GET` | `/tracking/{id}/live` | Instantaneous live telemetry readout |

### Ride History & Replay (`/api/v1/rides`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/rides` | List completed rides (paginated) |
| `GET` | `/rides/{id}` | Full ride details with polyline |
| `GET` | `/rides/{id}/route` | Complete ordered GPS points for route replay |
| `GET` | `/rides/{id}/export/gpx` | Export standardized GPX 1.1 file |
| `GET` | `/rides/{id}/export/geojson` | Export GeoJSON FeatureCollection |
| `DELETE`| `/rides/{id}` | Permanently delete ride |

### Parking Guard (`/api/v1/parking`)
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/parking` | Save current location as parked bike spot |
| `GET` | `/parking/current` | Get latest saved parking spot |
| `GET` | `/parking/directions`| Calculate walking compass heading and distance back |
| `DELETE`| `/parking/{id}` | Clear saved parking location |

### Live Ride Sharing (`/api/v1/shares`)
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/shares` | Generate secure time-limited live sharing link |
| `GET` | `/shares` | List active live share links |
| `POST` | `/shares/{id}/stop` | Revoke live sharing link |
| `GET` | `/shares/view/{token}`| Public zero-auth endpoint for family/friends live viewer |

### WebSockets (`/api/v1/ws`)
| Protocol | Endpoint | Description |
|---|---|---|
| `WS` | `/ws/tracking/{session_id}?token={jwt}` | Authenticated rider HUD real-time stream |
| `WS` | `/ws/live/{share_token}` | Public ephemeral live share subscriber stream |
