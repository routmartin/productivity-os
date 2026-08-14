/**
 * Goals API module (spec: docs/specs/api-integration.md, plan 002
 * Step 5). Real endpoints only — the goals store keeps the mock switch
 * (`VITE_USE_MOCK_GOALS=true`) and its milestone seed data.
 *
 * All calls go through the shared apiClient: Bearer token, silent
 * refresh, structured ApiError (ADR-005).
 */

import { apiClient } from "@/lib/api/client";

import type {
  CreateGoalRequest,
  GoalResponse,
  ReopenGoalRequest,
  UpdateGoalRequest,
} from "./api-types";

const BASE = "/goals";

/** All goals for the user (any status). */
async function list(): Promise<GoalResponse[]> {
  return apiClient.get<GoalResponse[]>(BASE);
}

async function get(id: string): Promise<GoalResponse> {
  return apiClient.get<GoalResponse>(`${BASE}/${id}`);
}

/** Creates a goal in DRAFT state. */
async function create(request: CreateGoalRequest): Promise<GoalResponse> {
  return apiClient.post<GoalResponse>(BASE, request);
}

/** DRAFT → ACTIVE. */
async function activate(id: string): Promise<GoalResponse> {
  return apiClient.post<GoalResponse>(`${BASE}/${id}/activation`);
}

/** ACTIVE → DRAFT. */
async function returnToDraft(id: string): Promise<GoalResponse> {
  return apiClient.post<GoalResponse>(`${BASE}/${id}/return-to-draft`);
}

/** ACTIVE → COMPLETED (requires no active projects; archives them). */
async function complete(id: string): Promise<GoalResponse> {
  return apiClient.post<GoalResponse>(`${BASE}/${id}/completion`);
}

/** COMPLETED → ACTIVE, reactivating the requested archived projects. */
async function reopening(
  id: string,
  request: ReopenGoalRequest,
): Promise<GoalResponse> {
  return apiClient.post<GoalResponse>(`${BASE}/${id}/reopening`, request);
}

/** COMPLETED → ARCHIVED. */
async function archive(id: string): Promise<GoalResponse> {
  return apiClient.post<GoalResponse>(`${BASE}/${id}/archival`);
}

/** Full-replace edit (amendment AC-016). */
async function update(
  id: string,
  request: UpdateGoalRequest,
): Promise<GoalResponse> {
  return apiClient.put<GoalResponse>(`${BASE}/${id}`, request);
}

/** Hard delete; the backend detaches the goal's projects (AC-017). */
async function remove(id: string): Promise<void> {
  await apiClient.delete<void>(`${BASE}/${id}`);
}

export const goalsApi = {
  list,
  get,
  create,
  activate,
  returnToDraft,
  complete,
  reopening,
  archive,
  update,
  delete: remove,
};
