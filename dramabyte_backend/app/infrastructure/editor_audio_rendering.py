from bisect import bisect_right
from pathlib import Path
from typing import Any

from app.domain.narration_timing import TimedWord, aligned_captions
from app.infrastructure.rendering import _executable, _run, duration


def fit_audio(master: Path, voice: Path, output: Path) -> float:
    seconds = duration(master)
    ratio = duration(voice) / seconds
    if not 0.75 <= ratio <= 1.35:
        raise ValueError("New voice pacing differs too much; original audio was kept")
    _run(
        [
            _executable("ffmpeg"),
            "-y",
            "-i",
            str(master),
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
            f"atempo={ratio:.9f},loudnorm=I=-14:LRA=7:TP=-1,apad",
            "-t",
            str(seconds),
            "-movflags",
            "+faststart",
            str(output),
        ],
        output.parent,
    )
    return seconds


def fit_voice_track(master: Path, voice: Path, output: Path) -> float:
    seconds = duration(master)
    ratio = duration(voice) / seconds
    if not 0.5 <= ratio <= 2:
        raise ValueError("Hindi narration pacing differs too much from the episode")
    _run(
        [
            _executable("ffmpeg"),
            "-y",
            "-i",
            str(voice),
            "-af",
            f"atempo={ratio:.9f},loudnorm=I=-14:LRA=7:TP=-1,apad",
            "-t",
            f"{seconds:.3f}",
            "-ar",
            "44100",
            "-b:a",
            "192k",
            str(output),
        ],
        output.parent,
    )
    return seconds


def hindi_captions(words: list[TimedWord]) -> list[dict[str, object]]:
    return aligned_captions(words)


def retime_captions(
    state: dict[str, Any],
    old: list[TimedWord],
    new: list[TimedWord],
    seconds: float,
) -> dict[str, Any]:
    if len(old) != len(new) or not old:
        raise ValueError("Missing narration timing; original audio was kept")
    anchors = [(0.0, 0.0)]
    for before, after in zip(old, new, strict=True):
        for left, right in [(before.start, after.start), (before.end, after.end)]:
            if anchors[-1][0] < left < seconds:
                anchors.append((left, right))
    anchors.append((seconds, seconds))
    times = [item[0] for item in anchors]

    def mapped(value: float) -> float:
        index = min(max(bisect_right(times, value) - 1, 0), len(anchors) - 2)
        left, start = anchors[index]
        right, end = anchors[index + 1]
        fraction = min(1.0, max(0.0, (value - left) / (right - left)))
        return round(start + fraction * (end - start), 3)

    captions = []
    for caption in state["captions"]:
        start, end = mapped(caption["start"]), mapped(caption["end"])
        if end <= start:
            raise ValueError("Caption retiming failed; original audio was kept")
        captions.append({**caption, "start": start, "end": end})
    return {**state, "captions": captions}
