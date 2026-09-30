import Link from "next/link";
import { homeSectionId } from "@/domain/home/section-id";
import styles from "./home.module.css";

export function StudioStrip({ genres }: { genres: string[] }) {
  return <nav className={`${styles.studios} ${styles.genreStrip}`} aria-label="Browse genres"><span>DRAMABYTE<br /><small>ORIGINAL STORIES</small></span>{genres.map((genre) => <Link key={genre} href={`#${homeSectionId(genre, true)}`}>{genre}</Link>)}</nav>;
}
