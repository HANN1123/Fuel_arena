export class EdgeFunctionError extends Error {
  constructor(
    message: string,
    public readonly status = 400,
    public readonly code = "bad_request",
  ) {
    super(message);
  }
}

export function toEdgeFunctionError(error: unknown) {
  if (error instanceof EdgeFunctionError) {
    return error;
  }
  if (error instanceof Error) {
    return new EdgeFunctionError(error.message, 400, "function_error");
  }
  return new EdgeFunctionError("요청을 처리하지 못했습니다.", 500, "unknown_error");
}
