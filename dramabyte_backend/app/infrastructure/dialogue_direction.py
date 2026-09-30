from typing import Any

from app.domain.dialogue import PilotPlan, PilotShot


def keyframe_prompt(
    plan: PilotPlan, shot: PilotShot, cast: list[dict[str, Any]]
) -> str:
    people = [person for person in cast if person["id"] in shot.character_ids]
    references = "; ".join(
        f"Reference {index + 1} is {person['name']}: {person['description']}"
        for index, person in enumerate(people)
    )
    subjects = (
        f"Show exactly {len(people)} person: {people[0]['name']}. "
        "The other character is off-screen; never depict them. "
        if len(people) == 1
        else "Show no people, faces, silhouettes or human reflections. "
        if not people
        else f"Show exactly {len(people)} assigned characters. "
    )
    return (
        f"{references}. Preserve the exact face, hair, gender and every garment "
        "from each character reference. Do not redesign, recolor, exchange or "
        "remove clothing. Character references supply identity and wardrobe only, "
        "not background, weather or pose. Cinematic live-action drama. "
        f"Reference {len(people) + 1} is the EMPTY set, supplying architecture "
        "and lighting only, never additional characters. "
        f"{subjects} Recompose the set to the requested camera framing; "
        "do not preserve its wide camera angle for close-ups. "
        f"LOCATION: {plan.location}. "
        f"ACTION: {shot.action}. CAMERA: {shot.camera}. "
        "No text, subtitles, extra people or unrequested props. "
        "Only the assigned speaker has a visible face in speaking shots."
    )


def motion_arguments(shot: PilotShot, image_url: str, seed: int) -> dict[str, Any]:
    return {
        "image_url": image_url,
        "prompt": (
            f"One continuous cinematic take. {shot.action}. {shot.camera}. "
            "Keep the same room geometry, face, costume, props and lighting. "
            "Natural restrained acting and breathing, no exaggerated mouth movements. "
            "No cuts or scene changes. Match the reference weather and lighting."
            + (" Keep lips closed, no speaking." if shot.role != "dialogue" else "")
        ),
        "negative_prompt": (
            "face morphing, changing costume, rain indoors, outdoor bench, "
            "extra people, distorted hands, camera shaking, covered mouth, "
            "profile face, slideshow, static image, subtitles, text"
        ),
        "enable_prompt_expansion": False,
        "aspect_ratio": "9:16",
        "resolution": "480p",
        "num_frames": 81,
        "frames_per_second": 16,
        "seed": seed,
        "enable_safety_checker": True,
    }


def lipsync_arguments(video_url: str, audio_url: str) -> dict[str, str]:
    return {
        "video_url": video_url,
        "audio_url": audio_url,
        "model": "lipsync-2",
        "sync_mode": "cut_off",
    }
