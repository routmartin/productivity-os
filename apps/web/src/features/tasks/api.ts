/**
 * Tasks API module (spec: docs/specs/api-integration.md, plan 002 Step 3).
 *
 * Real endpoints only — the tasks store keeps the mock mode switch
 * (`VITE_USE_MOCK_TASKS=true`) and its milestone seed data, so design
 * review never touches this module.
 *
 * All calls go through the shared apiClient: Bearer token, silent refresh,
 * structured ApiError (ADR-005).
 */

import { apiClient } from "@/lib/api/client";

import type {
  AssignProjectRequest,
  CreateTaskRequest,
  TaskResponse,
  UpdateTaskRequest,
} from "./api-types";

const BASE = "/tasks";

async function list(): Promise<TaskResponse[]> {
  return apiClient.get<TaskResponse[]>(`${BASE}?page=0&size=100`);
}

async function create(request: CreateTaskRequest): Promise<TaskResponse> {
  return apiClient.post<TaskResponse>(BASE, request);
}

/** IN_PROGRESS → COMPLETED (one-way; backend has no un-complete
 *  transition — plan 002 records the decision). */
async function complete(id: string): Promise<TaskResponse> {
  return apiClient.post<TaskResponse>(`${BASE}/${id}/completion`);
}

/** CANCELLED → PLANNED. */
async function reopening(id: string): Promise<TaskResponse> {
  return apiClient.post<TaskResponse>(`${BASE}/${id}/reopening`);
}

/** INBOX → PLANNED. */
async function plan(id: string): Promise<TaskResponse> {
  return apiClient.post<TaskResponse>(`${BASE}/${id}/plan`);
}

/** PLANNED → IN_PROGRESS. */
async function start(id: string): Promise<TaskResponse> {
  return apiClient.post<TaskResponse>(`${BASE}/${id}/start`);
}

/** INBOX | PLANNED | IN_PROGRESS → CANCELLED. */
async function cancel(id: string): Promise<TaskResponse> {
  return apiClient.post<TaskResponse>(`${BASE}/${id}/cancellation`);
}

/** Clears the soft delete. */
async function restore(id: string): Promise<TaskResponse> {
  return apiClient.post<TaskResponse>(`${BASE}/${id}/restoration`);
}

/** Assign or unassign (null projectId) a project. */
async function assignProject(
  id: string,
  request: AssignProjectRequest,
): Promise<TaskResponse> {
  return apiClient.put<TaskResponse>(`${BASE}/${id}/project`, request);
}

/** Full-replace edit (amendment AC-012). */
async function update(
  id: string,
  request: UpdateTaskRequest,
): Promise<TaskResponse> {
  return apiClient.put<TaskResponse>(`${BASE}/${id}`, request);
}

/** Soft delete. */
async function remove(id: string): Promise<void> {
  await apiClient.delete<void>(`${BASE}/${id}`);
}

export const tasksApi = {
  list,
  create,
  complete,
  reopening,
  plan,
  start,
  cancel,
  restore,
  assignProject,
  update,
  delete: remove,
};
