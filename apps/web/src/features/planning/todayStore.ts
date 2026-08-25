import { defineStore } from "pinia";
import { computed, ref } from "vue";

import { errorMessage } from "@/lib/api/errorMessages";
import { useMock } from "@/lib/mock";
import { tasksApi } from "@/features/tasks/api";
import { taskResponseToTask } from "@/features/tasks/api-types";
import type { Task } from "@/features/tasks/types";

import { planningApi, todayISODate } from "./api";
import {
  topThreeResponseToEntry,
  type TopThreeResponse,
} from "./api-types";
import { mockDailyPlan, mockSchedule, mockTopThree } from "./mock";
import { mockTasks } from "@/features/tasks/mock";
import type { DailyPlanSummary, PreviewState, ScheduleEntry, TopThreeEntry } from "./types";

export type LoadStatus = "idle" | "loading" | "ready" | "error";

const MOCK_LATENCY_MS = 700;

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const EMPTY_PLAN: DailyPlanSummary = {
  plannedMinutes: 0,
  // Backend default capacity is 6 hours when no row exists
  // (DailyPlanService.getCapacity) — not mock data.
  focusCapacityMinutes: 6 * 60,
  focusCompletedMinutes: 0,
};

/**
 * Aggregates everything the Today dashboard needs.
 *
 * Mock mode (global `VITE_USE_MOCK_DATA=true` or `VITE_USE_MOCK_PLANNING=true`)
 * keeps the milestone behavior for design review. Real mode (default)
 * loads the daily top three, the daily plan, its capacity, and the first
 * page of tasks from the backend, bucketing "today" in the user's profile
 * timezone (ADR-006).
 */
const USE_MOCK = useMock("PLANNING");

export const useTodayStore = defineStore("today", () => {
  const status = ref<LoadStatus>("idle");
  const topThree = ref<TopThreeEntry[]>([]);
  const plan = ref<DailyPlanSummary | null>(null);
  const schedule = ref<ScheduleEntry[]>([]);
  const tasks = ref<Task[]>([]);
  /** Last failed load message (null when none). */
  const lastError = ref<string | null>(null);

  function clearError(): void {
    lastError.value = null;
  }

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

  const UNPLANNED_DISPLAY_LIMIT = 5;

  /** Today shows the freshest captures only — the full list lives in Inbox. */
  const unplannedTasks = computed(() =>
    tasks.value
      .filter((t) => t.status === "INBOX")
      .slice()
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
      .slice(0, UNPLANNED_DISPLAY_LIMIT),
  );

  const unplannedExtraCount = computed(() =>
    Math.max(
      tasks.value.filter((t) => t.status === "INBOX").length -
        UNPLANNED_DISPLAY_LIMIT,
      0,
    ),
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
   * (`?preview=loading|error|empty`) — mock mode only.
   */
  async function load(preview: PreviewState = null): Promise<void> {
    status.value = "loading";
    lastError.value = null;

    if (preview === "loading") {
      return; // stay in the loading state for review
    }

    if (USE_MOCK) {
      await delay(MOCK_LATENCY_MS);

      if (preview === "error") {
        status.value = "error";
        return;
      }

      if (preview === "empty") {
        topThree.value = [];
        plan.value = EMPTY_PLAN;
        schedule.value = [];
        tasks.value = [];
      } else {
        topThree.value = mockTopThree;
        plan.value = mockDailyPlan;
        schedule.value = mockSchedule;
        tasks.value = mockTasks;
      }
      status.value = "ready";
      return;
    }

    try {
      const date = todayISODate();
      const [topThreeResponse, planEntries, capacity, taskList] =
        await Promise.all([
          planningApi.topThree(date),
          planningApi.dailyPlan(date),
          planningApi.capacity(date),
          tasksApi.list(),
        ]);

      topThree.value = topThreeResponse
        .map(topThreeResponseToEntry)
        .filter((entry): entry is TopThreeEntry => entry !== null);

      tasks.value = taskList.map(taskResponseToTask);

      const taskByIdMap = new Map(tasks.value.map((t) => [t.id, t]));
      const plannedMinutes = planEntries
        .filter((entry) => !entry.isDeleted)
        .reduce((sum, entry) => {
          const task = taskByIdMap.get(entry.taskId);
          return sum + (task?.estimatedMinutes ?? 0);
        }, 0);

      plan.value = {
        plannedMinutes,
        focusCapacityMinutes: capacity.capacityHours * 60,
        // Computed from focus sessions once those load (plan 002 Step 7).
        focusCompletedMinutes: 0,
      };

      // Today's schedule = the REAL daily plan entries. The backend has no
      // wall-clock times yet, so entries render without a time label
      // (mock mode keeps the timed mockSchedule for design review).
      schedule.value = planEntries
        .filter((entry) => !entry.isDeleted)
        .map((entry) => {
          const task = taskByIdMap.get(entry.taskId);
          return {
            id: entry.id,
            time: null,
            title: task?.title ?? "Planned task",
            meta: task?.priority ? `Priority ${task.priority}` : "Planned",
            durationMinutes: task?.estimatedMinutes ?? 0,
            tone: "accent" as const,
            taskId: entry.taskId,
          };
        });
      status.value = "ready";
    } catch (error) {
      status.value = "error";
      lastError.value = errorMessage(error);
    }
  }

  /** Selection IDs per task — needed for remove (backend key). */
  const selectionIds = ref<Map<string, string>>(new Map());

  function isInTopThree(taskId: string): boolean {
    return topThree.value.some((e) => e.taskId === taskId);
  }

  /** Add a task to today's Top 3 (first free slot). */
  async function selectForTopThree(taskId: string): Promise<void> {
    if (topThree.value.length >= 3) return;
    lastError.value = null;

    if (USE_MOCK) {
      const pos = ([1, 2, 3] as const).find(
        (p) => !topThree.value.some((e) => e.position === p),
      );
      if (pos) topThree.value.push({ taskId, position: pos });
      return;
    }

    try {
      const date = todayISODate();
      const response: TopThreeResponse = await planningApi.select(date, { taskId });
      selectionIds.value.set(response.id, taskId);
      const entry = topThreeResponseToEntry(response);
      if (entry) {
        topThree.value = [...topThree.value, entry];
      }
    } catch (error) {
      lastError.value = errorMessage(error);
    }
  }

  /** Remove a task from today's Top 3. */
  async function removeFromTopThree(taskId: string): Promise<void> {
    lastError.value = null;

    if (USE_MOCK) {
      topThree.value = topThree.value.filter((e) => e.taskId !== taskId);
      return;
    }

    try {
      const date = todayISODate();
      // Find the selectionId for this taskId
      let foundId: string | undefined;
      for (const [sid, tid] of selectionIds.value) {
        if (tid === taskId) { foundId = sid; break; }
      }
      // If not in our map, find from current topThree entries
      if (!foundId) {
        // Re-fetch to get selection IDs
        const responses = await planningApi.topThree(date);
        for (const r of responses) {
          if (r.taskId === taskId) { foundId = r.id; break; }
        }
      }
      if (!foundId) return;
      await planningApi.remove(date, foundId);
      selectionIds.value.delete(foundId);
      topThree.value = topThree.value.filter((e) => e.taskId !== taskId);
    } catch (error) {
      lastError.value = errorMessage(error);
    }
  }

  return {
    status,
    topThree,
    plan,
    schedule,
    plannedTasks,
    unplannedTasks,
    unplannedExtraCount,
    recentTasks,
    taskById,
    lastError,
    load,
    clearError,
    isInTopThree,
    selectForTopThree,
    removeFromTopThree,
  };
});
