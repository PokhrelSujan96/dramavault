from contextlib import contextmanager

import httpx

from app.infrastructure import http_download


def test_download_retries_transient_tls_failure(tmp_path, monkeypatch):
    calls = 0
    request = httpx.Request("GET", "https://media.example/video.mp4")

    class Response:
        headers = {"content-length": "7"}

        def raise_for_status(self):
            return None

        def iter_bytes(self):
            yield b"payload"

    @contextmanager
    def stream(*args, **kwargs):
        nonlocal calls
        calls += 1
        if calls == 1:
            raise httpx.ConnectError("temporary TLS EOF", request=request)
        yield Response()

    monkeypatch.setattr(http_download.httpx, "stream", stream)
    monkeypatch.setattr(http_download.time, "sleep", lambda _: None)
    target = tmp_path / "download.bin"

    http_download.download_file(request.url.__str__(), target)

    assert target.read_bytes() == b"payload"
    assert calls == 2
