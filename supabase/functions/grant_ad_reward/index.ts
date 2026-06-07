import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createAdminClient } from "../_shared/adminClient.ts";
import { getRequestUser } from "../_shared/auth.ts";
import { handleOptions } from "../_shared/cors.ts";
import { EdgeFunctionError, toEdgeFunctionError } from "../_shared/errors.ts";
import { runIdempotentRequest } from "../_shared/idempotency.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import { optionalString, optionalUuid } from "../_shared/validators.ts";

async function appSettingValue(
  client: ReturnType<typeof createAdminClient>,
  key: string,
) {
  const { data } = await client
    .from("app_settings")
    .select("value")
    .eq("key", key)
    .maybeSingle();
  const value = data?.value;
  if (value && typeof value === "object" && "value" in value) {
    return (value as Record<string, unknown>).value;
  }
  return value;
}

async function booleanSetting(
  client: ReturnType<typeof createAdminClient>,
  key: string,
  fallback: boolean,
) {
  const value = await appSettingValue(client, key);
  if (typeof value === "boolean") {
    return value;
  }
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    if (normalized === "true") return true;
    if (normalized === "false") return false;
  }
  return fallback;
}

async function integerSetting(
  client: ReturnType<typeof createAdminClient>,
  key: string,
  fallback: number,
  min = 0,
  max = 20,
) {
  const value = Number(await appSettingValue(client, key));
  if (!Number.isFinite(value) || value < min || value > max) {
    return fallback;
  }
  return Math.floor(value);
}

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
        functionName: "grant_ad_reward",
        requireKey: true,
      },
      async () => {
        const rewardType = optionalString(body.rewardType) ?? "season_xp_double";
        const adId = optionalUuid(body.adId);
        const enabled = await booleanSetting(client, "reward_ads_enabled", true);
        if (!enabled) {
          throw new EdgeFunctionError(
            "리워드 광고 보상이 비활성화되어 있습니다.",
            403,
            "reward_ads_disabled",
          );
        }

        const dailyLimit = await integerSetting(
          client,
          "reward_ad_daily_limit",
          3,
          0,
          20,
        );
        const today = new Date();
        today.setUTCHours(0, 0, 0, 0);
        const { count, error: countError } = await client
          .from("ad_rewards")
          .select("id", { count: "exact", head: true })
          .eq("user_id", user.id)
          .gte("claimed_at", today.toISOString());
        if (countError) {
          throw new EdgeFunctionError(
            countError.message,
            500,
            "ad_reward_count_failed",
          );
        }
        const usedToday = count ?? 0;
        if (usedToday >= dailyLimit) {
          throw new EdgeFunctionError(
            "오늘 받을 수 있는 리워드 광고 보상을 모두 사용했습니다.",
            429,
            "reward_ad_daily_limit_reached",
          );
        }

        const { data: reward, error: insertError } = await client
          .from("ad_rewards")
          .insert({
            user_id: user.id,
            ad_id: adId,
            reward_type: rewardType,
          })
          .select("id,reward_type,claimed_at")
          .single();
        if (insertError) {
          throw new EdgeFunctionError(
            insertError.message,
            500,
            "ad_reward_insert_failed",
          );
        }

        await client.from("analytics_events").insert({
          user_id: user.id,
          event_name: "ad_reward_granted",
          properties: {
            rewardType,
            adRewardId: reward.id,
            usedToday: usedToday + 1,
            dailyLimit,
          },
        });

        return {
          granted: true,
          rewardId: reward.id,
          userId: user.id,
          rewardType: reward.reward_type,
          usedToday: usedToday + 1,
          dailyLimit,
          claimedAt: reward.claimed_at,
          message: "리워드 광고 보상이 지급되었습니다.",
        };
      },
    );
    return jsonResponse(response);
  } catch (error) {
    const edgeError = toEdgeFunctionError(error);
    return errorResponse(edgeError.message, edgeError.status, edgeError.code);
  }
});

