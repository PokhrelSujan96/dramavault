import math
from pathlib import Path

import httpx

from app.domain.dialogue import PilotPlan
from app.infrastructure.adapters.fish_audio import FishAudioProvider
from app.infrastructure.dialogue_assets import DialogueAssets
from app.infrastructure.dialogue_direction import keyframe_prompt
from app.infrastructure.dialogue_store import DialogueStore
from app.infrastructure.rendering import _executable, _run, duration
from app.infrastructure.speech_alignment import align_narration
from app.infrastructure.voice_validation import validate_voice


def prepare_dialogue(
    store: DialogueStore, assets: DialogueAssets, root: Path
) -> PilotPlan:
    plan = PilotPlan.model_validate(store.row["plan"])
    voices = {
        person["id"]: person["voice_reference"] for person in store.row["cast_snapshot"]
    }
    for shot in plan.shots:
        if shot.role != "dialogue" or shot.voice_key:
            continue
        name = f"voice-{shot.index}"
        path = root / f"{name}.mp3"
        existing = store.row["assets"].get(name)
        if existing:
            assets.fetch(existing, path)
        else:
            prior = store.row["requests"].get(name)
            reference = voices[shot.speaker_id]
            store.reserve(name, 15, [shot.text, reference])
            if prior and prior.get("pending"):
                raise RuntimeError("Ambiguous Fish request; reconcile before retry")
            store.request(name, pending=True)
            assets.lease.ensure()
            try:
                path.write_bytes(FishAudioProvider().create_voice(shot.text, reference))
            except httpx.HTTPStatusError as error:
                if error.response.status_code in {400, 401, 402, 403, 404, 422}:
                    store.request(name, pending=False)
                raise
            assets.local(name, path, "audio/mpeg")
            store.request(name, pending=False)
        seconds = duration(path)
        validate_voice(path)
        if seconds + 0.35 > 5:
            raise ValueError("Dialogue exceeds one clip; shorten line in a new pilot")
        words = align_narration(path, shot.text, "en", seconds)
        shot.seconds = math.ceil((seconds + 0.35) * 30) / 30
        padded = root / f"padded-{shot.index}.wav"
        _run(
            [
                _executable("ffmpeg"),
                "-y",
                "-i",
                str(path),
                "-af",
                "adelay=150:all=1,apad",
                "-t",
                str(shot.seconds),
                "-ar",
                "48000",
                "-ac",
                "1",
                "-c:a",
                "pcm_s16le",
                str(padded),
            ],
            root,
        )
        shot.voice_key = assets.local(f"dialogue-{shot.index}", padded, "audio/wav")
        shot.words = [
            {"text": word.text, "start": word.start + 0.15, "end": word.end + 0.15}
            for word in words
        ]
        store.save(plan=plan.model_dump(mode="json"))
    total = sum(shot.seconds for shot in plan.shots)
    if not 20 <= total <= 35:
        raise ValueError("Pilot must last 20–35 seconds; revise its dialogue pacing")
    location = assets.generate(
        "location",
        "fal-ai/flux/schnell",
        {
            "prompt": (
                f"Photorealistic cinematic empty set. {plan.location}. "
                "No people, no text. Match the specified weather and time exactly."
            ),
            "image_size": "portrait_16_9",
            "num_images": 1,
            "num_inference_steps": 4,
            "enable_safety_checker": True,
        },
        10,
        image=True,
    )
    for shot in plan.shots:
        people = [
            person
            for person in store.row["cast_snapshot"]
            if person["id"] in shot.character_ids
        ]
        refs = [*[person["reference_key"] for person in people], location]
        assets.generate(
            f"image-{shot.index}",
            "fal-ai/flux-2/klein/9b/edit",
            {
                "prompt": keyframe_prompt(plan, shot, store.row["cast_snapshot"]),
                "image_urls": [assets.storage.signed_url(key) for key in refs],
                "image_size": "portrait_16_9",
                "num_images": 1,
                "num_inference_steps": 4,
                "enable_safety_checker": True,
                "output_format": "png",
            },
            10,
            image=True,
        )
    return plan
