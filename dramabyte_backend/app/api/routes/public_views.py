from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel

from app.api.preview_limits import limit_preview
from app.application.guest_views import GuestViewService
from app.infrastructure.database import get_database
from app.infrastructure.repositories.guest_views import GuestViewRepository
from supabase import AsyncClient

router = APIRouter(dependencies=[Depends(limit_preview)])


class ViewBody(BaseModel):
    episode_id: UUID
    event_id: UUID


async def guest_view_service(
    database: AsyncClient = Depends(get_database),
) -> GuestViewService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return GuestViewService(GuestViewRepository(database))


@router.post("", status_code=204)
async def record_view(
    body: ViewBody,
    response: Response,
    service: GuestViewService = Depends(guest_view_service),
) -> None:
    response.headers["Cache-Control"] = "no-store"
    if not await service.record(body.episode_id, body.event_id):
        raise HTTPException(status_code=404, detail="Episode unavailable")
