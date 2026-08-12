import type { FocusSessionRecord } from "./types";

function minutesAgo(minutes: number): string {
  return new Date(Date.now() - minutes * 60_000).toISOString();
}

export const mockFocusHistory: FocusSessionRecord[] = [
  {
    id: "fs-01",
    taskId: "task-01",
    taskTitle: "Finish authentication",
    projectName: "Productivity OS",
    goalName: "Become a better developer",
    priority: "HIGH",
    startedAt: minutesAgo(230),
    endedAt: minutesAgo(188),
    durationSeconds: 42 * 60,
  },
  {
    id: "fs-02",
    taskId: "task-02",
    taskTitle: "Build task dashboard",
    projectName: "Productivity OS",
    goalName: "Become a better developer",
    priority: "HIGH",
    startedAt: minutesAgo(310),
    endedAt: minutesAgo(279),
    durationSeconds: 31 * 60,
  },
  {
    id: "fs-03",
    taskId: "task-03",
    taskTitle: "Review API implementation",
    projectName: "Productivity OS",
    goalName: "Become a better developer",
    priority: "MEDIUM",
    startedAt: minutesAgo(400),
    endedAt: minutesAgo(346),
    durationSeconds: 54 * 60,
  },
  {
    id: "fs-04",
    taskId: "task-05",
    taskTitle: "Write documentation",
    projectName: "Productivity OS",
    goalName: "Become a better developer",
    priority: "LOW",
    startedAt: minutesAgo(510),
    endedAt: minutesAgo(483),
    durationSeconds: 27 * 60,
  },
];
