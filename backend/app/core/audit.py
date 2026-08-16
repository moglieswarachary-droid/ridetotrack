import logging
from typing import Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.audit_log import AuditLog

logger = logging.getLogger("ridetrack.audit")


async def record_audit_log(
    db: AsyncSession,
    action: str,
    user_id: Optional[str] = None,
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None,
    details: Optional[Dict[str, Any]] = None,
):
    """Persist a security audit log event."""
    try:
        log_entry = AuditLog(
            user_id=user_id,
            action=action,
            ip_address=ip_address,
            user_agent=user_agent,
            details=details or {},
        )
        db.add(log_entry)
        await db.commit()
    except Exception as e:
        logger.error(f"Failed to write audit log: {e}")
