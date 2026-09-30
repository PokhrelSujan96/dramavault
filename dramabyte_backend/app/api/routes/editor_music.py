from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query
from httpx import HTTPError

from app.core.security import require_admin
from app.infrastructure.adapters.openverse import OpenverseMusicProvider

router = APIRouter(dependencies=[Depends(require_admin)])


@router.get("/music/search")
def search_music(
    q: str = Query(min_length=2, max_length=100),
    page: int = Query(default=1, ge=1, le=100),
) -> dict[str, Any]:
    try:
        return OpenverseMusicProvider().search(q.strip(), page)
    except HTTPError as error:
        raise HTTPException(
            502, "Openverse music search is temporarily unavailable"
        ) from error


@router.get("/sound-effects/search")
def search_sound_effects(
    q: str = Query(min_length=2, max_length=100),
    page: int = Query(default=1, ge=1, le=100),
) -> dict[str, Any]:
    try:
        return OpenverseMusicProvider().search(
            q.strip(), page, category="sound_effect"
        )
    except HTTPError as error:
        raise HTTPException(
            502, "Openverse sound-effect search is temporarily unavailable"
        ) from error


@router.get("/music/{track_id}")
def music_track(track_id: str) -> dict[str, Any]:
    try:
        return OpenverseMusicProvider().get_track(track_id)
    except HTTPError as error:
        raise HTTPException(502, "Openverse track details are unavailable") from error
    except (ValueError, KeyError, TypeError) as error:
        raise HTTPException(404, "Openverse track is not available") from error
