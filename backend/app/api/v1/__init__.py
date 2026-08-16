from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.users import router as users_router
from app.api.v1.bikes import router as bikes_router
from app.api.v1.tracking import router as tracking_router
from app.api.v1.rides import router as rides_router
from app.api.v1.parking import router as parking_router
from app.api.v1.geofences import router as geofences_router
from app.api.v1.alerts import router as alerts_router
from app.api.v1.emergency import router as emergency_router
from app.api.v1.shares import router as shares_router
from app.api.v1.analytics import router as analytics_router
from app.api.v1.settings import router as settings_router
from app.api.v1.websocket import router as websocket_router

api_router = APIRouter()

api_router.include_router(auth_router)
api_router.include_router(users_router)
api_router.include_router(bikes_router)
api_router.include_router(tracking_router)
api_router.include_router(rides_router)
api_router.include_router(parking_router)
api_router.include_router(geofences_router)
api_router.include_router(alerts_router)
api_router.include_router(emergency_router)
api_router.include_router(shares_router)
api_router.include_router(analytics_router)
api_router.include_router(settings_router)
api_router.include_router(websocket_router)
