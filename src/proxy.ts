import type { NextRequest } from "next/server";
import { updateSession } from "@/lib/supabase/proxy";

export async function proxy(request: NextRequest) {
  return updateSession(request);
}

export const config = {
  matcher: [
    // Skip static assets, images and webhooks (webhooks authenticate via signature).
    "/((?!_next/static|_next/image|favicon.ico|api/payments|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)",
  ],
};
