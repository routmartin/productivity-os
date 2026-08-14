import { defineStore } from "pinia";
import { computed, ref } from "vue";

import { errorMessage } from "@/lib/api/errorMessages";
import { useMock } from "@/lib/mock";
import type { PreviewState } from "@/features/planning/types";
import { useProjectsStore } from "@/features/projects/store";
import type { Project } from "@/features/projects/types";
import { useTasksStore } from "@/features/tasks/store";
import type { Task } from "@/features/tasks/types";

import { goalsApi } from "./api";
import { goalResponseToGoal } from "./api-types";
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

/**
 * Goals collection for the Goals workspace (and the sidebar list).
 *
 * Mock mode (global `VITE_USE_MOCK_DATA=true` or `VITE_USE_MOCK_GOALS=true`)
 * keeps the milestone behavior for design review, and locally mirrors the
 * domain rules for complete/reopen (archiving/reactivating the goal's
 * projects). Real mode (default) talks to the Goal API; new goals are
 * created as DRAFT then activated when the dialog asked for an Active goal.
 */
export const USE_MOCK = useMock("GOALS");

export const useGoalsStore = defineStore("goals", () => {
  const goals = ref<Goal[]>(USE_MOCK ? [...mockGoals] : []);
  const status = ref<LoadStatus>("idle");
  const statusFilter = ref<GoalFilter>("ACTIVE");
  const previewEmpty = ref(false);
  /** Last failed mutation message (null when none). */
  const lastError = ref<string | null>(null);

  function clearError(): void {
    lastError.value = null;
  }

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

  /**
   * @param preview forces a UI state for design verification
   * (`?preview=loading|error|empty`) — mock mode only.
   */
  async function load(preview: PreviewState = null): Promise<void> {
    status.value = "loading";
    lastError.value = null;

    if (preview === "loading") return;

    if (USE_MOCK) {
      await delay(MOCK_LATENCY_MS);

      if (preview === "error") {
        status.value = "error";
        return;
      }

      previewEmpty.value = preview === "empty";
      status.value = "ready";
      return;
    }

    try {
      const list = await goalsApi.list();
      goals.value = list.map(goalResponseToGoal);
      status.value = "ready";
    } catch (error) {
      status.value = "error";
      lastError.value = errorMessage(error);
    }
  }

  function setFilter(filter: GoalFilter): void {
    statusFilter.value = filter;
  }

  /** Create a goal. Mock mode is immediate; real mode creates as DRAFT,
   *  then activates when the dialog asked for an Active goal. */
  function addGoal(draft: NewGoalDraft): Goal | null {
    lastError.value = null;

    if (USE_MOCK) {
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

    const activate = draft.status === "ACTIVE";
    goalsApi
      .create({
        title: draft.title,
        description: draft.description || null,
        deadline: draft.deadline,
      })
      .then((created) => (activate ? goalsApi.activate(created.id) : created))
      .then((created) => {
        goals.value.unshift(goalResponseToGoal(created));
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
    return null;
  }

  /** ACTIVE → COMPLETED. Mock mode mirrors the domain rule that the
   *  goal's active projects get archived. */
  function completeGoal(goalId: string): void {
    lastError.value = null;

    if (USE_MOCK) {
      const goal = goalById(goalId);
      if (!goal) return;
      goal.status = "COMPLETED";
      goal.completedAt = new Date().toISOString();
      for (const project of projectsStore.projects) {
        if (
          project.goalId === goalId &&
          (project.status === "ACTIVE" || project.status === "DRAFT")
        ) {
          project.status = "ARCHIVED";
        }
      }
      return;
    }

    goalsApi
      .complete(goalId)
      .then((updated) => {
        const live = goalById(goalId);
        if (live) Object.assign(live, goalResponseToGoal(updated));
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
  }

  /** COMPLETED → ACTIVE with the chosen archived projects reactivated. */
  function reopenGoal(goalId: string, projectIds: string[]): void {
    lastError.value = null;

    if (USE_MOCK) {
      const goal = goalById(goalId);
      if (!goal) return;
      goal.status = "ACTIVE";
      goal.completedAt = null;
      const reactivate = new Set(projectIds);
      for (const project of projectsStore.projects) {
        if (
          project.goalId === goalId &&
          project.status === "ARCHIVED" &&
          reactivate.has(project.id)
        ) {
          project.status = "ACTIVE";
        }
      }
      return;
    }

    goalsApi
      .reopening(goalId, { projectIds })
      .then((updated) => {
        const live = goalById(goalId);
        if (live) Object.assign(live, goalResponseToGoal(updated));
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
  }

  return {
    goals,
    status,
    statusFilter,
    visibleGoals,
    activeGoals,
    filterCounts,
    lastError,
    goalById,
    projectsForGoal,
    archivedProjectsForGoal,
    progressForGoal,
    projectCountsForGoal,
    recentActivityForGoal,
    load,
    setFilter,
    addGoal,
    completeGoal,
    reopenGoal,
    clearError,
  };
});
