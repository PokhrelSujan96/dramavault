from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException

from app.api.dependencies import referral_service
from app.application.referral import ReferralService
from app.core.security import Principal, current_principal
from app.domain.profile import AuthError
from app.domain.referral import ReferralSummary

router = APIRouter()


@router.get("/me", response_model=ReferralSummary)
async def my_referral(
    principal: Principal = Depends(current_principal),
    service: ReferralService = Depends(referral_service),
) -> ReferralSummary:
    try:
        return await service.summary(UUID(principal.user_id))
    except AuthError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error
