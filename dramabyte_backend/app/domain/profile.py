from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class AuthError(Exception):
    pass


class Profile(BaseModel):
    id: UUID
    email: str | None = None
    display_name: str = ""
    avatar_url: str | None = None
    auth_provider: str = "email"
    country: str | None = None
    language: str = "en"
    coins: int = 0
    bonus_coins: int = 0
    vip_expires_at: datetime | None = None
    is_onboarded: bool = False
    is_suspended: bool = False
    deleted_at: datetime | None = None
    last_login_at: datetime | None = None
    created_at: datetime


class AuthSession(BaseModel):
    user_id: UUID
    access_token: str
    refresh_token: str
    expires_in: int
