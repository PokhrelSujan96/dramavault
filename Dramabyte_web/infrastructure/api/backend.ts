import "server-only";

export function backendUrl(path: string): string {
  const base = process.env.API_URL ?? process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";
  const url = new URL(base.endsWith("/") ? base : `${base}/`);
  if (url.username || url.password || !["http:", "https:"].includes(url.protocol)) {
    throw new Error("Invalid backend configuration");
  }
  if (process.env.NODE_ENV === "production" && url.protocol !== "https:" && !["localhost", "127.0.0.1", "[::1]"].includes(url.hostname)) {
    throw new Error("The production backend requires HTTPS");
  }
  return new URL(path.replace(/^\//, ""), url).href;
}
