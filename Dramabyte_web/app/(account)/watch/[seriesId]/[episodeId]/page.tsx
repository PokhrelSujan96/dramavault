import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { Player } from "@/features/player/components/player";
import { loadEpisode } from "@/infrastructure/player/watch-repository";
import { BackendError } from "@/infrastructure/api/authenticated";

export default async function WatchPage({ params }: { params: Promise<{ seriesId: string; episodeId: string }> }) {
  const { seriesId, episodeId } = await params;
  let episode;
  try { episode = await loadEpisode(seriesId, episodeId); }
  catch (error) { if (error instanceof BackendError && error.status === 401) redirect(`/signin?returnTo=${encodeURIComponent(`/watch/${seriesId}/${episodeId}`)}`); if (error instanceof BackendError && error.status === 404) notFound(); throw error; }
  if (!episode) notFound();
  if (episode.locked) return <main className="container empty"><h1>This episode is locked</h1><p>Sign in to access more episodes. Paid episodes require access.</p><Link href={`/signin?returnTo=${encodeURIComponent(`/watch/${seriesId}/${episodeId}`)}`} className="button button-primary">Sign in</Link><Link href="/wallet" className="button button-red">My wallet</Link></main>;
  if (!episode.current) return <main className="container empty"><h1>Video temporarily unavailable</h1><p>Please try again shortly.</p><Link href="/discover">Browse series</Link></main>;
  return <Player key={episodeId} series={episode.series} current={episode.current} />;
}
