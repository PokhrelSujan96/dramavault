export type SeriesMetadata = {
  thumbnail_url: string; genre: string; target_episode_count: number; target_episode_seconds: number;
};
export const defaultSeriesMetadata: SeriesMetadata = {
  thumbnail_url: "", genre: "Drama", target_episode_count: 15, target_episode_seconds: 60,
};
export function SeriesFields({ value, onChange }: { value: SeriesMetadata; onChange: (value: SeriesMetadata) => void }) {
  return <><label>Cover image URL<input type="url" placeholder="https://…" value={value.thumbnail_url} onChange={(event) => onChange({ ...value, thumbnail_url: event.target.value })} /></label>
    <label>Genre<select value={value.genre} onChange={(event) => onChange({ ...value, genre: event.target.value })}>{["Drama", "Romance", "Thriller", "Mystery", "Fantasy", "Comedy", "Action"].map((genre) => <option key={genre}>{genre}</option>)}</select></label>
    <div className="series-plan-fields"><label>Planned episodes<input type="number" required min={1} max={500} value={value.target_episode_count} onChange={(event) => onChange({ ...value, target_episode_count: Number(event.target.value) })} /></label><label>Seconds per episode<input type="number" required min={10} max={600} value={value.target_episode_seconds} onChange={(event) => onChange({ ...value, target_episode_seconds: Number(event.target.value) })} /></label></div>
    <p>{value.target_episode_count} episodes · about {Math.round(value.target_episode_count * value.target_episode_seconds / 60)} minutes in total</p>
  </>;
}
