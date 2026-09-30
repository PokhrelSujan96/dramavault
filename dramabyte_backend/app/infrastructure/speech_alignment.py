import json
import shutil
import subprocess
from pathlib import Path

from app.core.config import settings
from app.domain.narration_timing import TimedWord, align_script
from app.infrastructure.rendering import _executable, _run


def alignment_dependencies() -> tuple[str, Path]:
    executable = shutil.which(settings.whisper_cli_path)
    model = Path(settings.whisper_model_path).resolve()
    if not executable or not model.is_file() or model.stat().st_size < 1000000:
        raise RuntimeError(
            "Install whisper-cli and configure a valid WHISPER_MODEL_PATH"
        )
    return executable, model


def align_narration(
    audio: Path,
    script: str,
    language: str,
    seconds: float,
) -> list[TimedWord]:
    executable, model = alignment_dependencies()
    wave, output = audio.parent / "alignment.wav", audio.parent / "alignment"
    _run(
        [
            _executable("ffmpeg"),
            "-y",
            "-i",
            str(audio),
            "-ar",
            "16000",
            "-ac",
            "1",
            "-c:a",
            "pcm_s16le",
            str(wave),
        ],
        audio.parent,
    )
    result = subprocess.run(
        [
            executable,
            "-m",
            str(model),
            "-f",
            str(wave),
            "-l",
            language,
            "-ml",
            "1",
            "-sow",
            "-oj",
            "-of",
            str(output),
            "-t",
            "2",
            "-np",
        ],
        capture_output=True,
        timeout=settings.whisper_timeout_seconds,
    )
    if result.returncode:
        raise RuntimeError(
            "Local Whisper alignment failed; inspect model configuration"
        )
    metadata = json.loads(output.with_suffix(".json").read_text())
    words: list[TimedWord] = []
    for segment in metadata["transcription"]:
        text = str(segment["text"]).strip()
        if not text or text.startswith("["):
            continue
        if len(text.split()) != 1:
            raise ValueError("Whisper did not return word-level timing")
        start = float(segment["offsets"]["from"]) / 1000
        end = float(segment["offsets"]["to"]) / 1000
        if end > start:
            words.append(TimedWord(text=text, start=start, end=end))
    return align_script(script, words, seconds)
