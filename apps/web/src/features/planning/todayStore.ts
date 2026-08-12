import { defineStore } from "pinia";
import { computed, ref } from "vue";

import { mockTasks } from "@/features/tasks/mock";
import type { Task } from "@/features/tasks/types";

import { mockDailyPlan, mockTopThree } from "./mock";
import type { DailyPlanSummary, PreviewState, TopThreeEntry } from "./types";

export type LoadStatus = "idle" | "loading" | "ready" | "error";

const MOCK_LATENCY_MS = 700;

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const EMPTY_PLAN: DailyPlanSummary = {
  plannedMinutes: 0,
  focusCapacityMinutes: mockDailyPlan.focusCapacityMinutes,
  focusCompletedMinutes: 0,
};

/**
 * Aggregates everything the Today dashboard needs. Milestone 1 serves mock
 * data with realistic latency; Milestone 2 swaps `load()` internals for
 * real endpoints (daily plan, daily top three, tasks) without touching
 * the components.
 */
export const useTodayStore = defineStore("today", () => {
  const status = ref<LoadStatus>("idle");
  const topThree = ref<TopThreeEntry[]>([]);
  const plan = ref<DailyPlanSummary | null>(null);
  const tasks = ref<Task[]>([]);

  const topThreeIds = computed(
    () => new Set(topThree.value.map((e) => e.taskId)),
  );

  const plannedTasks = computed(() =>
    tasks.value.filter(
      (t) =>
        (t.status === "PLANNED" || t.status === "IN_PROGRESS") &&
        !topThreeIds.value.has(t.id),
    ),
  );

  const unplannedTasks = computed(() =>
    tasks.value.filter((t) => t.status === "INBOX"),
  );

  const recentTasks = computed(() =>
    tasks.value
      .filter((t) => t.status === "COMPLETED")
      .slice()
      .sort((a, b) => (b.completedAt ?? "").localeCompare(a.completedAt ?? ""))
      .slice(0, 4),
  );

  const taskById = computed(() => {
    const map = new Map<string, Task>();
    for (const task of tasks.value) map.set(task.id, task);
    return map;
  });

  /**
   * @param preview forces a UI state for design verification
   * (`?preview=loading|error|empty`); null performs a normal mock load.
   */
  async function load(preview: PreviewState = null): Promise<void> {
    status.value = "loading";

    if (preview === "loading") {
      return; // stay in the loading state for review
    }

    await delay(MOCK_LATENCY_MS);

    if (preview === "error") {
      status.value = "error";
      return;
    }

    if (preview === "empty") {
      topThree.value = [];
      plan.value = EMPTY_PLAN;
      tasks.value = [];
    } else {
      topThree.value = mockTopThree;
      plan.value = mockDailyPlan;
      tasks.value = mockTasks;
    }
    status.value = "ready";
  }

  return {
    status,
    topThree,
    plan,
    plannedTasks,
    unplannedTasks,
    recentTasks,
    taskById,
    load,
  };
});
