from typing import Any

from app.domain.caption_defaults import CAPTION_STYLE
from app.infrastructure.production_store import ProductionStore


def save_narrated_metadata(
    store: ProductionStore,
    project_id: str,
    run_id: str,
    key: str,
    url: str,
    captions: list[dict[str, object]],
) -> None:
    output: dict[str, Any] = {"captions": captions, "style": CAPTION_STYLE}
    store.job(project_id, "subtitles", "dramabyte-editor", output)
    store.job(
        project_id,
        "publish",
        "cloudflare-r2-preview",
        {
            "key": key,
            "url": url,
            "run_id": run_id,
            "width": 1080,
            "height": 1920,
            "private": True,
            "audio_mode": "single_narrator",
            "music": False,
            "lipsync": False,
        },
    )
