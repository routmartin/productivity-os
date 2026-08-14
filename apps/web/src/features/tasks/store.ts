import { defineStore } from "pinia";
import { computed, ref } from "vue";

import { errorMessage } from "@/lib/api/errorMessages";
import { useMock } from "@/lib/mock";
import type { PreviewState } from "@/features/planning/types";

import { tasksApi } from "./api";
import { taskResponseToTask } from "./api-types";
import { mockTasks } from "./mock";
import type { NewTaskDraft, Task, TaskStatus } from "./types";

export type LoadStatus = "idle" | "loading" | "ready" | "error";

export type TaskStatusFilter =
  | "ALL"
  | "INBOX"
  | "PLANNED"
  | "IN_PROGRESS"
  | "COMPLETED";

export const TASK_FILTER_LABELS: Record<TaskStatusFilter, string> = {
  ALL: "All",
  INBOX: "Inbox",
  PLANNED: "Planned",
  IN_PROGRESS: "In Progress",
  COMPLETED: "Completed",
};

const MOCK_LATENCY_MS = 550;

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

let localIdCounter = 0;

function nextLocalId(): string {
  localIdCounter += 1;
  return `local-${Date.now()}-${localIdCounter}`;
}

/**
 * Tasks collection for the Tasks and Inbox workspaces.
 *
 * Mock mode (`VITE_USE_MOCK_DATA=true` global or `VITE_USE_MOCK_TASKS=true`)
 * keeps the milestone behavior: seed data, local ids, immediate optimistic
 * flips with Undo — for design review. Real mode (default) talks to the
 * Task API: server-confirmed writes, no optimistic flips, and completion is
 * one-way (the backend has no un-complete transition; plan 002 records
 * this decision).
 */
const USE_MOCK = useMock("TASKS");

