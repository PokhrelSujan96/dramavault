import { useState } from "react";
import { apiRequest } from "@/lib/api-client";
import { DialoguePilotReview } from "./dialogue-pilot-review";
import { PILOT_VOICES, type PilotCharacter } from "./dialogue-types";

type Props = { seriesId: string; characters: PilotCharacter[] };

export function DialoguePilotCreate({ seriesId, characters }: Props) {
  const [girl, setGirl] = useState(characters.find((item) => /maya/i.test(item.name))?.id ?? "");
  const [boy, setBoy] = useState(characters.find((item) => /boy/i.test(item.name))?.id ?? "");
  const [girlVoice, setGirlVoice] = useState(PILOT_VOICES.girl);
  const [boyVoice, setBoyVoice] = useState(PILOT_VOICES.boy);
  const [pilotId, setPilotId] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [template, setTemplate] = useState("train");

  async function create() {
    setBusy(true); setError("");
    try {
      const result = await apiRequest<{ id: string }>("/generation/pilots", {
        method: "POST",
        body: { series_id: seriesId, budget_usd: 5, template, cast: [
          { character_id: girl, voice_reference: girlVoice },
          { character_id: boy, voice_reference: boyVoice },
        ] },
      });
      setPilotId(result.id);
    } catch (cause) { setError(cause instanceof Error ? cause.message : "Unable to prepare pilot"); }
    finally { setBusy(false); }
  }

  if (pilotId) return <DialoguePilotReview pilotId={pilotId} />;
  return <section className="hybrid-production">
    <h3>Dialogue pilot · private test scene</h3>
    <p>Prepare a separate 20–35-second scene with two character voices, a shared set, reaction shots and selective lip-sync. Creating the draft does not spend credits or change this episode.</p>
    <label>Screenplay<select value={template} onChange={(event) => setTemplate(event.target.value)}><option value="train">The Last Train Home</option><option value="school">After the Bell · school bullying</option></select></label>
    <div className="hybrid-assignment">
      <label>{template === "school" ? "Nia" : "Maya"}<select value={girl} onChange={(event) => setGirl(event.target.value)}><option value="">Choose girl</option>{characters.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
      <label>{template === "school" ? "Ethan" : "Boy"}<select value={boy} onChange={(event) => setBoy(event.target.value)}><option value="">Choose boy</option>{characters.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
    </div>
    <label>Maya voice reference<input value={girlVoice} onChange={(event) => setGirlVoice(event.target.value)} /></label>
    <label>Boy voice reference<input value={boyVoice} onChange={(event) => setBoyVoice(event.target.value)} /></label>
    <p>Storyteller reference: {PILOT_VOICES.narrator}. This pilot uses dialogue rather than narration.</p>
    {error && <p role="alert" className="dashboard-error">{error}</p>}
    <button type="button" disabled={busy || !girl || !boy || girl === boy || girlVoice === boyVoice || !/^[a-f0-9]{32}$/.test(girlVoice) || !/^[a-f0-9]{32}$/.test(boyVoice)} onClick={() => void create()}>{busy ? "Preparing…" : "Prepare private pilot · no paid requests"}</button>
  </section>;
}
