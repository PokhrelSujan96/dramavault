from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Response

from app.api.dependencies import rating_service
from app.api.preview_limits import limit_preview
from app.application.public_series import PublicSeriesService
from app.application.ratings import RatingService
from app.domain.discover import DiscoverItem
from app.domain.series import SeriesDetails, SeriesError
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.database import get_database
from app.infrastructure.repositories.series import SeriesRepository
from supabase import AsyncClient

router = APIRouter(dependencies=[Depends(limit_preview)])


async def public_service(
    database: AsyncClient = Depends(get_database),
) -> PublicSeriesService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return PublicSeriesService(SeriesRepository(database), R2Storage().preview_url)


@router.get("/{series_id}", response_model=SeriesDetails)
async def details(
    series_id: UUID,
    response: Response,
    service: PublicSeriesService = Depends(public_service),
    ratings: RatingService = Depends(rating_service),
) -> SeriesDetails:
    response.headers["Cache-Control"] = "private, no-store"
    try:
        result = await service.details(series_id)
    except SeriesError as error:
        raise HTTPException(status_code=404, detail="Series not found") from error
    summary = (await ratings.series_averages([str(series_id)])).get(str(series_id))
    return result.model_copy(
        update={
            "rating_average": summary.average if summary else None,
            "rating_count": summary.count if summary else 0,
        }
    )


@router.get("/{series_id}/playlist", response_model=list[DiscoverItem])
async def playlist(
    series_id: UUID,
    response: Response,
    service: PublicSeriesService = Depends(public_service),
) -> list[DiscoverItem]:
    response.headers["Cache-Control"] = "private, no-store"
    try:
        return await service.playlist(series_id)
    except SeriesError as error:
        raise HTTPException(status_code=404, detail="Series not found") from error
