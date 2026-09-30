import math
import random
import struct
import wave
from pathlib import Path

from app.domain.dialogue import PilotPlan
from app.infrastructure.dialogue_assets import DialogueAssets
from app.infrastructure.rendering import _executable, _run


def train_ambience(path: Path, seconds: float, school: bool = False) -> None:
    generator = random.Random(47)
    rate = 24000
    noise = 0.0
    samples = bytearray()
    for index in range(math.ceil(seconds * rate)):
        time = index / rate
        noise = noise * 0.97 + generator.uniform(-1, 1) * 0.03
        wheels = math.exp(-(((time % 0.75) / 0.035) ** 2))
        sample = noise * (0.10 if school else 0.28 + wheels * 0.4)
        sample += math.sin(2 * math.pi * 55 * time) * (0.004 if school else 0.025)
        fade = min(1, time / 0.5, (seconds - time) / 0.5)
        samples.extend(struct.pack("<h", round(sample * max(0, fade) * 32767)))
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(rate)
        output.writeframes(samples)


def mix_dialogue(plan: PilotPlan, assets: DialogueAssets, root: Path) -> Path:
    seconds = sum(shot.seconds for shot in plan.shots)
    bed = root / "room-ambience.wav"
    train_ambience(bed, seconds, school=plan.ambience == "school")
    command = [_executable("ffmpeg"), "-y", "-i", str(bed)]
    filters = ["[0:a]volume=0.35[bed]"]
    labels = ["[bed]"]
    start, index = 0.0, 1
    for shot in plan.shots:
        if shot.voice_key:
            voice = root / f"mix-voice-{shot.index}.wav"
            assets.fetch(shot.voice_key, voice)
            command.extend(["-i", str(voice)])
            filters.append(
                f"[{index}:a]adelay={round(start * 1000)}:all=1[voice{index}]"
            )
            labels.append(f"[voice{index}]")
            index += 1
        start += shot.seconds
    filters.append(
        "".join(labels) + f"amix=inputs={len(labels)}:duration=first:normalize=0,"
        "alimiter=limit=0.95[mix]"
    )
    output = root / "soundtrack.wav"
    command.extend(
        [
            "-filter_complex",
            ";".join(filters),
            "-map",
            "[mix]",
            "-ar",
            "48000",
            "-ac",
            "2",
            "-t",
            str(seconds),
            str(output),
        ]
    )
    _run(command, root)
    return output
