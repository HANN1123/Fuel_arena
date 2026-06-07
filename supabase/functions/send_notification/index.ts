import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createAdminClient } from "../_shared/adminClient.ts";
import { getRequestUser, isAdminUser } from "../_shared/auth.ts";
import { handleOptions } from "../_shared/cors.ts";
import { EdgeFunctionError, toEdgeFunctionError } from "../_shared/errors.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import { optionalString, optionalUuid } from "../_shared/validators.ts";

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
    const requestedTargetUserId = optionalUuid(body.targetUserId);
    const targetUserId = requestedTargetUserId ?? user.id;
    if (targetUserId !== user.id && !(await isAdminUser(user.id, client))) {
      throw new EdgeFunctionError(
        "다른 사용자에게 알림을 보낼 권한이 없습니다.",
        403,
        "forbidden",
      );
    }

    const heldDuringDrive = body.isDriving === true;
    const notificationType = optionalString(body.notificationType) ?? "general";
    const targetRoute = optionalString(body.targetRoute);
    const title = optionalString(body.title) ?? "Fuel Arena";
    const message = optionalString(body.body) ?? "새 알림이 도착했습니다.";

    const { data: notification, error: insertError } = await client
      .from("notifications")
      .insert({
        user_id: targetUserId,
        title,
        body: message,
        notification_type: notificationType,
        target_route: targetRoute,
        held_during_drive: heldDuringDrive,
        is_read: false,
      })
      .select("id,created_at")
      .single();
    if (insertError) {
      throw new EdgeFunctionError(
        insertError.message,
        500,
        "notification_insert_failed",
      );
    }

    return jsonResponse({
      queued: true,
      notificationId: notification.id,
      userId: targetUserId,
      heldDuringDrive,
      notificationType,
      targetRoute,
      title,
      body: message,
      createdAt: notification.created_at,
    });
  } catch (error) {
    const edgeError = toEdgeFunctionError(error);
    return errorResponse(edgeError.message, edgeError.status, edgeError.code);
  }
});
