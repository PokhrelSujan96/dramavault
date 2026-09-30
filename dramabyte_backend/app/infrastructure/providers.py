from typing import Protocol


class ScriptProvider(Protocol):
    async def create_script(self, premise: str, language: str) -> str: ...


class ImageProvider(Protocol):
    async def create_image(self, prompt: str) -> bytes: ...


class VideoProvider(Protocol):
    async def create_video(self, prompt: str, image_url: str) -> str: ...


class VoiceProvider(Protocol):
    async def create_voice(self, script: str, voice_id: str) -> bytes: ...


class SubtitleProvider(Protocol):
    async def transcribe(self, audio_url: str) -> list[dict[str, object]]: ...


class ObjectStorage(Protocol):
    async def put(self, key: str, content: bytes, content_type: str) -> str: ...
    async def signed_url(self, key: str, expires_in: int = 900) -> str: ...
