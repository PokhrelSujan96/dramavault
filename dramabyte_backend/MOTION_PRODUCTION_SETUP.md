# Motion-only production

Apply pending Supabase migrations including `0010_motion_story_alignment.sql`, then restart the API and idle Celery worker. R2 storage and existing uploaded videos are preserved.

The worker now requires whisper.cpp's `whisper-cli` and `models/ggml-base.bin`, alongside FFmpeg and FFprobe. Both Whisper dependencies are installed on this Mac; the model uses approximately 141 MB. Other machines and Docker workers must install the CLI and mount the model. The existing Docker image only includes FFmpeg. Preflight rejects missing dependencies before paid generation.

Fish Audio uses reference `dcd006182803481390993aa6e9669207`. Local Whisper measures speech timestamps and matches the original script. Uncertain matches fail rather than using evenly spaced captions.

Each short narration passage receives an approved keyframe with explicit location, subject, action, required details, forbidden details and continuity. A second planning review checks the storyboard. Paid motion is assigned evenly after review and capped at eight clips per finished minute. Remaining keyframes receive a restrained local push-in during rendering. Character portraits provide identity, not background or weather. Wet clothing does not imply a wet carriage: the soaked boy and dry seat must remain inside, with rain outside windows.

Review and approve keyframes for identity and story accuracy, then generate and review only the budgeted motion clips. Approved still shots are rendered with subtle local movement rather than an additional paid video request. FFmpeg trims shots to narration intervals, scales to 1080 × 1920 and normalizes audio. Motion clips are never looped or frozen. Edit the single caption layer and export the public rendition to R2.

Budget production limits a 54.49-second narration to eight paid motion clips even when alignment produces 22 timed shots. Every shot still has a reviewed keyframe, while narration and local rendering preserve the complete timeline. Planning checks cannot guarantee model footage; human visual approval remains necessary.

The pipeline version and voice reference are included in revision hashes. Old generated footage is not corrected automatically. Regenerate a draft to use this workflow; published projects remain protected. Resumes reuse saved narration, alignment and provider checkpoints. No paid generation is performed by automated tests.

Configuration defaults: `WHISPER_CLI_PATH=whisper-cli`, `WHISPER_MODEL_PATH=models/ggml-base.bin`, `WHISPER_TIMEOUT_SECONDS=600`, `HYBRID_MAX_MOTION_SHOTS=24`, `HYBRID_MOTION_CLIPS_PER_MINUTE=8`, `HYBRID_EPISODE_BUDGET_CENTS=400`, `HYBRID_SERIES_BUDGET_CENTS=7000`, and `HYBRID_MAX_REROLLS_PER_SHOT=1`. Narration must last 10–180 seconds; each shot must fit five seconds. Local scaling cannot recover missing native-HD detail. Compute, hosting and R2 are not guaranteed free.
