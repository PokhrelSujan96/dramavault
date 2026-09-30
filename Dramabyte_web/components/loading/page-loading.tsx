import { Shimmer } from "./shimmer";
import styles from "./page-loading.module.css";

export function PageLoading() {
  return <main className={styles.page} aria-busy="true" aria-label="Loading content"><Shimmer className={styles.hero} /><section className="container"><Shimmer className={styles.heading} /><div className={styles.cards}>{Array.from({ length: 6 }, (_, index) => <Shimmer key={index} className={styles.card} />)}</div></section></main>;
}
