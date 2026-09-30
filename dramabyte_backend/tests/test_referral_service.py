from uuid import uuid4

import pytest

from app.application.referral import ReferralService
from app.domain.referral import ReferralError, ReferralSummary


class FakeStore:
    def __init__(self, result: str) -> None:
        self.result = result
        self.calls: list[tuple[int, int]] = []

    async def redeem(self, user_id, code, reward, max_referrals, window_hours):
        self.calls.append((reward, max_referrals))
        return self.result

    async def record_first_purchase(self, user_id, purchase_ref, reward):
        return self.result

    async def summary(self, user_id):
        return ReferralSummary(
            code="ABCD1234",
            invited=0,
            purchased=0,
            earned=0,
            redeemed=True,
            can_redeem=False,
            signup_reward=0,
            purchase_reward=0,
        )


def service(result: str) -> tuple[ReferralService, FakeStore]:
    store = FakeStore(result)
    return ReferralService(store, 5, 20, 50, 72), store


async def test_redeem_passes_configured_amounts() -> None:
    svc, store = service("ok")
    await svc.apply_code(uuid4(), "ABCD1234")
    assert store.calls == [(5, 50)]
    summary = await svc.summary(uuid4())
    assert (summary.signup_reward, summary.purchase_reward) == (5, 20)


@pytest.mark.parametrize("code", ["invalid_code", "already_redeemed", "not_eligible"])
async def test_redeem_failures_raise(code: str) -> None:
    svc, _ = service(code)
    with pytest.raises(ReferralError) as caught:
        await svc.apply_code(uuid4(), "ABCD1234")
    assert caught.value.code == code
