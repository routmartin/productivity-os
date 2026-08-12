/**
 * Thin API client for the Productivity OS backend.
 *
 * Conventions follow ADR-005: JSON over REST under `/api/v1`, Bearer
 * access tokens (ADR-004), and the structured error model
 * (`code` / `message` / `details` / `traceId`).
 */

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "/api/v1";

export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

type TokenProvider = () => string | null;

let tokenProvider: TokenProvider = () => null;

export function setTokenProvider(provider: TokenProvider): void {
  tokenProvider = provider;
}

interface ErrorResponseBody {
  code?: string;
  message?: string;
  details?: Record<string, unknown>;
}

async function request<T>(
  method: string,
  path: string,
  body?: unknown,
): Promise<T> {
  const headers: Record<string, string> = { Accept: "application/json" };
  if (body !== undefined) {
    headers["Content-Type"] = "application/json";
  }
  const token = tokenProvider();
  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  let response: Response;
  try {
    response = await fetch(`${BASE_URL}${path}`, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
      // Refresh tokens travel in an HttpOnly cookie (path /api/v1/auth).
      credentials: "include",
    });
  } catch {
    throw new ApiError(
      0,
      "NETWORK_ERROR",
      "Could not reach the server. Check your connection and try again.",
    );
  }

  if (!response.ok) {
    let code = "UNKNOWN_ERROR";
    let message = "Something went wrong. Please try again.";
    let details: Record<string, unknown> | undefined;
    try {
      const data = (await response.json()) as ErrorResponseBody;
      code = data.code ?? code;
      message = data.message ?? message;
      details = data.details;
    } catch {
      // Non-JSON error body — keep the defaults.
    }
    throw new ApiError(response.status, code, message, details);
  }

  if (response.status === 204) {
    return undefined as T;
  }
  return (await response.json()) as T;
}

export const apiClient = {
  get: <T>(path: string) => request<T>("GET", path),
  post: <T>(path: string, body?: unknown) => request<T>("POST", path, body),
  put: <T>(path: string, body?: unknown) => request<T>("PUT", path, body),
  delete: <T>(path: string) => request<T>("DELETE", path),
};
