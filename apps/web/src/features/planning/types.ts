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

/**
 * Today's Schedule — a visual timeline entry. UI-milestone mock shape; the
 * real schedule is derived from the daily plan in a later milestone.
 */
export type ScheduleTone =
  | "accent"
  | "blue"
  | "success"
  | "warning"
  | "neutral";

export interface ScheduleEntry {
  id: string;
  /** Wall-clock start time label, e.g. "09:00". */
  time: string;
  title: string;
  /** Secondary line, e.g. "Productivity OS · High Priority". */
  meta: string;
  durationMinutes: number;
  tone: ScheduleTone;
  /** Linked task — clicking the row opens its detail panel (null for breaks). */
  taskId: string | null;
}

/** Event context shown under the week rail in the Calendar panel. */
export interface CalendarEventAttendee {
  initials: string;
  color: string;
}

export interface CalendarEvent {
  id: string;
  /** e.g. "9:00 AM". */
  timeLabel: string;
  title: string;
  /** e.g. "Tomorrow 9:00 – 9:30 AM". */
  detail: string;
  /** e.g. "Microsoft Teams". */
  provider: string;
  attendees: CalendarEventAttendee[];
  extraAttendees: number;
}
