import json
import logging
from typing import Optional, Dict, Any
import redis.asyncio as redis
from app.core.config import settings

logger = logging.getLogger(__name__)


class LiveStateStore:
    """Manages real-time tracking session states with Redis or an in-memory fallback."""
    def __init__(self):
        self.redis: Optional[redis.Redis] = None
        self._in_memory_store: Dict[str, str] = {}
        self.is_connected = False

    async def connect(self):
        try:
            self.redis = redis.from_url(settings.REDIS_URL, decode_responses=True, socket_connect_timeout=1.5)
            await self.redis.ping()
            self.is_connected = True
            logger.info("Connected to Redis successfully.")
        except Exception as e:
            self.is_connected = False
            logger.warning(f"Redis not reachable ({e}). Utilizing in-memory state store fallback.")

    async def disconnect(self):
        if self.redis and self.is_connected:
            await self.redis.close()

    async def set_live_point(self, session_id: str, point_data: Dict[str, Any], expire_seconds: int = 3600):
        data_str = json.dumps(point_data)
        key = f"live:session:{session_id}"
        if self.is_connected and self.redis:
            try:
                await self.redis.set(key, data_str, ex=expire_seconds)
                return
            except Exception as e:
                logger.error(f"Redis set error: {e}")
        self._in_memory_store[key] = data_str

    async def get_live_point(self, session_id: str) -> Optional[Dict[str, Any]]:
        key = f"live:session:{session_id}"
        if self.is_connected and self.redis:
            try:
                val = await self.redis.get(key)
                if val:
                    return json.loads(val)
            except Exception as e:
                logger.error(f"Redis get error: {e}")
        
        val = self._in_memory_store.get(key)
        if val:
            return json.loads(val)
        return None

    async def remove_live_point(self, session_id: str):
        key = f"live:session:{session_id}"
        if self.is_connected and self.redis:
            try:
                await self.redis.delete(key)
            except Exception as e:
                logger.error(f"Redis delete error: {e}")
        self._in_memory_store.pop(key, None)


state_store = LiveStateStore()
