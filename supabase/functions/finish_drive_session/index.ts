import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createAdminClient } from "../_shared/adminClient.ts";
import { getRequestUser } from "../_shared/auth.ts";
import { handleOptions } from "../_shared/cors.ts";
import { EdgeFunctionError, toEdgeFunctionError } from "../_shared/errors.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import { nonNegativeNumber, requireString } from "../_shared/validators.ts";

function numberFrom(value: unknown, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(max, value));
}

function round2(value: number) {
  return Math.round(value * 100) / 100;
}

function firstPositive(...values: number[]) {
  return values.find((value) => Number.isFinite(value) && value > 0) ?? 0;
}

type SupabaseAdminClient = ReturnType<typeof createAdminClient>;

async function appSettingValue(client: SupabaseAdminClient, key: string) {
  const { data } = await client
    .from("app_settings")
    .select("value")
    .eq("key", key)
    .maybeSingle();
  const value = data?.value;
  if (value && typeof value === "object" && "value" in value) {
    return (value as Record<string, unknown>).value;
  }
  return value;
}

async function numericSetting(
  client: SupabaseAdminClient,
  key: string,
  fallback: number,
  min: number,
  max: number,
) {
  const parsed = Number(await appSettingValue(client, key));
  if (!Number.isFinite(parsed) || parsed < min || parsed > max) {
    return fallback;
  }
  return parsed;
}

function classAverageEfficiencyForFuelType(fuelType: string) {
  const normalized = fuelType.toLowerCase();
  if (normalized.includes("electric") || normalized.includes("전기")) return 5.4;
  if (normalized.includes("hybrid") || normalized.includes("하이브리드")) return 20.5;
  if (normalized.includes("diesel") || normalized.includes("디젤")) return 16.8;
  if (normalized.includes("lpg") || normalized.includes("lpi")) return 10.8;
  return 14.8;
}

type DrivePointRow = {
  latitude: unknown;
  longitude: unknown;
  speed_kmh: unknown;
  accuracy: unknown;
  recorded_at: unknown;
  is_mocked?: unknown;
};

type ParsedDrivePoint = {
  latitude: number;
  longitude: number;
  speedKmh: number;
  accuracy: number;
  recordedAt: number;
  isMocked: boolean;
};

function parseCoordinate(value: unknown) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function toRadians(value: number) {
  return (value * Math.PI) / 180;
}

function distanceMetersBetween(a: ParsedDrivePoint, b: ParsedDrivePoint) {
  const earthRadiusMeters = 6371000;
  const deltaLatitude = toRadians(b.latitude - a.latitude);
  const deltaLongitude = toRadians(b.longitude - a.longitude);
  const startLatitude = toRadians(a.latitude);
  const endLatitude = toRadians(b.latitude);
  const haversine =
    Math.sin(deltaLatitude / 2) ** 2 +
    Math.cos(startLatitude) * Math.cos(endLatitude) * Math.sin(deltaLongitude / 2) ** 2;
  return earthRadiusMeters * 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine));
}

function parseDrivePoint(row: DrivePointRow): ParsedDrivePoint | null {
  const latitude = parseCoordinate(row.latitude);
  const longitude = parseCoordinate(row.longitude);
  const accuracy = numberFrom(row.accuracy, 0);
  const recordedAt = Date.parse(`${row.recorded_at ?? ""}`);
  if (
    latitude === null ||
    longitude === null ||
    Math.abs(latitude) > 90 ||
    Math.abs(longitude) > 180 ||
    accuracy <= 0 ||
    accuracy > 100 ||
    !Number.isFinite(recordedAt)
  ) {
    return null;
  }
  return {
    latitude,
    longitude,
    speedKmh: clamp(numberFrom(row.speed_kmh, 0), 0, 260),
    accuracy,
    recordedAt,
    isMocked: row.is_mocked === true,
  };
}

