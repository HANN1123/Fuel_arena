import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
  const body = await req.json().catch(() => ({}));
  const myScore = Number(body.myScore ?? 0);
  const opponentScore = Number(body.opponentScore ?? 0);
  return Response.json({
    result: myScore >= opponentScore ? "win" : "lose",
    rewardSummary: myScore >= opponentScore ? "시즌 XP 지급" : "참가 보상 지급",
  });
});

