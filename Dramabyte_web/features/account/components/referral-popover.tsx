"use client";

import { Check, Copy } from "lucide-react";
import { useState } from "react";
import type { ReferralSummary } from "@/domain/account/navigation";
import styles from "./account-popover.module.css";

export function ReferralPopover({ summary }: { summary: ReferralSummary }) {
  const [copied, setCopied] = useState(false);
  const [error, setError] = useState(false);
  const copy = async () => {
    try { await navigator.clipboard.writeText(summary.code); setCopied(true); setError(false); }
    catch { setError(true); }
  };
  return <><section className={styles.referral}><span>Your referral code</span><strong>{summary.code}</strong><button className={styles.primary} onClick={copy}>{copied ? <Check size={16} /> : <Copy size={16} />}{copied ? "Copied" : "Copy code"}</button></section><p className={styles.reward}>You and your friend both get {summary.signup_reward} coins when they sign up with your code, and {summary.purchase_reward} more each when they make their first purchase.</p><div className={styles.referralStats}>{[["Invited", summary.invited], ["Purchased", summary.purchased], ["Earned", summary.earned]].map(([label, value]) => <div key={label}><strong>{value}</strong><span>{label}</span></div>)}</div>{error && <p className={styles.error} role="status">Couldn’t copy. Select and copy the code above.</p>}</>;
}
