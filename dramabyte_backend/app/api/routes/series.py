from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException

from app.api.dependencies import engagement_service, rating_service, series_service
from app.application.engagement import EngagementService
from app.application.ratings import RatingService
from app.application.series import SeriesService
from app.core.security import Principal, current_principal
from app.domain.discover import DiscoverError, DiscoverItem
from app.domain.series import SeriesDetails, SeriesError

router = APIRouter()


@router.get("/{series_id}", response_model=SeriesDetails)
async def series_details(
    series_id: UUID,
    principal: Principal = Depends(current_principal),
    service: SeriesService = Depends(series_service),
    ratings: RatingService = Depends(rating_service),
) -> SeriesDetails:
    try:
        details = await service.details(series_id)
    except SeriesError as error:
        raise HTTPException(status_code=404, detail="Series not found") from error
    summary = await ratings.series_summary(series_id, UUID(principal.user_id))
    return details.model_copy(
        update={
            "rating_average": summary.average,
            "rating_count": summary.count,
            "my_rating": summary.my_rating,
        }
    )


@router.get("/{series_id}/playlist", response_model=list[DiscoverItem])
async def series_playlist(
    series_id: UUID,
    principal: Principal = Depends(current_principal),
    service: SeriesService = Depends(series_service),
    engagement: EngagementService = Depends(engagement_service),
) -> list[DiscoverItem]:
    try:
        items = await service.playlist(series_id)
        return await engagement.decorate(items, UUID(principal.user_id))
    except DiscoverError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error
