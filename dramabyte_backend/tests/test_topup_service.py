from datetime import UTC, datetime
from uuid import UUID, uuid4

import pytest

from app.application.topup import TopupService
from app.core.config import Settings
from app.domain.topup import TopupError, TopupOrder, VerifiedPayment
from app.infrastructure.payments import SandboxPaymentVerifier, payment_verifier

USER = uuid4()


def order(status: str = "pending") -> TopupOrder:
    now = datetime.now(UTC)
    return TopupOrder(
        id=uuid4(),
        package_id="coins_60",
        product_id="p",
        coins=60,
        bonus_coins=0,
        price_cents=99,
        currency="USD",
        status=status,
        created_at=now,
        expires_at=now,
    )


class FakeStore:
    def __init__(self, existing: TopupOrder) -> None:
        self.existing = existing
        self.completed: list[tuple[UUID, str, int]] = []

    async def get_order(self, user_id, order_id):
        return self.existing

    async def complete(self, user_id, order_id, payment: VerifiedPayment, reward):
        self.completed.append((user_id, payment.provider_ref, reward))
        return self.existing.model_copy(update={"status": "completed"})


class CountingVerifier(SandboxPaymentVerifier):
    calls = 0

    async def verify(self, order, receipt):
        CountingVerifier.calls += 1
        return await super().verify(order, receipt)


def service(existing: TopupOrder, verifier) -> tuple[TopupService, FakeStore]:
    store = FakeStore(existing)
    return TopupService(store, verifier, 20, 30, 5), store  # type: ignore[arg-type]


async def test_confirm_completes_pending_with_verified_reference() -> None:
    pending = order()
    svc, store = service(pending, SandboxPaymentVerifier())
    result = await svc.confirm(USER, pending.id, None)
    assert result.status == "completed"
    assert store.completed == [(USER, f"sandbox:{pending.id}", 20)]


async def test_confirm_completed_order_is_idempotent_and_skips_verifier() -> None:
    CountingVerifier.calls = 0
    svc, store = service(order("completed"), CountingVerifier())
    await svc.confirm(USER, uuid4(), None)
    assert CountingVerifier.calls == 0
    assert store.completed == []


async def test_confirm_without_verifier_is_unavailable() -> None:
    svc, store = service(order(), None)
    with pytest.raises(TopupError) as caught:
        await svc.confirm(USER, uuid4(), None)
    assert caught.value.code == "payments_unavailable"
    assert store.completed == []


@pytest.mark.parametrize("status", ["expired", "refunded"])
async def test_confirm_rejects_dead_orders(status: str) -> None:
    svc, store = service(order(status), SandboxPaymentVerifier())
    with pytest.raises(TopupError) as caught:
        await svc.confirm(USER, uuid4(), None)
    assert caught.value.code == "invalid_state"
    assert store.completed == []


@pytest.mark.parametrize("env", ["production", "staging", "test"])
def test_sandbox_only_in_development(env: str) -> None:
    settings = Settings(app_env=env, topup_sandbox=True)
    assert payment_verifier(settings) is None


def test_sandbox_enabled_in_development() -> None:
    assert payment_verifier(Settings(app_env="development")) is not None
