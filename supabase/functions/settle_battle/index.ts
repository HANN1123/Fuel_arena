import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createAdminClient } from "../_shared/adminClient.ts";
import { getRequestUser } from "../_shared/auth.ts";
import { handleOptions } from "../_shared/cors.ts";
import { EdgeFunctionError, toEdgeFunctionError } from "../_shared/errors.ts";
import { runIdempotentRequest } from "../_shared/idempotency.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import {
  nonNegativeNumber,
  optionalUuid,
  requireUuid,
} from "../_shared/validators.ts";

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
        functionName: "settle_battle",
        requireKey: true,
      },
      async () => {
        const battleId = requireUuid(body.battleId, "battleId");
        const myScore = nonNegativeNumber(body.myScore, "myScore", 0);
        const opponentScore = nonNegativeNumber(
          body.opponentScore,
          "opponentScore",
          0,
        );
        const opponentUserId = optionalUuid(body.opponentUserId);
        const { data: battle, error: battleError } = await client
          .from("battles")
          .select("id,status,reward_summary")
          .eq("id", battleId)
          .maybeSingle();
        if (battleError) {
          throw new EdgeFunctionError(
            battleError.message,
            500,
            "battle_lookup_failed",
          );
        }
        if (!battle) {
          throw new EdgeFunctionError(
            "배틀을 찾을 수 없습니다.",
            404,
            "battle_not_found",
          );
        }

        const { error: myParticipantError } = await client
          .from("battle_participants")
          .upsert(
            {
              battle_id: battleId,
              user_id: user.id,
              score: Math.floor(myScore),
              result: "pending",
            },
            { onConflict: "battle_id,user_id" },
          );
        if (myParticipantError) {
          throw new EdgeFunctionError(
            myParticipantError.message,
            500,
            "battle_participant_upsert_failed",
          );
        }
        if (opponentUserId && opponentUserId !== user.id) {
          const { error: opponentParticipantError } = await client
            .from("battle_participants")
            .upsert(
              {
                battle_id: battleId,
                user_id: opponentUserId,
                score: Math.floor(opponentScore),
                result: "pending",
              },
              { onConflict: "battle_id,user_id" },
            );
          if (opponentParticipantError) {
            throw new EdgeFunctionError(
              opponentParticipantError.message,
              500,
              "battle_opponent_upsert_failed",
            );
          }
        }

        const { data: participants, error: participantsError } = await client
          .from("battle_participants")
          .select("user_id,score")
          .eq("battle_id", battleId);
        if (participantsError) {
          throw new EdgeFunctionError(
            participantsError.message,
            500,
            "battle_participants_lookup_failed",
          );
        }
        const realParticipants = participants ?? [];
        const scores = realParticipants.map((item) => Number(item.score ?? 0));
        if (!opponentUserId) {
          scores.push(Math.floor(opponentScore));
        }
        const maxScore = Math.max(...scores, Math.floor(myScore));
        const winnerCount = scores.filter((score) => score === maxScore).length;
        const myResult = Math.floor(myScore) === maxScore
          ? winnerCount > 1
            ? "draw"
            : "win"
          : "lose";

        for (const participant of realParticipants) {
          const score = Number(participant.score ?? 0);
          const result = score === maxScore
            ? winnerCount > 1
              ? "draw"
              : "win"
            : "lose";
          const { error: participantUpdateError } = await client
            .from("battle_participants")
            .update({ result })
            .eq("battle_id", battleId)
            .eq("user_id", participant.user_id);
          if (participantUpdateError) {
            throw new EdgeFunctionError(
              participantUpdateError.message,
              500,
              "battle_participant_result_update_failed",
            );
          }
        }
        const { error: battleUpdateError } = await client
          .from("battles")
          .update({ status: "completed" })
          .eq("id", battleId);
        if (battleUpdateError) {
          throw new EdgeFunctionError(
            battleUpdateError.message,
            500,
            "battle_status_update_failed",
          );
        }
        await client.from("analytics_events").insert({
          user_id: user.id,
          event_name: "battle_settled",
          properties: { battleId, myScore, opponentScore, result: myResult },
        });

        return {
          userId: user.id,
          battleId,
          result: myResult,
          rewardSummary: battle.reward_summary,
          participantCount: realParticipants.length,
        };
      },
    );
    return jsonResponse(response);
  } catch (error) {
    const edgeError = toEdgeFunctionError(error);
    return errorResponse(edgeError.message, edgeError.status, edgeError.code);
  }
});

