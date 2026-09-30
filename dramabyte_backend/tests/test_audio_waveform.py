import shutil
import subprocess

import pytest

from app.infrastructure.audio_waveform import audio_peaks
from app.infrastructure.rendering import _executable

pytestmark = pytest.mark.skipif(not shutil.which("ffmpeg"), reason="FFmpeg required")


def test_waveform_reads_real_audio_from_video(tmp_path):
    video = tmp_path / "narrated.mp4"
    subprocess.run(
        [
            _executable("ffmpeg"),
            "-v",
            "error",
            "-f",
            "lavfi",
            "-i",
            "color=c=blue:s=90x160:r=16",
            "-f",
            "lavfi",
            "-i",
            "sine=frequency=440:duration=1",
            "-t",
            "1",
            "-c:v",
            "libx264",
            "-c:a",
            "aac",
            str(video),
        ],
        check=True,
    )
    peaks = audio_peaks(video, 50)
    assert len(peaks) == 50
    assert max(peaks) == 1
    assert all(0 <= peak <= 1 for peak in peaks)


def test_waveform_rejects_video_without_audio(tmp_path):
    video = tmp_path / "silent.mp4"
    subprocess.run(
        [
            _executable("ffmpeg"),
            "-v",
            "error",
            "-f",
            "lavfi",
            "-i",
            "color=c=blue:s=90x160:r=16",
            "-t",
            "1",
            str(video),
        ],
        check=True,
    )
    with pytest.raises(subprocess.CalledProcessError):
        audio_peaks(video)
