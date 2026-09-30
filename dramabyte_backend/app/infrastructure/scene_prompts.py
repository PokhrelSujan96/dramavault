from typing import Any

from app.domain.hybrid import SceneSpec


def crowd_clause(spec: SceneSpec) -> str:
    return f"BACKGROUND CROWD: {spec.crowd}. " if spec.crowd else ""


def camera_clause(spec: SceneSpec) -> str:
    return f" Camera movement: {spec.camera_movement}." if spec.camera_movement else ""


def scene_prompt(shot: dict[str, Any]) -> str:
    spec = SceneSpec.model_validate(shot["scene_spec"])
    return (
        f"LOCATION: {spec.location}. SETTING: {spec.setting}. "
        f"SUBJECT: {spec.subject}. ACTION: {spec.action}. CAMERA: {spec.camera}. "
        f"{crowd_clause(spec)}"
        f"MUST SHOW: {'; '.join(spec.required_details)}. "
        f"MUST NOT SHOW: {'; '.join(spec.forbidden_details)}. "
        f"CONTINUITY: {spec.continuity}. FRAME: {shot['prompt']}. "
        "Photorealistic live-action cinematic frame. No text or watermark."
        " Keep every named character's face, hairstyle and exact garments "
        "unchanged from their reference; do not swap clothes with extras. "
        "Background extras are only those explicitly specified for this shot."
    )


def motion_negative(shot: dict[str, Any]) -> str:
    spec = SceneSpec.model_validate(shot["scene_spec"])
    return ", ".join(
        [
            "still image",
            "freeze frame",
            "slideshow",
            "scene transition",
            "face morphing",
            "changed clothing",
            "extra limbs",
            "deformed hands",
            "subtitles",
            "watermark",
            *spec.forbidden_details,
        ]
    )
