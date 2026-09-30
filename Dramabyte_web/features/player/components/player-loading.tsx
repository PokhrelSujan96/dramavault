import { Shimmer } from "@/components/loading/shimmer";
import { CommentsLoading } from "./comments-loading";
import styles from "./player.module.css";
import loading from "./player-loading.module.css";

export function PlayerLoading() {
  return <main className={`${styles.page} ${styles.withComments} ${loading.page}`} aria-busy="true" aria-label="Loading episode">
    <section className={styles.stage}><Shimmer className={`${styles.videoFrame} ${loading.video}`} /></section>
    <aside className={styles.details} aria-hidden="true">
      <Shimmer className={`${loading.placeholder} ${loading.breadcrumb}`} />
      <Shimmer className={`${loading.placeholder} ${loading.title}`} />
      <Shimmer className={loading.placeholder} /><Shimmer className={loading.placeholder} />
      <Shimmer className={`${loading.placeholder} ${loading.short}`} />
      <Shimmer className={loading.actions} />
    </aside>
    <aside className={loading.comments} aria-label="Loading comments"><Shimmer className={loading.title} /><CommentsLoading /></aside>
  </main>;
}
