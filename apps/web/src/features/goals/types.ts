/**
 * Goal domain types — mirror the backend contract (apps/api goal module,
 * GoalResponse): lifecycle DRAFT → ACTIVE → COMPLETED → ARCHIVED, with
 * Completed → Active reopen. Deadline is an optional ISO calendar date.
 */
export type GoalStatus = "DRAFT" | "ACTIVE" | "COMPLETED" | "ARCHIVED";

export interface Goal {
  id: string;
  title: string;
  description: string | null;
  status: GoalStatus;
  /** ISO calendar date (YYYY-MM-DD) or null. */
  deadline: string | null;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export const GOAL_STATUS_LABELS: Record<GoalStatus, string> = {
  DRAFT: "Draft",
  ACTIVE: "Active",
  COMPLETED: "Completed",
  ARCHIVED: "Archived",
};

/** Fields accepted by the New Goal dialog. */
export interface NewGoalDraft {
  title: string;
  description: string;
  deadline: string | null;
  status: "DRAFT" | "ACTIVE";
}
