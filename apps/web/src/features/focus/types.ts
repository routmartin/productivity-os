export type FocusState = "idle" | "active" | "paused" | "completed";

export interface FocusSessionRecord {
  id: string;
  taskId: string;
  taskTitle: string;
  projectName: string | null;
  goalName: string | null;
  priority: string | null;
  startedAt: string;
  endedAt: string;
  durationSeconds: number;
}
