import { config } from "@/lib/config";

type ApiOptions = Omit<RequestInit, "body"> & {
  body?: unknown;
  accessToken?: string;
  idempotencyKey?: string;
};

export async function apiRequest<T>(
  path: string,
  options: ApiOptions = {},
): Promise<T> {
  const headers = new Headers(options.headers);
  const multipart = typeof FormData !== "undefined" && options.body instanceof FormData;
  if (!multipart) headers.set("Content-Type", "application/json");
  if (options.accessToken) {
    headers.set("Authorization", `Bearer ${options.accessToken}`);
  }
  if (options.idempotencyKey) {
    headers.set("Idempotency-Key", options.idempotencyKey);
  }
  const response = await fetch(`${config.apiUrl}${path}`, {
    ...options,
    body: multipart ? options.body as FormData : options.body === undefined ? undefined : JSON.stringify(options.body),
    credentials: "include",
    headers,
  });
  if (!response.ok) {
    const payload = (await response.json().catch(() => null)) as {
      detail?: string;
    } | null;
    throw new ApiError(payload?.detail ?? "Request failed", response.status);
  }
  if (response.status === 204) return undefined as T;
  return response.json() as Promise<T>;
}

export class ApiError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
  }
}
