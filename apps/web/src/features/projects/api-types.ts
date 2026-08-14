/**
 * Projects API contract types — mirror the backend exactly
 * (apps/api project module: ProjectResponse, CreateProjectRequest).
 * The backend calls the display name `title`; the UI calls it `name`
 * (project/color are legacy UI concepts), so the mapper converts.
 */

import type { Project, ProjectStatus } from "./types";

/** Wire response of every project endpoint (backend ProjectResponse). */
export interface ProjectResponse {
  id: string;
  userId: string;
  title: string;
  description: string | null;
  goalId: string | null;
  status: ProjectStatus;
  deadline: string | null;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

/** Body of POST /api/v1/projects (backend CreateProjectRequest). */
export interface CreateProjectRequest {
  title: string;
  description?: string | null;
  goalId?: string | null;
  deadline?: string | null;
}

/** Body of PUT /api/v1/projects/{id} (backend UpdateProjectRequest,
 *  amendment AC-014). Full-replace: explicit null clears a nullable
 *  field (goalId, deadline, description); absent or blank title keeps
 *  the existing one. */
export interface UpdateProjectRequest {
  title?: string;
  description?: string | null;
  goalId?: string | null;
  deadline?: string | null;
}

/** Map a backend response to the UI Project shape. The backend has no
 *  `color` (UI-only accent); server-loaded projects get a stable palette
 *  color derived from their id, so the accent never flickers across
 *  reloads. New projects keep their locally chosen color after creation. */
export function projectResponseToProject(response: ProjectResponse): Project {
  return {
    id: response.id,
    name: response.title,
    description: response.description,
    goalId: response.goalId,
    status: response.status,
    deadline: response.deadline,
    color: colorForId(response.id),
    completedAt: response.completedAt,
    createdAt: response.createdAt,
  };
}

const PROJECT_PALETTE = [
  "#8b5cf6",
  "#5b9dff",
  "#4cc38a",
  "#e88349",
  "#45b8ac",
  "#6d63f6",
];

function colorForId(id: string): string {
  let hash = 0;
  for (let i = 0; i < id.length; i += 1) {
    hash = (hash * 31 + id.charCodeAt(i)) >>> 0;
  }
  return PROJECT_PALETTE[hash % PROJECT_PALETTE.length];
}
