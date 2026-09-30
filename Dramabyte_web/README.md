# Dramabyte Web

SEO-friendly Next.js web client for Dramabyte. The public catalog is crawlable, while playback and account features are protected by server middleware.

## Setup

1. Copy `.env.example` to `.env.local`.
2. Set the backend API URL and Google OAuth web client ID.
3. Add the website origin to the Google OAuth client’s authorised JavaScript origins.
4. Run `npm install` and `npm run dev -- --port 3001`.

The UI uses local fallback catalog data when the API is unavailable. Authenticated routes consume the existing `/api/v1` backend endpoints.
