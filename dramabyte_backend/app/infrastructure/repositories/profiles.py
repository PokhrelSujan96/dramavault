from datetime import UTC, datetime
from uuid import UUID

from app.domain.profile import AuthError, Profile
from supabase import AsyncClient


class ProfileRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def get(self, user_id: UUID) -> Profile:
        response = await (
            self.client.table("profiles")
            .select("*")
            .eq("id", str(user_id))
            .maybe_single()
            .execute()
        )
        if response is None or response.data is None:
            raise AuthError("Profile not found")
        return Profile.model_validate(response.data)

    async def touch_login(self, user_id: UUID) -> Profile:
        response = await (
            self.client.table("profiles")
            .update({"last_login_at": datetime.now(UTC).isoformat()})
            .eq("id", str(user_id))
            .execute()
        )
        if not response.data:
            raise AuthError("Profile not found")
        return Profile.model_validate(response.data[0])
