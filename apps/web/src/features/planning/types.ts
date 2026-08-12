/**
 * Planning types — mirror the backend contracts:
 * DailyTopThree (position 1–3, calendar date) and DailyPlan (capacity).
 * Dates are ISO calendar dates interpreted in the user's timezone (ADR-006).
 */

export interface TopThreeEntry {
  taskId: string;
  /** 1, 2, or 3 — unique per user and date (Daily Top 3 spec). */
  position: 1 | 2 | 3;
}

export interface DailyPlanSummary {
  /** Total estimated minutes planned for the day (Top 3 included). */
  plannedMinutes: number;
  /** Available focus capacity for the day, in minutes. */
  focusCapacityMinutes: number;
  /** Focus minutes already logged today. */
  focusCompletedMinutes: number;
}

export type PreviewState = "loading" | "error" | "empty" | null;
