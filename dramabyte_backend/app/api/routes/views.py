from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.api.dependencies import engagement_service
from app.application.engagement import EngagementService
from app.core.security import Principal, current_principal
from app.domain.engagement import EngagementError

router = APIRouter()

_FAILURES = {
    "invalid": (422, "Invalid view batch"),
    "user_unavailable": (403, "Your account cannot record views"),
}


class ViewItem(BaseModel):
    episode_id: UUID
    count: int = Field(ge=1, le=100)


class ViewBatchBody(BaseModel):
    batch_id: UUID
    items: list[ViewItem] = Field(min_length=1, max_length=50)


@router.post("/batch", status_code=204)
async def record_view_batch(
    body: ViewBatchBody,
    principal: Principal = Depends(current_principal),
    service: EngagementService = Depends(engagement_service),
) -> None:
    counts: dict[UUID, int] = {}
    for item in body.items:
        counts[item.episode_id] = counts.get(item.episode_id, 0) + item.count
    try:
        await service.record_views(UUID(principal.user_id), body.batch_id, counts)
    except EngagementError as error:
        if error.code == "rate_limited":
            raise HTTPException(
                status_code=429,
                detail="Too many views recorded. Try again shortly",
                headers={"Retry-After": "30"},
            ) from error
        status, detail = _FAILURES.get(error.code, (400, "View batch failed"))
        raise HTTPException(status_code=status, detail=detail) from error
