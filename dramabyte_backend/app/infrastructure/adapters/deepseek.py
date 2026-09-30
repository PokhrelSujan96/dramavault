import httpx

from app.core.config import settings


class DeepSeekScriptProvider:
    endpoint = "https://api.deepseek.com/chat/completions"

    async def create_script(
        self,
        premise: str,
        language: str,
        duration_seconds: int,
    ) -> str:
        words = max(40, round(duration_seconds * 2.2))
        system = (
            "You are the head writer for a vertical short-drama studio. "
            "Write production-ready narration with a strong first-three-second hook, "
            "clear escalation, emotional turns, and a final cliffhanger. "
            "Return only the script, without headings or markdown."
        )
        prompt = (
            f"Language: {language}. Target length: {words} words. "
            f"Story premise: {premise}"
        )
        async with httpx.AsyncClient(timeout=90) as client:
            response = await client.post(
                self.endpoint,
                headers={"Authorization": f"Bearer {settings.deepseek_api_key}"},
                json={
                    "model": "deepseek-chat",
                    "messages": [
                        {"role": "system", "content": system},
                        {"role": "user", "content": prompt},
                    ],
                    "temperature": 0.8,
                    "max_tokens": 1800,
                },
            )
            response.raise_for_status()
            data = response.json()
        return str(data["choices"][0]["message"]["content"]).strip()
