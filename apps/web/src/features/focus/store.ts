import { defineStore } from "pinia";
import { computed, ref } from "vue";

import { mockGoals } from "@/features/goals/mock";
import { mockProjects } from "@/features/projects/mock";
import { useTasksStore } from "@/features/tasks/store";
import type { Task } from "@/features/tasks/types";

import { mockFocusHistory } from "./mock";
import type { FocusSessionRecord, FocusState } from "./types";

export const useFocusStore = defineStore("focus", () => {
  const state = ref<FocusState>("idle");
  const selectedTaskId = ref<string | null>(null);
  const elapsedSeconds = ref(0);
  const sessionHistory = ref<FocusSessionRecord[]>([...mockFocusHistory]);

  let timerInterval: ReturnType<typeof setInterval> | undefined;

  const tasksStore = useTasksStore();

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

  function selectTask(taskId: string | null) {
    selectedTaskId.value = taskId;
  }

  function startFocus() {
    if (!selectedTaskId.value) return;
    state.value = "active";
    elapsedSeconds.value = 0;
    timerInterval = setInterval(() => {
      elapsedSeconds.value += 1;
    }, 1000);
  }

  function pauseFocus() {
    state.value = "paused";
    if (timerInterval) {
      clearInterval(timerInterval);
      timerInterval = undefined;
    }
  }

  function resumeFocus() {
    state.value = "active";
    timerInterval = setInterval(() => {
      elapsedSeconds.value += 1;
    }, 1000);
  }

  function stopFocus() {
    if (timerInterval) {
      clearInterval(timerInterval);
      timerInterval = undefined;
    }
    state.value = "completed";

    const task = selectedTask.value;
    if (!task) return;

    const project = task.projectId
      ? mockProjects.find((p) => p.id === task.projectId) ?? null
      : null;
    const goal =
      project?.goalId
        ? mockGoals.find((g) => g.id === project.goalId) ?? null
        : null;

    const record: FocusSessionRecord = {
      id: `fs-local-${Date.now()}`,
      taskId: task.id,
      taskTitle: task.title,
      projectName: project?.name ?? null,
      goalName: goal?.title ?? null,
      priority: task.priority,
      startedAt: new Date(Date.now() - elapsedSeconds.value * 1000).toISOString(),
      endedAt: new Date().toISOString(),
      durationSeconds: elapsedSeconds.value,
    };
    sessionHistory.value.unshift(record);
  }

  function doneFocus() {
    state.value = "idle";
    selectedTaskId.value = null;
    elapsedSeconds.value = 0;
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
    selectTask,
    startFocus,
    pauseFocus,
    resumeFocus,
    stopFocus,
    doneFocus,
    formattedDuration,
  };
});
