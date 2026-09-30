import Link from "next/link";
import { Instagram, Youtube } from "lucide-react";
import styles from "./site-footer.module.css";

export function SiteFooter(){return <footer className={styles.footer}><div className={styles.inner}><div><h2>Stories that stay with you,<br/>wherever you are.</h2><nav><Link href="/privacy">Privacy policy</Link><Link href="/terms">Terms of service</Link><Link href="/discover">Browse series</Link></nav></div><div className={styles.right}><div><a href="#" aria-label="Instagram"><Instagram/></a><a href="#" aria-label="YouTube"><Youtube/></a></div><span>© 2026 Dramabyte</span></div></div></footer>}
