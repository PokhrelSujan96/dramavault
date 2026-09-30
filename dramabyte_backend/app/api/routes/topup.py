from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException

from app.api.dependencies import topup_service
from app.api.schemas import ConfirmOrderBody, CreateOrderBody
from app.application.topup import TopupService
from app.core.security import Principal, current_principal
from app.domain.topup import CoinPackage, TopupError, TopupOrder

router = APIRouter()

_FAILURES = {
    "package_not_found": (404, "This coin package is not available"),
    "order_not_found": (404, "Order not found"),
    "too_many_pending": (429, "Too many unfinished top-ups. Try again shortly"),
    "key_reused": (409, "This request was already used for a different package"),
    "expired": (410, "This top-up expired. Please start again"),
    "invalid_state": (409, "This top-up can no longer be completed"),
    "payment_reused": (409, "This payment was already used"),
    "payment_not_verified": (402, "Payment could not be verified"),
    "payments_unavailable": (503, "Top-ups are not available yet"),
    "user_unavailable": (403, "Your account cannot make purchases"),
}

IdempotencyKey = Annotated[
    str, Header(alias="Idempotency-Key", pattern=r"^[A-Za-z0-9_-]{16,64}$")
]


def _failure(error: TopupError) -> HTTPException:
    status, detail = _FAILURES.get(error.code, (400, "Top-up failed"))
    return HTTPException(status_code=status, detail=detail)


@router.get("/packages", response_model=list[CoinPackage])
async def packages(
    _: Principal = Depends(current_principal),
    service: TopupService = Depends(topup_service),
) -> list[CoinPackage]:
    return await service.packages()


@router.get("/orders", response_model=list[TopupOrder])
async def orders(
    principal: Principal = Depends(current_principal),
    service: TopupService = Depends(topup_service),
) -> list[TopupOrder]:
    return await service.orders(UUID(principal.user_id))


@router.post("/orders", response_model=TopupOrder)
async def create_order(
    body: CreateOrderBody,
    key: IdempotencyKey,
    principal: Principal = Depends(current_principal),
    service: TopupService = Depends(topup_service),
) -> TopupOrder:
    try:
        return await service.create_order(UUID(principal.user_id), body.package_id, key)
    except TopupError as error:
        raise _failure(error) from error


@router.post("/orders/{order_id}/confirm", response_model=TopupOrder)
async def confirm_order(
    order_id: UUID,
    body: ConfirmOrderBody,
    principal: Principal = Depends(current_principal),
    service: TopupService = Depends(topup_service),
) -> TopupOrder:
    try:
        return await service.confirm(UUID(principal.user_id), order_id, body.receipt)
    except TopupError as error:
        raise _failure(error) from error