function analyzeDrivePoints(rows: DrivePointRow[]) {
  const sorted = rows
    .map(parseDrivePoint)
    .filter((point): point is ParsedDrivePoint => point !== null)
    .sort((a, b) => a.recordedAt - b.recordedAt);
  let rejectedPointCount = rows.length - sorted.length;
  let totalMeters = 0;
  let maxSpeedKmh = 0;
  let harshAccelerationCount = 0;
  let harshBrakingCount = 0;
  let previousAcceptedSpeedKmh: number | null = null;
  const mockedPointCount = sorted.filter((point) => point.isMocked).length;
  const averageAccuracy =
    sorted.length === 0
      ? 0
      : sorted.reduce((sum, point) => sum + point.accuracy, 0) / sorted.length;

  for (let index = 1; index < sorted.length; index += 1) {
    const previous = sorted[index - 1];
    const current = sorted[index];
    const seconds = (current.recordedAt - previous.recordedAt) / 1000;
    if (seconds <= 0 || seconds > 900) {
      rejectedPointCount += 1;
      continue;
    }
    const meters = distanceMetersBetween(previous, current);
    const impliedSpeedKmh = (meters / seconds) * 3.6;
    const speedKmh = current.speedKmh > 0 ? current.speedKmh : impliedSpeedKmh;
    maxSpeedKmh = Math.max(maxSpeedKmh, speedKmh, impliedSpeedKmh);

    if (meters > 1000 || impliedSpeedKmh > 220) {
      rejectedPointCount += 1;
      previousAcceptedSpeedKmh = null;
      continue;
    }

    totalMeters += meters;
    if (previousAcceptedSpeedKmh !== null) {
      const accelerationMps2 = ((speedKmh - previousAcceptedSpeedKmh) / 3.6) / seconds;
      if (accelerationMps2 >= 3.2) harshAccelerationCount += 1;
      if (accelerationMps2 <= -4.5) harshBrakingCount += 1;
    }
    previousAcceptedSpeedKmh = speedKmh;
  }

  const durationSeconds =
    sorted.length >= 2
      ? Math.max(0, Math.round((sorted[sorted.length - 1].recordedAt - sorted[0].recordedAt) / 1000))
      : 0;

  return {
    pointCount: rows.length,
    validPointCount: sorted.length,
    rejectedPointCount,
    mockedPointCount,
    distanceKm: round2(totalMeters / 1000),
    durationSeconds,
    maxSpeedKmh: round2(maxSpeedKmh),
    averageAccuracy: round2(averageAccuracy),
    harshAccelerationCount,
    harshBrakingCount,
  };
}

