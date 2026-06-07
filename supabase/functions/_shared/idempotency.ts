import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { EdgeFunctionError } from "./errors.ts";

type IdempotencyContext = {
  rowId: string;
  replayed: false;
};

type IdempotencyReplay = {
  response: unknown;
  replayed: true;
};

type IdempotencyStart = IdempotencyContext | IdempotencyReplay;

type IdempotencyParams = {
  req: Request;
  body: Record<string, unknown>;
  userId: string;
  functionName: string;
  requireKey?: boolean;
};

export async function runIdempotentRequest(
  client: SupabaseClient,
  params: IdempotencyParams,
  handler: () => Promise<Record<string, unknown>>,
) {
  const key = idempotencyKeyFromRequest(params.req, params.body);
  if (!key) {
    if (params.requireKey) {
      throw new EdgeFunctionError(
        "idempotency key가 필요합니다.",
        400,
        "idempotency_key_required",
      );
    }
    return await handler();
  }

  const start = await beginIdempotentRequest(client, {
    ...params,
    idempotencyKey: key,
  });
  if (start.replayed) {
    return start.response;
  }

  try {
    const response = await handler();
    await completeIdempotentRequest(client, start, response);
    return response;
  } catch (error) {
    await failIdempotentRequest(client, start, error);
    throw error;
  }
}

function idempotencyKeyFromRequest(
  req: Request,
  body: Record<string, unknown>,
) {
  const headerKey = req.headers.get("x-idempotency-key")?.trim();
  if (headerKey) return headerKey;
  const bodyKey = body.idempotencyKey;
  return typeof bodyKey === "string" && bodyKey.trim().length > 0
    ? bodyKey.trim()
    : null;
}

async function beginIdempotentRequest(
  client: SupabaseClient,
  params: IdempotencyParams & { idempotencyKey: string },
): Promise<IdempotencyStart> {
  const requestHash = await hashRequestBody(params.body);
  const { data: existing, error: lookupError } = await client
    .from("edge_function_idempotency_keys")
    .select("id,request_hash,status,response,updated_at")
    .eq("user_id", params.userId)
    .eq("function_name", params.functionName)
    .eq("idempotency_key", params.idempotencyKey)
    .maybeSingle();

  if (lookupError) {
    throw new EdgeFunctionError(
      lookupError.message,
      500,
      "idempotency_lookup_failed",
    );
  }

  if (existing) {
    if (`${existing.request_hash ?? ""}` !== requestHash) {
      throw new EdgeFunctionError(
        "같은 idempotency key가 다른 요청 본문으로 재사용되었습니다.",
        409,
        "idempotency_key_reused",
      );
    }
    if (existing.status === "completed" && existing.response !== null) {
      return { replayed: true, response: existing.response };
    }
    const updatedAt = Date.parse(`${existing.updated_at ?? ""}`);
    const stale = Number.isNaN(updatedAt)
      ? false
      : Date.now() - updatedAt > 10 * 60 * 1000;
    if (existing.status === "processing" && !stale) {
      throw new EdgeFunctionError(
        "같은 요청이 아직 처리 중입니다.",
        409,
        "idempotency_request_processing",
      );
    }
    const { data: retryRow, error: retryError } = await client
      .from("edge_function_idempotency_keys")
      .update({
        status: "processing",
        response: null,
        error_code: null,
        updated_at: new Date().toISOString(),
      })
      .eq("id", existing.id)
      .select("id")
      .single();
    if (retryError) {
      throw new EdgeFunctionError(
        retryError.message,
        500,
        "idempotency_retry_failed",
      );
    }
    return { replayed: false, rowId: `${retryRow.id}` };
  }

  const { data: created, error: insertError } = await client
    .from("edge_function_idempotency_keys")
    .insert({
      user_id: params.userId,
      function_name: params.functionName,
      idempotency_key: params.idempotencyKey,
      request_hash: requestHash,
      status: "processing",
    })
    .select("id")
    .single();

  if (insertError) {
    if (insertError.code === "23505") {
      return await beginIdempotentRequest(client, params);
    }
    throw new EdgeFunctionError(
      insertError.message,
      500,
      "idempotency_insert_failed",
    );
  }

  return { replayed: false, rowId: `${created.id}` };
}

async function completeIdempotentRequest(
  client: SupabaseClient,
  context: IdempotencyContext,
  response: Record<string, unknown>,
) {
  const { error } = await client
    .from("edge_function_idempotency_keys")
    .update({
      status: "completed",
      response,
      updated_at: new Date().toISOString(),
      completed_at: new Date().toISOString(),
    })
    .eq("id", context.rowId);
  if (error) {
    throw new EdgeFunctionError(
      error.message,
      500,
      "idempotency_complete_failed",
    );
  }
}

async function failIdempotentRequest(
  client: SupabaseClient,
  context: IdempotencyContext,
  error: unknown,
) {
  const code =
    error instanceof EdgeFunctionError ? error.code : "edge_function_error";
  await client
    .from("edge_function_idempotency_keys")
    .update({
      status: "failed",
      error_code: code,
      updated_at: new Date().toISOString(),
    })
    .eq("id", context.rowId);
}

async function hashRequestBody(body: Record<string, unknown>) {
  const normalized = { ...body };
  delete normalized.idempotencyKey;
  const bytes = new TextEncoder().encode(stableStringify(normalized));
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function stableStringify(value: unknown): string {
  if (Array.isArray(value)) {
    return `[${value.map(stableStringify).join(",")}]`;
  }
  if (value && typeof value === "object") {
    const object = value as Record<string, unknown>;
    return `{${Object.keys(object)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${stableStringify(object[key])}`)
      .join(",")}}`;
  }
  return JSON.stringify(value);
}
