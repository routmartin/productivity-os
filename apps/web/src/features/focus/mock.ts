import type { FocusSessionRecord } from "./types";

function minutesAgo(minutes: number): string {
  return new Date(Date.now() - minutes * 60_000).toISOString();
}

/**
 * Three sessions today total 2h 47m (the "Focus Today" figures in the
 * approved visual reference); the fourth record is yesterday's, so it shows
 * in history without affecting today's summary.
 */
export const mockFocusHistory: FocusSessionRecord[] = [
  {
    id: "fs-01",
    taskId: "task-01",
    taskTitle: "Finish authentication",
    projectName: "Productivity OS",
    goalName: "Become a better developer",
    priority: "HIGH",
    startedAt: minutesAgo(230),
    endedAt: minutesAgo(168),
    durationSeconds: 62 * 60,
  },
  {
    id: "fs-02",
    taskId: "task-02",
    taskTitle: "Build task dashboard",
    projectName: "Productivity OS",
    goalName: "Become a better developer",
    priority: "HIGH",
    startedAt: minutesAgo(320),
    endedAt: minutesAgo(265),
    durationSeconds: 55 * 60,
  },
  {
    id: "fs-03",
    taskId: "task-03",
    taskTitle: "Review API implementation",
    projectName: "Productivity OS",
    goalName: "Become a better developer",
    priority: "MEDIUM",
    startedAt: minutesAgo(420),
    endedAt: minutesAgo(370),
    durationSeconds: 50 * 60,
  },
  {
    id: "fs-04",
    taskId: "task-05",
    taskTitle: "Write documentation",
    projectName: "Productivity OS",
    goalName: "Become a better developer",
    priority: "LOW",
    startedAt: minutesAgo(60 * 26),
    endedAt: minutesAgo(60 * 26 - 27),
    durationSeconds: 27 * 60,
  },
];

/** Day-over-day focus trend shown on the Today rail (mock). */
export const mockFocusTrend = {
  deltaPercent: 22,
};
