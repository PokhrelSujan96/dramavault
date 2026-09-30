from uuid import UUID

from app.application.auth import ProfileStore
from app.domain.profile import Profile


class ProfileService:
    def __init__(self, profiles: ProfileStore) -> None:
        self.profiles = profiles

    async def get(self, user_id: UUID) -> Profile:
        return await self.profiles.get(user_id)
