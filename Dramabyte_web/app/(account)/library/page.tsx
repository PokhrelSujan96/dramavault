import { SeriesRail } from "@/features/catalog/components/series-rail";
import { getSavedSeries } from "@/infrastructure/home/library-repository";

export const metadata = { title: "My library" };

export default async function LibraryPage() {
  const saved = await getSavedSeries();
  return <main className="container" style={{ paddingTop: "var(--page-spacing)" }}><h1 className="section-title" style={{ fontSize: "clamp(2.5rem,5vw,5rem)" }}>My library</h1>{saved.length ? <SeriesRail title="Saved for later" items={saved} /> : <p className="empty">Your saved series will appear here.</p>}</main>;
}
