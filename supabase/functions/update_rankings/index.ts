import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createAdminClient } from "../_shared/adminClient.ts";
import { getRequestUser, isAdminUser } from "../_shared/auth.ts";
import { handleOptions } from "../_shared/cors.ts";
import { EdgeFunctionError, toEdgeFunctionError } from "../_shared/errors.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import { optionalString } from "../_shared/validators.ts";

function hasJobSecret(req: Request, body: Record<string, unknown>) {
  const expected = Deno.env.get("RANKING_JOB_SECRET");
  if (!expected) return false;
  const supplied =
    req.headers.get("x-ranking-job-secret") ?? `${body.jobSecret ?? ""}`;
  return supplied.length > 0 && supplied === expected;
}

async function findQueuedJob(
  client: ReturnType<typeof createAdminClient>,
  period: string,
) {
  const { data: pendingJob, error: pendingError } = await client
    .from("ranking_update_jobs")
    .select()
    .eq("period", period)
    .eq("status", "pending")
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();
  if (pendingError || pendingJob) {
    return { data: pendingJob, error: pendingError };
  }
  return await client
    .from("ranking_update_jobs")
    .select()
    .eq("period", period)
    .eq("status", "failed")
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();
}

async function findActiveJob(
  client: ReturnType<typeof createAdminClient>,
  period: string,
) {
  return await client
    .from("ranking_update_jobs")
    .select()
    .eq("period", period)
    .in("status", ["pending", "running"])
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();
}

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
    const allowed = user
      ? await isAdminUser(user.id, client)
      : hasJobSecret(req, body);
    if (!allowed) {
      throw new EdgeFunctionError(
        "랭킹 갱신 권한이 없습니다.",
        403,
        "ranking_update_forbidden",
      );
    }

    const period = optionalString(body.period) ?? "season";
    const requestedJobId = optionalString(body.jobId);
    const { data: existingJob, error: jobLookupError } = requestedJobId
      ? await client
          .from("ranking_update_jobs")
          .select()
          .eq("id", requestedJobId)
          .maybeSingle()
      : await findQueuedJob(client, period);

    if (jobLookupError) {
      throw new EdgeFunctionError(
        jobLookupError.message,
        500,
        "ranking_job_lookup_failed",
      );
    }

    let job = existingJob;
    if (!job) {
      const { data: createdJob, error: createJobError } = await client
        .from("ranking_update_jobs")
        .insert({
          period,
          status: "pending",
          requested_by: user?.id ?? null,
        })
        .select()
        .single();
      if (createJobError) {
        if (createJobError.code !== "23505") {
          throw new EdgeFunctionError(
            createJobError.message,
            500,
            "ranking_job_create_failed",
          );
        }
        const { data: activeJob, error: activeJobError } = await findActiveJob(
          client,
          period,
        );
        if (activeJobError) {
          throw new EdgeFunctionError(
            activeJobError.message,
            500,
            "ranking_job_lookup_failed",
          );
        }
        job = activeJob;
      } else {
        job = createdJob;
      }
    }

    if (!job) {
      throw new EdgeFunctionError(
        "랭킹 갱신 job을 만들지 못했습니다.",
        500,
        "ranking_job_create_failed",
      );
    }

    const { data: claimedJob, error: startJobError } = await client
      .from("ranking_update_jobs")
      .update({
        status: "running",
        started_at: new Date().toISOString(),
        error_message: null,
      })
      .eq("id", job.id)
      .in("status", ["pending", "failed"])
      .select()
      .maybeSingle();
    if (startJobError) {
      throw new EdgeFunctionError(
        startJobError.message,
        500,
        "ranking_job_start_failed",
      );
    }
    if (!claimedJob) {
      return jsonResponse({
        accepted: true,
        jobId: job.id,
        period,
        status: `${job.status ?? "already_running"}`,
      });
    }
    job = claimedJob;

    const { data: result, error: recomputeError } = await client.rpc(
      "recompute_rankings",
      { target_period: period },
    );

    if (recomputeError) {
      const { error: failJobError } = await client
        .from("ranking_update_jobs")
        .update({
          status: "failed",
          finished_at: new Date().toISOString(),
          error_message: recomputeError.message,
        })
        .eq("id", job.id);
      if (failJobError) {
        console.warn("ranking_job_fail_update_failed", failJobError.message);
      }
      throw new EdgeFunctionError(
        recomputeError.message,
        500,
        "ranking_recompute_failed",
      );
    }

    const { error: completeJobError } = await client
      .from("ranking_update_jobs")
      .update({
        status: "completed",
        finished_at: new Date().toISOString(),
        result: result ?? {},
      })
      .eq("id", job.id);
    if (completeJobError) {
      throw new EdgeFunctionError(
        completeJobError.message,
        500,
        "ranking_job_complete_failed",
      );
    }

    return jsonResponse({
      accepted: true,
      jobId: job.id,
      period,
      result,
    });
  } catch (error) {
    const edgeError = toEdgeFunctionError(error);
    return errorResponse(edgeError.message, edgeError.status, edgeError.code);
  }
});
