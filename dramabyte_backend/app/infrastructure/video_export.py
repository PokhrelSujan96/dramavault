from pathlib import Path
from typing import Any

from app.infrastructure.rendering import (
    _executable,
    _filter_path,
    _run,
    duration,
    validate_export,
)
from app.infrastructure.video_dimensions import video_dimensions


def render_export(
    master: Path,
    ass: Path,
    output: Path,
    music: Path | None = None,
    music_settings: dict[str, Any] | None = None,
    attribution: str | None = None,
    aspect: str = "9:16",
    image_overlays: list[dict[str, Any]] | None = None,
    sound_effects: list[tuple[Path, dict[str, Any]]] | None = None,
    narration: Path | None = None,
) -> None:
    width, height = video_dimensions(aspect)
    command = [_executable("ffmpeg"), "-y", "-i", str(master)]
    images = image_overlays or []
    effects = sound_effects or []
    for image in images:
        command.extend(["-loop", "1", "-i", str(image["path"])])
    audio_inputs: list[tuple[int, dict[str, Any], str]] = []
    next_input = len(images) + 1
    narration_input = None
    if narration:
        command.extend(["-i", str(narration)])
        narration_input = next_input
        next_input += 1
    music_input = None
    if music and music_settings:
        command.extend(["-stream_loop", "-1", "-i", str(music)])
        music_input = next_input
        next_input += 1
    for path, settings in effects:
        command.extend(["-i", str(path)])
        audio_inputs.append((next_input, settings, "effect"))
        next_input += 1
    base_filters = [
        f"scale={width}:{height}:force_original_aspect_ratio=increase:flags=lanczos",
        f"crop={width}:{height}",
        "setsar=1",
        "unsharp=5:5:0.25:3:3:0",
    ]
    if music_input is not None and music_settings is not None:
        audio_inputs.insert(0, (music_input, music_settings, "music"))
    filter_graph, video_map, audio_map = _filter_graph(
        base_filters,
        ass,
        images,
        audio_inputs,
        width,
        height,
        duration(master),
        narration_input,
    )
    has_graph = bool(images or audio_inputs or narration_input is not None)
    if has_graph:
        command.extend(["-filter_complex", filter_graph, "-map", video_map])
        command.extend(["-map", audio_map, "-c:a", "aac", "-b:a", "320k"])
    else:
        command.extend(
            [
                "-map",
                "0:v:0",
                "-map",
                "0:a:0",
                "-c:a",
                "copy",
                "-vf",
                ",".join(
                    [
                        *base_filters,
                        f"ass=filename='{_filter_path(ass)}':"
                        f"fontsdir='{_filter_path(ass.parent)}'",
                    ]
                ),
            ]
        )
    command.extend(
        [
            "-c:v",
            "libx264",
            "-preset",
            "slow",
            "-crf",
            "13",
            "-pix_fmt",
            "yuv420p",
            "-profile:v",
            "high",
            "-movflags",
            "+faststart",
            "-t",
            f"{duration(master):.3f}",
            str(output),
        ]
    )
    if attribution:
        command.extend(["-metadata", f"comment={attribution[:1800]}"])
    _run(command, output.parent)
    validate_export(output, aspect)


def _filter_graph(
    base_filters: list[str],
    ass: Path,
    images: list[dict[str, Any]],
    audio_inputs: list[tuple[int, dict[str, Any], str]],
    width: int,
    height: int,
    movie_duration: float,
    narration_input: int | None = None,
) -> tuple[str, str, str]:
    graphs = [f"[0:v]{','.join(base_filters)}[base0]"] if images else []
    previous = "base0"
    for index, image in enumerate(images):
        input_index = index + 1
        overlay_width = max(1, round(width * float(image.get("width", 0.5))))
        x = f"(W*{float(image.get('x', 0.5)):.5f}-w/2)"
        y = f"(H*{float(image.get('y', 0.5)):.5f}-h/2)"
        start, end = float(image.get("start", 0)), float(image.get("end", 5))
        label = f"base{index + 1}"
        graphs.append(
            f"[{input_index}:v]scale={overlay_width}:-1,format=rgba,"
            f"colorchannelmixer=aa={float(image.get('opacity', 1)):.3f}[img{index}];"
            f"[{previous}][img{index}]overlay=x='{x}':y='{y}':"
            f"enable='between(t,{start:.3f},{end:.3f})'[{label}]"
        )
        previous = label
    ass_filter = (
        f"ass=filename='{_filter_path(ass)}':fontsdir='{_filter_path(ass.parent)}'"
    )
    if images:
        graphs.append(f"[{previous}]{ass_filter}[vout]")
    video_map = "[vout]" if images else "0:v:0"
    if not audio_inputs and narration_input is None:
        return ";".join(graphs), video_map, "0:a:0"
    if not images:
        graphs.append(f"[0:v]{','.join(base_filters)},{ass_filter}[vout]")
        video_map = "[vout]"
    labels = [f"[{narration_input}:a]" if narration_input is not None else "[0:a]"]
    for index, (input_index, settings, kind) in enumerate(audio_inputs):
        if kind == "music":
            filters = _timed_audio_filters(settings, movie_duration, music=True)
        else:
            filters = _timed_audio_filters(settings, movie_duration, music=False)
        label = f"audio{index}"
        graphs.append(f"[{input_index}:a]{','.join(filters)}[{label}]")
        labels.append(f"[{label}]")
    mix = "".join(labels) + (
        f"amix=inputs={len(labels)}:duration=first:dropout_transition=0:"
        "normalize=0[aout]"
    )
    graphs.append(mix)
    return ";".join(graphs), video_map, "[aout]"


def _timed_audio_filters(
    settings: dict[str, Any], movie_duration: float, music: bool
) -> list[str]:
    if music:
        start = min(float(settings.get("start", 0)), max(0, movie_duration - 0.1))
        trim_start = 0.0
        end = movie_duration - start
    else:
        start = max(0, float(settings.get("start", 0)))
        trim_start = max(0, float(settings.get("trim_start", 0)))
        end = max(trim_start + 0.05, float(settings.get("trim_end", 5)))
    span = end - trim_start
    filters = [
        f"atrim=start={trim_start:.3f}:end={end:.3f}",
        "asetpts=PTS-STARTPTS",
        f"volume={float(settings.get('volume', 0.5)):.3f}",
    ]
    fade_in = min(float(settings.get("fade_in", 0)), span / 2)
    fade_out = min(float(settings.get("fade_out", 0)), span / 2)
    if fade_in > 0:
        filters.append(f"afade=t=in:st=0:d={fade_in:.3f}")
    if fade_out > 0:
        filters.append(f"afade=t=out:st={span - fade_out:.3f}:d={fade_out:.3f}")
    delay = round(start * 1000)
    filters.append(f"adelay={delay}|{delay}")
    return filters
