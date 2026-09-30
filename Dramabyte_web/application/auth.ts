export const protectedPaths = ["/discover", "/library", "/profile", "/series", "/referral", "/wallet"];

export function safeReturnPath(value: string | null) {
  if (!value?.startsWith("/") || value.startsWith("//")) return "/discover";
  return value;
}
