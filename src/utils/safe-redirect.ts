/**
 * Only allow same-origin relative paths to avoid open redirects
 * (e.g. `?next=https://evil.com` or `?next=//evil.com`).
 */
export function safeRedirectPath(next: unknown, fallback = "/dashboard"): string {
  if (typeof next !== "string") return fallback;
  if (!next.startsWith("/") || next.startsWith("//") || next.startsWith("/\\")) return fallback;
  return next;
}
