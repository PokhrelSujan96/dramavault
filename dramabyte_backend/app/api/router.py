from fastapi import APIRouter

from app.api.routes import (
    account,
    auth,
    characters,
    comments,
    dialogue_actions,
    dialogue_pilots,
    discover,
    editor_assets,
    editor_audio,
    editor_music,
    editor_waveform,
    engagement,
    episode_upload,
    feed,
    generation,
    health,
    history,
    home,
    hybrid,
    library,
    localized_audio,
    management,
    management_catalog,
    management_series,
    management_videos,
    platform_admin,
    profile,
    projects,
    public_comments,
    public_series,
    public_views,
    ratings,
    referral,
    search,
    series,
    series_feed,
    story_templates,
    topup,
    views,
)

api_router = APIRouter()
api_router.include_router(editor_audio.router, prefix="/generation", tags=["editor"])
api_router.include_router(localized_audio.router, prefix="/generation", tags=["editor"])
api_router.include_router(editor_assets.router, prefix="/generation", tags=["editor"])
api_router.include_router(editor_music.router, prefix="/generation", tags=["editor"])
api_router.include_router(editor_waveform.router, prefix="/generation", tags=["editor"])
api_router.include_router(
    story_templates.router, prefix="/generation", tags=["generation"]
)
api_router.include_router(dialogue_pilots.router, prefix="/generation", tags=["pilots"])
api_router.include_router(
    dialogue_actions.router, prefix="/generation", tags=["pilots"]
)
api_router.include_router(characters.router, prefix="/admin", tags=["admin"])
api_router.include_router(hybrid.router, prefix="/generation", tags=["generation"])
api_router.include_router(engagement.router, prefix="/engagement", tags=["engagement"])
api_router.include_router(platform_admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(health.router, tags=["health"])
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(profile.router, prefix="/profile", tags=["profile"])
api_router.include_router(projects.router, prefix="/projects", tags=["projects"])
api_router.include_router(generation.router, prefix="/generation", tags=["generation"])
api_router.include_router(referral.router, prefix="/referral", tags=["referral"])
api_router.include_router(feed.router, prefix="/feed", tags=["feed"])
api_router.include_router(series_feed.router, prefix="/feed", tags=["feed"])
api_router.include_router(management.router, prefix="/admin", tags=["admin"])
api_router.include_router(management_catalog.router, prefix="/admin", tags=["admin"])
api_router.include_router(episode_upload.router, prefix="/admin", tags=["admin"])
api_router.include_router(management_series.router, prefix="/admin", tags=["admin"])
api_router.include_router(management_videos.router, prefix="/admin", tags=["admin"])
api_router.include_router(topup.router, prefix="/topup", tags=["topup"])
api_router.include_router(discover.router, prefix="/discover", tags=["discover"])
api_router.include_router(history.router, prefix="/history", tags=["history"])
api_router.include_router(home.router, prefix="/home", tags=["home"])
api_router.include_router(series.router, prefix="/series", tags=["series"])
api_router.include_router(search.router, prefix="/search", tags=["search"])
api_router.include_router(library.router, prefix="/library", tags=["library"])
api_router.include_router(views.router, prefix="/views", tags=["views"])
api_router.include_router(comments.router, prefix="/comments", tags=["comments"])
api_router.include_router(ratings.router, prefix="/ratings", tags=["ratings"])
api_router.include_router(account.router, prefix="/account", tags=["account"])

api_router.include_router(
    public_series.router, prefix="/public/series", tags=["series"]
)

api_router.include_router(
    public_comments.router, prefix="/public/comments", tags=["comments"]
)

api_router.include_router(public_views.router, prefix="/public/views", tags=["views"])
