# Hybrid production

This is the previous workflow. See [MOTION_PRODUCTION_SETUP.md](MOTION_PRODUCTION_SETUP.md) for current motion-only production.

Apply all pending Supabase migrations in order, including `0007_hybrid_production.sql`, then restart the API and Celery worker. R2 remains the only storage provider. Existing generated videos remain playable; new generation uses the hybrid workflow.

## Production workflow

1. Create a series in management and open its details.
2. Add approved character portraits under Series character bible. Include precise identity and wardrobe descriptions. Portraits are normalized locally and stored in R2. References are immutable; every production snapshots its cast.
3. Create and save a portrait story draft. Assign it to the series and an episode number in Story Studio.
4. Start production. Fish narration establishes the actual duration. DeepSeek divides the exact script into distinct shots, approximately five seconds each. A 60-second narration produces 12 shots: six motion, six still.
5. Review each keyframe for faces, wardrobe, composition and story continuity. Approve acceptable frames. Reroll rejected frames explicitly, then start production again. Rerolls use paid credits, change the seed, reset approval and invalidate that shot's motion asset. Three rerolls per shot are allowed.
6. Generate approved motion. Wan requests are always 480p, 81 frames, 16 FPS. Review and approve the returned motion clips separately. A rejected motion shot can be rerolled from its keyframe, then regenerated.
7. Finish the approved episode. Local FFmpeg uses Lanczos scaling, light sharpening, gentle zoom for stills, H.264 video and normalized AAC narration. It assembles distinct shots without looping a clip through the episode. The final clean master is 1080 × 1920, with duration following narration.
8. Open the ready video in the existing editor, edit the single caption layer, and export to publish. Export burns captions once into a separate R2 rendition. Generation itself does not publish.

## Dependencies and limits

FFmpeg and FFprobe are required. The Docker image already includes FFmpeg. No Real-ESRGAN, GPU, model download or external upscaling service is required. Lanczos resizing is not AI super-resolution and cannot recover native-HD detail. Local compute, hosting and R2 are not guaranteed free.

Narration must be 10–180 seconds, and at most 18 motion shots are allowed by default. The process checks for 2 GB free temporary disk before paid generation. Silence and missing narration are rejected. The completed master is checked for dimensions, audio and duration before upload.

Character shots use `fal-ai/flux-2/klein/4b/edit` with up to four series reference portraits per shot. Environment-only shots use FLUX Schnell. Reference-conditioned image generation has different pricing from Schnell; the previous all-Schnell cost estimate no longer applies. Consistent seeds alone do not preserve identity. Human approvals remain necessary; identical faces cannot be guaranteed by these models.

Optional environment values:

```env
HYBRID_REFERENCE_MODEL=fal-ai/flux-2/klein/4b/edit
HYBRID_MAX_MOTION_SHOTS=18
HYBRID_PROVIDER_TIMEOUT=1800
```

## Recovery and operations

Runs are keyed by script, aspect ratio and cast snapshot. Resuming unchanged input reuses persisted narration, storyboard, R2 images and R2 motion assets. Fal request IDs and endpoints are recorded before polling; timeout resumes poll the same request rather than submitting another paid job. Redis leases prevent overlapping project production and serialize approval changes. No automatic paid rerolls are enabled.

An interruption between provider submission and saving its request ID is inherently ambiguous. Production deliberately stops instead of blindly resubmitting. Reconcile the provider's request history before recovery; a missing request ID is not proof that no billable job ran. Voice requests have the same limitation. Definitively rejected Fal submissions clear their pending reservation; network-ambiguous submissions remain blocked.

Changing script or cast creates a new revision and requires new approvals. Avoid adding cast members or moving episodes between series while a production is running. Existing character records are immutable. Old R2 assets are retained for recovery; this change does not delete uploaded media.

Captions currently use the existing approximate script timing, not word-level Whisper transcription. Caption edits and exports do not regenerate paid media. No live paid generation is part of automated tests.
