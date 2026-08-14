/**
 * Tasks API contract types — mirror the backend exactly
 * (apps/api task module: TaskResponse, CreateTaskRequest,
 * AssignProjectRequest). Field names match the serialized JSON
 * (ADR-005); the mapper converts wire shapes to the UI Task type.
 */

import type { Energy, Priority, Task, TaskStatus } from "./types";

/** Wire response of every task endpoint (backend TaskResponse). */
export interface TaskResponse {
  id: string;
  ownerId: string;
  title: string;
  description: string | null;
  dueDate: string | null;
  priority: Priority | null;
  energy: Energy | null;
  estimatedDurationMinutes: number | null;
  status: TaskStatus;
  completedAt: string | null;
  deletedAt: string | null;
  projectId: string | null;
  createdAt: string;
  updatedAt: string;
}

/** Body of POST /api/v1/tasks (backend CreateTaskRequest). */
export interface CreateTaskRequest {
  title: string;
  description?: string | null;
  dueDate?: string | null;
  priority?: Priority | null;
  energy?: Energy | null;
  estimatedDurationMinutes?: number | null;
}

/** Body of PUT /api/v1/tasks/{id} (backend UpdateTaskRequest, amendment
 *  AC-012). Full-replace: explicit null clears a nullable field; absent
 *  or blank title keeps the existing one. */
export interface UpdateTaskRequest {
  title?: string;
  description?: string | null;
  dueDate?: string | null;
  priority?: Priority | null;
  energy?: Energy | null;
  estimatedDurationMinutes?: number | null;
}

/** Body of PUT /api/v1/tasks/{id}/project (backend AssignProjectRequest).
 *  A null projectId unassigns the task. */
export interface AssignProjectRequest {
  projectId: string | null;
}

/** Map a backend response to the UI Task shape. Fields the backend does
 *  not carry (scheduledTime, recurrence) are dropped — they are UI-only
 *  for now and get reported, not silently invented (spec Rule 10). */
export function taskResponseToTask(response: TaskResponse): Task {
  return {
    id: response.id,
    title: response.title,
    description: response.description,
    status: response.status,
    priority: response.priority,
    energy: response.energy,
    estimatedMinutes: response.estimatedDurationMinutes,
    dueDate: response.dueDate,
    projectId: response.projectId,
    completedAt: response.completedAt,
    createdAt: response.createdAt,
    updatedAt: response.updatedAt,
  };
}
