import logging
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, status
from app.core.websocket_manager import ws_manager
from app.core.security import decode_token
from app.core.database import AsyncSessionLocal
from sqlalchemy.future import select
from app.models.tracking_session import TrackingSession
from app.models.shared_session import SharedTrackingSession
from datetime import datetime, timezone

logger = logging.getLogger(__name__)

router = APIRouter(tags=["WebSockets"])


@router.websocket("/ws/tracking/{session_id}")
async def websocket_tracking_session(
    websocket: WebSocket,
    session_id: str,
    token: str = Query(...)
):
    """
    Authenticated WebSocket endpoint for active ride tracking.
    Streams real-time updates to rider HUD and receives client ping/keepalive.
    """
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    user_id = payload.get("sub")
    async with AsyncSessionLocal() as db:
        res = await db.execute(
            select(TrackingSession).where(
                TrackingSession.id == session_id,
                TrackingSession.user_id == user_id
            )
        )
        if not res.scalars().first():
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

    await ws_manager.connect_session(session_id, websocket)
    try:
        while True:
            # Keepalive listener
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text('{"type": "pong"}')
    except WebSocketDisconnect:
        ws_manager.disconnect_session(session_id, websocket)
    except Exception as e:
        logger.warning(f"WebSocket error: {e}")
        ws_manager.disconnect_session(session_id, websocket)


@router.websocket("/ws/live/{share_token}")
async def websocket_live_share(
    websocket: WebSocket,
    share_token: str
):
    """
    Public ephemeral WebSocket stream for authorized viewers watching a live share link.
    Validates share token and auto-disconnects on expiration.
    """
    async with AsyncSessionLocal() as db:
        res = await db.execute(
            select(SharedTrackingSession).where(
                SharedTrackingSession.share_token == share_token,
                SharedTrackingSession.is_active == True,
                SharedTrackingSession.expires_at > datetime.now(timezone.utc)
            )
        )
        share = res.scalars().first()
        if not share:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

    await ws_manager.connect_share(share_token, websocket)
    try:
        while True:
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text('{"type": "pong"}')
    except WebSocketDisconnect:
        ws_manager.disconnect_share(share_token, websocket)
    except Exception as e:
        logger.warning(f"Share WebSocket error: {e}")
        ws_manager.disconnect_share(share_token, websocket)
