import { defineStore } from "pinia";
import { computed, ref } from "vue";

import { errorMessage } from "@/lib/api/errorMessages";
import { useMock } from "@/lib/mock";
import type { PreviewState } from "@/features/planning/types";

import { tasksApi } from "./api";
import { taskResponseToTask } from "./api-types";
import type { TaskResponse } from "./api-types";
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
  const tasks = ref<Task[]>(USE_MOCK ? [...mockTasks] : []);
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
   * completed work sinks to the bottom. Pinned tasks always float to top. */
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
      .sort((a, b) => {
        if (a.pinned && !b.pinned) return -1;
        if (!a.pinned && b.pinned) return 1;
        return statusOrder[a.status] - statusOrder[b.status];
      });
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
    /** UI-only creation destination (spec §12.1); undefined = Inbox. */
    const destination = draft.destination ?? "INBOX";

    if (USE_MOCK) {
      const now = new Date().toISOString();
      const task: Task = {
        id: nextLocalId(),
        title: draft.title,
        description: draft.description || null,
        status: destination,
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

    // Real mode: create always yields INBOX (backend contract); the store
    // chains sanctioned transitions per destination (Tasks & Inbox UI spec
    // §12.1), then assigns the project when the dialog picked one (backend
    // create has no projectId field — it must go through PUT /{id}/project,
    // mirroring updateTask's pattern). Only the final server state enters
    // the list; a mid-chain failure leaves the task visible in its actual
    // lifecycle state.
    let current: Promise<TaskResponse> = tasksApi.create({
      title: draft.title,
      description: draft.description || null,
      dueDate: draft.dueDate,
      priority: draft.priority ?? undefined,
      estimatedDurationMinutes: draft.estimatedMinutes,
    });
    if (destination !== "INBOX") {
      current = current.then((created) => tasksApi.plan(created.id));
    }
    if (destination === "IN_PROGRESS") {
      current = current.then((planned) => tasksApi.start(planned.id));
    }
    if (draft.projectId) {
      current = current.then((created) =>
        tasksApi.assignProject(created.id, { projectId: draft.projectId }),
      );
    }

    current
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

  /** INBOX → PLANNED. */
  function planTask(taskId: string): void {
    const task = taskById(taskId);
    if (!task) return;
    lastError.value = null;

    if (USE_MOCK) {
      task.status = "PLANNED";
      task.updatedAt = new Date().toISOString();
      return;
    }

    tasksApi
      .plan(taskId)
      .then((updated) => {
        const live = taskById(taskId);
        if (live) Object.assign(live, taskResponseToTask(updated));
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
  }

  /** PLANNED → IN_PROGRESS. */
  function startTask(taskId: string): void {
    const task = taskById(taskId);
    if (!task) return;
    lastError.value = null;

    if (USE_MOCK) {
      task.status = "IN_PROGRESS";
      task.updatedAt = new Date().toISOString();
      return;
    }

    tasksApi
      .start(taskId)
      .then((updated) => {
        const live = taskById(taskId);
        if (live) Object.assign(live, taskResponseToTask(updated));
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
  }

  /** One-click Start (Tasks & Inbox UI spec §15.1): resolves once the task
   *  is IN_PROGRESS. INBOX chains the sanctioned plan → start transitions;
   *  PLANNED starts directly; other statuses reject. Mock mode flips
   *  locally. */
  async function startTaskNow(taskId: string): Promise<void> {
    const task = taskById(taskId);
    if (!task || (task.status !== "INBOX" && task.status !== "PLANNED")) {
      return;
    }
    lastError.value = null;

    if (USE_MOCK) {
      task.status = "IN_PROGRESS";
      task.updatedAt = new Date().toISOString();
      return;
    }

    const chain: Promise<TaskResponse> =
      task.status === "INBOX"
        ? tasksApi.plan(taskId).then(() => tasksApi.start(taskId))
        : tasksApi.start(taskId);

    try {
      const updated = await chain;
      const live = taskById(taskId);
      if (live) Object.assign(live, taskResponseToTask(updated));
    } catch (error: unknown) {
      lastError.value = errorMessage(error);
    }
  }

  /** INBOX | PLANNED | IN_PROGRESS → CANCELLED (UI spec §15.3). */
  function cancelTask(taskId: string): void {
    const task = taskById(taskId);
    if (
      !task ||
      (task.status !== "INBOX" &&
        task.status !== "PLANNED" &&
        task.status !== "IN_PROGRESS")
    ) {
      return;
    }
    lastError.value = null;

    if (USE_MOCK) {
      task.status = "CANCELLED";
      task.updatedAt = new Date().toISOString();
      return;
    }

    tasksApi
      .cancel(taskId)
      .then((updated) => {
        const live = taskById(taskId);
        if (live) Object.assign(live, taskResponseToTask(updated));
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
  }

  /** CANCELLED → PLANNED (Task Management Rule 10, UI spec §15.3). */
  function reopenTask(taskId: string): void {
    const task = taskById(taskId);
    if (!task || task.status !== "CANCELLED") return;
    lastError.value = null;

    if (USE_MOCK) {
      task.status = "PLANNED";
      task.updatedAt = new Date().toISOString();
      return;
    }

    tasksApi
      .reopening(taskId)
      .then((updated) => {
        const live = taskById(taskId);
        if (live) Object.assign(live, taskResponseToTask(updated));
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
  }

  /** Persist edits (amendment AC-012). Mock mode mutates locally; real
   *  mode sends PUT /api/v1/tasks/{id} and reassigns the project through
   *  PUT /{id}/project when it changed. */
  function updateTask(taskId: string, draft: NewTaskDraft): void {
    const task = taskById(taskId);
    if (!task) return;
    lastError.value = null;

    if (USE_MOCK) {
      task.title = draft.title;
      task.description = draft.description;
      task.priority = draft.priority;
      task.dueDate = draft.dueDate;
      task.estimatedMinutes = draft.estimatedMinutes;
      task.projectId = draft.projectId;
      task.scheduledTime = draft.scheduledTime ?? null;
      task.recurrence = draft.recurrence ?? null;
      task.updatedAt = new Date().toISOString();
      return;
    }

    tasksApi
      .update(taskId, {
        title: draft.title,
        description: draft.description,
        dueDate: draft.dueDate,
        priority: draft.priority ?? null,
        estimatedDurationMinutes: draft.estimatedMinutes,
      })
      .then((updated) => {
        const live = taskById(taskId);
        if (live) Object.assign(live, taskResponseToTask(updated));
      })
      .then(() => {
        const live = taskById(taskId);
        if (live && live.projectId !== draft.projectId) {
          return tasksApi
            .assignProject(taskId, { projectId: draft.projectId })
            .then((updated) => {
              const current = taskById(taskId);
              if (current) Object.assign(current, taskResponseToTask(updated));
            });
        }
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
  }

  /** Delete a task (amendment AC-013). Mock removes locally; real mode
   *  soft-deletes via DELETE /api/v1/tasks/{id} then drops it from the
   *  list. */
  function deleteTask(taskId: string): void {
    const task = taskById(taskId);
    if (!task) return;
    lastError.value = null;

    if (USE_MOCK) {
      tasks.value = tasks.value.filter((t) => t.id !== taskId);
      if (lastUndoable.value?.taskId === taskId) lastUndoable.value = null;
      return;
    }

    tasksApi
      .delete(taskId)
      .then(() => {
        tasks.value = tasks.value.filter((t) => t.id !== taskId);
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
  }

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

  /** Toggle the pinned flag on a task (UI-only, no backend persistence yet). */
  function togglePin(taskId: string): void {
    const task = taskById(taskId);
    if (!task) return;
    task.pinned = !task.pinned;
    task.updatedAt = new Date().toISOString();
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
    planTask,
    startTask,
    startTaskNow,
    cancelTask,
    reopenTask,
    updateTask,
    deleteTask,
    toggleTaskComplete,
    undoLast,
    lastUndoable,
    togglePin,
    clearError,
  };
});
