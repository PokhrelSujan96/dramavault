from types import SimpleNamespace
from unittest.mock import AsyncMock
from uuid import uuid4

import pytest
from fastapi import HTTPException
from postgrest.exceptions import APIError

from app.api.routes.story_templates import TemplateRequest, create_school_draft
from app.core.security import Principal
from app.domain.last_seat_story import SCRIPT


@pytest.mark.asyncio
async def test_draft_uses_atomic_rpc_without_generation():
    identifier = uuid4()
    response = SimpleNamespace(data={"project_id": "project", "series_id": "series"})
    execute = AsyncMock(return_value=response)
    calls = []

    def rpc(name, args):
        calls.append((name, args))
        return SimpleNamespace(execute=execute)

    repo = SimpleNamespace(
        client=SimpleNamespace(rpc=rpc),
        get=AsyncMock(
            side_effect=[{"id": "project", "status": "draft"}, {"id": "series"}]
        ),
    )
    result = await create_school_draft(
        TemplateRequest(request_id=identifier), Principal("owner", "admin"), repo
    )
    assert calls == [
        (
            "create_school_story_draft",
            {
                "p_owner_id": "owner",
                "p_request_id": str(identifier),
                "p_script": SCRIPT,
            },
        )
    ]
    assert result["project"]["status"] == "draft"
    assert result["series"]["id"] == "series"


@pytest.mark.asyncio
async def test_missing_template_migration_returns_actionable_error():
    execute = AsyncMock(
        side_effect=APIError(
            {
                "code": "PGRST202",
                "message": "Missing function",
                "details": "",
                "hint": "",
            }
        )
    )
    repo = SimpleNamespace(
        client=SimpleNamespace(rpc=lambda *args: SimpleNamespace(execute=execute))
    )
    with pytest.raises(HTTPException) as caught:
        await create_school_draft(
            TemplateRequest(request_id=uuid4()), Principal("owner", "admin"), repo
        )
    assert caught.value.status_code == 503
    assert "0012" in caught.value.detail
