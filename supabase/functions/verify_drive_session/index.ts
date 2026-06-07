import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { handleOptions } from "../_shared/cors.ts";
import { toEdgeFunctionError } from "../_shared/errors.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import { nonNegativeNumber } from "../_shared/validators.ts";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;
  if (req.method !== "POST") return errorResponse("POST 요청만 지원합니다.", 405, "method_not_allowed");

  try {
    const body = await req.json().catch(() => ({}));
    const distanceKm = nonNegativeNumber(body.distanceKm, "distanceKm", 0);
    const durationSeconds = nonNegativeNumber(body.durationSeconds, "durationSeconds", 0);
    const status = distanceKm < 1 || durationSeconds < 180 ? "pending_review" : "verified";
    return jsonResponse({
      status,
      reasons: status === "verified" ? [] : ["비정상적으로 짧은 주행"],
    });
  } catch (error) {
    const edgeError = toEdgeFunctionError(error);
    return errorResponse(edgeError.message, edgeError.status, edgeError.code);
  }
});

