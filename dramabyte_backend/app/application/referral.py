from typing import Protocol
from uuid import UUID

from app.domain.referral import ReferralError, ReferralSummary


class ReferralStore(Protocol):
    async def redeem(
        self,
        user_id: UUID,
        code: str,
        reward: int,
        max_referrals: int,
        window_hours: int,
    ) -> str: ...

    async def record_first_purchase(
        self, user_id: UUID, purchase_ref: str, reward: int
    ) -> str: ...

    async def summary(self, user_id: UUID) -> ReferralSummary: ...


class ReferralService:
    def __init__(
        self,
        store: ReferralStore,
        signup_reward: int,
        purchase_reward: int,
        max_referrals: int,
        window_hours: int,
    ) -> None:
        self.store = store
        self.signup_reward = signup_reward
        self.purchase_reward = purchase_reward
        self.max_referrals = max_referrals
        self.window_hours = window_hours

    async def apply_code(self, user_id: UUID, code: str) -> None:
        result = await self.store.redeem(
            user_id, code, self.signup_reward, self.max_referrals, self.window_hours
        )
        if result != "ok":
            raise ReferralError(result)

    async def on_first_purchase(self, user_id: UUID, purchase_ref: str) -> str:
        return await self.store.record_first_purchase(
            user_id, purchase_ref, self.purchase_reward
        )

    async def summary(self, user_id: UUID) -> ReferralSummary:
        summary = await self.store.summary(user_id)
        return summary.model_copy(
            update={
                "signup_reward": self.signup_reward,
                "purchase_reward": self.purchase_reward,
            }
        )
