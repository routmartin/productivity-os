/**
 * Focus API module (spec: docs/specs/api-integration.md, plan 002
 * Step 7). Real endpoints only — the focus store keeps the mock switch
 * (`VITE_USE_MOCK_FOCUS=true`) and its milestone seed data.
 *
 * All calls go through the shared apiClient: Bearer token, silent
 * refresh, structured ApiError (ADR-005).
 */

import { apiClient } from "@/lib/api/client";

import type { FocusSessionResponse, StartFocusRequest } from "./api-types";

const BASE = "/focus";

/** The in-progress session, or a 404 with an empty body when none —
 *  the caller treats 404 as "no active session", not an error. */
async function active(): Promise<FocusSessionResponse> {
  return apiClient.get<FocusSessionResponse>(`${BASE}/active`);
}

/** Start a session for an IN_PROGRESS task. */
async function start(
  request: StartFocusRequest,
): Promise<FocusSessionResponse> {
  return apiClient.post<FocusSessionResponse>(BASE, request);
}

/** End the session; the response carries the computed duration. */
async function end(id: string): Promise<FocusSessionResponse> {
  return apiClient.post<FocusSessionResponse>(`${BASE}/${id}/end`);
}

/** All recorded sessions, newest page. */
async function history(): Promise<FocusSessionResponse[]> {
  return apiClient.get<FocusSessionResponse[]>(`${BASE}?page=0&size=100`);
}

export const focusApi = {
  active,
  start,
  end,
  history,
};
