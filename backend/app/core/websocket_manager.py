import json
import logging
from typing import Dict, Set
from fastapi import WebSocket

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manages active WebSocket connections for live ride tracking and viewer broadcasts."""
    def __init__(self):
        # session_id -> Set[WebSocket]
        self.active_session_connections: Dict[str, Set[WebSocket]] = {}
        # share_token -> Set[WebSocket]
        self.active_share_connections: Dict[str, Set[WebSocket]] = {}

    async def connect_session(self, session_id: str, websocket: WebSocket):
        await websocket.accept()
        if session_id not in self.active_session_connections:
            self.active_session_connections[session_id] = set()
        self.active_session_connections[session_id].add(websocket)
        logger.info(f"WebSocket client connected to session: {session_id}")

    def disconnect_session(self, session_id: str, websocket: WebSocket):
        if session_id in self.active_session_connections:
            self.active_session_connections[session_id].discard(websocket)
            if not self.active_session_connections[session_id]:
                del self.active_session_connections[session_id]
        logger.info(f"WebSocket client disconnected from session: {session_id}")

    async def broadcast_session_update(self, session_id: str, message: dict):
        """Broadcast live telemetry data to all active riders and authorized listeners."""
        if session_id in self.active_session_connections:
            data = json.dumps(message)
            dead_sockets = set()
            for connection in list(self.active_session_connections[session_id]):
                try:
                    await connection.send_text(data)
                except Exception:
                    dead_sockets.add(connection)
            for dead in dead_sockets:
                self.active_session_connections[session_id].discard(dead)

    async def connect_share(self, share_token: str, websocket: WebSocket):
        await websocket.accept()
        if share_token not in self.active_share_connections:
            self.active_share_connections[share_token] = set()
        self.active_share_connections[share_token].add(websocket)
        logger.info(f"Viewer connected to share token: {share_token}")

    def disconnect_share(self, share_token: str, websocket: WebSocket):
        if share_token in self.active_share_connections:
            self.active_share_connections[share_token].discard(websocket)
            if not self.active_share_connections[share_token]:
                del self.active_share_connections[share_token]
        logger.info(f"Viewer disconnected from share token: {share_token}")

    async def broadcast_share_update(self, share_token: str, message: dict):
        """Broadcast live updates to public ephemeral link viewers."""
        if share_token in self.active_share_connections:
            data = json.dumps(message)
            dead_sockets = set()
            for connection in list(self.active_share_connections[share_token]):
                try:
                    await connection.send_text(data)
                except Exception:
                    dead_sockets.add(connection)
            for dead in dead_sockets:
                self.active_share_connections[share_token].discard(dead)


ws_manager = ConnectionManager()
