# Private dialogue pilot

Paid generation is disabled by default and remains disabled as requested. No Fish or Fal media was generated while building this workflow.

## Setup

Apply pending Supabase migrations, including `0010_motion_story_alignment.sql` and `0011_dialogue_pilots.sql`. Restart the API and idle Celery worker. Whisper CLI, its model, FFmpeg, Redis, and configured Fish/Fal/R2 credentials are required. The new migration adds a private pilot table and atomic draft creation function; existing episodes and stored media are retained.

Open an existing series-assigned draft in Story Studio. Under Dialogue pilot, select Maya and the boy, then prepare a private draft. Draft creation has no paid requests. The draft appears separately on the dashboard. Its screenplay is a deliberately small fixed train-scene test, not a full-series generator.

Approved voice assignments:

| Role | Fish reference |
| --- | --- |
| Storyteller | dcd006182803481390993aa6e9669207 |
| Maya | 83c19893c4974594839bd2d101b1fd66 |
| Boy | 802e3bc2b27e49c2995d23ef70e6ac89 |

The pilot uses the character voices only. References are configured but their availability, licensing and live quality have not been verified through paid synthesis.

## Planned scene

1. The enclosed train carriage travels through night. Interior dry, rain outside.
2. Boy: “You're late, Maya.”
3. Maya reacts silently.
4. Maya: “How do you know my name?”
5. Detail: the boy's soaked coat above the dry teal seat.
6. Maya: “Your coat is soaked. But the seat is dry.”
7. Boy: “You promised you'd come back.”
8. Maya grips her pendant in recognition.

Eight motion shots, four speaking close-ups, approximately 20–35 seconds after measured dialogue timing. Every frame uses the same location reference and continuity specification. Reaction and detail shots do not lip-sync. No static footage or frozen padding is used.

## When paid testing is authorized

Set `DIALOGUE_PAID_ENABLED=true` only after authorizing a paid test, then restart the API and worker. Starting requires a second explicit confirmation. The default request allowance is $5; conservative image/voice allowances, $0.20 motion requests and $0.05/second Standard lip-sync are reserved before submitting. This is a local estimated request budget, not a guarantee of provider invoicing. Verify current rates and account caps before enabling.

First stage synthesizes character lines, validates audio and aligns words locally. Lines longer than a five-second clip are rejected, not rushed or looped. It generates one shared set and eight reference-conditioned keyframes, then pauses for set, identity, voice and story approvals.

Next stage creates 480p Wan clips. Speaking footage is trimmed before Standard Sync lip-sync, so unused seconds are not processed. The workflow pauses again to review actual performance, continuity and lip-sync. Final assembly scales to 1080 × 1920, mixes dialogue with a locally synthesized train ambience bed, and prepares one editable caption layer. This procedural sound bed is not a premium recorded sound-effects library; music and bespoke effects are future work.

The clean master remains private in R2 and available to admin preview/editor. Pilot publishing is blocked in the API and worker. No episode entry is created and no public app feed receives it. Visual approval is required; AI references do not guarantee perfectly consistent performances.

## Recovery

Redis serializes pilot production and approvals using its private project ID. Provider requests and reservations are persisted before polling. Known requests resume without submitting twice; ambiguous Fish/Fal submissions stop for reconciliation. Rejected shots currently require a new pilot draft rather than automatic rerolls. Existing assets are retained. Uncertain queue dispatch needs worker inspection before retry.

Validation uses mocks for paid providers and real local FFmpeg tests. No full-series rollout should occur before reviewing a paid pilot.
