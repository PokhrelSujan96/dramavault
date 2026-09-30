import { NextRequest, NextResponse } from "next/server";
import { safeReturnPath } from "@/application/auth";

const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";

export async function POST(request: NextRequest) {
  const body = await request.json();
  if (typeof body.credential !== "string" || body.credential.length < 20) return NextResponse.json({ error: "Invalid Google credential" }, { status: 400 });
  const upstream = await fetch(`${apiUrl}/auth/google`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ id_token: body.credential, referral_code: body.referralCode || null }), cache: "no-store" });
  if (!upstream.ok) return NextResponse.json({ error: "Google sign-in failed" }, { status: 401 });
  const session = await upstream.json();
  const response = NextResponse.json({ redirect: safeReturnPath(body.returnTo) });
  response.cookies.set("dramabyte_access", session.access_token, { httpOnly: true, secure: process.env.NODE_ENV === "production", sameSite: "lax", path: "/", maxAge: session.expires_in });
  response.cookies.set("dramabyte_refresh", session.refresh_token, { httpOnly: true, secure: process.env.NODE_ENV === "production", sameSite: "strict", path: "/api/auth", maxAge: 60 * 60 * 24 * 30 });
  return response;
}
