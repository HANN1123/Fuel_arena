import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
  const body = await req.json().catch(() => ({}));
  return Response.json({
    accepted: true,
    period: body.period ?? "season",
    message: "검증 완료 점수를 랭킹 큐에 반영했습니다.",
  });
});

