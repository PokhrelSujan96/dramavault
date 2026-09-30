from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from postgrest.types import CountMethod
from pydantic import BaseModel

from app.api.routes.management import repository
from app.core.security import require_admin
from app.infrastructure.repositories.management import ManagementRepository

router = APIRouter(dependencies=[Depends(require_admin)])


class ModerateComment(BaseModel):
    is_hidden: bool


@router.get("/overview")
async def overview(
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    summary = await repo.client.table("platform_summary").select("*").single().execute()
    start = (datetime.now(UTC) - timedelta(days=6)).date().isoformat()
    daily = (
        await repo.client.table("daily_engagement")
        .select("*")
        .gte("day", start)
        .order("day")
        .execute()
    )
    return {"summary": summary.data, "daily": daily.data}


@router.get("/comments")
async def comments(
    page: int = Query(1, ge=1),
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    result = (
        await repo.client.table("episode_comments")
        .select(
            "*,profiles(display_name),episodes(title,episode_number,series(title))",
            count=CountMethod.exact,
        )
        .order("created_at", desc=True)
        .range((page - 1) * 25, page * 25 - 1)
        .execute()
    )
    return {"items": result.data, "total": result.count}


@router.patch("/comments/{comment_id}")
async def moderate_comment(
    comment_id: UUID,
    body: ModerateComment,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    return await repo.update("episode_comments", str(comment_id), body.model_dump())
