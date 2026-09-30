from typing import Any, Literal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Response

from app.api.dependencies import comment_service
from app.api.preview_limits import limit_preview
from app.api.routes.comments import _failure
from app.application.comments import CommentService
from app.domain.comments import CommentError, CommentPage
from app.infrastructure.database import get_database
from app.infrastructure.repositories.public_comments import PublicCommentAccess
from supabase import AsyncClient

router = APIRouter(dependencies=[Depends(limit_preview)])
_VIEWER = UUID(int=0)


def public_page(page: CommentPage) -> dict[str, Any]:
    return {
        "items": [
            item.model_dump(
                mode="json",
                exclude={
                    "author_id",
                    "author_avatar",
                    "liked",
                    "is_mine",
                },
            )
            for item in page.items
        ],
        "next_cursor": page.next_cursor,
        "can_post": False,
    }


@router.get("/episodes/{episode_id}")
async def comments(
    episode_id: UUID,
    response: Response,
    sort: Literal["top", "new"] = "top",
    cursor: str | None = Query(default=None, max_length=300),
    limit: int = Query(default=20, ge=1, le=50),
    database: AsyncClient = Depends(get_database),
    service: CommentService = Depends(comment_service),
) -> dict[str, Any]:
    response.headers["Cache-Control"] = "no-store"
    if not await PublicCommentAccess(database).published(episode_id):
        raise HTTPException(status_code=404, detail="Episode unavailable")
    try:
        return public_page(await service.page(_VIEWER, episode_id, sort, cursor, limit))
    except CommentError as error:
        raise _failure(error) from error


@router.get("/{comment_id}/replies")
async def replies(
    comment_id: UUID,
    response: Response,
    cursor: str | None = Query(default=None, max_length=300),
    limit: int = Query(default=10, ge=1, le=50),
    database: AsyncClient = Depends(get_database),
    service: CommentService = Depends(comment_service),
) -> dict[str, Any]:
    response.headers["Cache-Control"] = "no-store"
    access = PublicCommentAccess(database)
    episode = await access.parent_episode(comment_id)
    if not episode or not await access.published(episode):
        raise HTTPException(status_code=404, detail="Comment unavailable")
    try:
        return public_page(await service.replies(_VIEWER, comment_id, cursor, limit))
    except CommentError as error:
        raise _failure(error) from error
