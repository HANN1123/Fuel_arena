import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
  const body = await req.json().catch(() => ({}));
  return Response.json({
    granted: true,
    rewardType: body.rewardType ?? "season_xp_double",
    message: "리워드 광고 보상이 지급되었습니다.",
  });
});

