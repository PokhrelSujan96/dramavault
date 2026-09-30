from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from app.api.dependencies import history_service
from app.application.history import HistoryService
from app.core.security import Principal, current_principal
from app.domain.discover import DiscoverError
from app.domain.history import HistoryError, HistoryPage

router = APIRouter()

_FAILURES = {
    "episode_not_found": (404, "Episode not available"),
    "user_unavailable": (403, "Your account cannot record history"),
}


class WatchBody(BaseModel):
    position_seconds: int = Field(ge=0, le=86400)


@router.get("", response_model=HistoryPage)
async def list_history(
    cursor: str | None = Query(default=None, max_length=200),
    limit: int = Query(default=10, ge=1, le=30),
    principal: Principal = Depends(current_principal),
    service: HistoryService = Depends(history_service),
) -> HistoryPage:
    try:
        return await service.page(UUID(principal.user_id), cursor, limit)
    except DiscoverError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


@router.put("/{episode_id}", status_code=204)
async def record_watch(
    episode_id: UUID,
    body: WatchBody,
    principal: Principal = Depends(current_principal),
    service: HistoryService = Depends(history_service),
) -> None:
    try:
        await service.record(UUID(principal.user_id), episode_id, body.position_seconds)
    except HistoryError as error:
        status, detail = _FAILURES.get(error.code, (400, "History update failed"))
        raise HTTPException(status_code=status, detail=detail) from error


@router.delete("/{episode_id}", status_code=204)
async def remove_watch(
    episode_id: UUID,
    principal: Principal = Depends(current_principal),
    service: HistoryService = Depends(history_service),
) -> None:
    await service.remove(UUID(principal.user_id), episode_id)


@router.delete("", status_code=204)
async def clear_history(
    principal: Principal = Depends(current_principal),
    service: HistoryService = Depends(history_service),
) -> None:
    await service.remove(UUID(principal.user_id), None)
