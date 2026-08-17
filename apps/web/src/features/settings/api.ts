/**
 * Settings API module (spec: docs/specs/users/account-settings.md,
 * plan 003 Step 1). Real endpoints talk to the backend; mock mode is
 * opt-in via the per-feature `VITE_USE_MOCK_SETTINGS=true` toggle (or the
 * global `VITE_USE_MOCK_DATA` switch) — see src/lib/mock.ts.
 *
 * No userId is ever sent: identity comes from the Bearer token (ADR-004,
 * AC-006). All calls go through the shared apiClient (silent refresh,
 * structured ApiError — ADR-005).
 */

import { ApiError, apiClient } from "@/lib/api/client";
import { useMock } from "@/lib/mock";

import type {
  ChangePasswordRequest,
  ChangeTimezoneRequest,
  UserResponse,
} from "./types";

export const USE_MOCK = useMock("SETTINGS");

const MOCK_LATENCY_MS = 650;
const MOCK_USER_ID = "3f6b2a1c-8e4d-4c7a-9b2f-1d5e6a7c8b9d";
const MOCK_EMAIL = "you@example.com";

const BASE = "/users";

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function isValidTimezone(id: string): boolean {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: id });
    return true;
  } catch {
    return false;
  }
}

/** Mirrors the backend validation codes so error paths are reviewable
 *  without the backend (spec Resolved Question 3). */
async function mockChangePassword(
  request: ChangePasswordRequest,
): Promise<UserResponse> {
  await delay(MOCK_LATENCY_MS);

  if (request.newPassword.length < 12) {
    throw new ApiError(
      400,
      "VALIDATION_ERROR",
      "Password must be at least 12 characters.",
    );
  }
  if (request.currentPassword.length < 8) {
    throw new ApiError(
      401,
      "invalid_credentials",
      "Incorrect email or password.",
    );
  }

  return { id: MOCK_USER_ID, email: MOCK_EMAIL, timezone: "Asia/Phnom_Penh" };
}

async function mockChangeTimezone(
  request: ChangeTimezoneRequest,
): Promise<UserResponse> {
  await delay(MOCK_LATENCY_MS);

  if (!isValidTimezone(request.timezone)) {
    throw new ApiError(400, "INVALID_TIMEZONE", "Invalid timezone identifier");
  }

  return { id: MOCK_USER_ID, email: MOCK_EMAIL, timezone: request.timezone };
}

export const settingsApi = {
  changePassword(request: ChangePasswordRequest): Promise<UserResponse> {
    if (USE_MOCK) return mockChangePassword(request);
    return apiClient.put<UserResponse>(`${BASE}/password`, request);
  },

  changeTimezone(request: ChangeTimezoneRequest): Promise<UserResponse> {
    if (USE_MOCK) return mockChangeTimezone(request);
    return apiClient.put<UserResponse>(`${BASE}/timezone`, request);
  },
};
