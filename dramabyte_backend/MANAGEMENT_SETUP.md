# Management database setup

Run `supabase/migrations/0003_management.sql` once in the Supabase SQL Editor for the project configured by `SUPABASE_URL`. Apply migrations 0001 and 0002 first only for a new database.

Restart the backend and refresh management after applying the migration.

Users supports profile edits, suspension, recoverable removal, restoration, and signed coin adjustments with a mandatory reason. The transaction function locks the balance and uses a request identifier to prevent duplicate credits. Removed and suspended accounts are denied backend access and authentication refresh.

Productions supports reviewing projects, opening the editor, publishing an existing exported video, unpublishing, and deleting project records. Deletion also deletes generation jobs and episode assignments. R2 objects are retained.

Series supports creating and editing series, assigning existing productions as numbered episodes, removing assignments, and deleting series while preserving videos. A project belongs to only one episode; episode numbers are unique within each series.

Production endpoints require the admin role in trusted Supabase app metadata. The existing development guard accepts authenticated accounts; keep development private.

Payments remain deferred. Mobile series browsing is not connected to the Flutter placeholder pages yet.
