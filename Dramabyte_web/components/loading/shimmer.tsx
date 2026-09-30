import type { CSSProperties } from "react";
import styles from "./shimmer.module.css";

export function Shimmer({ className = "", style }: { className?: string; style?: CSSProperties }) {
  return <div aria-hidden="true" className={`${styles.shimmer} ${className}`} style={style} />;
}
