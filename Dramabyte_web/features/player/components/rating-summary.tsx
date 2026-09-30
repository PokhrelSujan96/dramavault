import { Star } from "lucide-react";
import type { SeriesDetails } from "@/domain/models";
import styles from "./rating-summary.module.css";

export function RatingSummary({ series }: { series: SeriesDetails }) {
  const count = series.rating_count ?? 0;
  const average = series.rating_average;
  return <div className={styles.rating} aria-label="Series rating"><Star size={15} fill={count && average != null ? "currentColor" : "none"} />{count > 0 && average != null ? <><strong>{average.toFixed(1)}<span> / 10</span></strong><span>· {count.toLocaleString()} {count === 1 ? "rating" : "ratings"}</span></> : <span>No ratings yet</span>}</div>;
}
