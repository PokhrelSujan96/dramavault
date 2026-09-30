import { NextResponse } from "next/server";

export async function POST() {
  const response = NextResponse.json({ ok: true });
  response.cookies.delete("dramabyte_access");
  response.cookies.delete("dramabyte_refresh");
  return response;
}
