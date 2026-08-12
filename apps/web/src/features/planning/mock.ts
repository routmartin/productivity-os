import type { DailyPlanSummary, TopThreeEntry } from "./types";

/** Today's Top 3 — references tasks from the tasks feature mock. */
export const mockTopThree: TopThreeEntry[] = [
  { taskId: "task-01", position: 1 },
  { taskId: "task-02", position: 2 },
  { taskId: "task-03", position: 3 },
];

/**
 * Today is deliberately over-planned (540m planned vs 372m of focus
 * capacity ≈ 45% over) so the AI briefing has something meaningful to
 * say — the situation the product's planning intelligence exists for.
 */
export const mockDailyPlan: DailyPlanSummary = {
  plannedMinutes: 540,
  focusCapacityMinutes: 372,
  focusCompletedMinutes: 0,
};
