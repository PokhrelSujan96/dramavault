import math
import re
from difflib import SequenceMatcher

from pydantic import BaseModel, Field, model_validator


class TimedWord(BaseModel):
    text: str = Field(min_length=1)
    start: float = Field(ge=0, allow_inf_nan=False)
    end: float = Field(gt=0, allow_inf_nan=False)

    @model_validator(mode="after")
    def positive(self) -> "TimedWord":
        if self.end <= self.start:
            raise ValueError("Word timing must be positive")
        return self


MIN_WORD_SECONDS = 0.08
MAX_UNALIGNED_GAP_SECONDS = 3.0


class TimedBeat(BaseModel):
    index: int
    narration: str
    start: float
    end: float


def normalize_word(text: str) -> str:
    return re.sub(r"[^\w]", "", text.casefold())


def align_script(
    script: str, heard: list[TimedWord], seconds: float
) -> list[TimedWord]:
    source = script.split()
    heard = [word for word in heard if normalize_word(word.text)]
    matcher = SequenceMatcher(
        None,
        [normalize_word(word) for word in source],
        [normalize_word(word.text) for word in heard],
        autojunk=False,
    )
    mapping = {
        block.a + offset: block.b + offset
        for block in matcher.get_matching_blocks()
        for offset in range(block.size)
    }
    if len(mapping) / max(1, len(source)) < 0.94:
        raise ValueError(
            "Narration differs from script; inspect voice and transcription"
        )
    result: list[TimedWord] = []
    for index, text in enumerate(source):
        if index in mapping:
            word = heard[mapping[index]]
            start, end = word.start, word.end
        else:
            previous = max((key for key in mapping if key < index), default=-1)
            following = min(
                (key for key in mapping if key > index), default=len(source)
            )
            if following - previous > 3:
                raise ValueError(
                    "Too many unaligned words; refusing approximate subtitles"
                )
            left = heard[mapping[previous]].end if previous >= 0 else 0
            right = (
                heard[mapping[following]].start if following < len(source) else seconds
            )
            missing = following - previous - 1
            if right - left > MAX_UNALIGNED_GAP_SECONDS:
                raise ValueError("Uncertain word alignment; inspect the narration")
            span = max(right - left, MIN_WORD_SECONDS * missing)
            step = span / missing
            start = left + step * (index - previous - 1)
            end = start + step
        start = max(start, result[-1].end if result else 0)
        end = min(max(end, start + MIN_WORD_SECONDS), seconds)
        if end <= start:
            raise ValueError("Overlapping or invalid speech timestamps")
        result.append(TimedWord(text=text, start=start, end=end))
    return result


def timed_beats(words: list[TimedWord], seconds: float) -> list[TimedBeat]:
    if not words or not math.isfinite(seconds) or not 10 <= seconds <= 180:
        raise ValueError("Narration must last 10–180 seconds with aligned words")
    beats: list[TimedBeat] = []
    first = 0
    start = 0.0
    for index, word in enumerate(words):
        boundary = words[index + 1].start if index + 1 < len(words) else seconds
        next_boundary = words[index + 2].start if index + 2 < len(words) else seconds
        sentence = bool(re.search(r"[.!?][\"'”’]*$", word.text))
        should_cut = (
            sentence and boundary - start >= 1.2
        ) or next_boundary - start > 4.8
        if should_cut or index == len(words) - 1:
            if not 0 < boundary - start <= 5.0:
                raise ValueError(
                    "Speech/pause exceeds one clip; revise narration pacing"
                )
            beats.append(
                TimedBeat(
                    index=len(beats),
                    narration=" ".join(item.text for item in words[first : index + 1]),
                    start=start,
                    end=boundary,
                )
            )
            start, first = boundary, index + 1
    return beats


def aligned_captions(words: list[TimedWord]) -> list[dict[str, object]]:
    captions: list[dict[str, object]] = []
    group: list[TimedWord] = []
    for index, word in enumerate(words):
        group.append(word)
        sentence = bool(re.search(r"[.!?][\"'”’]*$", word.text))
        if (
            sentence
            or len(group) >= 7
            or word.end - group[0].start >= 3.2
            or index == len(words) - 1
        ):
            captions.append(
                {
                    "id": len(captions),
                    "text": " ".join(item.text for item in group),
                    "start": round(group[0].start, 3),
                    "end": round(group[-1].end, 3),
                }
            )
            group = []
    return captions
