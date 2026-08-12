import { ApiError, apiClient } from "@/lib/api/client";

import type { LoginRequest, LoginResponse } from "./types";

/**
 * Milestone 1 runs against a mock adapter by default so the UI can be
 * evaluated without the backend. Set VITE_USE_MOCK_AUTH=false to call the
 * real POST /api/v1/auth/login endpoint — the request/response contract
 * is identical, so no other code changes.
 */
const USE_MOCK = import.meta.env.VITE_USE_MOCK_AUTH !== "false";

const MOCK_LATENCY_MS = 650;

const MOCK_USER_ID = "3f6b2a1c-8e4d-4c7a-9b2f-1d5e6a7c8b9d";

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function mockLogin(request: LoginRequest): Promise<LoginResponse> {
  await delay(MOCK_LATENCY_MS);

  // Mirrors the backend's AuthenticationException → 401 invalid_credentials.
  if (request.password.length < 8) {
    throw new ApiError(
      401,
      "invalid_credentials",
      "Incorrect email or password.",
    );
  }

  return {
    accessToken: `mock.${window.btoa(request.email)}.token`,
    user: {
      id: MOCK_USER_ID,
      email: request.email,
      timezone: "Asia/Phnom_Penh",
    },
  };
}

export const authApi = {
  login(request: LoginRequest): Promise<LoginResponse> {
    if (USE_MOCK) return mockLogin(request);
    return apiClient.post<LoginResponse>("/auth/login", request);
  },

  async logout(): Promise<void> {
    if (USE_MOCK) {
      await delay(150);
      return;
    }
    await apiClient.post<void>("/auth/logout");
  },
};
