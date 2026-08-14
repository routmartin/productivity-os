/**
 * Auth contracts — mirror the backend API exactly (apps/api user module):
 * POST /api/v1/auth/login → LoginResponse, per ADR-004 / ADR-005.
 * Do not invent fields the backend does not return.
 */

export interface UserProfile {
  id: string;
  email: string;
  /** IANA timezone identifier, e.g. "Asia/Phnom_Penh" (ADR-006). */
  timezone: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

/** Body of POST /api/v1/auth/register (backend RegisterRequest).
 *  Password must be at least 12 characters; timezone is optional
 *  (server defaults to UTC). */
export interface RegisterRequest {
  email: string;
  password: string;
  timezone?: string | null;
}

export interface LoginResponse {
  accessToken: string;
  user: UserProfile | null;
}

export interface AuthSession {
  accessToken: string;
  user: UserProfile;
}
