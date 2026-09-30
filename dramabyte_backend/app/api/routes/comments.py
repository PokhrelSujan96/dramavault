from typing import Literal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from app.api.dependencies import comment_service
from app.application.comments import CommentService
from app.core.security import Principal, current_principal
from app.domain.comments import Comment, CommentError, CommentPage, LikeResult

router = APIRouter()

_FAILURES = {
    "invalid_body": (422, "Comment must be between 1 and 500 characters"),
    "invalid_cursor": (400, "Invalid cursor"),
    "episode_not_found": (404, "Episode not available"),
    "comment_not_found": (404, "Comment not found"),
    "parent_not_found": (404, "The comment you replied to no longer exists"),
    "user_unavailable": (403, "Your account cannot comment"),
}


class PostBody(BaseModel):
    body: str = Field(min_length=1, max_length=2000)
    parent_id: UUID | None = None
    idempotency_key: UUID | None = None


class LikeBody(BaseModel):
    liked: bool


class ReportBody(BaseModel):
    reason: str = Field(min_length=1, max_length=200)


def _failure(error: CommentError) -> HTTPException:
    if error.code == "rate_limited":
        return HTTPException(
            status_code=429,
            detail="You're commenting too fast. Try again in a moment",
            headers={"Retry-After": "20"},
        )
    status, detail = _FAILURES.get(error.code, (400, "Comment request failed"))
    return HTTPException(status_code=status, detail=detail)


@router.get("/episodes/{episode_id}", response_model=CommentPage)
async def list_comments(
    episode_id: UUID,
    sort: Literal["top", "new"] = "top",
    cursor: str | None = Query(default=None, max_length=300),
    limit: int = Query(default=20, ge=1, le=50),
    principal: Principal = Depends(current_principal),
    service: CommentService = Depends(comment_service),
) -> CommentPage:
    try:
        return await service.page(
            UUID(principal.user_id), episode_id, sort, cursor, limit
        )
    except CommentError as error:
        raise _failure(error) from error


@router.get("/{comment_id}/replies", response_model=CommentPage)
async def list_replies(
    comment_id: UUID,
    cursor: str | None = Query(default=None, max_length=300),
    limit: int = Query(default=10, ge=1, le=50),
    principal: Principal = Depends(current_principal),
    service: CommentService = Depends(comment_service),
) -> CommentPage:
    try:
        return await service.replies(UUID(principal.user_id), comment_id, cursor, limit)
    except CommentError as error:
        raise _failure(error) from error


@router.post("/episodes/{episode_id}", response_model=Comment, status_code=201)
async def post_comment(
    episode_id: UUID,
    body: PostBody,
    principal: Principal = Depends(current_principal),
    service: CommentService = Depends(comment_service),
) -> Comment:
    try:
        return await service.post(
            UUID(principal.user_id),
            episode_id,
            body.body,
            body.parent_id,
            body.idempotency_key,
        )
    except CommentError as error:
        raise _failure(error) from error


@router.put("/{comment_id}/like", response_model=LikeResult)
async def like_comment(
    comment_id: UUID,
    body: LikeBody,
    principal: Principal = Depends(current_principal),
    service: CommentService = Depends(comment_service),
) -> LikeResult:
    try:
        count = await service.like(UUID(principal.user_id), comment_id, body.liked)
    except CommentError as error:
        raise _failure(error) from error
    return LikeResult(like_count=count)


@router.delete("/{comment_id}", status_code=204)
async def delete_comment(
    comment_id: UUID,
    principal: Principal = Depends(current_principal),
    service: CommentService = Depends(comment_service),
) -> None:
    try:
        await service.delete(UUID(principal.user_id), comment_id)
    except CommentError as error:
        raise _failure(error) from error


@router.post("/{comment_id}/report", status_code=204)
async def report_comment(
    comment_id: UUID,
    body: ReportBody,
    principal: Principal = Depends(current_principal),
    service: CommentService = Depends(comment_service),
) -> None:
    try:
        await service.report(UUID(principal.user_id), comment_id, body.reason)
    except CommentError as error:
        raise _failure(error) from error
