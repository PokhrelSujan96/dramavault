import httpx
import pytest
from fal_client.client import FalClientHTTPError

from app.infrastructure.provider_checkpoint import submit_once


@pytest.mark.parametrize("code", [400, 401, 402, 403, 404, 422])
def test_known_rejection_releases_reservation(code: int) -> None:
    released = []

    def reject() -> None:
        raise FalClientHTTPError("Rejected", code, {}, httpx.Response(code))

    with pytest.raises(FalClientHTTPError):
        submit_once(reject, lambda: released.append(True))
    assert released == [True]


def test_ambiguous_timeout_does_not_release_reservation() -> None:
    released = []

    def timeout() -> None:
        raise TimeoutError("Transport timeout")

    with pytest.raises(TimeoutError):
        submit_once(timeout, lambda: released.append(True))
    assert released == []
