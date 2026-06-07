import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createAdminClient } from "../_shared/adminClient.ts";
import { getRequestUser } from "../_shared/auth.ts";
import { handleOptions } from "../_shared/cors.ts";
import { toEdgeFunctionError } from "../_shared/errors.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import { fuelLeagueForFuelType, requireString } from "../_shared/validators.ts";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;
  if (req.method !== "POST") return errorResponse("POST 요청만 지원합니다.", 405, "method_not_allowed");

  try {
    const client = createAdminClient();
    const user = await getRequestUser(req, client);
    if (!user) return errorResponse("로그인이 필요합니다.", 401, "unauthorized");

    const body = await req.json().catch(() => ({}));
    const userVehicleId = requireString(body.userVehicleId, "userVehicleId");
    const fuelType = requireString(body.fuelType, "fuelType");
    const vehicleClass = requireString(body.vehicleClass, "vehicleClass");
    const fuelLeague = fuelLeagueForFuelType(fuelType);

    const { data, error } = await client
      .from("user_vehicles")
      .update({ fuel_league: fuelLeague, vehicle_class: vehicleClass, updated_at: new Date().toISOString() })
      .eq("id", userVehicleId)
      .eq("user_id", user.id)
      .select()
      .single();

    if (error) return errorResponse(error.message, 400, "update_failed");

    return jsonResponse({
      userVehicle: data,
      fuelLeague,
      vehicleClass,
      officialRankingEligible: data?.verification_status === "verified" && fuelLeague !== "other",
    });
  } catch (error) {
    const edgeError = toEdgeFunctionError(error);
    return errorResponse(edgeError.message, edgeError.status, edgeError.code);
  }
});
