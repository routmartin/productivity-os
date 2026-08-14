/**
 * Goals API contract types — mirror the backend exactly
 * (apps/api goal module: GoalResponse, CreateGoalRequest,
 * ReopenGoalRequest). The UI Goal shape matches the wire shape
 * 1:1 (minus the owner id), so the mapper is trivial.
 */

import type { Goal, GoalStatus } from "./types";

/** Wire response of every goal endpoint (backend GoalResponse). */
export interface GoalResponse {
  id: string;
  userId: string;
  title: string;
  description: string | null;
  status: GoalStatus;
  deadline: string | null;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

/** Body of POST /api/v1/goals (backend CreateGoalRequest). */
export interface CreateGoalRequest {
  title: string;
  description?: string | null;
  deadline?: string | null;
}

/** Body of POST /api/v1/goals/{id}/reopening (backend ReopenGoalRequest).
 *  The archived projects to reactivate; empty list reopens just the goal. */
export interface ReopenGoalRequest {
  projectIds: string[];
}

/** Map a backend response to the UI Goal shape. */
export function goalResponseToGoal(response: GoalResponse): Goal {
  return {
    id: response.id,
    title: response.title,
    description: response.description,
    status: response.status,
    deadline: response.deadline,
    completedAt: response.completedAt,
    createdAt: response.createdAt,
    updatedAt: response.updatedAt,
  };
}
