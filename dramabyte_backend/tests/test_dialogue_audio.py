import shutil
import subprocess

import pytest

from app.domain.dialogue import PilotPlan, PilotShot
from app.infrastructure.dialogue_audio import mix_dialogue, train_ambience
from app.infrastructure.rendering import _executable, duration
from app.infrastructure.voice_validation import validate_voice

pytestmark = pytest.mark.skipif(not shutil.which("ffmpeg"), reason="FFmpeg required")


def test_local_ambience_has_valid_duration(tmp_path):
    bed = tmp_path / "bed.wav"
    train_ambience(bed, 2)
    assert abs(duration(bed) - 2) < 0.01


def test_real_dialogue_audio_is_delayed_and_mixed_with_ambience(tmp_path):
    voice = tmp_path / "voice.wav"
    subprocess.run(
        [
            _executable("ffmpeg"),
            "-y",
            "-v",
            "error",
            "-f",
            "lavfi",
            "-i",
            "sine=frequency=440:duration=1",
            str(voice),
        ],
        check=True,
    )
    plan = PilotPlan(
        title="Audio test",
        location="Train interior",
        continuity="Dry carriage",
        shots=[
            PilotShot(
                index=0,
                role="reaction",
                character_ids=[],
                action="Wait silently",
                camera="Wide shot",
                seconds=1,
            ),
            PilotShot(
                index=1,
                role="dialogue",
                character_ids=["maya"],
                speaker_id="maya",
                text="Hello",
                action="Maya speaks",
                camera="Close-up",
                seconds=1,
                voice_key="voice",
            ),
        ],
    )

    class Assets:
        def fetch(self, key, path):
            shutil.copyfile(voice, path)

    soundtrack = mix_dialogue(plan, Assets(), tmp_path)
    assert abs(duration(soundtrack) - 2) < 0.02
    validate_voice(soundtrack)
