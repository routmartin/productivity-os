/**
 * Task domain types — mirror the backend contract (apps/api task module):
 * TaskResponse, TaskStatus, Priority, Energy. Dates are ISO-8601 calendar
 * dates; timestamps are ISO-8601 UTC instants (ADR-005, ADR-006).
 */

export type TaskStatus =
  | "INBOX"
  | "PLANNED"
  | "IN_PROGRESS"
  | "COMPLETED"
  | "CANCELLED";

export type Priority = "LOW" | "MEDIUM" | "HIGH";

export type Energy = "LOW" | "MEDIUM" | "HIGH";

export interface Task {
  id: string;
  title: string;
  description: string | null;
  status: TaskStatus;
  priority: Priority | null;
  energy: Energy | null;
  estimatedMinutes: number | null;
  /** ISO calendar date (YYYY-MM-DD) or null. */
  dueDate: string | null;
  projectId: string | null;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
  scheduledTime?: string | null;
  recurrence?: string | null;
  pinned?: boolean;
}

/** Canonical Project and Goal types live in their own features; tasks
 * reference them by id, exactly like the backend. */
export const TASK_STATUS_LABELS: Record<TaskStatus, string> = {
  INBOX: "Inbox",
  PLANNED: "Planned",
  IN_PROGRESS: "In progress",
  COMPLETED: "Completed",
  CANCELLED: "Cancelled",
};

export const PRIORITY_LABELS: Record<Priority, string> = {
  LOW: "Low",
  MEDIUM: "Medium",
  HIGH: "High",
};

export const ENERGY_LABELS: Record<Energy, string> = {
  LOW: "Low energy",
  MEDIUM: "Medium energy",
  HIGH: "Deep work",
};

/** Fields accepted by the New Task dialog. Mirrors CreateTaskRequest on
 * the backend (title required, the rest optional). */
export interface NewTaskDraft {
  title: string;
  description: string;
  projectId: string | null;
  priority: Priority | null;
  dueDate: string | null;
  estimatedMinutes: number | null;
  scheduledTime?: string | null;
  recurrence?: string | null;
  /** UI-only (Tasks & Inbox UI spec §12.1): where a created task should
   * land. The backend create always yields INBOX; the store chains the
   * sanctioned plan/start transitions per destination. Undefined = INBOX.
   * Never sent to the API. */
  destination?: "INBOX" | "PLANNED" | "IN_PROGRESS";
}
