/**
 * Project domain types — mirror the backend contract (apps/api project
 * module): ProjectStatus lifecycle DRAFT → ACTIVE → COMPLETED → ARCHIVED.
 */
export type ProjectStatus = "DRAFT" | "ACTIVE" | "COMPLETED" | "ARCHIVED";

export interface Project {
  id: string;
  name: string;
  description: string | null;
  /** Zero-or-one goal (Goal → Project → Task). */
  goalId: string | null;
  /** Small identifying accent color. */
  color: string;
  status: ProjectStatus;
  createdAt: string;
  completedAt: string | null;
}

export const PROJECT_STATUS_LABELS: Record<ProjectStatus, string> = {
  DRAFT: "Draft",
  ACTIVE: "Active",
  COMPLETED: "Completed",
  ARCHIVED: "Archived",
};

/** Fields accepted by the New Project dialog (name required, rest optional). */
export interface NewProjectDraft {
  name: string;
  description: string;
  goalId: string | null;
  color: string;
}
