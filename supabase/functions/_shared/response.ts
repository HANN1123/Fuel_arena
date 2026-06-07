import { corsHeaders } from "./cors.ts";

export function jsonResponse(body: unknown, status = 200) {
  return Response.json(body, {
    status,
    headers: corsHeaders,
  });
}

export function errorResponse(message: string, status = 400, code = "bad_request") {
  return jsonResponse({ error: { code, message } }, status);
}
