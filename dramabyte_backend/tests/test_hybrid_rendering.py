import shutil
import subprocess

import pytest

from app.infrastructure.hybrid_rendering import assemble, render_shot, validate_master
from app.infrastructure.rendering import _executable
from app.infrastructure.voice_validation import validate_voice

pytestmark = pytest.mark.skipif(not shutil.which("ffmpeg"), reason="FFmpeg required")


def generate(arguments: list[str]) -> None:
    subprocess.run([_executable("ffmpeg"), "-y", "-v", "error", *arguments], check=True)


def test_real_ffmpeg_motion_only_has_hd_video_and_audible_audio(tmp_path) -> None:
    second_clip = tmp_path / "second.mp4"
    clip = tmp_path / "clip.mp4"
    voice = tmp_path / "voice.wav"
    generate(
        ["-f", "lavfi", "-i", "color=c=blue:s=270x480", "-t", "1", str(second_clip)]
    )
    generate(
        [
            "-f",
            "lavfi",
            "-i",
            "testsrc2=s=270x480:r=16",
            "-t",
            "1",
            "-pix_fmt",
            "yuv420p",
            str(clip),
        ]
    )
    generate(["-f", "lavfi", "-i", "sine=frequency=440:duration=2", str(voice)])
    first, second, master = (
        tmp_path / "shot-0.mp4",
        tmp_path / "shot-1.mp4",
        tmp_path / "master.mp4",
    )
    render_shot(clip, first, 1, "motion", "9:16")
    render_shot(second_clip, second, 1, "motion", "9:16")
    assemble([first, second], voice, master, 2)
    validate_master(master, 2, "9:16")
    validate_voice(master)


def test_silent_narration_is_rejected(tmp_path) -> None:
    silence = tmp_path / "silence.wav"
    generate(["-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono", "-t", "1", str(silence)])
    with pytest.raises(ValueError):
        validate_voice(silence)


def test_short_motion_is_not_repeated(tmp_path) -> None:
    clip = tmp_path / "short.mp4"
    generate(
        ["-f", "lavfi", "-i", "color=c=red:s=270x480:r=16", "-t", "0.5", str(clip)]
    )
    with pytest.raises(ValueError):
        render_shot(clip, tmp_path / "shot.mp4", 5, "motion", "9:16")


def test_static_frame_receives_local_motion(tmp_path) -> None:
    image, shot = tmp_path / "image.png", tmp_path / "shot.mp4"
    generate(["-f", "lavfi", "-i", "color=c=blue:s=270x480", "-frames:v", "1", str(image)])
    render_shot(image, shot, 1, "still", "9:16")
    assert shot.exists()


def test_editor_audio_replacement_keeps_video_bitstream(tmp_path) -> None:
    from app.infrastructure.editor_audio_rendering import fit_audio
    from app.infrastructure.rendering import duration

    master, voice, result = (
        tmp_path / "master.mp4",
        tmp_path / "voice.wav",
        tmp_path / "result.mp4",
    )
    generate(
        [
            "-f",
            "lavfi",
            "-i",
            "testsrc2=s=90x160:r=16",
            "-f",
            "lavfi",
            "-i",
            "sine=frequency=220:duration=2",
            "-t",
            "2",
            "-c:v",
            "libx264",
            "-c:a",
            "aac",
            str(master),
        ]
    )
    generate(["-f", "lavfi", "-i", "sine=frequency=880:duration=2.2", str(voice)])
    fit_audio(master, voice, result)
    validate_voice(result)
    assert abs(duration(result) - duration(master)) < 0.1

    def video_hash(path):
        return subprocess.run(
            [
                _executable("ffmpeg"),
                "-v",
                "error",
                "-i",
                str(path),
                "-map",
                "0:v:0",
                "-c:v",
                "copy",
                "-f",
                "hash",
                "-",
            ],
            check=True,
            capture_output=True,
        ).stdout

    assert video_hash(master) == video_hash(result)
