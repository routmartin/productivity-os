import { defineStore } from "pinia";
import { computed, ref } from "vue";

/**
 * The right contextual panel is a shell-level concern: any page can ask
 * the shell to show contextual content. Milestone 1 has exactly one kind
 * of content — task details — but the store keeps the door open for more
 * (e.g. AI recommendation context) without restructuring the shell.
 */
export const useContextPanelStore = defineStore("contextPanel", () => {
  const activeTaskId = ref<string | null>(null);

  const isOpen = computed(() => activeTaskId.value !== null);

  function openTask(taskId: string): void {
    activeTaskId.value = taskId;
  }

  function close(): void {
    activeTaskId.value = null;
  }

  /** Keeps highlight state in sync when the same row is clicked again. */
  function toggleTask(taskId: string): void {
    activeTaskId.value = activeTaskId.value === taskId ? null : taskId;
  }

  return { activeTaskId, isOpen, openTask, close, toggleTask };
});
