from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.models.geofence import Geofence
from app.models.alert import Alert
from app.utils.geo import haversine_distance_meters
from app.core.websocket_manager import ws_manager


async def check_geofences_for_point(
    db: AsyncSession,
    user_id: str,
    bike_id: str,
    session_id: Optional[str],
    lat: float,
    lng: float
) -> List[Alert]:
    """Check if a new motorcycle coordinate breaches any active geofences and trigger alerts."""
    result = await db.execute(
        select(Geofence).where(
            Geofence.bike_id == bike_id,
            Geofence.is_active == True
        )
    )
    geofences = result.scalars().all()
    created_alerts = []

    for gf in geofences:
        dist_m = haversine_distance_meters(gf.latitude, gf.longitude, lat, lng)
        is_outside = dist_m > gf.radius_meters

        if is_outside and gf.notify_on_exit:
            # Check if an alert was already triggered recently to avoid spam
            recent_alert = await db.execute(
                select(Alert).where(
                    Alert.bike_id == bike_id,
                    Alert.alert_type == "geofence_exit",
                    Alert.is_acknowledged == False
                )
            )
            if not recent_alert.scalars().first():
                alert = Alert(
                    user_id=user_id,
                    bike_id=bike_id,
                    session_id=session_id,
                    alert_type="geofence_exit",
                    severity="warning",
                    title="Geofence Breach Alert",
                    message=f"Motorcycle moved outside the '{gf.name}' safe perimeter ({int(dist_m)}m away).",
                    latitude=lat,
                    longitude=lng,
                    metadata_json={
                        "geofence_id": gf.id,
                        "geofence_name": gf.name,
                        "distance_m": round(dist_m, 1),
                        "radius_m": gf.radius_meters
                    }
                )
                db.add(alert)
                created_alerts.append(alert)

    if created_alerts:
        await db.commit()
        if session_id:
            for al in created_alerts:
                await ws_manager.broadcast_session_update(
                    session_id,
                    {
                        "type": "ALERT",
                        "alert_type": al.alert_type,
                        "title": al.title,
                        "message": al.message,
                        "severity": al.severity,
                    }
                )

    return created_alerts
