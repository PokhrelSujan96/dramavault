from typing import Protocol
from uuid import UUID

from app.domain.topup import CoinPackage, TopupError, TopupOrder, VerifiedPayment


class PaymentVerifier(Protocol):
    async def verify(
        self, order: TopupOrder, receipt: str | None
    ) -> VerifiedPayment: ...


class TopupStore(Protocol):
    async def packages(self) -> list[CoinPackage]: ...

    async def create_order(
        self,
        user_id: UUID,
        package_id: str,
        key: str,
        ttl_minutes: int,
        max_pending: int,
    ) -> TopupOrder: ...

    async def get_order(self, user_id: UUID, order_id: UUID) -> TopupOrder: ...

    async def orders(self, user_id: UUID) -> list[TopupOrder]: ...

    async def complete(
        self,
        user_id: UUID,
        order_id: UUID,
        payment: VerifiedPayment,
        referral_reward: int,
    ) -> TopupOrder: ...

    async def refund(self, order_id: UUID) -> TopupOrder: ...


class TopupService:
    def __init__(
        self,
        store: TopupStore,
        verifier: PaymentVerifier | None,
        referral_reward: int,
        order_ttl_minutes: int,
        max_pending: int,
    ) -> None:
        self.store = store
        self.verifier = verifier
        self.referral_reward = referral_reward
        self.order_ttl_minutes = order_ttl_minutes
        self.max_pending = max_pending

    async def packages(self) -> list[CoinPackage]:
        return await self.store.packages()

    async def orders(self, user_id: UUID) -> list[TopupOrder]:
        return await self.store.orders(user_id)

    async def create_order(
        self, user_id: UUID, package_id: str, key: str
    ) -> TopupOrder:
        return await self.store.create_order(
            user_id, package_id, key, self.order_ttl_minutes, self.max_pending
        )

    async def confirm(
        self, user_id: UUID, order_id: UUID, receipt: str | None
    ) -> TopupOrder:
        order = await self.store.get_order(user_id, order_id)
        if order.status == "completed":
            return order
        if order.status != "pending":
            raise TopupError("invalid_state")
        if self.verifier is None:
            raise TopupError("payments_unavailable")
        payment = await self.verifier.verify(order, receipt)
        return await self.store.complete(
            user_id, order_id, payment, self.referral_reward
        )

    async def refund(self, order_id: UUID) -> TopupOrder:
        return await self.store.refund(order_id)
