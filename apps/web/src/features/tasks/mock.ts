/**
 * Realistic mock workspace for Milestone 1 — a solo builder shipping the
 * Productivity OS MVP. Aligned with the approved visual reference and
 * replaced by real API calls in Milestone 2; shapes match backend contracts.
 *
 * Timestamps are authored relative to "now" at module load so relative
 * times ("2h ago") always read naturally in the browser.
 */
import { toISODate } from "@/lib/utils/date";

import type { GoalRef, ProjectRef, Task } from "./types";

function hoursAgo(hours: number): string {
  return new Date(Date.now() - hours * 3_600_000).toISOString();
}

function daysFromNow(days: number): string {
  const date = new Date();
  date.setDate(date.getDate() + days);
  return toISODate(date);
}

export const mockProjects: ProjectRef[] = [
  {
    id: "proj-pos",
    name: "Productivity OS",
    color: "#8b5cf6",
    goalId: "goal-mrr",
  },
  {
    id: "proj-mobile",
    name: "Mobile App",
    color: "#5b9dff",
    goalId: "goal-mrr",
  },
  {
    id: "proj-web",
    name: "Website Redesign",
    color: "#4cc38a",
    goalId: "goal-dev",
  },
  {
    id: "proj-personal",
    name: "Personal",
    color: "#e88349",
    goalId: "goal-health",
  },
];

export const mockGoals: GoalRef[] = [
  { id: "goal-dev", name: "Become a better developer" },
  { id: "goal-mrr", name: "Build $10k MRR" },
  { id: "goal-health", name: "Health & Fitness" },
];

