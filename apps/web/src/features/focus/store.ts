import { defineStore } from "pinia";
import { computed, ref } from "vue";

import { errorMessage } from "@/lib/api/errorMessages";
import { useGoalsStore } from "@/features/goals/store";
import { useProjectsStore } from "@/features/projects/store";
import { useTasksStore } from "@/features/tasks/store";
import type { Task } from "@/features/tasks/types";

import { useMock } from "@/lib/mock";
import { focusApi } from "./api";
import type { FocusSessionResponse } from "./api-types";
import { mockFocusHistory } from "./mock";
import type { FocusSessionRecord, FocusState } from "./types";

/**
 * Focus session state for the Focus workspace and dock.
 *
 * Mock mode (global `VITE_USE_MOCK_DATA=true` or `VITE_USE_MOCK_FOCUS=true`)
 * keeps the milestone behavior for design review. Real mode (default)
 * talks to the Focus API: sessions start and end on the server, an active
 * session resumes after a page reload from its server-recorded start time,
 * and the history comes from GET /focus.
 */
const USE_MOCK = useMock("FOCUS");

const MOCK_LATENCY_MS = 500;

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export const useFocusStore = defineStore("focus", () => {
  const state = ref<FocusState>("idle");
  const selectedTaskId = ref<string | null>(null);
  const elapsedSeconds = ref(0);
  const sessionHistory = ref<FocusSessionRecord[]>([...mockFocusHistory]);
  /** Id of the server-side active session (real mode). */
  const activeSessionId = ref<string | null>(null);
  /** Last failed mutation message (null when none). */
  const lastError = ref<string | null>(null);

  function clearError(): void {
    lastError.value = null;
  }

  let timerInterval: ReturnType<typeof setInterval> | undefined;

  const tasksStore = useTasksStore();
  const projectsStore = useProjectsStore();
  const goalsStore = useGoalsStore();

  function stopTimer(): void {
    if (timerInterval) {
      clearInterval(timerInterval);
      timerInterval = undefined;
    }
  }

  function startTimer(): void {
    timerInterval = setInterval(() => {
      elapsedSeconds.value += 1;
    }, 1000);
  }

  /** Enrich a wire session with the local task/project/goal context the
   *  UI shows (projectName, goalName, priority). */
  function recordFromResponse(
    session: FocusSessionResponse,
  ): FocusSessionRecord {
    const task = tasksStore.taskById(session.taskId);
    const project = task?.projectId
      ? projectsStore.projectById(task.projectId)
      : undefined;
    const goal = project?.goalId
      ? goalsStore.goalById(project.goalId)
      : undefined;
    return {
      id: session.id,
      taskId: session.taskId,
      taskTitle: session.taskTitle ?? task?.title ?? "Deleted task",
      projectName: project?.name ?? null,
      goalName: goal?.title ?? null,
      priority: task?.priority ?? null,
      startedAt: session.startedAt,
      endedAt: session.endedAt ?? "",
      durationSeconds: session.durationSeconds ?? 0,
    };
  }

  const selectedTask = computed<Task | null>(() => {
    if (!selectedTaskId.value) return null;
    return tasksStore.taskById(selectedTaskId.value) ?? null;
  });

  const eligibleTasks = computed<Task[]>(() => {
    return tasksStore.tasks.filter(
      (t) => t.status === "IN_PROGRESS" || t.status === "PLANNED",
    );
  });

  const recentTasks = computed<Task[]>(() => {
    return eligibleTasks.value.slice(0, 6);
  });

  const formattedTime = computed(() => {
    const hrs = Math.floor(elapsedSeconds.value / 3600);
    const mins = Math.floor((elapsedSeconds.value % 3600) / 60);
    const secs = elapsedSeconds.value % 60;
    const pad = (n: number) => String(n).padStart(2, "0");
    return `${pad(hrs)}:${pad(mins)}:${pad(secs)}`;
  });

  const todaySummary = computed(() => {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todaySessions = sessionHistory.value.filter(
      (s) => new Date(s.startedAt) >= todayStart,
    );
    const totalSeconds = todaySessions.reduce(
      (sum, s) => sum + s.durationSeconds,
      0,
    );
    const totalMinutes = Math.floor(totalSeconds / 60);
    const hrs = Math.floor(totalMinutes / 60);
    const mins = totalMinutes % 60;
    const avgSeconds =
      todaySessions.length > 0 ? Math.floor(totalSeconds / todaySessions.length) : 0;
    const avgMinutes = Math.floor(avgSeconds / 60);
    return {
      formatted: hrs > 0 ? `${hrs}h ${mins}m` : `${mins}m`,
      sessions: todaySessions.length,
      avgMinutes,
    };
  });

  /**
   * Load the recorded history and resume an active session after a page
   * reload (spec edge case). Mock mode keeps the seeded history.
   */
  async function load(): Promise<void> {
    lastError.value = null;

    if (USE_MOCK) {
      await delay(MOCK_LATENCY_MS);
      return;
    }

    try {
      const [history, activeSession] = await Promise.all([
        focusApi.history(),
        // 404 with an empty body means "no active session" — not an error.
        focusApi.active().catch(() => null),
      ]);

      sessionHistory.value = history.map(recordFromResponse);

      if (activeSession) {
        activeSessionId.value = activeSession.id;
        selectedTaskId.value = activeSession.taskId;
        state.value = "active";
        elapsedSeconds.value = Math.max(
          0,
          Math.floor(
            (Date.now() - new Date(activeSession.startedAt).getTime()) / 1000,
          ),
        );
        startTimer();
      }
    } catch (error) {
      lastError.value = errorMessage(error);
    }
  }

  function selectTask(taskId: string | null) {
    selectedTaskId.value = taskId;
  }

  function startFocus() {
    if (!selectedTaskId.value) return;
    state.value = "active";
    elapsedSeconds.value = 0;
    startTimer();
    lastError.value = null;

    if (USE_MOCK) return;

    focusApi
      .start({ taskId: selectedTaskId.value })
      .then((started) => {
        activeSessionId.value = started.id;
      })
      .catch((error: unknown) => {
        // The server never started the session — stop the local timer.
        stopTimer();
        state.value = "idle";
        elapsedSeconds.value = 0;
        lastError.value = errorMessage(error);
      });
  }

  function pauseFocus() {
    state.value = "paused";
    stopTimer();
  }

  function resumeFocus() {
    state.value = "active";
    startTimer();
  }

  function stopFocus() {
    stopTimer();
    state.value = "completed";
    lastError.value = null;

    if (USE_MOCK) {
      const task = selectedTask.value;
      if (!task) return;

      const project = task.projectId
        ? projectsStore.projectById(task.projectId)
        : null;
      const goal = project?.goalId
        ? goalsStore.goalById(project.goalId)
        : null;

      const record: FocusSessionRecord = {
        id: `fs-local-${Date.now()}`,
        taskId: task.id,
        taskTitle: task.title,
        projectName: project?.name ?? null,
        goalName: goal?.title ?? null,
        priority: task.priority,
        startedAt: new Date(
          Date.now() - elapsedSeconds.value * 1000,
        ).toISOString(),
        endedAt: new Date().toISOString(),
        durationSeconds: elapsedSeconds.value,
      };
      sessionHistory.value.unshift(record);
      return;
    }

    const sessionId = activeSessionId.value;
    activeSessionId.value = null;
    if (!sessionId) {
      // Nothing recorded server-side — end the local session.
      doneFocus();
      return;
    }

    focusApi
      .end(sessionId)
      .then((ended) => {
        sessionHistory.value.unshift(recordFromResponse(ended));
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
        doneFocus();
      });
  }

  function doneFocus() {
    state.value = "idle";
    selectedTaskId.value = null;
    elapsedSeconds.value = 0;
    activeSessionId.value = null;
  }

  function formattedDuration(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    if (mins < 60) return `${mins}m`;
    const hrs = Math.floor(mins / 60);
    const rem = mins % 60;
    return rem > 0 ? `${hrs}h ${rem}m` : `${hrs}h`;
  }

  return {
    state,
    selectedTaskId,
    selectedTask,
    elapsedSeconds,
    formattedTime,
    sessionHistory,
    eligibleTasks,
    recentTasks,
    todaySummary,
    lastError,
    load,
    selectTask,
    startFocus,
    pauseFocus,
    resumeFocus,
    stopFocus,
    doneFocus,
    formattedDuration,
    clearError,
  };
});
