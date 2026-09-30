export async function readJson(response: Response, limit = 2000000): Promise<unknown> {
  if (Number(response.headers.get("content-length")) > limit) {
    await response.body?.cancel();
    throw new Error("Response exceeds size limit");
  }
  if (!response.body) throw new Error("Missing response body");
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let text = "";
  let size = 0;
  try {
    while (true) {
      const chunk = await reader.read();
      if (chunk.done) break;
      size += chunk.value.byteLength;
      if (size > limit) throw new Error("Response exceeds size limit");
      text += decoder.decode(chunk.value, { stream: true });
    }
    text += decoder.decode();
    return JSON.parse(text) as unknown;
  } finally {
    await reader.cancel().catch(() => {});
    reader.releaseLock();
  }
}
