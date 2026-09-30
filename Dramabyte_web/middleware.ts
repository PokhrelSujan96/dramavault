import { NextRequest, NextResponse } from "next/server";
import { protectedPaths } from "@/application/auth";

export function middleware(request: NextRequest) {
  const protectedRoute = protectedPaths.some((path) => request.nextUrl.pathname === path || request.nextUrl.pathname.startsWith(`${path}/`));
  if (!protectedRoute || request.cookies.has("dramabyte_access")) return NextResponse.next();
  const signIn = new URL("/signin", request.url);
  signIn.searchParams.set("returnTo", request.nextUrl.pathname);
  return NextResponse.redirect(signIn);
}

export const config = { matcher: ["/((?!api|_next/static|_next/image|favicon.svg).*)"] };
