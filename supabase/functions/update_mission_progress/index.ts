import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
  const body = await req.json().catch(() => ({}));
  const progress = Number(body.progress ?? 0);
  const target = Number(body.target ?? 1);
  return Response.json({
    progress,
    target,
    complete: progress >= target,
  });
});

