from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from httpx import ConnectError
from postgrest.exceptions import APIError

from app.api.router import api_router
from app.core.config import settings
from app.core.logging import configure_logging


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    configure_logging()
    yield


app = FastAPI(
    title="DramaByte API",
    version="0.1.0",
    docs_url="/docs" if not settings.is_production else None,
    redoc_url=None,
    lifespan=lifespan,
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[settings.management_origin],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type", "Idempotency-Key"],
)


@app.exception_handler(ConnectError)
async def upstream_unavailable(_: object, __: ConnectError) -> JSONResponse:
    return JSONResponse(
        status_code=503,
        content={"detail": "Database connection is temporarily unavailable"},
    )


app.include_router(api_router, prefix=settings.api_prefix)


@app.exception_handler(APIError)
async def database_request_failed(_: object, error: APIError) -> JSONResponse:
    missing_schema = error.code in {"PGRST205", "PGRST202", "42703", "42P01"}
    detail = (
        "Database setup is pending. Apply the pending Supabase migrations."
        if missing_schema
        else "Database rejected this action. Check conflicting records."
    )
    return JSONResponse(
        status_code=503 if missing_schema else 409, content={"detail": detail}
    )
