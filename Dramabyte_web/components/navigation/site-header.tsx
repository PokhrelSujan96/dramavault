import Link from "next/link";
import { Search } from "lucide-react";
import { Logo } from "@/components/brand/logo";
import { ThemeToggle } from "@/components/theme/theme-toggle";
import { MainNavigation } from "./main-navigation";
import styles from "./site-header.module.css";

export function SiteHeader() {
  return <header className={styles.header}><div className={styles.inner}><Logo /><MainNavigation /><div className={styles.actions}><ThemeToggle /><Link className={styles.icon} href="/search" aria-label="Search"><Search size={18} /></Link></div></div></header>;
}
