# Series platform

Apply `supabase/migrations/0006_series_platform.sql` in the same Supabase project as the backend. It requires migration 0003. Keep the existing referral and realtime migrations intact. Restart the backend after migration.

The default editorial plan is 15 episodes at 60 seconds each. These are editable targets, not artificial duration limits. Series and episodes have independent titles, descriptions, and thumbnail URLs. Use stable HTTPS image URLs.

Admins can attach generated productions or upload MP4 episodes up to 250 MB. Upload requires FFprobe on the backend; duration is detected from the file. Uploaded episodes remain ready for review and can be published from Productions. Uploaded files are not automatically transcribed or re-captioned.

Engagement endpoints are under `/api/v1/engagement`. The authenticated Flutter player must call views, likes, ratings, and comments endpoints before audience statistics appear. Counts are not seeded or fabricated.

- `POST /episodes/{episode_id}/views` accepts `session_id` and `watched_seconds`. At least 10 seconds are required; views are deduplicated per viewer, episode, and UTC day.
- `POST /episodes/{episode_id}/likes` accepts `liked` and keeps one like per viewer and episode.
- `POST /series/{series_id}/ratings` accepts `rating` from 1 to 5 and updates a viewer's previous rating.
- `POST /episodes/{episode_id}/comments` accepts `body`.
- `GET /episodes/{episode_id}/comments` returns the latest 50 visible comments.

Only published episodes accept engagement. Hidden comments are excluded from public responses and visible-comment counts. Series ratings are weighted across individual audience ratings in the dashboard.

The public series feed returns episode identifiers and metadata for future Flutter integration. The mobile dummy pages are not replaced by this admin change.
