import json
from typing import Any

import httpx

from app.core.config import settings
from app.domain.hybrid import Storyboard, motion_budget
from app.domain.narration_timing import TimedBeat
from app.infrastructure.adapters.storyboard_prompts import (
    DIRECTOR_PROMPT,
    REVIEW_PROMPT,
)


class StoryboardProvider:
    def _request(self, system: str, payload: dict[str, Any]) -> dict[str, Any]:
        with httpx.Client(timeout=180) as client:
            response = client.post(
                "https://api.deepseek.com/chat/completions",
                headers={"Authorization": f"Bearer {settings.deepseek_api_key}"},
                json={
                    "model": "deepseek-chat",
                    "messages": [
                        {"role": "system", "content": system},
                        {"role": "user", "content": json.dumps(payload)},
                    ],
                    "response_format": {"type": "json_object"},
                    "temperature": 0.1,
                    "max_tokens": 16000,
                },
            )
            response.raise_for_status()
        value = json.loads(response.json()["choices"][0]["message"]["content"])
        if not isinstance(value, dict):
            raise ValueError("Invalid storyboard response")
        return value

    def plan(
        self,
        script: str,
        beats: list[TimedBeat],
        cast: list[dict[str, Any]],
    ) -> Storyboard:
        if len(beats) > settings.hybrid_max_motion_shots:
            raise ValueError("Episode exceeds configured motion-shot budget")
        payload = {
            "script": script,
            "cast": cast,
            "timed_beats": [beat.model_dump() for beat in beats],
        }
        board = Storyboard.model_validate(self._request(DIRECTOR_PROMPT, payload))
        for attempt in range(3):
            self._validate(board, beats, cast)
            review = self._request(
                REVIEW_PROMPT,
                {
                    **payload,
                    "storyboard": board.model_dump(mode="json"),
                },
            )
            if review.get("passed") is True and not review.get("issues"):
                return self._assign_motion(board, beats)
            issues = review.get("issues") or ["Continuity review did not pass"]
            if attempt == 2:
                raise ValueError(
                    "Storyboard continuity review failed after repairs: "
                    f"{str(issues)[:700]}"
                )
            board = Storyboard.model_validate(
                self._request(
                    DIRECTOR_PROMPT
                    + " Repair the supplied storyboard using every review "
                    "issue. Return the full corrected scenes array. Change only visual "
                    "direction and cast assignments that need correction. Never change "
                    "narration, indexes or timestamps. Back-of-classroom does not mean "
                    "behind the student at the final desk: stage the whisperer beside "
                    "that desk, and view from the front or aisle. Explicitly identify "
                    "unnamed students as anonymous background extras, "
                    "not recurring cast.",
                    {
                        **payload,
                        "storyboard": board.model_dump(mode="json"),
                        "issues": issues,
                    },
                )
            )
        raise RuntimeError("Storyboard repair loop exhausted")

    def _assign_motion(
        self, board: Storyboard, beats: list[TimedBeat]
    ) -> Storyboard:
        seconds = beats[-1].end
        limit = min(
            settings.hybrid_max_motion_shots,
            motion_budget(seconds, settings.hybrid_motion_clips_per_minute),
        )
        count = len(board.scenes)
        indexes = (
            set(range(count))
            if count <= limit
            else {
                round(position * (count - 1) / (limit - 1))
                for position in range(limit)
            }
        )
        scenes = [
            scene.model_copy(
                update={"kind": "motion" if scene.index in indexes else "still"}
            )
            for scene in board.scenes
        ]
        estimated = len(indexes) * 20 + (count + 1) * 4 + 45
        if estimated > settings.hybrid_episode_budget_cents:
            raise ValueError("Episode exceeds configured generation budget")
        return Storyboard(scenes=scenes)

    def _validate(
        self, board: Storyboard, beats: list[TimedBeat], cast: list[dict[str, Any]]
    ) -> None:
        if len(board.scenes) != len(beats):
            raise ValueError("Every timed beat requires exactly one motion shot")
        allowed = {str(character["id"]) for character in cast}
        for scene, beat in zip(board.scenes, beats, strict=True):
            if (
                scene.narration != beat.narration
                or scene.start != beat.start
                or scene.end != beat.end
            ):
                raise ValueError("Storyboard changed the aligned narration timeline")
            if scene.spec is None:
                raise ValueError("Every shot requires explicit continuity constraints")
            if not 0 < scene.end - scene.start <= 5:
                raise ValueError("Shot cannot fit the default 480p motion clip")
            if any(
                str(identifier) not in allowed for identifier in scene.character_ids
            ):
                raise ValueError("Storyboard references an unknown character")
