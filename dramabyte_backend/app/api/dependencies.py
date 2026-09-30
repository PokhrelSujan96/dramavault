from fastapi import Depends, HTTPException

from app.application.account import AccountService
from app.application.auth import AuthService
from app.application.comments import CommentService
from app.application.discover import DiscoverService
from app.application.engagement import EngagementService
from app.application.history import HistoryService
from app.application.home import HomeService
from app.application.library import LibraryService
from app.application.profile import ProfileService
from app.application.ratings import RatingService
from app.application.referral import ReferralService
from app.application.search import SearchService
from app.application.series import SeriesService
from app.application.topup import TopupService
from app.core.config import settings
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.database import get_database
from app.infrastructure.identity import SupabaseIdentityProvider
from app.infrastructure.payments import payment_verifier
from app.infrastructure.repositories.accounts import AccountRepository
from app.infrastructure.repositories.comments import CommentRepository
from app.infrastructure.repositories.discover import DiscoverRepository
from app.infrastructure.repositories.engagement import EngagementRepository
from app.infrastructure.repositories.history import HistoryRepository
from app.infrastructure.repositories.home import HomeRepository
from app.infrastructure.repositories.library import LibraryRepository
from app.infrastructure.repositories.profiles import ProfileRepository
from app.infrastructure.repositories.projects import ProjectRepository
from app.infrastructure.repositories.ratings import RatingRepository
from app.infrastructure.repositories.referrals import ReferralRepository
from app.infrastructure.repositories.search import SearchRepository
from app.infrastructure.repositories.series import SeriesRepository
from app.infrastructure.repositories.topups import TopupRepository
from supabase import AsyncClient


async def project_repository(
    database: AsyncClient = Depends(get_database),
) -> ProjectRepository:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return ProjectRepository(database)


async def profile_service(
    database: AsyncClient = Depends(get_database),
) -> ProfileService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return ProfileService(ProfileRepository(database))


async def auth_service(
    database: AsyncClient = Depends(get_database),
) -> AuthService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    identity = SupabaseIdentityProvider(
        settings.supabase_url, settings.supabase_anon_key
    )
    referrals = ReferralService(
        ReferralRepository(database),
        settings.referral_signup_reward,
        settings.referral_purchase_reward,
        settings.referral_max_per_user,
        settings.referral_window_hours,
    )
    return AuthService(identity, ProfileRepository(database), referrals)


async def referral_service(
    database: AsyncClient = Depends(get_database),
) -> ReferralService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return ReferralService(
        ReferralRepository(database),
        settings.referral_signup_reward,
        settings.referral_purchase_reward,
        settings.referral_max_per_user,
        settings.referral_window_hours,
    )


async def topup_service(
    database: AsyncClient = Depends(get_database),
) -> TopupService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return TopupService(
        TopupRepository(database),
        payment_verifier(settings),
        settings.referral_purchase_reward,
        settings.topup_order_ttl_minutes,
        settings.topup_max_pending,
    )


async def cached_discover_service(
    database: AsyncClient = Depends(get_database),
) -> DiscoverService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return DiscoverService(DiscoverRepository(database), R2Storage().published_url)


async def history_service(
    database: AsyncClient = Depends(get_database),
) -> HistoryService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return HistoryService(HistoryRepository(database), settings.history_max_rows)


async def home_service(
    database: AsyncClient = Depends(get_database),
) -> HomeService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return HomeService(
        HomeRepository(database),
        settings.home_rail_size,
        settings.home_cache_seconds,
        ratings=RatingService(
            RatingRepository(database), settings.ratings_max_per_minute
        ),
    )


async def series_service(
    database: AsyncClient = Depends(get_database),
) -> SeriesService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return SeriesService(SeriesRepository(database), R2Storage().published_url)


async def search_service(
    database: AsyncClient = Depends(get_database),
) -> SearchService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return SearchService(
        SearchRepository(database),
        settings.search_min_length,
        settings.search_max_length,
    )


async def library_service(
    database: AsyncClient = Depends(get_database),
) -> LibraryService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return LibraryService(LibraryRepository(database), settings.library_max_items)


async def engagement_service(
    database: AsyncClient = Depends(get_database),
) -> EngagementService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return EngagementService(
        EngagementRepository(database),
        settings.views_max_batch_items,
        settings.views_max_item_count,
        settings.views_max_per_minute,
    )


async def comment_service(
    database: AsyncClient = Depends(get_database),
) -> CommentService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return CommentService(
        CommentRepository(database),
        settings.comments_max_length,
        settings.comments_max_per_minute,
    )


async def rating_service(
    database: AsyncClient = Depends(get_database),
) -> RatingService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return RatingService(RatingRepository(database), settings.ratings_max_per_minute)


async def account_service(
    database: AsyncClient = Depends(get_database),
) -> AccountService:
    if not database:
        raise HTTPException(status_code=503, detail="Database unavailable")
    identity = SupabaseIdentityProvider(
        settings.supabase_url, settings.supabase_anon_key
    )
    return AccountService(AccountRepository(database), identity)
