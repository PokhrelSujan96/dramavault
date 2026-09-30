from collections.abc import Mapping
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from postgrest.exceptions import APIError
from pydantic import BaseModel

from app.api.routes.management import repository
from app.core.config import settings
from app.core.security import Principal, require_admin
from app.domain.dialogue import PilotPlan, PilotRequest, estimate
from app.domain.school_pilot import school_pilot
from app.domain.train_pilot import train_pilot
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.repositories.management import ManagementRepository

router = APIRouter(dependencies=[Depends(require_admin)])


async def require_pilot_schema(repo: ManagementRepository) -> None:
    try:
        await repo.client.table("dialogue_pilots").select("id").limit(1).execute()
    except APIError as error:
        raise HTTPException(
            503, "Apply migration 0011_dialogue_pilots.sql first"
        ) from error


class PaidConsent(BaseModel):
    paid_confirmed: bool


class PilotApproval(BaseModel):
    approved: bool


@router.post("/pilots", status_code=201)
async def create_pilot(
    body: PilotRequest,
    principal: Principal = Depends(require_admin),
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    await require_pilot_schema(repo)
    await repo.get("series", str(body.series_id))
    cast = []
    for member in body.cast:
        person = await repo.get("series_characters", str(member.character_id))
        if person["series_id"] != str(body.series_id):
            raise HTTPException(422, "Character does not belong to this series")
        cast.append({**person, "voice_reference": member.voice_reference})
    factory = school_pilot if body.template == "school" else train_pilot
    plan = factory(cast[0]["id"], cast[1]["id"])
    costs = estimate(plan)
    if sum(costs.values()) > body.budget_usd:
        raise HTTPException(422, "Budget is below this pilot's conservative allowance")
    response = await repo.client.rpc(
        "create_dialogue_pilot",
        {
            "p_owner_id": principal.user_id,
            "p_series_id": str(body.series_id),
            "p_plan": plan.model_dump(mode="json"),
            "p_cast": cast,
            "p_budget_cents": round(body.budget_usd * 100),
        },
    ).execute()
    if not isinstance(response.data, Mapping):
        raise HTTPException(502, "Invalid pilot creation response")
    return {**dict(response.data), "estimate": costs}


@router.get("/pilots")
async def pilots(
    project_id: UUID | None = None,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    await require_pilot_schema(repo)
    query = repo.client.table("dialogue_pilots").select("*")
    if project_id:
        query = query.eq("project_id", str(project_id))
    response = await query.order("created_at", desc=True).limit(30).execute()
    return {
        "items": [
            await present(dict(row))
            for row in response.data
            if isinstance(row, Mapping)
        ]
    }


async def present(row: dict[str, Any]) -> dict[str, Any]:
    storage = R2Storage()
    return {
        **row,
        "paid_generation_enabled": settings.dialogue_paid_enabled,
        "asset_urls": {
            name: storage.signed_url(key) for name, key in row["assets"].items()
        },
        "estimate": estimate(PilotPlan.model_validate(row["plan"])),
        "billing_note": "Reserved estimates, not provider invoices; rates can change.",
    }


@router.get("/pilots/{pilot_id}")
async def pilot(
    pilot_id: UUID,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    return await present(await repo.get("dialogue_pilots", str(pilot_id)))
