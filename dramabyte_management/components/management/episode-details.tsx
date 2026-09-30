import { useState } from "react";
import { useManagement } from "@/hooks/use-management";
import { EpisodeFields, type EpisodeMetadata } from "./episode-fields";

export function EpisodeDetails({ episode, seriesId, onClose }: { episode: EpisodeMetadata & { id: string }; seriesId: string; onClose: () => void }) {
  const [value, setValue] = useState<EpisodeMetadata>(episode);
  const data = useManagement(`/admin/series/${seriesId}/episodes`);
  return <form onSubmit={(event) => { event.preventDefault(); void data.mutate(`/admin/episodes/${episode.id}`, "PATCH", value).then((success) => { if (success) onClose(); }); }}><h3>Edit episode details</h3>{data.error && <p role="alert">{data.error}</p>}<EpisodeFields value={value} onChange={setValue} /><div className="management-actions"><button disabled={data.busy}>Save details</button><button type="button" onClick={onClose}>Cancel</button></div></form>;
}
