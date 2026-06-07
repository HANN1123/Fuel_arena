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
        functionName: "claim_season_reward",
        requireKey: true,
      },
      async () => {
        const missionId = requireUuid(body.missionId, "missionId");
        const { data: result, error: claimError } = await client.rpc(
          "claim_mission_reward",
          {
            target_user_id: user.id,
            target_mission_id: missionId,
          },
        );
        if (claimError) {
          const message = claimError.message ?? "";
          if (message.includes("mission_not_found")) {
            throw new EdgeFunctionError(
              "시즌 미션을 찾을 수 없습니다.",
              404,
              "mission_not_found",
            );
          }
          if (message.includes("season_reward_not_ready")) {
            throw new EdgeFunctionError(
              "아직 받을 수 없는 시즌 보상입니다.",
              400,
              "season_reward_not_ready",
            );
          }
          throw new EdgeFunctionError(
            claimError.message,
            500,
            "season_reward_claim_failed",
          );
        }
        const response = result && typeof result === "object"
          ? (result as Record<string, unknown>)
          : {};
        const rewardXp = Number(response.rewardXp ?? 0);
        const progress = Number(response.progress ?? response.target ?? 0);
        const target = Number(response.target ?? 0);
        await client.from("analytics_events").insert({
          user_id: user.id,
          event_name: "season_reward_claimed",
          properties: {
            missionId,
            rewardXp,
            alreadyClaimed: response.alreadyClaimed === true,
          },
        });

        return {
          claimed: response.claimed === true,
          alreadyClaimed: response.alreadyClaimed === true,
          progressId: response.progressId,
          userId: user.id,
          missionId,
          progress,
          target,
          rewardClaimed: true,
          rewardXp,
        };
      },
    );
    return jsonResponse(response);
  } catch (error) {
    const edgeError = toEdgeFunctionError(error);
    return errorResponse(edgeError.message, edgeError.status, edgeError.code);
  }
});

