import { ApiError, apiClient } from "@/lib/api/client";

import type {
  LoginRequest,
  LoginResponse,
  RegisterRequest,
  UserProfile,
} from "./types";

/**
 * Milestone 1 runs against a mock adapter by default so the UI can be
 * evaluated without the backend. Set VITE_USE_MOCK_AUTH=false to call the
 * real POST /api/v1/auth/login endpoint — the request/response contract
 * is identical, so no other code changes.
 */
export const USE_MOCK = import.meta.env.VITE_USE_MOCK_AUTH !== "false";

const MOCK_LATENCY_MS = 650;

const MOCK_USER_ID = "3f6b2a1c-8e4d-4c7a-9b2f-1d5e6a7c8b9d";

/** Emails created through the mock register flow — mirrors the backend's
 *  EMAIL_TAKEN on duplicates. */
const mockRegisteredEmails = new Set<string>();

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

  register(request: RegisterRequest): Promise<UserProfile> {
    if (USE_MOCK) return mockRegister(request);
    return apiClient.post<UserProfile>("/auth/register", request);
  },

  async logout(): Promise<void> {
    if (USE_MOCK) {
      await delay(150);
      return;
    }
    await apiClient.post<void>("/auth/logout");
  },
};

/** Mirrors the backend RegisterRequest validation and EMAIL_TAKEN
 *  conflict so the mock flow stays reviewable without the backend. */
async function mockRegister(request: RegisterRequest): Promise<UserProfile> {
  await delay(MOCK_LATENCY_MS);

  if (request.password.length < 12) {
    throw new ApiError(
      400,
      "VALIDATION_ERROR",
      "Password must be at least 12 characters.",
    );
  }

  const email = request.email.toLowerCase();
  if (mockRegisteredEmails.has(email)) {
    throw new ApiError(
      409,
      "EMAIL_TAKEN",
      "An account with this email already exists.",
    );
  }

  mockRegisteredEmails.add(email);
  return {
    id: `mock-${mockRegisteredEmails.size}`,
    email,
    timezone: request.timezone ?? "UTC",
  };
}
