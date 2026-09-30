# DramaByte Backend

FastAPI API and Celery orchestration foundation for the DramaByte production
pipeline.

## Architecture

- `api`: versioned HTTP routes, schemas, authentication, and authorization
- `application`: orchestration services and deterministic pipeline planning
- `domain`: provider-independent models and workflow states
- `infrastructure`: Supabase repositories, Redis/Celery, R2, and AI adapters
- `supabase`: database migrations, indexes, constraints, and RLS policies

The generation pipeline is resumable from any stage:

1. DeepSeek V3 script generation or an administrator-supplied script
2. Storyboard and scene prompt planning
3. FLUX.1 Schnell image generation
4. Wan 2.1 scene video generation
5. Fish Audio S2.1 Pro narration
6. Script-aligned subtitle timing
7. FFmpeg assembly, normalization, and final render
8. R2 upload and publication to Supabase

Each stage records provider output and failures independently. Narrated episodes
use distinct motion-only shots timed to one Fish storyteller, with no lip-sync,
music or additional voices. Shared empty environment plates anchor the set across
angles. Named cast retain portrait references; explicitly directed anonymous
extras can populate schools and other public spaces. Keyframes and motion clips
require manual quality approval. Local scaling produces 1080p output but does not
recover missing native detail. Masters remain private until a separate export.

## School-story preset

Apply `supabase/migrations/0012_narrated_school_template.sql` before using the new
preset or shared environment generation. Restart the API and Celery worker after
updating code. In Story Studio, choose **Create series + Episode 1 draft**. This
atomically creates **The Last Seat** and the full supplied story, without provider
calls. Retries with the same request ID return the same draft.

Add approved portraits for Ellie, Mia, Claire and Ms Reed in Series management;
their wardrobe descriptions appear beside the script. Use the narrator reference
`dcd006182803481390993aa6e9669207`. Set `HYBRID_REFERENCE_MODEL` to
`fal-ai/flux-2/klein/9b/edit` for the strengthened reference-image editor. Start
production only when ready to spend credits. The target duration guides AI script
writing; pasted stories retain their full text and measured audio duration.

## Local setup

```sh
cp .env.example .env
supabase link --project-ref your-project-ref
supabase db push
docker compose up --build
```

The API runs at `http://localhost:8000` and development documentation is at
`http://localhost:8000/docs`.

## Security

Use the Supabase service-role key only on the backend. The admin application
uses a user session and sends its access token to the API. Assign the `admin`
role in trusted app metadata. Validate Stripe and RevenueCat webhook signatures
before writing entitlement state. Keep generation provider keys server-side.
