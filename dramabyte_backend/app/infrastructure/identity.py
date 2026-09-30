import logging

import jwt
from supabase_auth.errors import AuthError as SupabaseAuthError
from supabase_auth.types import AuthResponse

from app.domain.profile import AuthError, AuthSession
from supabase import acreate_client

logger = logging.getLogger(__name__)


class SupabaseIdentityProvider:
    def __init__(self, url: str, anon_key: str) -> None:
        self.url = url
        self.anon_key = anon_key

    async def sign_in_with_google(self, id_token: str) -> AuthSession:
        client = await acreate_client(self.url, self.anon_key)
        try:
            result = await client.auth.sign_in_with_id_token(
                {"provider": "google", "token": id_token}
            )
        except SupabaseAuthError as error:
            try:
                claims = jwt.decode(id_token, options={"verify_signature": False})
            except jwt.PyJWTError:
                claims = {}
            logger.error(
                "Supabase auth error: %s aud=%s iss=%s",
                error,
                claims.get("aud"),
                claims.get("iss"),
            )
            raise AuthError("Google sign-in rejected") from error
        return self._session(result)

    async def verify_google(self, id_token: str) -> str:
        return (await self.sign_in_with_google(id_token)).user_id

    async def refresh(self, refresh_token: str) -> AuthSession:
        client = await acreate_client(self.url, self.anon_key)
        try:
            result = await client.auth.refresh_session(refresh_token)
        except SupabaseAuthError as error:
            logger.error("Supabase auth error: %s", error)
            raise AuthError("Session expired") from error
        return self._session(result)

    @staticmethod
    def _session(result: AuthResponse) -> AuthSession:
        if result.session is None or result.user is None:
            raise AuthError("Session unavailable")
        return AuthSession(
            user_id=result.user.id,
            access_token=result.session.access_token,
            refresh_token=result.session.refresh_token,
            expires_in=result.session.expires_in,
        )
