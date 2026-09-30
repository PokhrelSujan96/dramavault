from collections.abc import Mapping
from dataclasses import dataclass

import jwt
from fastapi import Cookie, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.config import settings
from app.infrastructure.database import get_database

bearer = HTTPBearer(auto_error=False)


@dataclass(frozen=True, slots=True)
class Principal:
    user_id: str
    role: str


async def current_principal(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    dramabyte_access: str | None = Cookie(default=None),
) -> Principal:
    token = credentials.credentials if credentials else dramabyte_access
    if token is None or not settings.supabase_url:
        raise HTTPException(status_code=401, detail="Authentication required")
    jwks_url = f"{settings.supabase_url}/auth/v1/.well-known/jwks.json"
    try:
        signing_key = jwt.PyJWKClient(jwks_url).get_signing_key_from_jwt(token)
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256", "ES256"],
            audience=settings.supabase_jwt_audience,
            options={"require": ["exp", "sub"]},
        )
    except jwt.PyJWTError as error:
        raise HTTPException(status_code=401, detail="Invalid access token") from error
    metadata = payload.get("app_metadata", {})
    role = metadata.get("role", payload.get("role", ""))
    database = await get_database()
    profile = (
        await database.table("profiles")
        .select("*")
        .eq("id", str(payload["sub"]))
        .limit(1)
        .execute()
    )
    if (
        profile.data
        and isinstance(profile.data[0], Mapping)
        and (profile.data[0].get("is_suspended") or profile.data[0].get("deleted_at"))
    ):
        raise HTTPException(status_code=403, detail="Account is inactive")
    return Principal(user_id=str(payload["sub"]), role=str(role))


async def require_admin(
    principal: Principal = Depends(current_principal),
) -> Principal:
    allowed = {"admin", "service_role"}
    if not settings.is_production:
        allowed.add("authenticated")
    if principal.role not in allowed:
        raise HTTPException(status_code=403, detail="Administrator access required")
    return principal
