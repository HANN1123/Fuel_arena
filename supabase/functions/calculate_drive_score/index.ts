import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { handleOptions } from "../_shared/cors.ts";
import { toEdgeFunctionError } from "../_shared/errors.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import { nonNegativeNumber, positiveNumber } from "../_shared/validators.ts";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;
  if (req.method !== "POST") return errorResponse("POST 요청만 지원합니다.", 405, "method_not_allowed");

  try {
    const body = await req.json().catch(() => ({}));
    const distanceKm = nonNegativeNumber(body.distanceKm, "distanceKm", 0);
    const efficiency = nonNegativeNumber(body.averageEfficiency, "averageEfficiency", 0);
    const harshAccelerationCount = nonNegativeNumber(body.harshAccelerationCount, "harshAccelerationCount", 0);
    const harshBrakingCount = nonNegativeNumber(body.harshBrakingCount, "harshBrakingCount", 0);
    const idleMinutes = nonNegativeNumber(body.idleMinutes, "idleMinutes", 0);
    const classAverageEfficiency = positiveNumber(body.classAverageEfficiency, "classAverageEfficiency", 15);
    const ratio = efficiency / classAverageEfficiency;
    const totalScore = Math.max(
      0,
      Math.min(
        1000,
        Math.round(
          ratio * 620 +
            260 -
            harshAccelerationCount * 12 -
            harshBrakingCount * 14 -
            idleMinutes * 3 +
            Math.min(distanceKm * 3, 120),
        ),
      ),
    );

    return jsonResponse({
      totalScore,
      efficiencyScore: Math.round(ratio * 100),
      stabilityScore: Math.max(0, 100 - harshAccelerationCount * 5 - harshBrakingCount * 6),
      verificationStatus: totalScore > 980 || distanceKm < 1 ? "pending_review" : "verified",
    });
  } catch (error) {
    const edgeError = toEdgeFunctionError(error);
    return errorResponse(edgeError.message, edgeError.status, edgeError.code);
  }
});

