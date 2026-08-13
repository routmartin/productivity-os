import type {
  CalendarEvent,
  DailyPlanSummary,
  ScheduleEntry,
  TopThreeEntry,
} from "./types";

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

/**
 * Today's Schedule — timeline content mirrors the approved visual reference.
 * Task-linked rows open the task detail panel; breaks are informational.
 */
export const mockSchedule: ScheduleEntry[] = [
  {
    id: "sched-01",
    time: "09:00",
    title: "Finish authentication",
    meta: "Productivity OS · High Priority",
    durationMinutes: 90,
    tone: "accent",
    taskId: "task-01",
  },
  {
    id: "sched-02",
    time: "10:30",
    title: "Review API implementation",
    meta: "Productivity OS · Medium Priority",
    durationMinutes: 45,
    tone: "blue",
    taskId: "task-03",
  },
  {
    id: "sched-03",
    time: "12:00",
    title: "Lunch Break",
    meta: "Take a break and recharge",
    durationMinutes: 60,
    tone: "success",
    taskId: null,
  },
  {
    id: "sched-04",
    time: "14:00",
    title: "Build task dashboard",
    meta: "Productivity OS · High Priority",
    durationMinutes: 120,
    tone: "warning",
    taskId: "task-02",
  },
  {
    id: "sched-05",
    time: "16:00",
    title: "Write documentation",
    meta: "Productivity OS · Low Priority",
    durationMinutes: 60,
    tone: "neutral",
    taskId: "task-05",
  },
];

/** The selected day's event context under the Calendar week rail. */
export const mockCalendarEvent: CalendarEvent = {
  id: "event-01",
  timeLabel: "9:00 AM",
  title: "Meeting with Ben Johnson",
  detail: "Tomorrow 9:00 – 9:30 AM",
  provider: "Microsoft Teams",
  attendees: [
    { initials: "BJ", color: "#e88349" },
    { initials: "MK", color: "#5b9dff" },
    { initials: "AS", color: "#4cc38a" },
    { initials: "TR", color: "#8b6cff" },
  ],
  extraAttendees: 7,
};
