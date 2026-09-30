"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import styles from "./comments.module.css";

export function CommentSignIn() {
  const path = usePathname();
  return <div className={styles.signIn}><Link href={`/signin?returnTo=${encodeURIComponent(path)}`}>Sign in to add a comment</Link></div>;
}
