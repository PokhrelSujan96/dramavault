"use client";

import { useState, useTransition } from "react";
import { useAccountCache } from "@/features/account/components/account-cache-provider";

export function SignOutButton() {
  const cache = useAccountCache();
  const [pending, startTransition] = useTransition();
  const [failed, setFailed] = useState(false);
  const signOut = () => startTransition(async () => {
    setFailed(false);
    try {
      const response = await fetch("/api/auth/signout", { method: "POST", signal: AbortSignal.timeout(8000) });
      if (!response.ok) throw new Error("Sign out failed");
      cache.clear();
      window.location.assign("/");
    } catch { setFailed(true); }
  });
  return <><button className="button button-dark" onClick={signOut} disabled={pending}>{pending ? "Signing out…" : "Sign out"}</button>{failed && <span role="status">Couldn’t sign out. Please try again.</span>}</>;
}
