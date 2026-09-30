import json
import subprocess
from pathlib import Path

from app.infrastructure.rendering import _executable, _run, duration


def dimensions(aspect: str) -> tuple[int, int]:
    return {"9:16": (1080, 1920), "16:9": (1920, 1080), "1:1": (1080, 1080)}[aspect]


def frame_duration(start: float, end: float) -> float:
    frames = round(end * 30) - round(start * 30)
    if frames < 1:
        raise ValueError("Shot interval must cover at least one output frame")
    return frames / 30


def render_shot(
    source: Path, output: Path, seconds: float, kind: str, aspect: str
) -> None:
    width, height = dimensions(aspect)
    fit = f"scale={width}:{height}:force_original_aspect_ratio=increase:flags=lanczos"
    crop = f"crop={width}:{height},setsar=1"
    if kind == "still":
        frames = round(seconds * 30)
        zoom = (
            f"zoompan=z='min(zoom+0.0008,1.06)':"
            f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':"
            f"d={frames}:s={width}x{height}:fps=30"
        )
        filters = f"{fit},{crop},{zoom},unsharp=5:5:0.25:5:5:0"
        inputs = ["-loop", "1", "-i", str(source)]
    elif kind == "motion":
        filters = f"{fit},{crop},unsharp=5:5:0.35:5:5:0,fps=30"
        inputs = ["-i", str(source)]
    else:
        raise ValueError("Unknown shot kind")
    if kind == "motion" and duration(source) + 0.005 < seconds:
        raise ValueError(
            "Motion clip is shorter than its shot; refusing to loop or freeze"
        )
    _run(
        [
            _executable("ffmpeg"),
            "-y",
            *inputs,
            "-vf",
            filters,
            "-frames:v",
            str(round(seconds * 30)),
            "-an",
            "-c:v",
            "libx264",
            "-preset",
            "medium",
            "-crf",
            "18",
            "-pix_fmt",
            "yuv420p",
            "-threads",
            "2",
            str(output),
        ],
        output.parent,
    )


def assemble(shots: list[Path], voice: Path, output: Path, seconds: float) -> None:
    manifest = output.parent / "shots.txt"
    manifest.write_text("\n".join(f"file '{path.name}'" for path in shots))
    _run(
        [
            _executable("ffmpeg"),
            "-y",
            "-f",
            "concat",
            "-safe",
            "1",
            "-i",
            str(manifest),
            "-i",
            str(voice),
            "-map",
            "0:v:0",
            "-map",
            "1:a:0",
            "-c:v",
            "copy",
            "-c:a",
            "aac",
            "-b:a",
            "192k",
            "-af",
            "loudnorm=I=-14:LRA=7:TP=-1",
            "-t",
            str(seconds),
            "-movflags",
            "+faststart",
            str(output),
        ],
        output.parent,
    )


def validate_master(path: Path, seconds: float, aspect: str) -> None:
    result = subprocess.run(
        [
            _executable("ffprobe"),
            "-v",
            "error",
            "-show_streams",
            "-show_format",
            "-of",
            "json",
            str(path),
        ],
        capture_output=True,
        check=True,
        timeout=30,
    )
    metadata = json.loads(result.stdout)
    streams = metadata["streams"]
    video = next(stream for stream in streams if stream["codec_type"] == "video")
    if (video["width"], video["height"]) != dimensions(aspect):
        raise RuntimeError("Master dimensions failed validation")
    if not any(stream["codec_type"] == "audio" for stream in streams):
        raise RuntimeError("Master has no narration track")
    if abs(float(metadata["format"]["duration"]) - seconds) > 0.25:
        raise RuntimeError("Master duration does not match narration")