export const useTasksStore = defineStore("tasks", () => {
  const tasks = ref<Task[]>([...mockTasks]);
  const status = ref<LoadStatus>("idle");
  const searchQuery = ref("");
  const statusFilter = ref<TaskStatusFilter>("ALL");
  const previewEmpty = ref(false);
  /** Last failed mutation message (null when none). */
  const lastError = ref<string | null>(null);

  function clearError(): void {
    lastError.value = null;
  }

  function taskById(id: string): Task | undefined {
    return tasks.value.find((task) => task.id === id);
  }

  const inboxCount = computed(
    () => tasks.value.filter((task) => task.status === "INBOX").length,
  );

  /** Inbox tasks, newest capture first. */
  const inboxTasks = computed(() => {
    if (previewEmpty.value) return [];
    return tasks.value
      .filter((task) => task.status === "INBOX")
      .slice()
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  });

  const filterCounts = computed<Record<TaskStatusFilter, number>>(() => ({
    ALL: tasks.value.length,
    INBOX: tasks.value.filter((t) => t.status === "INBOX").length,
    PLANNED: tasks.value.filter((t) => t.status === "PLANNED").length,
    IN_PROGRESS: tasks.value.filter((t) => t.status === "IN_PROGRESS").length,
    COMPLETED: tasks.value.filter((t) => t.status === "COMPLETED").length,
  }));

  const matchesFilter = (task: Task): boolean =>
    statusFilter.value === "ALL" || task.status === statusFilter.value;

  const matchesSearch = (task: Task): boolean => {
    const query = searchQuery.value.trim().toLowerCase();
    return query === "" || task.title.toLowerCase().includes(query);
  };

  /** Tasks for the Tasks workspace list: filter + search applied,
   * completed work sinks to the bottom. */
  const visibleTasks = computed(() => {
    if (previewEmpty.value) return [];
    const statusOrder: Record<TaskStatus, number> = {
      IN_PROGRESS: 0,
      PLANNED: 1,
      INBOX: 2,
      COMPLETED: 3,
      CANCELLED: 4,
    };
    return tasks.value
      .filter((task) => matchesFilter(task) && matchesSearch(task))
      .slice()
      .sort((a, b) => statusOrder[a.status] - statusOrder[b.status]);
  });

  const hasActiveSearch = computed(() => searchQuery.value.trim().length > 0);

  /**
   * @param preview forces a UI state for design verification
   * (`?preview=loading|error|empty`) — mock mode only.
   */
  async function load(preview: PreviewState = null): Promise<void> {
    status.value = "loading";
    lastError.value = null;

    if (preview === "loading") return; // stay loading for review

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
      const list = await tasksApi.list();
      tasks.value = list.map(taskResponseToTask);
      status.value = "ready";
    } catch (error) {
      status.value = "error";
      lastError.value = errorMessage(error);
    }
  }

  function setSearch(query: string): void {
    searchQuery.value = query;
  }

  function setFilter(filter: TaskStatusFilter): void {
    statusFilter.value = filter;
  }

  /** Create a task in the inbox. Mock mode is synchronous and immediate;
   *  real mode persists on the server and prepends the confirmed task. */
  function addInboxTask(title: string): Task | null {
    lastError.value = null;

    if (USE_MOCK) {
      const now = new Date().toISOString();
      const task: Task = {
        id: nextLocalId(),
        title,
        description: null,
        status: "INBOX",
        priority: null,
        energy: null,
        estimatedMinutes: null,
        dueDate: null,
        projectId: null,
        completedAt: null,
        createdAt: now,
        updatedAt: now,
      };
      tasks.value.unshift(task);
      return task;
    }

    tasksApi
      .create({ title })
      .then((created) => {
        tasks.value.unshift(taskResponseToTask(created));
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
    return null;
  }

  function addTask(draft: NewTaskDraft): Task | null {
    lastError.value = null;

    if (USE_MOCK) {
      const now = new Date().toISOString();
      const task: Task = {
        id: nextLocalId(),
        title: draft.title,
        description: draft.description || null,
        status: "INBOX",
        priority: draft.priority,
        energy: null,
        estimatedMinutes: draft.estimatedMinutes,
        dueDate: draft.dueDate,
        projectId: draft.projectId,
        completedAt: null,
        createdAt: now,
        updatedAt: now,
        scheduledTime: draft.scheduledTime,
        recurrence: draft.recurrence,
      };
      tasks.value.unshift(task);
      return task;
    }

    tasksApi
      .create({
        title: draft.title,
        description: draft.description || null,
        dueDate: draft.dueDate,
        priority: draft.priority ?? undefined,
        estimatedDurationMinutes: draft.estimatedMinutes,
      })
      .then((created) => {
        tasks.value.unshift(taskResponseToTask(created));
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
    return null;
  }

  /** Snapshot of the last destructive change, so the UI can offer Undo.
   *  Set only in mock mode — real-mode completion is one-way. */
  const lastUndoable = ref<{
    kind: "complete" | "reopen" | "create";
    taskId: string;
    task: Task;
  } | null>(null);

  function toggleTaskComplete(taskId: string): void {
    const task = taskById(taskId);
    if (!task) return;
    lastError.value = null;

    if (USE_MOCK) {
      const now = new Date().toISOString();
      lastUndoable.value = {
        kind: task.status === "COMPLETED" ? "reopen" : "complete",
        taskId,
        task: { ...task },
      };

      if (task.status === "COMPLETED") {
        task.status = "PLANNED";
        task.completedAt = null;
      } else {
        task.status = "COMPLETED";
        task.completedAt = now;
      }
      task.updatedAt = now;
      return;
    }

    // Real mode: server-confirmed, no optimistic flip, no undo
    // (backend has no un-complete transition — plan 002).
    tasksApi
      .complete(taskId)
      .then((updated) => {
        const live = taskById(taskId);
        if (live) Object.assign(live, taskResponseToTask(updated));
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
  }

  function undoLast(): Task | null {
    const last = lastUndoable.value;
    if (!last) return null;
    const task = taskById(last.taskId);
    if (!task) return null;

    Object.assign(task, last.task);
    task.updatedAt = new Date().toISOString();

    if (last.kind === "create") {
      tasks.value = tasks.value.filter((t) => t.id !== last.taskId);
      lastUndoable.value = null;
      return null;
    }

    lastUndoable.value = null;
    return task;
  }

  return {
    tasks,
    status,
    searchQuery,
    statusFilter,
    visibleTasks,
    inboxTasks,
    inboxCount,
    filterCounts,
    hasActiveSearch,
    lastError,
    taskById,
    load,
    setSearch,
    setFilter,
    addInboxTask,
    addTask,
    toggleTaskComplete,
    undoLast,
    lastUndoable,
    clearError,
  };
});
