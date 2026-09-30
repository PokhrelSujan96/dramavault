from fastapi import APIRouter, Depends, Query

from app.api.dependencies import search_service
from app.application.search import SearchService
from app.domain.home import SeriesCard

router = APIRouter()


@router.get("", response_model=list[SeriesCard])
async def search(
    q: str = Query(default="", max_length=200),
    limit: int = Query(default=20, ge=1, le=30),
    service: SearchService = Depends(search_service),
) -> list[SeriesCard]:
    return await service.search(q, limit)
