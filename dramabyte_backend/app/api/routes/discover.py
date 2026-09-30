from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query

from app.api.dependencies import cached_discover_service, engagement_service
from app.application.discover import DiscoverService
from app.application.engagement import EngagementService
from app.core.security import Principal, current_principal
from app.domain.discover import DiscoverError, DiscoverPage

router = APIRouter()


@router.get("", response_model=DiscoverPage)
async def discover(
    cursor: str | None = Query(default=None, max_length=200),
    limit: int = Query(default=6, ge=1, le=20),
    principal: Principal = Depends(current_principal),
    service: DiscoverService = Depends(cached_discover_service),
    engagement: EngagementService = Depends(engagement_service),
) -> DiscoverPage:
    try:
        page = await service.page(cursor, limit)
        items = await engagement.decorate(page.items, UUID(principal.user_id))
        return page.model_copy(update={"items": items})
    except DiscoverError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
