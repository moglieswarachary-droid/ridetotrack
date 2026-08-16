from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.bike import Bike
from app.models.alert import Alert
from app.models.emergency_contact import EmergencyContact
from app.schemas.alert import AlertResponse, CrashReportRequest
from app.core.websocket_manager import ws_manager

router = APIRouter(prefix="/alerts", tags=["Alerts & Safety Engine"])


@router.get("", response_model=List[AlertResponse])
async def list_alerts(
    unread_only: bool = False,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve rider security and safety alerts."""
    query = select(Alert).where(Alert.user_id == current_user.id)
    if unread_only:
        query = query.where(Alert.is_read == False)
    query = query.order_by(Alert.created_at.desc()).limit(50)
    result = await db.execute(query)
    return result.scalars().all()


@router.post("/{alert_id}/acknowledge", response_model=AlertResponse)
async def acknowledge_alert(
    alert_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Acknowledge or dismiss an alert."""
    result = await db.execute(
        select(Alert).where(Alert.id == alert_id, Alert.user_id == current_user.id)
    )
    alert = result.scalars().first()
    if not alert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found.")

    alert.is_read = True
    alert.is_acknowledged = True
    await db.commit()
    await db.refresh(alert)
    return alert


@router.post("/crash-report", response_model=AlertResponse)
async def report_crash_event(
    data: CrashReportRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Handle verified crash event after phone countdown completes.
    Broadcasts emergency alert and prepares notification payload for verified emergency contacts.
    """
    bike_id = data.bike_id
    if not bike_id:
        res = await db.execute(
            select(Bike).where(Bike.user_id == current_user.id, Bike.is_active == True)
        )
        active_bike = res.scalars().first()
        bike_id = active_bike.id if active_bike else None

    # Fetch emergency contacts
    contacts_res = await db.execute(
        select(EmergencyContact).where(
            EmergencyContact.user_id == current_user.id,
            EmergencyContact.notify_on_crash == True
        )
    )
    contacts = contacts_res.scalars().all()
    contact_names = [c.name for c in contacts]

    alert = Alert(
        user_id=current_user.id,
        bike_id=bike_id,
        session_id=data.session_id,
        alert_type="crash",
        severity="emergency",
        title="CRASH DETECTED - SOS INITIATED",
        message=f"Severe deceleration ({data.impact_g}G) detected. Emergency contacts notified: {', '.join(contact_names) if contact_names else 'None configured'}.",
        latitude=data.latitude,
        longitude=data.longitude,
        metadata_json={
            "impact_g": data.impact_g,
            "speed_before_kmh": data.speed_before_impact_kmh,
            "notified_contacts": [{"name": c.name, "phone": c.phone_number} for c in contacts]
        }
    )
    db.add(alert)
    await db.commit()
    await db.refresh(alert)

    if data.session_id:
        await ws_manager.broadcast_session_update(
            data.session_id,
            {
                "type": "CRASH_ALERT",
                "alert_id": alert.id,
                "latitude": data.latitude,
                "longitude": data.longitude,
                "message": alert.message
            }
        )

    return alert
