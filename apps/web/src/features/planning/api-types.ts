/**
 * Planning API contract types — mirror the backend exactly (apps/api
 * topthree + dailyplan modules). Dates are ISO calendar dates in the
 * user's timezone (ADR-006); the mapper converts wire shapes to the
 * UI types.
 */

import type { TopThreeEntry } from "./types";

/* ------------------------- Daily Top 3 ------------------------- */

/** Wire entry of GET /api/v1/daily-top-three/{date} (backend
 *  TopThreeResponse). `id` IS the selectionId used by reorder/remove. */
export interface TopThreeResponse {
  id: string;
  taskId: string | null;
  taskTitle: string | null;
  calendarDate: string;
  position: number;
  selectedAt: string;
  isCompleted: boolean;
  isDeleted: boolean;
  isCancelled: boolean;
}

/** Body of POST /api/v1/daily-top-three/{date} (SelectTaskRequest).
 *  Omit position to take the first free slot. */
export interface SelectTaskRequest {
  taskId: string;
  position?: number | null;
}

/** Body of PUT /api/v1/daily-top-three/{date}/{selectionId}/position. */
export interface ReorderRequest {
  position: number;
}

/** Map a wire entry to the UI TopThreeEntry, dropping deleted
 *  placeholders (taskId null) that past-date reads return. */
export function topThreeResponseToEntry(
  response: TopThreeResponse,
): TopThreeEntry | null {
  if (response.isDeleted || !response.taskId) return null;
  return {
    taskId: response.taskId,
    position: response.position as 1 | 2 | 3,
  };
}

/* ------------------------- Daily Plan ------------------------- */

/** Wire entry of GET /api/v1/daily-plan/{date} (DailyPlanResponse).
 *  `id` IS the planId used by remove. */
export interface DailyPlanResponse {
  id: string;
  taskId: string;
  taskTitle: string | null;
  calendarDate: string;
  remark: string | null;
  isDeleted: boolean;
}

/** Body of POST /api/v1/daily-plan/{date} (PlanTaskRequest). */
export interface PlanTaskRequest {
  taskId: string;
  remark?: string | null;
}

/** Body of PUT /api/v1/daily-plan/capacity/{date} (SetCapacityRequest). */
export interface SetCapacityRequest {
  hours: number;
}

/** Response of GET /api/v1/daily-plan/{date}/capacity (CapacityInfo). */
export interface CapacityInfo {
  capacityHours: number;
  plannedHours: number;
  overCapacity: boolean;
}