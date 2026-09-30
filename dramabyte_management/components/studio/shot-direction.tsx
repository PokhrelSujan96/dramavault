import type { HybridShot } from "./hybrid-types";

export function ShotDirection({ shot }: { shot: HybridShot }) {
  const spec = shot.scene_spec;
  return <details className="shot-direction">
    <summary>Story accuracy & direction</summary>
    {shot.start_seconds !== undefined && <p>{shot.start_seconds.toFixed(2)}s – {shot.end_seconds?.toFixed(2)}s · matched to spoken narration</p>}
    {spec?.location && <>
      <p><strong>Location:</strong> {spec.location} · {spec.setting}</p>
      <p><strong>Subject:</strong> {spec.subject}</p>
      <p><strong>Action:</strong> {spec.action}</p>
      {spec.camera_movement && <p><strong>Camera:</strong> {spec.camera} · {spec.camera_movement}</p>}
      {spec.crowd && <p><strong>Background crowd:</strong> {spec.crowd}</p>}
      <p><strong>Must show:</strong> {spec.required_details.join(" · ")}</p>
      <p><strong>Must not show:</strong> {spec.forbidden_details.join(" · ")}</p>
      <p><strong>Continuity:</strong> {spec.continuity}</p>
    </>}
    <p>{shot.prompt}</p>
  </details>;
}
