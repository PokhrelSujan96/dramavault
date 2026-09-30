from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException

from app.api.dependencies import profile_service
from app.api.schemas import ProfileResponse
from app.application.profile import ProfileService
from app.core.security import Principal, current_principal
from app.domain.profile import AuthError

router = APIRouter()


@router.get("/me", response_model=ProfileResponse)
async def my_profile(
    principal: Principal = Depends(current_principal),
    service: ProfileService = Depends(profile_service),
) -> ProfileResponse:
    try:
        profile = await service.get(UUID(principal.user_id))
    except AuthError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error
    return ProfileResponse.from_domain(profile)
