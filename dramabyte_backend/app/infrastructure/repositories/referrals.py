from uuid import UUID

from postgrest.types import CountMethod

from app.domain.profile import AuthError
from app.domain.referral import ReferralSummary
from supabase import AsyncClient


class ReferralRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def redeem(
        self,
        user_id: UUID,
        code: str,
        reward: int,
        max_referrals: int,
        window_hours: int,
    ) -> str:
        response = await self.client.rpc(
            "redeem_referral",
            {
                "p_user": str(user_id),
                "p_code": code,
                "p_reward": reward,
                "p_max_referrals": max_referrals,
                "p_window_hours": window_hours,
            },
        ).execute()
        return str(response.data)

    async def record_first_purchase(
        self, user_id: UUID, purchase_ref: str, reward: int
    ) -> str:
        response = await self.client.rpc(
            "record_first_purchase",
            {
                "p_user": str(user_id),
                "p_purchase_ref": purchase_ref,
                "p_reward": reward,
            },
        ).execute()
        return str(response.data)

    async def summary(self, user_id: UUID) -> ReferralSummary:
        uid = str(user_id)
        profile = await (
            self.client.table("profiles")
            .select("referral_code")
            .eq("id", uid)
            .maybe_single()
            .execute()
        )
        if profile is None or not isinstance(profile.data, dict):
            raise AuthError("Profile not found")
        invited = await (
            self.client.table("referrals")
            .select("status")
            .eq("referrer_id", uid)
            .execute()
        )
        redeemed = await (
            self.client.table("referrals")
            .select("id", count=CountMethod.exact)
            .eq("referee_id", uid)
            .execute()
        )
        rewards = await (
            self.client.table("referral_rewards")
            .select("amount")
            .eq("user_id", uid)
            .execute()
        )
        rows = [row for row in invited.data if isinstance(row, dict)]
        has_redeemed = (redeemed.count or 0) > 0
        return ReferralSummary(
            code=str(profile.data["referral_code"]),
            invited=len(rows),
            purchased=sum(1 for row in rows if row["status"] == "rewarded"),
            earned=sum(
                int(row["amount"]) for row in rewards.data if isinstance(row, dict)
            ),
            redeemed=has_redeemed,
            signup_reward=0,
            purchase_reward=0,
        )
