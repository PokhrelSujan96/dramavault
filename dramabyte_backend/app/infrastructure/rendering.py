import json
import re
import shutil
import subprocess
from pathlib import Path
from typing import Any

from app.infrastructure.http_download import download_file
from app.infrastructure.video_dimensions import video_dimensions


def download(url: str, destination: Path) -> None:
    download_file(url, destination)


def duration(path: Path) -> float:
    result = subprocess.run(
        [
            _executable("ffprobe"),
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            str(path),
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return float(result.stdout.strip())


def build_captions(script: str, seconds: float) -> list[dict[str, Any]]:
    words = script.split()
    groups = [words[index : index + 8] for index in range(0, len(words), 8)]
    interval = seconds / max(1, len(groups))
    return [
        {
            "id": index,
            "text": re.sub(r"\s+", " ", " ".join(group)).strip(),
            "start": round(index * interval, 3),
            "end": round(min(seconds, (index + 1) * interval), 3),
        }
        for index, group in enumerate(groups)
    ]


def render_master(video: Path, audio: Path, output: Path) -> None:
    _run(
        [
            _executable("ffmpeg"),
            "-y",
            "-stream_loop",
            "-1",
            "-i",
            str(video),
            "-i",
            str(audio),
            "-c:v",
            "libx264",
            "-preset",
            "medium",
            "-crf",
            "20",
            "-c:a",
            "aac",
            "-af",
            "loudnorm=I=-14:LRA=7:TP=-1",
            "-b:a",
            "192k",
            "-shortest",
            "-movflags",
            "+faststart",
            str(output),
        ],
        output.parent,
    )


def create_ass(
    captions: list[dict[str, Any]],
    style: dict[str, Any],
    path: Path,
    aspect: str = "9:16",
    text_overlays: list[dict[str, Any]] | None = None,
) -> None:
    width, height = video_dimensions(aspect)
    color = _ass_color(str(style.get("color", "#ffffff")), 1)
    opacity = float(style.get("background_opacity", 0.82))
    background = _ass_color(str(style.get("background", "#111111")), opacity)
    outline_color = _ass_color(str(style.get("outline_color", "#000000")), 1)
    x = round(float(style.get("x", 0.5)) * width)
    y = round(float(style.get("y", 0.82)) * height)
    align = {"left": 1, "center": 2, "right": 3}.get(
        str(style.get("align", "center")), 2
    )
    font = str(style.get("font", "Poppins"))
    size = int(style.get("size", 54))
    weight = -1 if int(style.get("weight", 700)) >= 700 else 0
    italic = int(bool(style.get("italic", False)))
    underline = int(bool(style.get("underline", False)))
    outline = float(style.get("outline", 0))
    shadow = float(style.get("shadow", 0))
    spacing = float(style.get("letter_spacing", 0))
    animation = str(style.get("animation", "none"))
    side_margin = round((1 - float(style.get("max_width", 0.82))) * width / 2)
    alignment = {"left": 1, "center": 2, "right": 3}.get(
        str(style.get("align", "center")), 2
    )
    border_style = 3 if opacity > 0 else 1
    header = (
        f"[Script Info]\nScriptType: v4.00+\nPlayResX: {width}\nPlayResY: {height}\n"
        "WrapStyle: 2\n\n[V4+ Styles]\n"
        "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, "
        "OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, "
        "ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, "
        "Alignment, MarginL, MarginR, MarginV, Encoding\n"
        f"Style: Caption,{font},{size},{color},{color},{outline_color},{background},"
        f"{weight},{italic},{underline},0,100,100,{spacing},0,{border_style},"
        f"{outline},{shadow},{align},{side_margin},{side_margin},40,1\n"
    )
    overlay_styles = []
    overlay_events = []
    for index, overlay in enumerate(text_overlays or []):
        text_style = overlay.get("style", {})
        name = f"Overlay{index}"
        overlay_align = {"left": 1, "center": 2, "right": 3}.get(
            str(text_style.get("align", "center")), 2
        )
        text_opacity = float(text_style.get("background_opacity", 0))
        text_border = 3 if text_opacity > 0 else 1
        text_color = _ass_color(str(text_style.get("color", "#ffffff")), 1)
        text_back = _ass_color(
            str(text_style.get("background", "#111111")), text_opacity
        )
        text_outline = _ass_color(
            str(text_style.get("outline_color", "#000000")), 1
        )
        text_weight = -1 if int(text_style.get("weight", 700)) >= 700 else 0
        overlay_styles.append(
            f"Style: {name},{text_style.get('font', 'Poppins')},"
            f"{int(text_style.get('size', 54))},{text_color},{text_color},"
            f"{text_outline},{text_back},{text_weight},"
            f"{int(bool(text_style.get('italic', False)))},"
            f"{int(bool(text_style.get('underline', False)))},0,100,100,"
            f"{float(text_style.get('letter_spacing', 0))},0,{text_border},"
            f"{float(text_style.get('outline', 0))},"
            f"{float(text_style.get('shadow', 0))},{overlay_align},0,0,0,1\n"
        )
        overlay_x = round(float(overlay.get("x", 0.5)) * width)
        overlay_y = round(float(overlay.get("y", 0.5)) * height)
        overlay_width = max(1, round(float(overlay.get("width", 0.65)) * width))
        font_size = int(text_style.get("size", 54))
        character_limit = max(1, int(overlay_width / (font_size * 0.55)))
        overlay_text = _wrap_ass_text(str(overlay.get("text", "")), character_limit)
        overlay_animation = _ass_animation(str(text_style.get("animation", "none")))
        overlay_events.append(
            f"Dialogue: 1,{_ass_time(float(overlay.get('start', 0)))},"
            f"{_ass_time(float(overlay.get('end', 5)))},{name},,0,0,0,,"
            f"{{\\an{overlay_align}\\pos({overlay_x},{overlay_y})"
            f"{overlay_animation}}}{overlay_text}"
        )
    header += "".join(overlay_styles) + "\n"
    header += (
        "[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, "
        "MarginV, Effect, Text\n"
    )
    events = []
    for item in captions:
        value = str(item["text"]).replace("\n", r"\N").replace("{", r"\{")
        if animation != "none":
            value = f"{{{_ass_animation(animation)}}}" + value
        events.append(
            f"Dialogue: 0,{_ass_time(float(item['start']))},"
            f"{_ass_time(float(item['end']))},Caption,,0,0,0,,"
            f"{{\\an{alignment}\\pos({x},{y})}}{value}"
        )
    path.write_text(
        header + "\n".join([*events, *overlay_events]), encoding="utf-8"
    )


def validate_export(path: Path, aspect: str) -> None:
    result = subprocess.run(
        [
            _executable("ffprobe"),
            "-v",
            "error",
            "-show_entries",
            "stream=codec_type,codec_name,width,height",
            "-of",
            "json",
            str(path),
        ],
        capture_output=True,
        check=True,
        timeout=30,
        text=True,
    )
    streams = json.loads(result.stdout).get("streams", [])
    width, height = video_dimensions(aspect)
    video: dict[str, Any] = next(
        (item for item in streams if item.get("codec_type") == "video"), {}
    )
    if (video.get("width"), video.get("height")) != (width, height):
        raise RuntimeError("Export resolution failed Full HD validation")
    if video.get("codec_name") != "h264":
        raise RuntimeError("Export video codec failed mobile compatibility validation")
    if not any(item.get("codec_type") == "audio" for item in streams):
        raise RuntimeError("Export is missing its audio track")


def _run(command: list[str], cwd: Path) -> None:
    result = subprocess.run(command, cwd=str(cwd), capture_output=True, timeout=1800)
    if result.returncode != 0:
        detail = result.stderr.decode(errors="replace")[-3000:]
        raise RuntimeError(f"FFmpeg render failed: {detail}")


def _ass_time(seconds: float) -> str:
    centis = round(seconds * 100)
    hours, remainder = divmod(centis, 360000)
    minutes, remainder = divmod(remainder, 6000)
    secs, fraction = divmod(remainder, 100)
    return f"{hours}:{minutes:02}:{secs:02}.{fraction:02}"


def _ass_animation(value: str) -> str:
    if value == "fade":
        return r"\fad(140,140)"
    if value == "pop":
        return r"\fscx82\fscy82\t(0,160,\fscx100\fscy100)"
    return ""


def _wrap_ass_text(value: str, limit: int) -> str:
    lines = []
    for paragraph in value.splitlines() or [value]:
        words = paragraph.split()
        line = ""
        for word in words:
            candidate = f"{line} {word}".strip()
            if line and len(candidate) > limit:
                lines.append(line)
                line = word
            else:
                line = candidate
        if line:
            lines.append(line)
    return r"\N".join(lines).replace("{", r"\{").replace("}", r"\}")


def _filter_path(path: Path) -> str:
    return path.as_posix().replace("\\", "\\\\").replace(":", "\\:").replace("'", "\\'")


def _ass_color(value: str, opacity: float) -> str:
    value = value.lstrip("#").zfill(6)
    red, green, blue = value[:2], value[2:4], value[4:6]
    alpha = round((1 - opacity) * 255)
    return f"&H{alpha:02X}{blue}{green}{red}"


def _executable(name: str) -> str:
    full = Path(f"/opt/homebrew/opt/ffmpeg-full/bin/{name}")
    if full.exists():
        return str(full)
    executable = shutil.which(name)
    if executable is None:
        raise RuntimeError(f"{name} is not installed")
    return executable
