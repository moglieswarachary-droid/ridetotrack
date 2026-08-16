from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.analytics import (
    AnalyticsSummaryResponse,
    SmartRideIntelligenceResponse
)
from app.services.analytics_service import (
    get_user_analytics_summary,
    get_smart_ride_intelligence
)

router = APIRouter(prefix="/analytics", tags=["Analytics & Smart Intelligence"])


@router.get("/summary", response_model=AnalyticsSummaryResponse)
async def get_summary(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get total rider statistics (distance, hours, average & top speeds)."""
    return await get_user_analytics_summary(db, current_user.id)


@router.get("/intelligence", response_model=SmartRideIntelligenceResponse)
async def get_intelligence(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get Smart Ride Intelligence analysis, daily trends, and speed histograms."""
    return await get_smart_ride_intelligence(db, current_user.id)
