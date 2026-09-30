# Guest playback

Guests can watch published episode numbers 1 and 2 through `/public/series/{id}` and `/public/series/{id}/playlist`. Later episodes never receive media URLs through these endpoints. Authentication remains required for engagement mutations and account data.

Apply `supabase/migrations/0027_public_episode_previews.sql` to the intended database and deploy the updated backend before enabling the web change. This checkout has no linked Supabase project, so the migration has not been applied here. The RPC is executable only by the service role, with a fixed search path and published-only queries.

Preview links use R2 presigning with a five-minute expiration and are returned with `Cache-Control: private, no-store`. Redis must be available; a limiter failure denies requests. Limits are shared across workers and allow 120 requests per minute per backend caller address. Web requests originate from the web server, so that address shares a bucket; account for this when sizing traffic limits at the production edge. Do not trust arbitrary forwarded IP headers.

Paid media must reside behind private storage or an authenticated CDN. Existing public bucket/CDN URLs bypass API access checks; issuing expiring preview links does not revoke those permanent links. Disable public delivery for paid objects and purge previously exposed CDN copies before claiming paid media is protected. Keep storage keys, service-role credentials and signing credentials on the backend. Browser clients necessarily receive the authorized preview URL and can copy a free video they can play.

Verification covers signed-out HTTP access, exclusion of later episodes, mismatched series and episode metadata, missing publications, rate limiting, limiter failure and presigning expiration. The web independently denies guest episode numbers outside 1–2 before fetching a playlist.

Guest comments use `/public/comments/episodes/{id}` and `/public/comments/{id}/replies`. Only published episodes are readable; hidden comments stay excluded by existing database RPCs. Public responses omit author account IDs, avatar URLs and viewer-specific flags. Pagination and rate limits bound reads. Posting and all mutations continue to require verified authentication. These comment routes reuse existing migrations; deploy the updated backend to activate them.

Web view tracking matches the mobile two-second threshold using active, visible playback time. Each replay generates a new event; pause/resume and retries reuse the existing event. Signed-in events use `/views/batch`; guests use `/public/views`. Apply `0028_guest_views.sql` and deploy the backend to activate guest counting. Guest RPCs enforce published episode numbers 1–2 and increment by exactly one, deduplicating the event in the same transaction as the counters. Anonymous requests are rate-limited. Browser telemetry cannot prove a human watched; these counts are analytics, not an entitlement or payment authority. Retain guest event IDs for an appropriate retry window and schedule cleanup of old ledger rows as part of database maintenance.

The watch rating control uses authenticated `/ratings/episodes/{id}` PUT and DELETE with scores 1–10. The UI updates the selected score immediately and restores it on failure.
