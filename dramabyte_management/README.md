# DramaByte Management

Responsive React management workspace for creating, supervising, reviewing,
and publishing DramaByte episodes.

## Local setup

```sh
cp .env.example .env.local
npm install
npm run dev
```

The default local address is `http://localhost:3000`.

Sign in with a Supabase Auth email and password. In development, any
authenticated user can use the workspace. Production requires an `admin` or
`service_role` value in trusted app metadata.

## Commands

- `npm run dev`: start the local dashboard
- `npm run lint`: validate the source
- `npm run build`: create a production build

Only public client configuration belongs in `NEXT_PUBLIC_*` values. Provider,
payment, storage, and service-role credentials belong exclusively in
`dramabyte_backend`.