export const mockTasks: Task[] = [
  // — Today's Top 3 —
  {
    id: "task-01",
    title: "Finish authentication",
    description:
      "Close out the auth slice: verify refresh-token rotation on /api/v1/auth/refresh, confirm the cookie is scoped to /api/v1/auth, and finish the login rate-limiter tests.",
    status: "IN_PROGRESS",
    priority: "HIGH",
    energy: "HIGH",
    estimatedMinutes: 90,
    dueDate: daysFromNow(0),
    projectId: "proj-pos",
    completedAt: null,
    createdAt: hoursAgo(52),
    updatedAt: hoursAgo(2),
  },
  {
    id: "task-02",
    title: "Build task dashboard",
    description:
      "First frontend milestone: login screen, three-zone app shell, and the Today dashboard with realistic mock data. Dark-first, calm, no visual noise.",
    status: "PLANNED",
    priority: "HIGH",
    energy: "MEDIUM",
    estimatedMinutes: 120,
    dueDate: daysFromNow(0),
    projectId: "proj-pos",
    completedAt: null,
    createdAt: hoursAgo(30),
    updatedAt: hoursAgo(5),
  },
  {
    id: "task-03",
    title: "Review API implementation",
    description:
      "Self-review the daily-plan vertical slice against the spec before invoking the reviewer: capacity rollover, planned-date immutability, error codes.",
    status: "PLANNED",
    priority: "MEDIUM",
    energy: "MEDIUM",
    estimatedMinutes: 45,
    dueDate: daysFromNow(0),
    projectId: "proj-pos",
    completedAt: null,
    createdAt: hoursAgo(28),
    updatedAt: hoursAgo(6),
  },

  // — Planned today —
  {
    id: "task-04",
    title: "Fix validation",
    description:
      "Trim whitespace before validating email, disable submit while pending, and surface the 401 invalid_credentials error inline instead of a generic message.",
    status: "PLANNED",
    priority: "HIGH",
    energy: "MEDIUM",
    estimatedMinutes: 45,
    dueDate: daysFromNow(0),
    projectId: "proj-pos",
    completedAt: null,
    createdAt: hoursAgo(20),
    updatedAt: hoursAgo(8),
  },
  {
    id: "task-05",
    title: "Write documentation",
    description:
      "Short completion report for the auth + task slice: files changed, acceptance criteria status, deviations, follow-ups.",
    status: "PLANNED",
    priority: "LOW",
    energy: "LOW",
    estimatedMinutes: 90,
    dueDate: daysFromNow(1),
    projectId: "proj-pos",
    completedAt: null,
    createdAt: hoursAgo(26),
    updatedAt: hoursAgo(26),
  },
  {
    id: "task-06",
    title: "Review database schema",
    description:
      "Check the Flyway migrations against the domain model: indexes, uniqueness constraints, timestamptz coverage.",
    status: "PLANNED",
    priority: "MEDIUM",
    energy: "MEDIUM",
    estimatedMinutes: 60,
    dueDate: daysFromNow(1),
    projectId: "proj-pos",
    completedAt: null,
    createdAt: hoursAgo(18),
    updatedAt: hoursAgo(18),
  },
  {
    id: "task-07",
    title: "Update landing page",
    description:
      "Refresh the hero copy and swap in the new Today dashboard screenshot.",
    status: "PLANNED",
    priority: "LOW",
    energy: "LOW",
    estimatedMinutes: 60,
    dueDate: daysFromNow(3),
    projectId: "proj-web",
    completedAt: null,
    createdAt: hoursAgo(40),
    updatedAt: hoursAgo(40),
  },
  {
    id: "task-08",
    title: "Prepare for sprint review",
    description:
      "Demo script: login → shell → Today. Note known limitations and milestone 2 scope.",
    status: "PLANNED",
    priority: "MEDIUM",
    energy: "MEDIUM",
    estimatedMinutes: 30,
    dueDate: daysFromNow(4),
    projectId: "proj-mobile",
    completedAt: null,
    createdAt: hoursAgo(44),
    updatedAt: hoursAgo(44),
  },

  // — Unplanned (inbox) —
  {
    id: "task-09",
    title: "Check emails",
    description: null,
    status: "INBOX",
    priority: "LOW",
    energy: "LOW",
    estimatedMinutes: 15,
    dueDate: null,
    projectId: "proj-personal",
    completedAt: null,
    createdAt: hoursAgo(9),
    updatedAt: hoursAgo(9),
  },
  {
    id: "task-10",
    title: "Respond to messages",
    description: null,
    status: "INBOX",
    priority: "LOW",
    energy: "LOW",
    estimatedMinutes: 20,
    dueDate: null,
    projectId: "proj-personal",
    completedAt: null,
    createdAt: hoursAgo(7),
    updatedAt: hoursAgo(7),
  },

  // — More captured inbox items —
  {
    id: "task-15",
    title: "Read ADR-004 on auth isolation",
    description: null,
    status: "INBOX",
    priority: "MEDIUM",
    energy: "LOW",
    estimatedMinutes: 20,
    dueDate: null,
    projectId: null,
    completedAt: null,
    createdAt: hoursAgo(9),
    updatedAt: hoursAgo(9),
  },
  {
    id: "task-16",
    title: "Refactor task repository queries",
    description:
      "Extract the user-scoped finders into a single place; the controller review noted duplication between active and deleted listing.",
    status: "INBOX",
    priority: "MEDIUM",
    energy: "MEDIUM",
    estimatedMinutes: 45,
    dueDate: null,
    projectId: null,
    completedAt: null,
    createdAt: hoursAgo(14),
    updatedAt: hoursAgo(14),
  },
  {
    id: "task-17",
    title: "Update OpenAPI annotations",
    description: null,
    status: "INBOX",
    priority: "LOW",
    energy: "LOW",
    estimatedMinutes: 25,
    dueDate: null,
    projectId: null,
    completedAt: null,
    createdAt: hoursAgo(30),
    updatedAt: hoursAgo(30),
  },
  {
    id: "task-18",
    title: "Plan next sprint scope",
    description:
      "Draft the milestone 2 slice list: inbox triage, task lifecycle actions, and connecting the real login endpoint.",
    status: "INBOX",
    priority: "MEDIUM",
    energy: "MEDIUM",
    estimatedMinutes: 30,
    dueDate: null,
    projectId: null,
    completedAt: null,
    createdAt: hoursAgo(46),
    updatedAt: hoursAgo(46),
  },
  {
    id: "task-19",
    title: "Buy new monitor",
    description: null,
    status: "INBOX",
    priority: "LOW",
    energy: "LOW",
    estimatedMinutes: 15,
    dueDate: null,
    projectId: "proj-personal",
    completedAt: null,
    createdAt: hoursAgo(50),
    updatedAt: hoursAgo(50),
  },

  // — Recently completed —
  {
    id: "task-11",
    title: "Set up database",
    description: null,
    status: "COMPLETED",
    priority: "MEDIUM",
    energy: "MEDIUM",
    estimatedMinutes: 40,
    dueDate: daysFromNow(0),
    projectId: "proj-pos",
    completedAt: hoursAgo(2),
    createdAt: hoursAgo(50),
    updatedAt: hoursAgo(2),
  },
  {
    id: "task-12",
    title: "Configure Vite dev proxy",
    description: null,
    status: "COMPLETED",
    priority: "LOW",
    energy: "LOW",
    estimatedMinutes: 15,
    dueDate: null,
    projectId: "proj-pos",
    completedAt: hoursAgo(5),
    createdAt: hoursAgo(27),
    updatedAt: hoursAgo(5),
  },
  {
    id: "task-13",
    title: "Triage inbox to zero",
    description: null,
    status: "COMPLETED",
    priority: "LOW",
    energy: "LOW",
    estimatedMinutes: 20,
    dueDate: null,
    projectId: null,
    completedAt: hoursAgo(21),
    createdAt: hoursAgo(48),
    updatedAt: hoursAgo(21),
  },
  {
    id: "task-14",
    title: "Review daily plan slice diff",
    description: null,
    status: "COMPLETED",
    priority: "MEDIUM",
    energy: "MEDIUM",
    estimatedMinutes: 40,
    dueDate: null,
    projectId: "proj-pos",
    completedAt: hoursAgo(27),
    createdAt: hoursAgo(52),
    updatedAt: hoursAgo(27),
  },
];

export function findTaskById(id: string): Task | undefined {
  return mockTasks.find((task) => task.id === id);
}

export function findProjectById(id: string | null): ProjectRef | undefined {
  return mockProjects.find((project) => project.id === id);
}

export function findGoalById(id: string | null): GoalRef | undefined {
  return mockGoals.find((goal) => goal.id === id);
}

/** Goal a task rolls up to, via its project. */
export function goalForTask(task: Task): GoalRef | undefined {
  const project = findProjectById(task.projectId);
  return findGoalById(project?.goalId ?? null);
}
