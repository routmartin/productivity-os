import { defineStore } from "pinia";
import { computed, ref } from "vue";

/**
 * The right contextual panel is a shell-level concern: any page can ask
 * the shell to show contextual content. Content is a tagged union so new
 * panel kinds (AI context, …) slot in without restructuring.
 */
export type PanelContent =
  | { kind: "task"; taskId: string }
  | { kind: "project"; projectId: string }
  | { kind: "goal"; goalId: string };

export const useContextPanelStore = defineStore("contextPanel", () => {
  const content = ref<PanelContent | null>(null);

  const isOpen = computed(() => content.value !== null);

  const activeTaskId = computed(() =>
    content.value?.kind === "task" ? content.value.taskId : null,
  );

  const activeProjectId = computed(() =>
    content.value?.kind === "project" ? content.value.projectId : null,
  );

  const activeGoalId = computed(() =>
    content.value?.kind === "goal" ? content.value.goalId : null,
  );

  function openTask(taskId: string): void {
    content.value = { kind: "task", taskId };
  }

  function openProject(projectId: string): void {
    content.value = { kind: "project", projectId };
  }

  function openGoal(goalId: string): void {
    content.value = { kind: "goal", goalId };
  }

  function close(): void {
    content.value = null;
  }

  /** Keeps highlight state in sync when the same row is clicked again. */
  function toggleTask(taskId: string): void {
    if (content.value?.kind === "task" && content.value.taskId === taskId) {
      content.value = null;
    } else {
      openTask(taskId);
    }
  }

  function toggleProject(projectId: string): void {
    if (
      content.value?.kind === "project" &&
      content.value.projectId === projectId
    ) {
      content.value = null;
    } else {
      openProject(projectId);
    }
  }

  function toggleGoal(goalId: string): void {
    if (content.value?.kind === "goal" && content.value.goalId === goalId) {
      content.value = null;
    } else {
      openGoal(goalId);
    }
  }

  return {
    content,
    isOpen,
    activeTaskId,
    activeProjectId,
    activeGoalId,
    openTask,
    openProject,
    openGoal,
    close,
    toggleTask,
    toggleProject,
    toggleGoal,
  };
});
