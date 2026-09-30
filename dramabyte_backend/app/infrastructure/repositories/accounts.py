from uuid import UUID

from app.domain.account import Preferences
from supabase import AsyncClient


class AccountRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def preferences(self, user_id: UUID) -> Preferences:
        response = await (
            self.client.table("profiles")
            .select("marketing_opt_in,analytics_consent,personalization_consent")
            .eq("id", str(user_id))
            .limit(1)
            .execute()
        )
        rows = response.data if isinstance(response.data, list) else []
        row = rows[0] if rows and isinstance(rows[0], dict) else {}
        return Preferences(
            bool(row.get("marketing_opt_in")),
            bool(row.get("analytics_consent")),
            bool(row.get("personalization_consent")),
        )

    async def save(self, user_id: UUID, preferences: Preferences) -> None:
        await self.client.rpc(
            "save_preferences",
            {
                "p_user": str(user_id),
                "p_marketing": preferences.marketing,
                "p_analytics": preferences.analytics,
                "p_personalization": preferences.personalization,
            },
        ).execute()

    async def erase(self, user_id: UUID) -> None:
        await self.client.rpc("delete_account", {"p_user": str(user_id)}).execute()
        await self.client.auth.admin.delete_user(str(user_id), should_soft_delete=True)
