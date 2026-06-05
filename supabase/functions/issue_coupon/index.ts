import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
  const body = await req.json().catch(() => ({}));
  return Response.json({
    issued: true,
    couponId: body.couponId ?? "coupon-dev",
    status: "issued",
  });
});

