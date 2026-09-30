# Editor voice replacement

Apply `supabase/migrations/0013_editor_audio.sql` in Supabase SQL Editor once.
Restart the API and the Celery worker after deploying this change.

In a completed narrated episode, open Audio, choose Female storyteller or enter
a Fish reference ID, and click Generate replacement voice. Confirm the paid
Fish Audio request. Preview the replacement, then Export to publish it.

The female preset uses the supplied reference
`83c19893c4974594839bd2d101b1fd66`. The original storyteller preset uses
`dcd006182803481390993aa6e9669207`.

The editor task does not call Fal, generate shots, change character references,
or alter production configuration. FFmpeg copies the existing video stream and
fits the replacement narration to its duration without pitch shifting. A voice
whose duration differs excessively is rejected. Local Whisper verifies the
script and retimes the existing captions while retaining text and styling.

The previous private master and published video remain unchanged. Export is
required to publish the replacement. Database updates are committed atomically;
concurrent caption or preview edits cause rejection rather than being overwritten.

Duplicate task deliveries never repeat a paid call. If a worker dies after
claiming an operation, it stays processing for manual review. Do not reset or
resubmit it until provider usage and worker logs have been checked. Failed voice
requests may still incur Fish charges. A broker dispatch error is treated as
uncertain, not automatically resubmitted.
