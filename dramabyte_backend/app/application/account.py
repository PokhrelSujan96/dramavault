from typing import Protocol
from uuid import UUID

from app.domain.account import AccountError, Preferences


class AccountStore(Protocol):
    async def preferences(self, user_id: UUID) -> Preferences: ...

    async def save(self, user_id: UUID, preferences: Preferences) -> None: ...

    async def erase(self, user_id: UUID) -> None: ...


class Reauthenticator(Protocol):
    async def verify_google(self, id_token: str) -> str: ...


class AccountService:
    def __init__(self, store: AccountStore, identity: Reauthenticator) -> None:
        self.store = store
        self.identity = identity

    async def preferences(self, user_id: UUID) -> Preferences:
        return await self.store.preferences(user_id)

    async def save(self, user_id: UUID, preferences: Preferences) -> Preferences:
        await self.store.save(user_id, preferences)
        return preferences

    async def delete(self, user_id: UUID, id_token: str) -> None:
        if await self.identity.verify_google(id_token) != str(user_id):
            raise AccountError("Identity mismatch")
        await self.store.erase(user_id)
