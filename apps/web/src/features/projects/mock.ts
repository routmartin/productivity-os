/**
 * Mock projects — canonical project list for the whole app (sidebar, tasks,
 * today, projects). Content follows the approved Projects UI spec; task
 * counts and progress are COMPUTED from the tasks store so the detail
 * panel's task lists always match the numbers.
 */
import type { Project } from "./types";

function daysAgo(days: number): string {
  return new Date(Date.now() - days * 86_400_000).toISOString();
}

export const mockProjects: Project[] = [
  {
    id: "proj-pos",
    name: "Productivity OS",
    description: "Build your personal productivity system.",
    goalId: "goal-dev",
    color: "#8b5cf6",
    status: "ACTIVE",
    createdAt: daysAgo(62),
    completedAt: null,
  },
  {
    id: "proj-mobile",
    name: "Mobile App",
    description: "Improve the mobile application experience.",
    goalId: "goal-dev",
    color: "#5b9dff",
    status: "ACTIVE",
    createdAt: daysAgo(45),
    completedAt: null,
  },
  {
    id: "proj-web",
    name: "Website Redesign",
    description: "Refresh the company website experience.",
    goalId: "goal-business",
    color: "#4cc38a",
    status: "ACTIVE",
    createdAt: daysAgo(30),
    completedAt: null,
  },
  {
    id: "proj-research",
    name: "Customer Research",
    description: "Interview ten potential users and synthesize the findings.",
    goalId: "goal-business",
    color: "#6d63f6",
    status: "ACTIVE",
    createdAt: daysAgo(20),
    completedAt: null,
  },
  {
    id: "proj-fitness",
    name: "Fitness Routine",
    description: "Three strength sessions a week, no excuses.",
    goalId: "goal-health",
    color: "#4cc38a",
    status: "ACTIVE",
    createdAt: daysAgo(35),
    completedAt: null,
  },
  {
    id: "proj-sleep",
    name: "Better Sleep",
    description: "Consistent wind-down and a hard screens-off time.",
    goalId: "goal-health",
    color: "#5b9dff",
    status: "ACTIVE",
    createdAt: daysAgo(25),
    completedAt: null,
  },
  {
    id: "proj-personal",
    name: "Personal",
    description: "Personal projects and life tasks.",
    goalId: null,
    color: "#e88349",
    status: "ACTIVE",
    createdAt: daysAgo(80),
    completedAt: null,
  },
  // — Needed to demonstrate the Completed and Archived filters —
  {
    id: "proj-home",
    name: "Home Server Setup",
    description: "Self-hosted NAS, backups, and media streaming.",
    goalId: null,
    color: "#45b8ac",
    status: "COMPLETED",
    createdAt: daysAgo(90),
    completedAt: daysAgo(12),
  },
  {
    id: "proj-portfolio",
    name: "Old Portfolio Site",
    description: "Previous personal website — superseded by the redesign.",
    goalId: "goal-portfolio",
    color: "#6a7180",
    status: "ARCHIVED",
    createdAt: daysAgo(120),
    completedAt: null,
  },
  {
    id: "proj-blog",
    name: "Personal Blog",
    description: "Writing archive from the portfolio era.",
    goalId: "goal-portfolio",
    color: "#6a7180",
    status: "ARCHIVED",
    createdAt: daysAgo(110),
    completedAt: null,
  },
];

/** Swatches offered by the New Project dialog. */
export const PROJECT_COLORS = [
  "#8b5cf6",
  "#5b9dff",
  "#4cc38a",
  "#e88349",
  "#45b8ac",
  "#6d63f6",
];
