from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel, Field

from app.api.dependencies import account_service
from app.application.account import AccountService
from app.core.security import Principal, current_principal
from app.domain.account import AccountError, Preferences
from app.domain.profile import AuthError

router = APIRouter()


class PreferencesBody(BaseModel):
    marketing: bool
    analytics: bool
    personalization: bool


class DeleteBody(BaseModel):
    id_token: str = Field(min_length=20, max_length=4096)


@router.get("/preferences", response_model=PreferencesBody)
async def get_preferences(
    principal: Principal = Depends(current_principal),
    service: AccountService = Depends(account_service),
) -> PreferencesBody:
    found = await service.preferences(UUID(principal.user_id))
    return PreferencesBody(**_dump(found))


@router.put("/preferences", response_model=PreferencesBody)
async def put_preferences(
    body: PreferencesBody,
    principal: Principal = Depends(current_principal),
    service: AccountService = Depends(account_service),
) -> PreferencesBody:
    saved = await service.save(
        UUID(principal.user_id),
        Preferences(body.marketing, body.analytics, body.personalization),
    )
    return PreferencesBody(**_dump(saved))


@router.post("/delete", status_code=204)
async def delete_account(
    body: DeleteBody,
    principal: Principal = Depends(current_principal),
    service: AccountService = Depends(account_service),
) -> Response:
    try:
        await service.delete(UUID(principal.user_id), body.id_token)
    except (AccountError, AuthError) as error:
        raise HTTPException(
            status_code=403, detail="Re-authentication failed"
        ) from error
    return Response(status_code=204)


def _dump(value: Preferences) -> dict[str, bool]:
    return {
        "marketing": value.marketing,
        "analytics": value.analytics,
        "personalization": value.personalization,
    }
