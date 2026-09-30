export const config = {
  apiUrl: process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1",
  supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL ?? "",
  supabaseAnonKey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "",
} as const;
