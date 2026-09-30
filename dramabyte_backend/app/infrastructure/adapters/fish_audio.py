import httpx

from app.core.config import settings


class FishAudioProvider:
    endpoint = "https://api.fish.audio/v1/tts"

    def create_voice(self, script: str, reference_id: str | None = None) -> bytes:
        response = httpx.post(
            self.endpoint,
            headers={
                "Authorization": f"Bearer {settings.fish_audio_api_key}",
                "Content-Type": "application/json",
                "model": "s2.1-pro-free",
            },
            json={
                "text": script,
                "format": "mp3",
                "reference_id": reference_id or settings.fish_audio_reference_id,
                "temperature": 0.5,
                "latency": "normal",
                "prosody": {"speed": 1, "normalize_loudness": True},
            },
            timeout=180,
        )
        response.raise_for_status()
        return response.content
