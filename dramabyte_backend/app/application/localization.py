import httpx

from app.core.config import settings


class HindiTranslator:
    endpoint = "https://api.deepseek.com/chat/completions"

    def translate(self, script: str) -> str:
        if not settings.deepseek_api_key:
            raise RuntimeError("Configure DEEPSEEK_API_KEY to translate narration")
        response = httpx.post(
            self.endpoint,
            headers={"Authorization": f"Bearer {settings.deepseek_api_key}"},
            json={
                "model": "deepseek-chat",
                "messages": [
                    {
                        "role": "system",
                        "content": (
                            "Translate the narration into natural spoken Hindi in "
                            "Devanagari. Preserve meaning, names, "
                            "paragraph order, and every story detail. Return only "
                            "the translated narration, with no notes or headings."
                        ),
                    },
                    {"role": "user", "content": script},
                ],
                "temperature": 0.2,
                "max_tokens": 12000,
            },
            timeout=120,
        )
        response.raise_for_status()
        translated = str(response.json()["choices"][0]["message"]["content"]).strip()
        if not translated or not any(
            "\u0900" <= char <= "\u097f" for char in translated
        ):
            raise ValueError("Translation did not return Hindi in Devanagari")
        return translated
