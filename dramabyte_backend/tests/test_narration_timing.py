import pytest

from app.domain.narration_timing import TimedWord, align_script, aligned_captions
from app.infrastructure.hybrid_rendering import frame_duration


def test_caption_timestamps_preserve_spoken_intervals():
    script = "His coat was soaked. The seat beneath him was dry."
    starts = [0.2, 0.5, 0.8, 1.1, 2, 2.4, 2.9, 3.5, 4, 4.6]
    heard = [
        TimedWord(text=text, start=start, end=start + 0.2)
        for text, start in zip(script.split(), starts, strict=True)
    ]
    captions = aligned_captions(align_script(script, heard, 10))
    assert captions[0]["text"] == "His coat was soaked."
    assert captions[0]["start"] == 0.2
    assert captions[0]["end"] == 1.3
    assert captions[1]["start"] == 2


def test_wrong_narration_rejected():
    heard = [TimedWord(text="Outside", start=0, end=1)]
    with pytest.raises(ValueError, match="differs from script"):
        align_script("The boy sat inside the dry train.", heard, 10)


def test_global_frame_boundaries_prevent_drift():
    points = [0, 1.23, 3.47, 5.91, 8.12, 10.04]
    durations = [
        frame_duration(a, b) for a, b in zip(points, points[1:], strict=False)
    ]
    assert sum(round(duration * 30) for duration in durations) == round(10.04 * 30)


def test_zero_length_word_still_aligns_with_minimum_duration():
    script = "It was the best day ever. " + " ".join(f"word{i}" for i in range(30))
    words = script.split()
    heard = [
        TimedWord(text=text, start=index * 0.25, end=index * 0.25 + 0.2)
        for index, text in enumerate(words)
        if text != "ever."
    ]
    aligned = align_script(script, heard, 10)
    assert [word.text for word in aligned] == words
    assert all(word.end > word.start for word in aligned)
    assert all(a.end <= b.start for a, b in zip(aligned, aligned[1:], strict=False))
