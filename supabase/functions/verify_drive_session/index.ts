import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
  const body = await req.json().catch(() => ({}));
  const distanceKm = Number(body.distanceKm ?? 0);
  const durationSeconds = Number(body.durationSeconds ?? 0);
  const status = distanceKm < 1 || durationSeconds < 180 ? "pending_review" : "verified";
  return Response.json({
    status,
    reasons: status === "verified" ? [] : ["비정상적으로 짧은 주행"],
  });
});

