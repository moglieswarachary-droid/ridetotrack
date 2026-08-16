from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.bike import Bike
from app.models.emergency_contact import EmergencyContact
from app.models.alert import Alert
from app.schemas.emergency import (
    EmergencyContactCreate,
    EmergencyContactUpdate,
    EmergencyContactResponse,
    SOSTriggerRequest
)
from app.core.audit import record_audit_log

router = APIRouter(prefix="/emergency-contacts", tags=["Safety & Emergency Contacts"])


@router.get("", response_model=List[EmergencyContactResponse])
async def list_emergency_contacts(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retrieve rider's configured emergency contacts."""
    result = await db.execute(
        select(EmergencyContact).where(EmergencyContact.user_id == current_user.id)
    )
    return result.scalars().all()


@router.post("", response_model=EmergencyContactResponse, status_code=status.HTTP_201_CREATED)
async def add_emergency_contact(
    data: EmergencyContactCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Add a new emergency contact (spouse, family, riding partner)."""
    contact = EmergencyContact(
        user_id=current_user.id,
        name=data.name,
        phone_number=data.phone_number,
        relationship_type=data.relationship_type,
        is_verified=True,
        notify_on_crash=data.notify_on_crash,
        notify_on_sos=data.notify_on_sos,
    )
    db.add(contact)
    await db.commit()
    await db.refresh(contact)
    return contact


@router.put("/{contact_id}", response_model=EmergencyContactResponse)
async def update_emergency_contact(
    contact_id: str,
    update_data: EmergencyContactUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update emergency contact settings."""
    result = await db.execute(
        select(EmergencyContact).where(
            EmergencyContact.id == contact_id,
            EmergencyContact.user_id == current_user.id
        )
    )
    contact = result.scalars().first()
    if not contact:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contact not found.")

    for field, val in update_data.model_dump(exclude_unset=True).items():
        setattr(contact, field, val)

    await db.commit()
    await db.refresh(contact)
    return contact


@router.delete("/{contact_id}", status_code=status.HTTP_200_OK)
async def delete_emergency_contact(
    contact_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete an emergency contact."""
    result = await db.execute(
        select(EmergencyContact).where(
            EmergencyContact.id == contact_id,
            EmergencyContact.user_id == current_user.id
        )
    )
    contact = result.scalars().first()
    if not contact:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contact not found.")

    await db.delete(contact)
    await db.commit()
    return {"message": "Emergency contact removed successfully."}


@router.post("/sos-broadcast", status_code=status.HTTP_200_OK)
async def trigger_manual_sos(
    data: SOSTriggerRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Trigger manual SOS broadcast to all configured emergency contacts."""
    res = await db.execute(select(Bike).where(Bike.user_id == current_user.id, Bike.is_active == True))
    active_bike = res.scalars().first()
    bike_id = active_bike.id if active_bike else None

    # Fetch contacts
    contacts_res = await db.execute(
        select(EmergencyContact).where(
            EmergencyContact.user_id == current_user.id,
            EmergencyContact.notify_on_sos == True
        )
    )
    contacts = contacts_res.scalars().all()

    alert = Alert(
        user_id=current_user.id,
        bike_id=bike_id,
        alert_type="sos",
        severity="emergency",
        title="EMERGENCY SOS BROADCAST",
        message=f"{current_user.full_name} triggered an SOS emergency alert: '{data.message}'. GPS: ({data.latitude}, {data.longitude})",
        latitude=data.latitude,
        longitude=data.longitude,
        metadata_json={
            "battery_pct": data.battery_pct,
            "notified_contacts": [{"name": c.name, "phone": c.phone_number} for c in contacts]
        }
    )
    db.add(alert)
    await db.commit()
    await record_audit_log(db, action="SOS_TRIGGERED", user_id=current_user.id)

    return {
        "status": "SOS_BROADCASTED",
        "contacts_notified_count": len(contacts),
        "message": "Emergency broadcast dispatched to configured contacts."
    }
