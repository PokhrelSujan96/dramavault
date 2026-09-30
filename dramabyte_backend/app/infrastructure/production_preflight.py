import shutil
from tempfile import gettempdir

from app.core.config import settings
from app.infrastructure.rendering import _executable
from app.infrastructure.speech_alignment import alignment_dependencies


def production_preflight() -> None:
    _executable("ffmpeg")
    _executable("ffprobe")
    alignment_dependencies()
    required = (
        settings.fal_api_key,
        settings.deepseek_api_key,
        settings.fish_audio_api_key,
        settings.cloudflare_account_id,
        settings.cloudflare_r2_access_key_id,
        settings.cloudflare_r2_secret_access_key,
    )
    if not all(required):
        raise ValueError("Generation and R2 credentials must be configured")
    if shutil.disk_usage(gettempdir()).free < 2 * 1024**3:
        raise ValueError("At least 2 GB of temporary disk space is required")
