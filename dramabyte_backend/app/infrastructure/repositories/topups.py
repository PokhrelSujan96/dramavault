from typing import Any
from uuid import UUID

from app.domain.topup import CoinPackage, TopupError, TopupOrder, VerifiedPayment
from supabase import AsyncClient


class TopupRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def packages(self) -> list[CoinPackage]:
        response = await (
            self.client.table("coin_packages")
            .select("id,coins,bonus_coins,price_cents,currency")
            .eq("active", True)
            .order("sort_order")
            .execute()
        )
        return [CoinPackage.model_validate(row) for row in response.data]

    async def create_order(
        self,
        user_id: UUID,
        package_id: str,
        key: str,
        ttl_minutes: int,
        max_pending: int,
    ) -> TopupOrder:
        return await self._call(
            "create_topup_order",
            {
                "p_user": str(user_id),
                "p_package": package_id,
                "p_key": key,
                "p_ttl_minutes": ttl_minutes,
                "p_max_pending": max_pending,
            },
        )

    async def get_order(self, user_id: UUID, order_id: UUID) -> TopupOrder:
        response = await (
            self.client.table("topup_orders")
            .select("*")
            .eq("id", str(order_id))
            .eq("user_id", str(user_id))
            .maybe_single()
            .execute()
        )
        if response is None or response.data is None:
            raise TopupError("order_not_found")
        return TopupOrder.model_validate(response.data)

    async def orders(self, user_id: UUID) -> list[TopupOrder]:
        response = await (
            self.client.table("topup_orders")
            .select("*")
            .eq("user_id", str(user_id))
            .order("created_at", desc=True)
            .limit(50)
            .execute()
        )
        return [TopupOrder.model_validate(row) for row in response.data]

    async def complete(
        self,
        user_id: UUID,
        order_id: UUID,
        payment: VerifiedPayment,
        referral_reward: int,
    ) -> TopupOrder:
        return await self._call(
            "complete_topup",
            {
                "p_order": str(order_id),
                "p_user": str(user_id),
                "p_provider": payment.provider,
                "p_provider_ref": payment.provider_ref,
                "p_referral_reward": referral_reward,
            },
        )

    async def refund(self, order_id: UUID) -> TopupOrder:
        return await self._call("refund_topup", {"p_order": str(order_id)})

    async def _call(self, function: str, params: dict[str, Any]) -> TopupOrder:
        response = await self.client.rpc(function, params).execute()
        data = response.data
        if not isinstance(data, dict) or data.get("code") != "ok":
            code = data.get("code") if isinstance(data, dict) else "unknown"
            raise TopupError(str(code))
        return TopupOrder.model_validate(data["order"])
