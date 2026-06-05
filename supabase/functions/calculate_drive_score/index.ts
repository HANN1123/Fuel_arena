import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (req) => {
  const body = await req.json().catch(() => ({}));
  const distanceKm = Number(body.distanceKm ?? 0);
  const efficiency = Number(body.averageEfficiency ?? 0);
  const harshAccelerationCount = Number(body.harshAccelerationCount ?? 0);
  const harshBrakingCount = Number(body.harshBrakingCount ?? 0);
  const idleMinutes = Number(body.idleMinutes ?? 0);
  const classAverageEfficiency = Number(body.classAverageEfficiency ?? 15);
  const ratio = classAverageEfficiency <= 0 ? 1 : efficiency / classAverageEfficiency;
  const totalScore = Math.max(
    0,
    Math.min(
      1000,
      Math.round(ratio * 620 + 260 - harshAccelerationCount * 12 - harshBrakingCount * 14 - idleMinutes * 3 + Math.min(distanceKm * 3, 120)),
    ),
  );

  return Response.json({
    totalScore,
    efficiencyScore: Math.round(ratio * 100),
    stabilityScore: Math.max(0, 100 - harshAccelerationCount * 5 - harshBrakingCount * 6),
    verificationStatus: totalScore > 980 || distanceKm < 1 ? "pending_review" : "verified",
  });
});

