from app.core.config import Settings
from app.domain.topup import TopupOrder, VerifiedPayment


class SandboxPaymentVerifier:
    async def verify(self, order: TopupOrder, receipt: str | None) -> VerifiedPayment:
        return VerifiedPayment(provider="sandbox", provider_ref=f"sandbox:{order.id}")


def payment_verifier(settings: Settings) -> SandboxPaymentVerifier | None:
    return SandboxPaymentVerifier() if settings.sandbox_enabled else None
