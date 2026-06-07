import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createAdminClient } from "../_shared/adminClient.ts";
import { getRequestUser } from "../_shared/auth.ts";
import { handleOptions } from "../_shared/cors.ts";
import { EdgeFunctionError, toEdgeFunctionError } from "../_shared/errors.ts";
import { runIdempotentRequest } from "../_shared/idempotency.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import { nonNegativeNumber, requireUuid } from "../_shared/validators.ts";

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
        functionName: "update_mission_progress",
        requireKey: true,
      },
      async () => {
        const missionId = requireUuid(body.missionId, "missionId");
        const progress = nonNegativeNumber(body.progress, "progress", 0);
        const { data: mission, error: missionError } = await client
          .from("season_missions")
          .select("id,target,reward_xp")
          .eq("id", missionId)
          .maybeSingle();
        if (missionError) {
          throw new EdgeFunctionError(
            missionError.message,
            500,
            "mission_lookup_failed",
          );
        }
        if (!mission) {
          throw new EdgeFunctionError(
            "시즌 미션을 찾을 수 없습니다.",
            404,
            "mission_not_found",
          );
        }

        const { data: existing, error: existingError } = await client
          .from("mission_progress")
          .select("id,progress,reward_claimed")
          .eq("user_id", user.id)
          .eq("mission_id", missionId)
          .maybeSingle();
        if (existingError) {
          throw new EdgeFunctionError(
            existingError.message,
            500,
            "mission_progress_lookup_failed",
          );
        }

        const target = Number(mission.target);
        const nextProgress = Math.min(
          Math.max(Number(existing?.progress ?? 0), Math.floor(progress)),
          target,
        );
        const { data: row, error: upsertError } = await client
          .from("mission_progress")
          .upsert(
            {
              user_id: user.id,
              mission_id: missionId,
              progress: nextProgress,
              reward_claimed: existing?.reward_claimed === true,
              updated_at: new Date().toISOString(),
            },
            { onConflict: "user_id,mission_id" },
          )
          .select("id,progress,reward_claimed,updated_at")
          .single();
        if (upsertError) {
          throw new EdgeFunctionError(
            upsertError.message,
            500,
            "mission_progress_upsert_failed",
          );
        }

        await client.from("analytics_events").insert({
          user_id: user.id,
          event_name: "mission_progress_updated",
          properties: { missionId, progress: row.progress, target },
        });

        return {
          progressId: row.id,
          userId: user.id,
          missionId,
          progress: row.progress,
          target,
          complete: row.progress >= target,
          rewardClaimed: row.reward_claimed === true,
          rewardXp: Number(mission.reward_xp ?? 0),
        };
      },
    );
    return jsonResponse(response);
  } catch (error) {
    const edgeError = toEdgeFunctionError(error);
    return errorResponse(edgeError.message, edgeError.status, edgeError.code);
  }
});

