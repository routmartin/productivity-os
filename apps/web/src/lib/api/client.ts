/**
 * Thin API client for the Productivity OS backend.
 *
 * Conventions follow ADR-005: JSON over REST under `/api/v1`, Bearer
 * access tokens (ADR-004), and the structured error model
 * (`code` / `message` / `details` / `traceId`).
 *
 * Silent refresh (spec: docs/specs/api-integration.md, AC-006/AC-007):
 * a 401 on any non-auth endpoint triggers one shared
 * `POST /auth/refresh`; on success the original request is retried once,
 * on failure the session-expired handler runs (clear + redirect to login).
 */

const configuredBaseUrl = import.meta.env.VITE_API_BASE_URL;

if (import.meta.env.PROD && !configuredBaseUrl) {
  throw new Error(
    "VITE_API_BASE_URL is required in production. Set it in the Cloudflare Pages build environment.",
  );
}

const BASE_URL = (configuredBaseUrl ?? "/api/v1").replace(/\/+$/, "");

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

export interface SessionHandlers {
  /** Called with the new access token after a successful silent refresh. */
  onRefreshed?: (accessToken: string) => void;
  /** Called when the refresh token is expired/revoked — clear + redirect. */
  onSessionExpired?: () => void;
}

let sessionHandlers: SessionHandlers = {};

export function setSessionHandlers(handlers: SessionHandlers): void {
  sessionHandlers = handlers;
}

interface ErrorResponseBody {
  code?: string;
  message?: string;
  details?: Record<string, unknown>;
}

interface RefreshResponseBody {
  accessToken?: string;
}

/** Auth endpoints never trigger a refresh attempt (login 401 = bad
 *  credentials, not an expired token; refresh 401 = session over). */
function isAuthPath(path: string): boolean {
  return path.startsWith("/auth/");
}

let refreshPromise: Promise<boolean> | null = null;

/** One in-flight refresh at most — concurrent 401s share the result
 *  (spec Rule 5). */
function refreshAccessToken(): Promise<boolean> {
  if (!refreshPromise) {
    refreshPromise = (async () => {
      try {
        const response = await fetch(`${BASE_URL}/auth/refresh`, {
          method: "POST",
          headers: { Accept: "application/json" },
          credentials: "include",
        });
        if (!response.ok) return false;
        const data = (await response.json()) as RefreshResponseBody;
        if (typeof data.accessToken !== "string" || !data.accessToken) {
          return false;
        }
        sessionHandlers.onRefreshed?.(data.accessToken);
        return true;
      } catch {
        return false;
      } finally {
        refreshPromise = null;
      }
    })();
  }
  return refreshPromise;
}

async function request<T>(
  method: string,
  path: string,
  body?: unknown,
  isRetry = false,
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

  // Expired access token — try one silent refresh, then retry once
  // (spec Rule 6).
  if (response.status === 401 && !isAuthPath(path) && !isRetry) {
    const refreshed = await refreshAccessToken();
    if (refreshed) {
      return request<T>(method, path, body, true);
    }
    sessionHandlers.onSessionExpired?.();
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
