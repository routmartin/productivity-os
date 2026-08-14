/**
 * Focus API contract types — mirror the backend exactly (apps/api focus
 * module: FocusSessionResponse, StartFocusRequest). There is no status
 * enum: a session is active when `endedAt` is null / `isActive` true.
 */

/** Wire response of every focus endpoint (FocusSessionResponse). */
export interface FocusSessionResponse {
  id: string;
  taskId: string;
  taskTitle: string | null;
  startedAt: string;
  endedAt: string | null;
  durationSeconds: number | null;
  configuredDurationSeconds: number | null;
  note: string | null;
  isActive: boolean;
}

/** Body of POST /api/v1/focus (StartFocusRequest). */
export interface StartFocusRequest {
  taskId: string;
  configuredDurationSeconds?: number | null;
  note?: string | null;
}
