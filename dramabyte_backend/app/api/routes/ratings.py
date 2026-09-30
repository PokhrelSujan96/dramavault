from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.api.dependencies import rating_service
from app.application.ratings import Kind, RatingService
from app.core.security import Principal, current_principal
from app.domain.ratings import RatingError, RatingSummary

router = APIRouter()

_FAILURES = {
    "invalid_rating": (422, "Ratings go from 1 to 10"),
    "not_found": (404, "This title is not available"),
    "user_unavailable": (403, "Your account cannot rate titles"),
}


class RatingBody(BaseModel):
    rating: int = Field(ge=1, le=10)


def _failure(error: RatingError) -> HTTPException:
    if error.code == "rate_limited":
        return HTTPException(
            status_code=429,
            detail="You're rating too fast. Try again in a moment",
            headers={"Retry-After": "30"},
        )
    status, detail = _FAILURES.get(error.code, (400, "Rating failed"))
    return HTTPException(status_code=status, detail=detail)


async def _rate(
    kind: Kind,
    target: UUID,
    body: RatingBody,
    principal: Principal,
    service: RatingService,
) -> RatingSummary:
    try:
        return await service.rate(kind, UUID(principal.user_id), target, body.rating)
    except RatingError as error:
        raise _failure(error) from error


async def _clear(
    kind: Kind, target: UUID, principal: Principal, service: RatingService
) -> RatingSummary:
    try:
        return await service.clear(kind, UUID(principal.user_id), target)
    except RatingError as error:
        raise _failure(error) from error


@router.put("/series/{series_id}", response_model=RatingSummary)
async def rate_series(
    series_id: UUID,
    body: RatingBody,
    principal: Principal = Depends(current_principal),
    service: RatingService = Depends(rating_service),
) -> RatingSummary:
    return await _rate("series", series_id, body, principal, service)


@router.delete("/series/{series_id}", response_model=RatingSummary)
async def clear_series_rating(
    series_id: UUID,
    principal: Principal = Depends(current_principal),
    service: RatingService = Depends(rating_service),
) -> RatingSummary:
    return await _clear("series", series_id, principal, service)


@router.put("/episodes/{episode_id}", response_model=RatingSummary)
async def rate_episode(
    episode_id: UUID,
    body: RatingBody,
    principal: Principal = Depends(current_principal),
    service: RatingService = Depends(rating_service),
) -> RatingSummary:
    return await _rate("episode", episode_id, body, principal, service)


@router.delete("/episodes/{episode_id}", response_model=RatingSummary)
async def clear_episode_rating(
    episode_id: UUID,
    principal: Principal = Depends(current_principal),
    service: RatingService = Depends(rating_service),
) -> RatingSummary:
    return await _clear("episode", episode_id, principal, service)
