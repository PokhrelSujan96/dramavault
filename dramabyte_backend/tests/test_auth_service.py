from datetime import UTC, datetime
from uuid import uuid4

import pytest

from app.application.auth import AuthService
from app.domain.profile import AuthError, AuthSession, Profile
from app.domain.referral import ReferralError

USER = uuid4()


class FakeIdentity:
    async def sign_in_with_google(self, id_token: str) -> AuthSession:
        if id_token != "valid":
            raise AuthError("Google sign-in rejected")
        return AuthSession(
            user_id=USER, access_token="a", refresh_token="r", expires_in=3600
        )

    async def refresh(self, refresh_token: str) -> AuthSession:
        return await self.sign_in_with_google("valid")


class FakeProfiles:
    async def touch_login(self, user_id):
        return Profile(id=user_id, created_at=datetime.now(UTC))


async def test_google_sign_in_returns_profile() -> None:
    result = await AuthService(FakeIdentity(), FakeProfiles()).google_sign_in("valid")
    assert result.profile.id == USER
    assert result.session.access_token == "a"


async def test_google_sign_in_rejects_invalid_token() -> None:
    with pytest.raises(AuthError):
        await AuthService(FakeIdentity(), FakeProfiles()).google_sign_in("bad")


class FakeReferrals:
    def __init__(self, fail: bool) -> None:
        self.fail = fail
        self.applied: list[str] = []

    async def apply_code(self, user_id, code: str) -> None:
        self.applied.append(code)
        if self.fail:
            raise ReferralError("invalid_code")


async def test_sign_in_applies_referral_code() -> None:
    referrals = FakeReferrals(fail=False)
    service = AuthService(FakeIdentity(), FakeProfiles(), referrals)
    await service.google_sign_in("valid", "ABCD1234")
    assert referrals.applied == ["ABCD1234"]


async def test_invalid_referral_never_blocks_sign_in() -> None:
    service = AuthService(FakeIdentity(), FakeProfiles(), FakeReferrals(fail=True))
    result = await service.google_sign_in("valid", "ABCD1234")
    assert result.profile.id == USER
