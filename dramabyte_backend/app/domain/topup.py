from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class TopupError(Exception):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


class CoinPackage(BaseModel):
    id: str
    coins: int
    bonus_coins: int
    price_cents: int
    currency: str


class TopupOrder(BaseModel):
    id: UUID
    package_id: str
    product_id: str
    coins: int
    bonus_coins: int
    price_cents: int
    currency: str
    status: str
    created_at: datetime
    expires_at: datetime
    completed_at: datetime | None = None
    balance_after: int | None = None


class VerifiedPayment(BaseModel):
    provider: str
    provider_ref: str