function scoreForDrive(params: {
  distanceKm: number;
  averageEfficiency: number;
  classAverageEfficiency: number;
  harshAccelerationCount: number;
  harshBrakingCount: number;
  idleMinutes: number;
}) {
  const ratio = params.averageEfficiency / params.classAverageEfficiency;
  const distanceBonus = Math.round(clamp(params.distanceKm * 3, 0, 120));
  const totalScore = Math.round(
    ratio * 620 +
      260 -
      params.harshAccelerationCount * 12 -
      params.harshBrakingCount * 14 -
      params.idleMinutes * 3 +
      distanceBonus,
  );
  return {
    totalScore: clamp(totalScore, 0, 1000),
    efficiencyScore: Math.round(clamp(ratio * 100, 0, 160)),
    stabilityScore: Math.round(
      clamp(100 - params.harshAccelerationCount * 5 - params.harshBrakingCount * 6, 0, 100),
    ),
    distanceBonus,
  };
}

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;
  if (req.method !== "POST") return errorResponse("POST 요청만 지원합니다.", 405, "method_not_allowed");

  try {
    const client = createAdminClient();
    const user = await getRequestUser(req, client);
    if (!user) {
      throw new EdgeFunctionError("로그인이 필요합니다.", 401, "unauthorized");
    }

    const body = await req.json().catch(() => ({}));
    const sessionId = requireString(body.sessionId, "sessionId");
    const inputDistanceKm = nonNegativeNumber(body.distanceKm, "distanceKm", 0);
    const inputDurationSeconds = nonNegativeNumber(body.durationSeconds, "durationSeconds", 0);
    const inputAverageEfficiency = nonNegativeNumber(body.averageEfficiency, "averageEfficiency", 0);
    const inputFuelUsedLiters = nonNegativeNumber(body.fuelUsedLiters, "fuelUsedLiters", 0);
    const inputHarshAccelerationCount = nonNegativeNumber(
      body.harshAccelerationCount,
      "harshAccelerationCount",
      0,
    );
    const inputHarshBrakingCount = nonNegativeNumber(body.harshBrakingCount, "harshBrakingCount", 0);
    const idleMinutes = nonNegativeNumber(body.idleMinutes, "idleMinutes", 0);

    const { data: session, error: sessionError } = await client
      .from("drive_sessions")
      .select(
        "id,user_id,vehicle_id,started_at,distance_km,duration_seconds,fuel_used_liters,average_efficiency,status",
      )
      .eq("id", sessionId)
      .eq("user_id", user.id)
      .maybeSingle();

    if (sessionError) {
      throw new EdgeFunctionError(sessionError.message, 500, "session_lookup_failed");
    }
    if (!session) {
      throw new EdgeFunctionError("주행 세션을 찾을 수 없습니다.", 404, "drive_session_not_found");
    }

    const { data: existingScore, error: existingScoreError } = await client
      .from("drive_scores")
      .select()
      .eq("drive_session_id", sessionId)
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (existingScoreError) {
      throw new EdgeFunctionError(existingScoreError.message, 500, "score_lookup_failed");
    }
    if (existingScore) {
      return jsonResponse({
        session,
        score: existingScore,
        verification: {
          status: existingScore.verification_status,
          reasons: ["이미 확정된 주행"],
        },
      });
    }

    const { data: vehicle } = await client
      .from("vehicles")
      .select("fuel_type,vehicle_class")
      .eq("id", session.vehicle_id)
      .maybeSingle();

    const { data: pointRows, error: pointError } = await client
      .from("drive_points")
      .select("latitude,longitude,speed_kmh,accuracy,recorded_at,is_mocked")
      .eq("drive_session_id", sessionId)
      .eq("user_id", user.id)
      .order("recorded_at", { ascending: true })
      .limit(6000);

    if (pointError) {
      throw new EdgeFunctionError(pointError.message, 500, "drive_points_lookup_failed");
    }

    const pointAnalysis = analyzeDrivePoints((pointRows ?? []) as DrivePointRow[]);
    const startedAt = new Date(session.started_at);
    const fallbackDurationSeconds = Number.isFinite(startedAt.getTime())
      ? Math.max(0, Math.round((Date.now() - startedAt.getTime()) / 1000))
      : 0;
    const distanceKm = round2(
      firstPositive(pointAnalysis.distanceKm, inputDistanceKm, numberFrom(session.distance_km, 0)),
    );
    const persistedDurationSeconds = numberFrom(session.duration_seconds, 0);
    const durationSeconds = Math.round(
      firstPositive(
        pointAnalysis.durationSeconds,
        inputDurationSeconds,
        persistedDurationSeconds,
        fallbackDurationSeconds,
      ),
    );
    let fuelUsedLiters = round2(
      inputFuelUsedLiters > 0 ? inputFuelUsedLiters : numberFrom(session.fuel_used_liters, 0),
    );
    const classAverageEfficiency = classAverageEfficiencyForFuelType(`${vehicle?.fuel_type ?? ""}`);
    let averageEfficiency =
      inputAverageEfficiency > 0
        ? inputAverageEfficiency
        : numberFrom(session.average_efficiency, 0);

    if (averageEfficiency <= 0 && distanceKm > 0 && fuelUsedLiters > 0) {
      averageEfficiency = distanceKm / fuelUsedLiters;
    }
    if (averageEfficiency <= 0) {
      averageEfficiency = classAverageEfficiency;
    }
    if (fuelUsedLiters <= 0 && averageEfficiency > 0) {
      fuelUsedLiters = round2(distanceKm / averageEfficiency);
    }
    const harshAccelerationCount = Math.max(
      inputHarshAccelerationCount,
      pointAnalysis.harshAccelerationCount,
    );
    const harshBrakingCount = Math.max(
      inputHarshBrakingCount,
      pointAnalysis.harshBrakingCount,
    );

    const result = scoreForDrive({
      distanceKm,
      averageEfficiency,
      classAverageEfficiency,
      harshAccelerationCount,
      harshBrakingCount,
      idleMinutes,
    });
    const minDistanceKm = await numericSetting(
      client,
      "official_drive_min_distance_km",
      1,
      0.1,
      50,
    );
    const minDurationSeconds = await numericSetting(
      client,
      "official_drive_min_duration_seconds",
      180,
      30,
      7200,
    );
    const abnormalSpeedKmh = await numericSetting(
      client,
      "abnormal_speed_kmh",
      180,
      60,
      300,
    );
    const reasons: string[] = [];
    if (distanceKm < minDistanceKm) reasons.push("최소 거리 미달");
    if (durationSeconds < minDurationSeconds) reasons.push("최소 시간 미달");
    if (pointAnalysis.pointCount === 0 && distanceKm >= minDistanceKm) {
      reasons.push("GPS 포인트 없음");
    }
    if (pointAnalysis.pointCount > 0 && pointAnalysis.validPointCount < 2) {
      reasons.push("유효 GPS 포인트 부족");
    }
    if (pointAnalysis.mockedPointCount > 0) reasons.push("모의 위치 신호 감지");
    if (pointAnalysis.maxSpeedKmh > abnormalSpeedKmh) {
      reasons.push("비정상 속도 감지");
    }
    if (pointAnalysis.averageAccuracy > 50) reasons.push("GPS 정확도 낮음");
    if (
      pointAnalysis.pointCount >= 10 &&
      pointAnalysis.rejectedPointCount / pointAnalysis.pointCount > 0.2
    ) {
      reasons.push("GPS 이상치 다수");
    }
    if (result.totalScore > 980) reasons.push("상위 점수 자동 검토");
    const verificationStatus = reasons.length === 0 ? "verified" : "pending_review";
    const classPercentile = Math.round(clamp(100 - (result.totalScore / 1000) * 100, 1, 99));
    const consistencyBonus = verificationStatus === "verified" ? 31 : 0;

    const { data: updatedSession, error: updateError } = await client
      .from("drive_sessions")
      .update({
        ended_at: new Date().toISOString(),
        distance_km: distanceKm,
        duration_seconds: durationSeconds,
        fuel_used_liters: fuelUsedLiters,
        average_efficiency: round2(averageEfficiency),
        status: verificationStatus,
      })
      .eq("id", sessionId)
      .eq("user_id", user.id)
      .select()
      .single();

    if (updateError) {
      throw new EdgeFunctionError(updateError.message, 500, "session_update_failed");
    }

    const scorePayload = {
      drive_session_id: sessionId,
      user_id: user.id,
      total_score: result.totalScore,
      efficiency_score: result.efficiencyScore,
      stability_score: result.stabilityScore,
      class_percentile: classPercentile,
      fuel_efficiency_score: result.efficiencyScore,
      acceleration_penalty: -Math.round(harshAccelerationCount * 12),
      braking_penalty: -Math.round(harshBrakingCount * 14),
      idle_penalty: -Math.round(idleMinutes * 3),
      distance_bonus: result.distanceBonus,
      consistency_bonus: consistencyBonus,
      verification_status: verificationStatus,
    };
    const { data: score, error: scoreError } = await client
      .from("drive_scores")
      .insert(scorePayload)
      .select()
      .single();

    if (scoreError) {
      if (scoreError.code === "23505") {
        const { data: duplicateScore } = await client
          .from("drive_scores")
          .select()
          .eq("drive_session_id", sessionId)
          .eq("user_id", user.id)
          .maybeSingle();
        if (duplicateScore) {
          return jsonResponse({
            session: updatedSession,
            score: duplicateScore,
            verification: {
              status: duplicateScore.verification_status,
              reasons: ["이미 확정된 주행"],
            },
          });
        }
      }
      throw new EdgeFunctionError(scoreError.message, 500, "score_insert_failed");
    }

    if (verificationStatus === "verified") {
      const { data: profile } = await client
        .from("profiles")
        .select("season_score")
        .eq("id", user.id)
        .maybeSingle();
      const nextSeasonScore = numberFrom(profile?.season_score, 0) + result.totalScore;
      await client.from("profiles").update({ season_score: nextSeasonScore }).eq("id", user.id);
      const { error: rankingJobError } = await client.from("ranking_update_jobs").insert({
        period: "season",
        status: "pending",
        requested_by: user.id,
        related_drive_score_id: score.id,
        result: {
          reason: "drive_score_verified",
          driveSessionId: sessionId,
          totalScore: result.totalScore,
        },
      });
      if (rankingJobError && rankingJobError.code !== "23505") {
        console.warn("ranking_update_job_enqueue_failed", rankingJobError.message);
      }
    }

    return jsonResponse({
      session: updatedSession,
      score,
      verification: {
        status: verificationStatus,
        reasons,
        thresholds: {
          minDistanceKm,
          minDurationSeconds,
          abnormalSpeedKmh,
        },
      },
    });
  } catch (error) {
    const edgeError = toEdgeFunctionError(error);
    return errorResponse(edgeError.message, edgeError.status, edgeError.code);
  }
});
