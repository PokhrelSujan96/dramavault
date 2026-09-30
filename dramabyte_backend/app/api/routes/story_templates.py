from collections.abc import Mapping
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from postgrest.exceptions import APIError
from pydantic import BaseModel

from app.api.routes.management import repository
from app.core.config import settings
from app.core.security import Principal, require_admin
from app.domain.last_seat_story import CAST, EPISODE, SCRIPT, TITLE
from app.infrastructure.repositories.management import ManagementRepository

router = APIRouter(dependencies=[Depends(require_admin)])


class TemplateRequest(BaseModel):
    request_id: UUID


@router.get("/templates/last-seat")
async def school_template() -> dict[str, Any]:
    return {
        "series_title": TITLE,
        "episode_title": EPISODE,
        "script": SCRIPT,
        "characters": [
            {"name": name, "description": description} for name, description in CAST
        ],
        "narrator_reference": settings.fish_audio_reference_id,
        "audio_mode": "single_narrator",
        "music": False,
        "lipsync": False,
    }


@router.post("/templates/last-seat/draft", status_code=201)
async def create_school_draft(
    body: TemplateRequest,
    principal: Principal = Depends(require_admin),
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    try:
        result = await repo.client.rpc(
            "create_school_story_draft",
            {
                "p_owner_id": principal.user_id,
                "p_request_id": str(body.request_id),
                "p_script": SCRIPT,
            },
        ).execute()
    except APIError as error:
        if error.code in {"PGRST202", "42883", "42P01"}:
            raise HTTPException(
                503, "Apply migration 0012_narrated_school_template.sql first"
            ) from error
        raise
    if not isinstance(result.data, Mapping):
        raise HTTPException(502, "Invalid template draft response")
    return {
        **dict(result.data),
        "project": await repo.get("projects", str(result.data["project_id"])),
        "series": await repo.get("series_metrics", str(result.data["series_id"])),
    }
