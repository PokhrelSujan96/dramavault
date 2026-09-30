from pathlib import Path
from shutil import copyfile
from typing import Any

from app.domain.caption_defaults import CAPTION_STYLE
from app.infrastructure.rendering import create_ass
from app.infrastructure.video_export import render_export


def save_preview(master: Path, project_id: str, captions: list[dict[str, Any]]) -> None:
    output = (Path("output/episodes") / project_id).resolve()
    output.mkdir(parents=True, exist_ok=True)
    copyfile(master, output / "master.mp4")
    create_ass(captions, CAPTION_STYLE, output / "captions.ass")
    render_export(
        output / "master.mp4", output / "captions.ass", output / "preview.mp4"
    )
