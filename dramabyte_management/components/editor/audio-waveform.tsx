"use client";

import { useEffect, useState } from "react";
import { apiRequest } from "@/lib/api-client";

type Props = { projectId: string; source?: string };

export function AudioWaveform({ projectId, source }: Props) {
  const [peaks, setPeaks] = useState<number[]>([]);
  const [error, setError] = useState(false);

  useEffect(() => {
    if (!source) return;
    let live = true;
    void apiRequest<{ peaks: number[] }>(`/generation/project/${projectId}/waveform`)
      .then((result) => {
        if (live) {
          setPeaks(result.peaks);
          setError(false);
        }
      })
      .catch(() => {
        if (live) {
          setPeaks([]);
          setError(true);
        }
      });
    return () => { live = false; };
  }, [projectId, source]);

  if (error) return <span className="waveform-message">Waveform unavailable</span>;
  if (!peaks.length) return <span className="waveform-message">Reading narration waveform…</span>;
  return (
    <svg aria-label="Narration audio waveform" className="audio-waveform" preserveAspectRatio="none" role="img" viewBox={`0 0 ${peaks.length * 3} 40`}>
      {peaks.map((peak, index) => {
        const height = Math.max(2, Math.sqrt(peak) * 34);
        return <rect height={height} key={index} rx="1" width="1.8" x={index * 3} y={(40 - height) / 2} />;
      })}
    </svg>
  );
}
