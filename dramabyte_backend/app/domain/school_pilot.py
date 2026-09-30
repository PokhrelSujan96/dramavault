from app.domain.dialogue import PilotPlan, PilotShot


def school_pilot(girl: str, boy: str) -> PilotPlan:
    beats = [
        (
            "establishing",
            [],
            None,
            "",
            "Show the sunlit cafeteria aisle and one empty blue chair at the "
            "foreground table. No people or moving objects in this establishing shot.",
            "Slow dolly along the aisle toward the foreground table",
            3.5,
        ),
        (
            "dialogue",
            [boy],
            boy,
            "That seat isn't for you.",
            "Ethan sits at the foreground table, leaning back with a smug expression. "
            "Only his face is visible; he addresses Nia at camera-left. "
            "Keep his face steady and mouth unobstructed.",
            "Stable eye-level medium close-up, eyeline camera-left",
            3,
        ),
        (
            "reaction",
            [girl],
            None,
            "",
            "Nia stands beside the empty chair, holding a beige lunch tray with "
            "both hands. She glances at the chair then back at Ethan, hurt "
            "but composed. "
            "Keep her lips closed and tray level; no sudden gestures.",
            "Medium close-up, eyeline camera-right",
            3.5,
        ),
        (
            "dialogue",
            [girl],
            girl,
            "It's the only empty seat.",
            "Nia answers quietly and steadily. Her beige lunch tray is held below "
            "frame. Only Nia's face is visible, no other mouths or background people.",
            "Stable front three-quarter close-up, eyeline camera-right",
            3,
        ),
        (
            "detail",
            [],
            None,
            "",
            "Show the empty blue chair at the foreground table, with a red backpack "
            "on the adjacent chair. The seat remains empty and objects stay still. "
            "No people, text, lunch tray or hands in this detail shot.",
            "Slow push-in on the empty blue chair and adjacent red backpack",
            3.5,
        ),
        (
            "dialogue",
            [boy],
            boy,
            "Then eat somewhere else.",
            "Ethan gives a dismissive smirk from the same foreground table. "
            "Only Ethan's unobstructed face is visible, eyeline camera-left; "
            "no head turns, no physical aggression.",
            "Stable close-up, same background window and camera axis",
            3,
        ),
        (
            "dialogue",
            [girl],
            girl,
            "You don't get to decide that.",
            "Nia answers with restrained confidence, no shouting. Only Nia's face "
            "is visible; she looks toward Ethan at camera-right. Keep head steady.",
            "Stable medium close-up, same background and screen direction",
            3.5,
        ),
        (
            "reaction",
            [boy],
            None,
            "",
            "Ethan's smirk fades as he looks toward Nia. His lips stay closed. "
            "He is taken aback by her confidence; no violence or other characters.",
            "Gentle push-in on Ethan's unsettled reaction",
            3.5,
        ),
    ]
    return PilotPlan(
        title="After the Bell · Episode 1 · The Empty Seat",
        ambience="school",
        location=(
            "One modern school cafeteria at midday. Pale cream walls, large "
            "rectangular windows with consistent soft daylight, maple lunch "
            "tables, blue plastic chairs, clean beige tiled floor. Foreground "
            "table beside the window, one empty blue chair, a red backpack on "
            "the adjacent chair. No logos, readable signs or crowds."
        ),
        continuity=(
            "Nia and Ethan are eighteen-year-old final-year school students. "
            "Nia stands camera-left of the same table, holding one beige tray. "
            "Ethan stays seated camera-right; his red backpack remains on "
            "the adjacent chair. Keep wardrobe, hairstyle, faces, table, "
            "window, chair positions and midday lighting unchanged. "
            "No additional characters, indoor rain, train objects or uniforms "
            "from other scenes. Respect the same camera axis across cuts."
        ),
        shots=[
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
        ],
    )
