from app.domain.dialogue import PilotPlan, PilotShot


def train_pilot(maya: str, boy: str) -> PilotPlan:
    beats = [
        (
            "establishing",
            [],
            None,
            "",
            "Empty enclosed carriage moving through night. Rain streaks only "
            "outside windows; interior is completely dry.",
            "Wide view along aisle; moving lights outside",
            3.5,
        ),
        (
            "dialogue",
            [boy],
            boy,
            "You're late, Maya.",
            "Boy seated inside on dry teal seat, wet red coat, closed red umbrella "
            "beside him. Only boy's unobstructed face visible; he looks "
            "camera-left toward Maya.",
            "Eye-level medium close-up, stable camera",
            3,
        ),
        (
            "reaction",
            [maya],
            None,
            "",
            "Maya stands in aisle, turns toward boy with a startled, restrained "
            "expression. Her silver pendant remains at her neck. Lips closed.",
            "Medium close-up; eyeline camera-right",
            3,
        ),
        (
            "dialogue",
            [maya],
            maya,
            "How do you know my name?",
            "Maya addresses the boy calmly with growing fear. Only Maya's "
            "unobstructed face visible, no head turn or hand across mouth.",
            "Stable front three-quarter close-up; eyeline camera-right",
            3.5,
        ),
        (
            "detail",
            [boy],
            None,
            "",
            "Show the hem of the boy's visibly wet red coat directly above a "
            "completely dry teal seat. No puddles, indoor rain or wet bench. "
            "His closed umbrella rests beside him.",
            "Slow detail tilt from wet coat hem to dry seat",
            3.5,
        ),
        (
            "dialogue",
            [maya],
            maya,
            "Your coat is soaked. But the seat is dry.",
            "Maya studies the seated boy with disbelief. Only Maya's face "
            "visible; keep mouth unobstructed and camera stable.",
            "Medium close-up; eyeline camera-right",
            4.5,
        ),
        (
            "dialogue",
            [boy],
            boy,
            "You promised you'd come back.",
            "Boy speaks softly to Maya from his dry seat. Only boy's face "
            "visible. Same wet coat, same closed umbrella, same carriage, "
            "no smile or morphing.",
            "Stable close-up; eyeline camera-left",
            3.5,
        ),
        (
            "reaction",
            [maya],
            None,
            "",
            "Maya grips her silver pendant and freezes in recognition. Mouth "
            "closed; no other person enters, no scene change.",
            "Gentle push-in on Maya's shocked face",
            3,
        ),
    ]
    shots = [
        PilotShot(
            index=index,
            role=role,
            character_ids=ids,
            speaker_id=speaker,
            text=text,
            action=action,
            camera=camera,
            seconds=seconds,
        )
        for index, (role, ids, speaker, text, action, camera, seconds) in enumerate(
            beats
        )
    ]
    return PilotPlan(
        title="The Last Train Home · dialogue pilot",
        location=(
            "One enclosed late-night train carriage. Dry teal upholstered seats "
            "in parallel rows, brushed steel walls, warm overhead lights, "
            "black wet windows, narrow central aisle. No outdoor platform "
            "or wooden bench."
        ),
        continuity=(
            "Maya remains in the aisle on the boy's right; boy remains seated "
            "on the left. Fixed clothing and faces from cast references. "
            "Maya's pendant stays around her neck. Red umbrella is closed "
            "and beside the boy. Rain is outside only. Preserve the same seat, "
            "window, lighting and screen direction across cuts."
        ),
        shots=shots,
    )
