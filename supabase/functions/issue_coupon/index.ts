import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createAdminClient } from "../_shared/adminClient.ts";
import { getRequestUser } from "../_shared/auth.ts";
import { handleOptions } from "../_shared/cors.ts";
import { EdgeFunctionError, toEdgeFunctionError } from "../_shared/errors.ts";
import { runIdempotentRequest } from "../_shared/idempotency.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import { requireUuid } from "../_shared/validators.ts";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;
  if (req.method !== "POST") {
    return errorResponse("POST 요청만 지원합니다.", 405, "method_not_allowed");
  }

  try {
    const client = createAdminClient();
    const body = await req.json().catch(() => ({})) as Record<string, unknown>;
    const user = await getRequestUser(req, client);
    if (!user) {
      throw new EdgeFunctionError("로그인이 필요합니다.", 401, "unauthorized");
    }

    const response = await runIdempotentRequest(
      client,
      {
        req,
        body,
        userId: user.id,
        functionName: "issue_coupon",
        requireKey: true,
      },
      async () => {
        const couponId = requireUuid(body.couponId, "couponId");
        const { data: coupon, error: couponError } = await client
          .from("coupons")
          .select("id,title,expires_at")
          .eq("id", couponId)
          .maybeSingle();
        if (couponError) {
          throw new EdgeFunctionError(
            couponError.message,
            500,
            "coupon_lookup_failed",
          );
        }
        if (!coupon) {
          throw new EdgeFunctionError(
            "쿠폰을 찾을 수 없습니다.",
            404,
            "coupon_not_found",
          );
        }
        if (Date.parse(`${coupon.expires_at}`) <= Date.now()) {
          throw new EdgeFunctionError(
            "만료된 쿠폰입니다.",
            400,
            "coupon_expired",
          );
        }

        const { data: existing, error: existingError } = await client
          .from("user_coupons")
          .select("id,status,issued_at,used_at")
          .eq("user_id", user.id)
          .eq("coupon_id", couponId)
          .maybeSingle();
        if (existingError) {
          throw new EdgeFunctionError(
            existingError.message,
            500,
            "user_coupon_lookup_failed",
          );
        }
        if (existing) {
          return {
            issued: true,
            alreadyIssued: true,
            userId: user.id,
            couponId,
            userCouponId: existing.id,
            status: existing.status,
            issuedAt: existing.issued_at,
            usedAt: existing.used_at,
          };
        }

        const { data: issued, error: insertError } = await client
          .from("user_coupons")
          .insert({
            user_id: user.id,
            coupon_id: couponId,
            status: "issued",
          })
          .select("id,status,issued_at,used_at")
          .single();
        if (insertError) {
          throw new EdgeFunctionError(
            insertError.message,
            500,
            "user_coupon_insert_failed",
          );
        }
        await client.from("analytics_events").insert({
          user_id: user.id,
          event_name: "coupon_issued",
          properties: { couponId, userCouponId: issued.id },
        });

        return {
          issued: true,
          alreadyIssued: false,
          userId: user.id,
          couponId,
          userCouponId: issued.id,
          status: issued.status,
          issuedAt: issued.issued_at,
          usedAt: issued.used_at,
        };
      },
    );
    return jsonResponse(response);
  } catch (error) {
    const edgeError = toEdgeFunctionError(error);
    return errorResponse(edgeError.message, edgeError.status, edgeError.code);
  }
});

