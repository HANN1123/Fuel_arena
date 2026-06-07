import { EdgeFunctionError } from "./errors.ts";

export function requireString(value: unknown, fieldName: string) {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new EdgeFunctionError(
      `${fieldName} is required.`,
      400,
      "required_field",
    );
  }
  return value.trim();
}

export function optionalString(value: unknown) {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : null;
}

export function requireUuid(value: unknown, fieldName: string) {
  const text = requireString(value, fieldName);
  if (!isUuid(text)) {
    throw new EdgeFunctionError(
      `${fieldName} must be a UUID.`,
      400,
      "invalid_uuid",
    );
  }
  return text;
}

export function optionalUuid(value: unknown) {
  const text = optionalString(value);
  if (!text) return null;
  if (!isUuid(text)) {
    throw new EdgeFunctionError(
      "UUID 값 형식이 올바르지 않습니다.",
      400,
      "invalid_uuid",
    );
  }
  return text;
}

export function numberValue(
  value: unknown,
  fieldName: string,
  fallback?: number,
) {
  if (value === undefined || value === null || value === "") {
    if (fallback !== undefined) return fallback;
    throw new EdgeFunctionError(
      `${fieldName} is required.`,
      400,
      "required_field",
    );
  }

  const parsed = Number(value);
  if (!Number.isFinite(parsed)) {
    throw new EdgeFunctionError(
      `${fieldName} must be a number.`,
      400,
      "invalid_number",
    );
  }
  return parsed;
}

export function nonNegativeNumber(
  value: unknown,
  fieldName: string,
  fallback?: number,
) {
  const parsed = numberValue(value, fieldName, fallback);
  if (parsed < 0) {
    throw new EdgeFunctionError(
      `${fieldName} must be greater than or equal to 0.`,
      400,
      "invalid_number",
    );
  }
  return parsed;
}

export function positiveNumber(
  value: unknown,
  fieldName: string,
  fallback?: number,
) {
  const parsed = numberValue(value, fieldName, fallback);
  if (parsed <= 0) {
    throw new EdgeFunctionError(
      `${fieldName} must be greater than 0.`,
      400,
      "invalid_number",
    );
  }
  return parsed;
}

export function fuelLeagueForFuelType(fuelType: string) {
  const normalized = fuelType.toLowerCase().replaceAll("-", "_").replaceAll(
    " ",
    "_",
  );
  if (["gasoline", "gas", "가솔린"].includes(normalized)) return "gasoline";
  if (["diesel", "디젤"].includes(normalized)) return "diesel";
  if (["hybrid", "하이브리드"].includes(normalized)) return "hybrid";
  if (["electric", "ev", "전기", "전기차"].includes(normalized)) return "electric";
  if (["lpg", "lpi", "lp_i"].includes(normalized)) return "lpg";
  if (
    ["phev", "plug_in_hybrid", "plugin_hybrid", "플러그인_하이브리드"].includes(
      normalized,
    )
  ) {
    return "plug_in_hybrid";
  }
  return "other";
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}
