import Link from "next/link";
import { ChevronRight, Plus } from "lucide-react";
import type { Profile } from "@/domain/models";
import styles from "./account-popover.module.css";

export function ProfileWallet({ profile, onClose }: { profile: Profile; onClose: () => void }) {
  const expires = profile.vip_expires_at ? new Date(profile.vip_expires_at).toLocaleDateString("en-GB", { day: "numeric", month: "short", timeZone: "Europe/London" }) : "—";
  return <section className={styles.wallet}><Link href="/wallet" onClick={onClose} className={styles.sectionTitle}><h3>My Wallet</h3><ChevronRight size={17} /></Link><div className={styles.balances}><div><strong>{profile.coins.toLocaleString("en-GB")}</strong><span>Coins</span></div><div><strong>{profile.bonus_coins.toLocaleString("en-GB")}</strong><span>Bonus</span></div><div><strong className={styles.expiry}>{expires}</strong><span>VIP expires</span></div><Link href="/wallet" className={styles.topup} onClick={onClose}><Plus size={22} /><span>Top up</span></Link></div></section>;
}
