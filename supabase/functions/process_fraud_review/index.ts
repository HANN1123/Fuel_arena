import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
  const body = await req.json().catch(() => ({}));
  return Response.json({
    reviewId: body.reviewId ?? "review-dev",
    status: "review_completed",
    message: "공정성 검토가 완료되었습니다.",
  });
});

