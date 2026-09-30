import Link from "next/link";
import { ChevronRight, Gift, ReceiptText, Settings } from "lucide-react";
import type { Profile } from "@/domain/models";
import type { AccountPanel, WatchHistory } from "@/domain/account/navigation";
import { HistoryPopover } from "./history-popover";
import { ProfileWallet } from "./profile-wallet";
import { SignOutButton } from "@/features/profile/components/signout-button";
import styles from "./account-popover.module.css";

export function ProfilePopover({ profile, history, navigate, onClose }: { profile: Profile; history?: WatchHistory[]; navigate: (panel: AccountPanel) => void; onClose: () => void }) {
  return <><div className={styles.identity}><span className={styles.avatar}>{(profile.display_name || profile.email || "D").slice(0, 1).toUpperCase()}</span><div><h3>{profile.display_name || "Dramabyte viewer"}</h3><p>{profile.email}</p></div><Link href="/profile" aria-label="Account settings" onClick={onClose}><Settings size={18} /></Link></div><section className={styles.history}><button className={styles.sectionTitle} onClick={() => navigate("history")}><h3>History</h3><ChevronRight size={17} /></button>{history ? <HistoryPopover items={history} compact onClose={onClose} /> : <p className={styles.empty}>History is temporarily unavailable.</p>}</section><ProfileWallet profile={profile} onClose={onClose} /><div className={styles.profileLinks}><button onClick={() => navigate("referral")}><Gift size={19} />Refer & Earn<ChevronRight size={16} /></button><Link href="/wallet" onClick={onClose}><ReceiptText size={19} />Your invoices<ChevronRight size={16} /></Link></div><div className={styles.signout}><SignOutButton /></div></>;
}
