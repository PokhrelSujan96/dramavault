from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.api.dependencies import account_service
from app.application.account import AccountService
from app.core.security import Principal, current_principal
from app.domain.account import Preferences
from app.domain.profile import AuthError
from app.main import app

USER = str(uuid4())
TOKEN = "t" * 40


class FakeStore:
    def __init__(self) -> None:
        self.saved = Preferences(False, False, False)
        self.erased = False

    async def preferences(self, user_id):
        return self.saved

    async def save(self, user_id, preferences):
        self.saved = preferences

    async def erase(self, user_id):
        self.erased = True


class FakeIdentity:
    def __init__(self, user: str | None) -> None:
        self.user = user

    async def verify_google(self, id_token):
        if self.user is None:
            raise AuthError("rejected")
        return self.user


def client(identity_user: str | None):
    store = FakeStore()
    app.dependency_overrides[current_principal] = lambda: Principal(
        USER, "authenticated"
    )
    app.dependency_overrides[account_service] = lambda: AccountService(
        store, FakeIdentity(identity_user)
    )
    return TestClient(app), store


@pytest.fixture(autouse=True)
def _clear():
    yield
    app.dependency_overrides.clear()


def test_preferences_round_trip() -> None:
    http, _ = client(USER)
    body = {"marketing": True, "analytics": False, "personalization": True}
    assert http.put("/api/v1/account/preferences", json=body).json() == body
    assert http.get("/api/v1/account/preferences").json() == body


def test_delete_erases_after_matching_reauthentication() -> None:
    http, store = client(USER)
    assert (
        http.post("/api/v1/account/delete", json={"id_token": TOKEN}).status_code == 204
    )
    assert store.erased


@pytest.mark.parametrize("identity_user", [str(uuid4()), None])
def test_delete_refuses_a_different_or_invalid_identity(identity_user) -> None:
    http, store = client(identity_user)
    assert (
        http.post("/api/v1/account/delete", json={"id_token": TOKEN}).status_code == 403
    )
    assert not store.erased
