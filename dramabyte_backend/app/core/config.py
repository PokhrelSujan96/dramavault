from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    app_env: str = "development"
    api_prefix: str = "/api/v1"
    management_origin: str = "http://localhost:3000"
    supabase_url: str = ""
    supabase_anon_key: str = ""
    supabase_service_role_key: str = Field(default="", repr=False)
    supabase_jwt_audience: str = "authenticated"
    redis_url: str = "redis://localhost:6379/0"
    celery_broker_url: str = "redis://localhost:6379/1"
    celery_result_backend: str = "redis://localhost:6379/2"
    fal_api_key: str = Field(default="", repr=False)
    hybrid_reference_model: str = "fal-ai/flux-2/klein/4b/edit"
    hybrid_max_motion_shots: int = Field(default=24, ge=1, le=64)
    hybrid_motion_clips_per_minute: int = Field(default=8, ge=2, le=12)
    hybrid_episode_budget_cents: int = Field(default=400, ge=200, le=1000)
    hybrid_series_budget_cents: int = Field(default=7000, ge=1000, le=50000)
    hybrid_max_rerolls_per_shot: int = Field(default=1, ge=0, le=3)
    hybrid_provider_timeout: int = Field(default=1800, ge=60, le=3600)
    deepseek_api_key: str = Field(default="", repr=False)
    fish_audio_api_key: str = Field(default="", repr=False)
    fish_audio_reference_id: str = Field(
        default="dcd006182803481390993aa6e9669207",
        pattern=r"^[a-f0-9]{32}$",
    )
    whisper_cli_path: str = "whisper-cli"
    whisper_model_path: str = "models/ggml-base.bin"
    whisper_timeout_seconds: int = Field(default=600, ge=30, le=1800)
    dialogue_paid_enabled: bool = False
    cloudflare_account_id: str = ""
    cloudflare_r2_access_key_id: str = Field(default="", repr=False)
    cloudflare_r2_secret_access_key: str = Field(default="", repr=False)
    cloudflare_r2_bucket: str = "dramabyte-media"
    cloudflare_r2_public_url: str = ""
    stripe_secret_key: str = Field(default="", repr=False)
    stripe_webhook_secret: str = Field(default="", repr=False)
    referral_signup_reward: int = 5
    referral_purchase_reward: int = 20
    referral_max_per_user: int = 50
    referral_window_hours: int = 1
    history_max_rows: int = 200
    ratings_max_per_minute: int = 30
    comments_max_length: int = 500
    comments_max_per_minute: int = 10
    views_max_batch_items: int = 50
    views_max_item_count: int = 100
    views_max_per_minute: int = 120
    library_max_items: int = 200
    home_rail_size: int = 12
    search_min_length: int = 2
    search_max_length: int = 80
    home_cache_seconds: int = 60
    topup_sandbox: bool = True
    topup_order_ttl_minutes: int = 30
    topup_max_pending: int = 5
    revenuecat_webhook_secret: str = Field(default="", repr=False)

    @property
    def sandbox_enabled(self) -> bool:
        return self.topup_sandbox and self.app_env == "development"

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
