from datetime import UTC, datetime
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from postgrest.exceptions import APIError

from app.api.management_schemas import (
    CoinAdjustment,
    UserUpdate,
)
from app.core.security import Principal, require_admin
from app.infrastructure.database import get_database
from app.infrastructure.repositories.management import ManagementRepository
from supabase import AsyncClient

router = APIRouter(dependencies=[Depends(require_admin)])


async def repository(
    database: AsyncClient = Depends(get_database),
) -> ManagementRepository:
    return ManagementRepository(database)


@router.get("/users")
async def users(
    page: int = Query(1, ge=1),
    size: int = Query(25, ge=1, le=100),
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    return await repo.list("profiles", page, size)


@router.get("/users/{user_id}")
async def user(
    user_id: UUID,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    profile = await repo.get("profiles", str(user_id))
    ledger = (
        await repo.client.table("coin_transactions")
        .select("*")
        .eq("user_id", str(user_id))
        .order("created_at", desc=True)
        .limit(100)
        .execute()
    )
    return {"profile": profile, "transactions": ledger.data}


@router.patch("/users/{user_id}")
async def update_user(
    user_id: UUID,
    body: UserUpdate,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    return await repo.update(
        "profiles", str(user_id), body.model_dump(exclude_none=True)
    )


@router.delete("/users/{user_id}")
async def remove_user(
    user_id: UUID,
    principal: Principal = Depends(require_admin),
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    if str(user_id) == principal.user_id:
        raise HTTPException(400, "You cannot remove your own account")
    return await repo.update(
        "profiles",
        str(user_id),
        {
            "deleted_at": datetime.now(UTC).isoformat(),
            "is_suspended": True,
        },
    )


@router.post("/users/{user_id}/restore")
async def restore_user(
    user_id: UUID,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    return await repo.update(
        "profiles",
        str(user_id),
        {
            "deleted_at": None,
            "is_suspended": False,
        },
    )


@router.post("/users/{user_id}/coins")
async def coins(
    user_id: UUID,
    body: CoinAdjustment,
    principal: Principal = Depends(require_admin),
    repo: ManagementRepository = Depends(repository),
) -> Any:
    if body.amount == 0:
        raise HTTPException(422, "Amount cannot be zero")
    try:
        result = await repo.client.rpc(
            "admin_adjust_coins",
            {
                "target_id": str(user_id),
                "actor_id": principal.user_id,
                "delta": body.amount,
                "note": body.reason,
                "operation_id": str(body.request_id),
            },
        ).execute()
        return result.data
    except APIError as error:
        raise HTTPException(
            409, "Coin adjustment rejected; check balance and request"
        ) from error
