import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createAdminClient } from "../_shared/adminClient.ts";
import { getRequestUser, isAdminUser } from "../_shared/auth.ts";
import { handleOptions } from "../_shared/cors.ts";
import { toEdgeFunctionError } from "../_shared/errors.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import {
  fuelLeagueForFuelType,
  optionalString,
  requireString,
} from "../_shared/validators.ts";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;
  if (req.method !== "POST") {
    return errorResponse("POST 요청만 지원합니다.", 405, "method_not_allowed");
  }

  try {
    const client = createAdminClient();
    const user = await getRequestUser(req, client);
    if (!user) return errorResponse("로그인이 필요합니다.", 401, "unauthorized");
    if (!(await isAdminUser(user.id, client))) {
      return errorResponse("관리자만 차량 검수를 처리할 수 있습니다.", 403, "forbidden");
    }

    const body = await req.json().catch(() => ({}));
    const userVehicleId = requireString(body.userVehicleId, "userVehicleId");
    const decision = requireString(body.decision, "decision");
    if (decision !== "approve" && decision !== "reject") {
      return errorResponse(
        "approve 또는 reject 결정만 지원합니다.",
        400,
        "invalid_decision",
      );
    }
    const customVehicleRequestId = optionalString(body.customVehicleRequestId);
    const fuelType = optionalString(body.fuelType);
    const fuelLeague = fuelType
      ? fuelLeagueForFuelType(fuelType)
      : optionalString(body.fuelLeague);
    const vehicleClass = optionalString(body.vehicleClass);
    const verificationStatus = decision === "approve" ? "verified" : "rejected";
    const patch: Record<string, unknown> = {
      verification_status: verificationStatus,
      updated_at: new Date().toISOString(),
    };
    if (fuelLeague) patch.fuel_league = fuelLeague;
    if (vehicleClass) patch.vehicle_class = vehicleClass;

    const { data: before, error: vehicleLookupError } = await client
      .from("user_vehicles")
      .select()
      .eq("id", userVehicleId)
      .maybeSingle();
    if (vehicleLookupError) {
      return errorResponse(
        vehicleLookupError.message,
        400,
        "user_vehicle_lookup_failed",
      );
    }
    if (!before) {
      return errorResponse(
        "검수할 사용자 차량을 찾을 수 없습니다.",
        404,
        "user_vehicle_not_found",
      );
    }

    if (customVehicleRequestId) {
      const { data: requestRow, error: requestLookupError } = await client
        .from("custom_vehicle_requests")
        .select("id,user_id,user_vehicle_id,status")
        .eq("id", customVehicleRequestId)
        .maybeSingle();
      if (requestLookupError) {
        return errorResponse(
          requestLookupError.message,
          400,
          "custom_vehicle_request_lookup_failed",
        );
      }
      if (!requestRow) {
        return errorResponse(
          "직접 입력 차량 요청을 찾을 수 없습니다.",
          404,
          "custom_vehicle_request_not_found",
        );
      }
      if (`${requestRow.user_vehicle_id ?? ""}` !== userVehicleId) {
        return errorResponse(
          "요청과 차량 연결이 일치하지 않습니다.",
          409,
          "request_vehicle_mismatch",
        );
      }
      if (`${requestRow.user_id ?? ""}` !== `${before.user_id ?? ""}`) {
        return errorResponse(
          "요청 사용자와 차량 소유자가 일치하지 않습니다.",
          409,
          "request_vehicle_owner_mismatch",
        );
      }
    }

    const { data, error } = await client
      .from("user_vehicles")
      .update(patch)
      .eq("id", userVehicleId)
      .select()
      .single();

    if (error) return errorResponse(error.message, 400, "review_failed");

    await client.from("vehicle_catalog_change_logs").insert({
      admin_user_id: user.id,
      entity_type: "user_vehicle",
      entity_id: userVehicleId,
      action: decision,
      before_data: before ?? null,
      after_data: data,
    });

    if (customVehicleRequestId) {
      await client
        .from("custom_vehicle_requests")
        .update({
          status: decision === "approve" ? "approved" : "rejected",
          reviewed_by: user.id,
          reviewed_at: new Date().toISOString(),
          review_note: optionalString(body.reviewNote) ?? "",
          updated_at: new Date().toISOString(),
        })
        .eq("id", customVehicleRequestId);
    }

    const ownerId = `${data.user_id ?? before?.user_id ?? ""}`;
    let notificationQueued = false;
    if (ownerId) {
      const approved = decision === "approve";
      const notificationTitle = approved
        ? "직접 입력 차량 검수가 완료됐어요"
        : "직접 입력 차량 검수가 보류됐어요";
      const notificationBody = approved
        ? "차량이 공식 리그에 반영됐어요. 랭킹과 배틀에 사용할 수 있습니다."
        : "입력 정보를 다시 확인해 주세요. 차량 설정에서 다시 제출할 수 있습니다.";
      const { error: notificationError } = await client
        .from("notifications")
        .insert({
          user_id: ownerId,
          title: notificationTitle,
          body: notificationBody,
          notification_type: "vehicle_review",
          target_route: "/settings/vehicles",
          held_during_drive: false,
          is_read: false,
        });
      notificationQueued = !notificationError;
    }

    return jsonResponse({
      userVehicle: data,
      verificationStatus,
      notificationQueued,
    });
  } catch (error) {
    const edgeError = toEdgeFunctionError(error);
    return errorResponse(edgeError.message, edgeError.status, edgeError.code);
  }
});
