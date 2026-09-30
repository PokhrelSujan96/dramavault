from collections.abc import Mapping
from typing import Any

from app.domain.dialogue import fingerprint
from supabase import Client


class DialogueStore:
    def __init__(self, database: Client, pilot_id: str) -> None:
        self.database = database
        response = (
            database.table("dialogue_pilots")
            .select("*")
            .eq("id", pilot_id)
            .single()
            .execute()
        )
        if not isinstance(response.data, Mapping):
            raise ValueError("Pilot unavailable")
        self.row: dict[str, Any] = dict(response.data)

    def save(self, **values: Any) -> None:
        self.database.table("dialogue_pilots").update(values).eq(
            "id", self.row["id"]
        ).execute()
        self.row.update(values)

    def asset(self, name: str, key: str) -> None:
        self.save(assets={**self.row["assets"], name: key})

    def reserve(self, name: str, cents: int, payload: object) -> dict[str, Any]:
        existing = self.row["requests"].get(name)
        digest = fingerprint(payload)
        if existing:
            if existing["fingerprint"] != digest:
                raise ValueError("Checkpoint inputs changed; create a new pilot")
            return dict(existing)
        total = self.row["reserved_cents"] + cents
        if total > self.row["budget_cents"]:
            raise ValueError("Pilot spending allowance reached; no request submitted")
        entry = {"fingerprint": digest, "cents": cents, "pending": True}
        self.save(
            reserved_cents=total,
            requests={**self.row["requests"], name: entry},
        )
        return entry

    def request(self, name: str, **values: Any) -> None:
        entry = {**self.row["requests"][name], **values}
        self.save(requests={**self.row["requests"], name: entry})

    def project_state(self, status: str, stage: str, progress: int) -> None:
        self.database.table("projects").update(
            {"status": status, "current_stage": stage, "progress": progress}
        ).eq("id", self.row["project_id"]).execute()
