/**
 * Projects API module (spec: docs/specs/api-integration.md, plan 002
 * Step 4). Real endpoints only — the projects store keeps the mock
 * switch (`VITE_USE_MOCK_PROJECTS=true`) and its milestone seed data.
 *
 * All calls go through the shared apiClient: Bearer token, silent
 * refresh, structured ApiError (ADR-005).
 */

import { apiClient } from "@/lib/api/client";

import type {
  CreateProjectRequest,
  ProjectResponse,
  UpdateProjectRequest,
} from "./api-types";

const BASE = "/projects";

/** All projects for the user (any status). */
async function list(): Promise<ProjectResponse[]> {
  return apiClient.get<ProjectResponse[]>(BASE);
}

async function get(id: string): Promise<ProjectResponse> {
  return apiClient.get<ProjectResponse>(`${BASE}/${id}`);
}

/** Creates a project in DRAFT state. */
async function create(request: CreateProjectRequest): Promise<ProjectResponse> {
  return apiClient.post<ProjectResponse>(BASE, request);
}

/** DRAFT → ACTIVE. */
async function activate(id: string): Promise<ProjectResponse> {
  return apiClient.post<ProjectResponse>(`${BASE}/${id}/activation`);
}

/** ACTIVE → DRAFT. */
async function returnToDraft(id: string): Promise<ProjectResponse> {
  return apiClient.post<ProjectResponse>(`${BASE}/${id}/return-to-draft`);
}

/** ACTIVE → COMPLETED (requires zero non-completed tasks). */
async function complete(id: string): Promise<ProjectResponse> {
  return apiClient.post<ProjectResponse>(`${BASE}/${id}/completion`);
}

/** COMPLETED → ARCHIVED. */
async function archive(id: string): Promise<ProjectResponse> {
  return apiClient.post<ProjectResponse>(`${BASE}/${id}/archival`);
}

/** Full-replace edit (amendment AC-014). */
async function update(
  id: string,
  request: UpdateProjectRequest,
): Promise<ProjectResponse> {
  return apiClient.put<ProjectResponse>(`${BASE}/${id}`, request);
}

/** Hard delete; the backend detaches the project's tasks (AC-015). */
async function remove(id: string): Promise<void> {
  await apiClient.delete<void>(`${BASE}/${id}`);
}

export const projectsApi = {
  list,
  get,
  create,
  activate,
  returnToDraft,
  complete,
  archive,
  update,
  delete: remove,
};
