"use client";

import Link from "next/link";
import { ArrowLeft, X } from "lucide-react";
import { useEffect, useState } from "react";
import type { AccountPanel } from "@/domain/account/navigation";
import { useAccountPanel } from "./account-cache-provider";
import { LibraryPopover } from "./library-popover";
import { ProfilePopover } from "./profile-popover";
import { ReferralPopover } from "./referral-popover";
import { HistoryPopover } from "./history-popover";
import styles from "./account-popover.module.css";

const headings = { library: "Saved series", profile: "Profile", referral: "Refer & Earn", history: "Watch history" };
export function AccountPopover({ initial, onClose }: { initial: AccountPanel; onClose: () => void }) {
  const [panel, setPanel] = useState(initial);
  const { cache, data } = useAccountPanel(panel);
  useEffect(() => { void cache.load(panel); }, [cache, panel]);
  return <div className={`${styles.content} ${panel === "library" ? styles.compactLibrary : styles.compactProfile}`}>
    <header className={styles.heading}>{panel !== initial && <button aria-label="Back to profile" onClick={() => setPanel(initial)}><ArrowLeft size={17} /></button>}<h2>{headings[panel]}</h2><button aria-label="Close panel" onClick={onClose}><X size={17} /></button></header>
    {!data ? <p className={styles.message} role="status">Loading…</p> : data.signIn ? <div className={styles.message}><p>Sign in to see your {panel === "library" ? "saved series" : "account"}.</p><Link href="/signin" className={styles.primary} onClick={onClose}>Sign in</Link></div> : data.error ? <div className={styles.message} role="status"><p>{data.error}</p><button className={styles.primary} onClick={() => { void cache.load(panel, true); }}>Try again</button></div> : <>
      {panel === "library" && <LibraryPopover items={data.library ?? []} onClose={onClose} />}
      {panel === "profile" && data.profile && <ProfilePopover profile={data.profile} history={data.history} navigate={setPanel} onClose={onClose} />}
      {panel === "referral" && data.referral && <ReferralPopover summary={data.referral} />}
      {panel === "history" && <HistoryPopover items={data.history ?? []} onClose={onClose} />}
    </>}
  </div>;
}
