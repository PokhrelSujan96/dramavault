import { notFound, redirect } from "next/navigation";
import { BackendError } from "@/infrastructure/api/authenticated";
import { loadSeries } from "@/infrastructure/player/watch-repository";

export default async function WatchSeriesPage({ params }: { params: Promise<{ seriesId: string }> }) {
  const { seriesId } = await params;
  let series;
  try { series = await loadSeries(seriesId); }
  catch (error) { if (error instanceof BackendError && error.status === 401) redirect(`/signin?returnTo=${encodeURIComponent(`/watch/${seriesId}`)}`); if (error instanceof BackendError && error.status === 404) notFound(); throw error; }
  if (!series) notFound();
  const first = series.episodes.find((episode) => !episode.locked) ?? series.episodes[0];
  if (!first) notFound();
  redirect(`/watch/${seriesId}/${first.episode_id}`);
}
