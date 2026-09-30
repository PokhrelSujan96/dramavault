import json
import subprocess
from pathlib import Path

from app.infrastructure.rendering import _executable, _run


def normalize_reference(source: Path, output: Path) -> None:
    result = subprocess.run(
        [
            _executable("ffprobe"),
            "-v",
            "error",
            "-show_streams",
            "-of",
            "json",
            str(source),
        ],
        capture_output=True,
        timeout=20,
    )
    if result.returncode:
        raise ValueError("Invalid image")
    streams = json.loads(result.stdout).get("streams", [])
    if not streams or streams[0].get("codec_name") not in {"png", "mjpeg", "webp"}:
        raise ValueError("Unsupported image codec")
    if int(streams[0].get("width", 0)) * int(streams[0].get("height", 0)) > 25000000:
        raise ValueError("Image resolution exceeds safety limit")
    _run(
        [
            _executable("ffmpeg"),
            "-y",
            "-i",
            str(source),
            "-frames:v",
            "1",
            "-vf",
            "scale=768:1024:force_original_aspect_ratio=decrease:flags=lanczos,"
            "pad=768:1024:(ow-iw)/2:(oh-ih)/2",
            str(output),
        ],
        output.parent,
    )
