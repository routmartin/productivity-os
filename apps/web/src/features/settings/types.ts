/**
 * Settings API contracts — mirror the backend exactly (apps/api user
 * module): PUT /api/v1/users/password and PUT /api/v1/users/timezone
 * (spec: docs/specs/users/account-settings.md, verified contract).
 */

import type { UserProfile } from "@/features/auth/types";

/** Body of PUT /api/v1/users/password (backend ChangePasswordRequest).
 *  The new password must be at least 12 characters (validated client-side
 *  first; the server remains the authority). */
export interface ChangePasswordRequest {
  currentPassword: string;
  newPassword: string;
}

/** Body of PUT /api/v1/users/timezone (backend ChangeTimezoneRequest). */
export interface ChangeTimezoneRequest {
  timezone: string;
}

/** Both user endpoints return the same shape as the login profile
 *  (backend UserResponse: id, email, timezone). */
export type UserResponse = UserProfile;
