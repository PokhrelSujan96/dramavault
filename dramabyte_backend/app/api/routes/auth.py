from fastapi import APIRouter, Depends, HTTPException, Response
from supabase_auth.errors import AuthApiError
from supabase_auth.types import SignInWithEmailAndPasswordCredentials

from app.api.dependencies import auth_service
from app.api.schemas import (
    GoogleSignInBody,
    RefreshBody,
    SessionResponse,
    SignInBody,
    TokenResponse,
)
from app.application.auth import AuthService, SignedIn
from app.core.config import settings
from app.domain.profile import AuthError
from supabase import acreate_client

router = APIRouter()


@router.post("/sign-in", response_model=SessionResponse)
async def sign_in(body: SignInBody, response: Response) -> SessionResponse:
    client = await acreate_client(settings.supabase_url, settings.supabase_anon_key)
    try:
        credentials: SignInWithEmailAndPasswordCredentials = {
            "email": body.email,
            "password": body.password,
        }
        result = await client.auth.sign_in_with_password(credentials)
    except AuthApiError as error:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password",
        ) from error
    if result.session is None or result.user is None:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    response.set_cookie(
        "dramabyte_access",
        result.session.access_token,
        httponly=True,
        secure=settings.is_production,
        samesite="lax",
        max_age=result.session.expires_in,
    )
    return SessionResponse(
        user_id=result.user.id,
        email=result.user.email or body.email,
    )


@router.post("/sign-out", status_code=204)
async def sign_out(response: Response) -> None:
    response.delete_cookie("dramabyte_access")


def _token_response(signed_in: SignedIn) -> TokenResponse:
    return TokenResponse(
        access_token=signed_in.session.access_token,
        refresh_token=signed_in.session.refresh_token,
        expires_in=signed_in.session.expires_in,
        user_id=signed_in.session.user_id,
    )


@router.post("/google", response_model=TokenResponse)
async def google_sign_in(
    body: GoogleSignInBody,
    service: AuthService = Depends(auth_service),
) -> TokenResponse:
    try:
        return _token_response(
            await service.google_sign_in(body.id_token, body.referral_code)
        )
    except AuthError as error:
        raise HTTPException(status_code=401, detail=str(error)) from error


@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    body: RefreshBody,
    service: AuthService = Depends(auth_service),
) -> TokenResponse:
    try:
        return _token_response(await service.refresh(body.refresh_token))
    except AuthError as error:
        raise HTTPException(status_code=401, detail=str(error)) from error
