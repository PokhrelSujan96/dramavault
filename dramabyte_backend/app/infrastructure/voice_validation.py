import re
import subprocess
from pathlib import Path

from app.infrastructure.rendering import _executable


def validate_voice(path: Path) -> None:
    result = subprocess.run(
        [
            _executable("ffmpeg"),
            "-v",
            "info",
            "-i",
            str(path),
            "-map",
            "0:a:0",
            "-af",
            "volumedetect",
            "-f",
            "null",
            "-",
        ],
        capture_output=True,
        timeout=60,
    )
    match = re.search(r"mean_volume: (-?[\d.]+|-[iI]nf) dB", result.stderr.decode())
    if result.returncode or not match or float(match.group(1)) < -65:
        raise ValueError("Narration is missing or silent; check the voice provider")
