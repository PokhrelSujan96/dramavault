from functools import lru_cache

from app.core.config import settings
from supabase import AsyncClient, acreate_client


@lru_cache
def database_credentials() -> tuple[str, str]:
    return settings.supabase_url, settings.supabase_service_role_key


async def get_database() -> AsyncClient:
    url, key = database_credentials()
    return await acreate_client(url, key)
