/**
 * Mock goals — canonical goal list for the whole app. Covers every state
 * the spec calls out: active (with projects and projectless), draft,
 * completed (with archived projects for the reopen flow), and archived.
 * Progress is COMPUTED from project progress in the goals store.
 */
import type { Goal } from "./types";

function daysAgo(days: number): string {
  return new Date(Date.now() - days * 86_400_000).toISOString();
}

export const mockGoals: Goal[] = [
  {
    id: "goal-dev",
    title: "Become a better developer",
    description:
      "Build stronger backend, architecture, and system design skills.",
    status: "ACTIVE",
    deadline: null,
    completedAt: null,
    createdAt: daysAgo(70),
    updatedAt: daysAgo(2),
  },
  {
    id: "goal-business",
    title: "Build a sustainable side business",
    description: "Build and validate a profitable software product.",
    status: "ACTIVE",
    deadline: null,
    completedAt: null,
    createdAt: daysAgo(60),
    updatedAt: daysAgo(4),
  },
  {
    id: "goal-health",
    title: "Improve personal health",
    description: "Build consistent habits and improve overall health.",
    status: "ACTIVE",
    deadline: null,
    completedAt: null,
    createdAt: daysAgo(55),
    updatedAt: daysAgo(1),
  },
  {
    id: "goal-reading",
    title: "Read 20 books this year",
    description: "Mostly fiction, some craft. Evenings and weekends count.",
    status: "ACTIVE",
    deadline: "2026-12-31",
    completedAt: null,
    createdAt: daysAgo(40),
    updatedAt: daysAgo(6),
  },
  {
    id: "goal-korean",
    title: "Learn system design deeply",
    description:
      "Work through the classic literature and case studies before committing.",
    status: "DRAFT",
    deadline: null,
    completedAt: null,
    createdAt: daysAgo(5),
    updatedAt: daysAgo(5),
  },
  {
    id: "goal-portfolio",
    title: "Launch personal portfolio",
    description: "Ship a personal site worth sending to people.",
    status: "COMPLETED",
    deadline: null,
    completedAt: daysAgo(30),
    createdAt: daysAgo(120),
    updatedAt: daysAgo(30),
  },
  {
    id: "goal-old",
    title: "Old Personal Goals",
    description: "Goals from an earlier season — kept for the record.",
    status: "ARCHIVED",
    deadline: null,
    completedAt: null,
    createdAt: daysAgo(200),
    updatedAt: daysAgo(150),
  },
];
