import subprocess
from array import array
from pathlib import Path

from app.infrastructure.rendering import _executable


def audio_peaks(path: Path, count: int = 320) -> list[float]:
    result = subprocess.run(
        [
            _executable("ffmpeg"),
            "-v",
            "error",
            "-i",
            str(path),
            "-map",
            "0:a:0",
            "-vn",
            "-ac",
            "1",
            "-ar",
            "8000",
            "-f",
            "s16le",
            "pipe:1",
        ],
        check=True,
        capture_output=True,
        timeout=180,
    )
    samples = array("h")
    samples.frombytes(result.stdout)
    if not samples:
        raise ValueError("Audio track is empty")
    step = max(1, len(samples) // count)
    peaks = [
        max(abs(sample) for sample in samples[index : index + step]) / 32768
        for index in range(0, len(samples), step)
    ][:count]
    highest = max(peaks) or 1
    return [round(min(1.0, peak / highest), 3) for peak in peaks]
