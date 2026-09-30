import "server-only";
import { cookies } from "next/headers";
import type { AccountPanel, NavigationData } from "@/domain/account/navigation";
import { backendUrl } from "@/infrastructure/api/backend";
import { readJson } from "@/infrastructure/api/read-json";
import { parseSeries } from "@/infrastructure/home/validate-feed";
import { parseHistory, parseProfile, parseReferral } from "./validate-navigation";

async function request(path: string, token: string) {
  const response = await fetch(backendUrl(path), {
    headers: { Authorization: `Bearer ${token}` }, cache: "no-store",
    signal: AbortSignal.timeout(8000), redirect: "error",
  });
  if (!response.ok) {
    await response.body?.cancel();
    throw new Error(response.status === 401 ? "session" : "unavailable");
  }
  return readJson(response);
}

export async function getNavigationData(panel: AccountPanel): Promise<NavigationData> {
  const token = (await cookies()).get("dramabyte_access")?.value;
  if (!token) return { signIn: true };
  try {
    if (panel === "library") return { library: parseSeries(await request("/library", token), 200) };
    if (panel === "referral") return { referral: parseReferral(await request("/referral/me", token)) };
    if (panel === "history") return { history: parseHistory(await request("/history?limit=10", token)) };
    const [profile, history] = await Promise.allSettled([request("/profile/me", token), request("/history?limit=4", token)]);
    if (profile.status === "rejected") throw profile.reason;
    return { profile: parseProfile(profile.value), history: history.status === "fulfilled" ? parseHistory(history.value) : undefined };
  } catch (error) {
    if (error instanceof Error && error.message === "session") return { signIn: true };
    return { error: "Couldn’t load your account. Please try again." };
  }
}
