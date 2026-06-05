import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
  const body = await req.json().catch(() => ({}));
  return Response.json({
    queued: true,
    title: body.title ?? "Fuel Arena",
    body: body.body ?? "새 알림이 도착했습니다.",
  });
});
