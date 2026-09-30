import logging
from dataclasses import dataclass
from typing import Protocol
from uuid import UUID

from app.domain.profile import AuthError, AuthSession, Profile
from app.domain.referral import ReferralError

logger = logging.getLogger(__name__)


class IdentityProvider(Protocol):
    async def sign_in_with_google(self, id_token: str) -> AuthSession: ...

    async def refresh(self, refresh_token: str) -> AuthSession: ...


class ProfileStore(Protocol):
    async def touch_login(self, user_id: UUID) -> Profile: ...

    async def get(self, user_id: UUID) -> Profile: ...


class ReferralRedeemer(Protocol):
    async def apply_code(self, user_id: UUID, code: str) -> None: ...


@dataclass(frozen=True, slots=True)
class SignedIn:
    session: AuthSession
    profile: Profile


class AuthService:
    def __init__(
        self,
        identity: IdentityProvider,
        profiles: ProfileStore,
        referrals: ReferralRedeemer | None = None,
    ) -> None:
        self.identity = identity
        self.profiles = profiles
        self.referrals = referrals

    async def google_sign_in(
        self, id_token: str, referral_code: str | None = None
    ) -> SignedIn:
        session = await self.identity.sign_in_with_google(id_token)
        signed_in = await self._complete(session)
        if referral_code and self.referrals:
            try:
                await self.referrals.apply_code(session.user_id, referral_code)
            except ReferralError as error:
                logger.info("Referral not applied: %s", error.code)
        return signed_in

    async def refresh(self, refresh_token: str) -> SignedIn:
        return await self._complete(await self.identity.refresh(refresh_token))

    async def _complete(self, session: AuthSession) -> SignedIn:
        profile = await self.profiles.touch_login(session.user_id)
        if profile.is_suspended or profile.deleted_at:
            raise AuthError("Account is inactive")
        return SignedIn(session, profile)
