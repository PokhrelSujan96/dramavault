import Link from "next/link";
import type { WatchHistory } from "@/domain/account/navigation";
import { HomeArtwork } from "@/features/home/components/reference/home-artwork";
import styles from "./account-popover.module.css";

export function HistoryPopover({ items, onClose, compact = false }: { items: WatchHistory[]; onClose: () => void; compact?: boolean }) {
  if (!items.length) return <p className={styles.empty}>The series you watch will appear here.</p>;
  if (compact) return <div className={styles.recentRows}>{items.slice(0, 2).map((item) => <Link key={item.episode_id} href={`/watch/${item.series_id}/${item.episode_id}`} onClick={onClose} className={styles.recentRow}><div className={styles.poster}><HomeArtwork src={item.thumbnail_url} title={item.title} fill sizes="48px" /></div><h3 title={item.title}>{item.title}</h3><span>EP {item.episode_number}</span></Link>)}</div>;
  return <div className={compact ? styles.historyCards : styles.historyList}>{items.slice(0, compact ? 2 : 10).map((item) => <Link key={item.episode_id} href={`/watch/${item.series_id}/${item.episode_id}`} onClick={onClose} className={styles.historyCard}><div className={styles.historyArt}><HomeArtwork src={item.thumbnail_url} title={item.title} fill sizes="140px" /></div><div className={styles.historyCaption}><h3>{item.title}</h3><span>EP {item.episode_number}</span></div><progress aria-label={`${item.title} progress`} max={Math.max(1, item.duration_seconds)} value={Math.min(item.position_seconds, item.duration_seconds)} /></Link>)}</div>;
}
