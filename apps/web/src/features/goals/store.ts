import { defineStore } from "pinia";
import { computed, ref } from "vue";

import type { PreviewState } from "@/features/planning/types";
import { useProjectsStore } from "@/features/projects/store";
import type { Project } from "@/features/projects/types";
import { useTasksStore } from "@/features/tasks/store";
import type { Task } from "@/features/tasks/types";

import { mockGoals } from "./mock";
import type { Goal, NewGoalDraft } from "./types";

export type LoadStatus = "idle" | "loading" | "ready" | "error";

/** UI filters. Draft goals surface inside the Active view (with a Draft
 * pill) — they are defined but not yet pursued (Goal Management spec). */
export type GoalFilter = "ACTIVE" | "COMPLETED" | "ARCHIVED";

export const GOAL_FILTER_LABELS: Record<GoalFilter, string> = {
  ACTIVE: "Active",
  COMPLETED: "Completed",
  ARCHIVED: "Archived",
};

const MOCK_LATENCY_MS = 550;

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export const useGoalsStore = defineStore("goals", () => {
  const goals = ref<Goal[]>([...mockGoals]);
  const status = ref<LoadStatus>("idle");
  const statusFilter = ref<GoalFilter>("ACTIVE");
  const previewEmpty = ref(false);

  const projectsStore = useProjectsStore();
  const tasksStore = useTasksStore();

  function goalById(id: string): Goal | undefined {
    return goals.value.find((goal) => goal.id === id);
  }

  /** All projects linked to a goal (any status). */
  function projectsForGoal(goalId: string): Project[] {
    return projectsStore.projects.filter(
      (project) => project.goalId === goalId,
    );
  }

  /** Projects archived with a completed goal — candidates for the reopen
   * reactivation choice. */
  function archivedProjectsForGoal(goalId: string): Project[] {
    return projectsForGoal(goalId).filter(
      (project) => project.status === "ARCHIVED",
    );
  }

  /** Mean of the goal's countable project progresses, or null when the
   * goal has no projects (a projectless goal stays valid). */
  function progressForGoal(goalId: string): number | null {
    const projects = projectsForGoal(goalId).filter(
      (p) => p.status !== "ARCHIVED",
    );
    if (projects.length === 0) return null;
    const sum = projects.reduce(
      (acc, p) => acc + projectsStore.statsForProject(p.id).progress,
      0,
    );
    return Math.round(sum / projects.length);
  }

  function projectCountsForGoal(goalId: string): {
    active: number;
    completed: number;
  } {
    const projects = projectsForGoal(goalId);
    return {
      active: projects.filter(
        (p) => p.status === "ACTIVE" || p.status === "DRAFT",
      ).length,
      completed: projects.filter((p) => p.status === "COMPLETED").length,
    };
  }

  /** Recently completed tasks across the goal's projects. */
  function recentActivityForGoal(goalId: string): Task[] {
    const projectIds = new Set(projectsForGoal(goalId).map((p) => p.id));
    return tasksStore.tasks
      .filter(
        (task) =>
          task.status === "COMPLETED" && projectIds.has(task.projectId ?? ""),
      )
      .slice()
      .sort((a, b) => (b.completedAt ?? "").localeCompare(a.completedAt ?? ""))
      .slice(0, 3);
  }

  const filterCounts = computed<Record<GoalFilter, number>>(() => ({
    ACTIVE: goals.value.filter(
      (g) => g.status === "ACTIVE" || g.status === "DRAFT",
    ).length,
    COMPLETED: goals.value.filter((g) => g.status === "COMPLETED").length,
    ARCHIVED: goals.value.filter((g) => g.status === "ARCHIVED").length,
  }));

  const visibleGoals = computed(() => {
    if (previewEmpty.value) return [];
    if (statusFilter.value === "ACTIVE") {
      return goals.value.filter(
        (g) => g.status === "ACTIVE" || g.status === "DRAFT",
      );
    }
    return goals.value.filter((g) => g.status === statusFilter.value);
  });

  /** Sidebar shows pursued goals — drafts stay out until activated. */
  const activeGoals = computed(() =>
    goals.value.filter((g) => g.status === "ACTIVE"),
  );

  async function load(preview: PreviewState = null): Promise<void> {
    status.value = "loading";

    if (preview === "loading") return;

    await delay(MOCK_LATENCY_MS);

    if (preview === "error") {
      status.value = "error";
      return;
    }

    previewEmpty.value = preview === "empty";
    status.value = "ready";
  }

  function setFilter(filter: GoalFilter): void {
    statusFilter.value = filter;
  }

  function addGoal(draft: NewGoalDraft): Goal {
    const now = new Date().toISOString();
    const goal: Goal = {
      id: `goal-local-${Date.now()}`,
      title: draft.title,
      description: draft.description || null,
      status: draft.status,
      deadline: draft.deadline,
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    };
    goals.value.unshift(goal);
    return goal;
  }

  return {
    goals,
    status,
    statusFilter,
    visibleGoals,
    activeGoals,
    filterCounts,
    goalById,
    projectsForGoal,
    archivedProjectsForGoal,
    progressForGoal,
    projectCountsForGoal,
    recentActivityForGoal,
    load,
    setFilter,
    addGoal,
  };
});
