"use server";

import type { AccountPanel, NavigationData } from "@/domain/account/navigation";
import { getNavigationData } from "@/infrastructure/account/navigation-repository";

export async function loadNavigationPanel(panel: AccountPanel): Promise<NavigationData> {
  if (!["library", "profile", "referral", "history"].includes(panel)) return { error: "Invalid panel." };
  return getNavigationData(panel);
}
