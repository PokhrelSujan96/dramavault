"use client";

import Link from "next/link";
import { Bookmark } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import type { SeriesCard } from "@/domain/models";
import { setWatchlist } from "@/features/home/actions/watchlist";
import { useAccountCache } from "./account-cache-provider";
import { HomeArtwork } from "@/features/home/components/reference/home-artwork";
import styles from "./account-popover.module.css";

export function LibraryPopover({ items, onClose }: { items: SeriesCard[]; onClose: () => void }) {
  const router = useRouter();
  const cache = useAccountCache();
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  const saved = items;
  const remove = (item: SeriesCard) => {
    const change = cache.editLibrary(item, false);
    setError(null);
    startTransition(async () => {
      try {
        const result = await setWatchlist(item.series_id, false);
        if (result.error) {
          change.rollback();
          if (result.signIn) { cache.clear(); router.push("/signin"); onClose(); }
          else setError(result.error);
        } else { change.commit(); router.refresh(); }
      } catch { change.rollback(); setError("Couldn’t update your library. Please try again."); }
    });
  };
  return <><div className={styles.library}>{saved.length ? saved.map((item) => <article className={styles.savedRow} key={item.series_id}><Link className={styles.savedLink} href={`/watch/${item.series_id}`} onClick={onClose}><div className={styles.poster}><HomeArtwork src={item.thumbnail_url} title={item.title} fill sizes="48px" /></div><h3 title={item.title}>{item.title}</h3></Link><button disabled={pending} aria-label={`Remove ${item.title} from library`} onClick={() => remove(item)}><Bookmark size={15} fill="currentColor" /></button></article>) : <p className={styles.message}>Your saved series will appear here.</p>}</div>{error && <p className={styles.error} role="status">{error}</p>}<Link href="/library" className={styles.footerLink} onClick={onClose}>View library</Link></>;
}
