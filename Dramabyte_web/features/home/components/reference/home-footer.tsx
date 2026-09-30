import Link from "next/link";
import { Facebook, Instagram, Twitter } from "lucide-react";
import styles from "./home.module.css";

export function HomeFooter() {
  return <footer className={styles.footer} id="about"><div className={styles.footerTop}><h2>Original stories.<br />Unforgettable drama.<br />One more episode.<br />Only on Dramabyte.</h2><div className={styles.footerRight}><nav aria-label="Footer navigation"><a href="#home">Home</a><span>/</span><a href="/discover">Discover</a><span>/</span><a href="#popular">Trending</a><span>/</span><a href="#explore-series">Explore</a></nav><div className={styles.socials} aria-label="Social platforms"><Instagram size={23} /><Facebook size={23} fill="currentColor" /><Twitter size={23} fill="currentColor" /><span>G</span></div></div></div><div className={styles.footerBottom}><div><Link href="/privacy">Privacy policy</Link><Link href="/terms">Terms of service</Link><span>Language</span></div><span>© {new Date().getFullYear()} Dramabyte</span></div></footer>;
}
