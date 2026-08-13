<script setup lang="ts">
import { computed, ref } from "vue";
import { Check } from "lucide-vue-next";

import UiInput from "@/components/ui/UiInput.vue";
import { useFocusStore } from "@/features/focus/store";
import { findProjectById } from "@/features/tasks/mock";
import type { Task } from "@/features/tasks/types";
import { PRIORITY_LABELS } from "@/features/tasks/types";

const store = useFocusStore();

const search = ref("");

const filteredTasks = computed<Task[]>(() => {
  const query = search.value.trim().toLowerCase();
  if (!query) return store.eligibleTasks.slice(0, 6);
  return store.eligibleTasks.filter((t) =>
    t.title.toLowerCase().includes(query),
  );
});

function onSelect(taskId: string) {
  store.selectTask(store.selectedTaskId === taskId ? null : taskId);
}
</script>

<template>
  <div class="task-selector">
    <UiInput
      v-model="search"
      label="Search tasks"
      placeholder="Search tasks..."
    />

    <div v-if="filteredTasks.length === 0" class="no-results">
      <p class="no-title">No matching tasks</p>
      <p class="no-desc">Try a different search.</p>
    </div>

    <ul v-else class="task-list" role="listbox" aria-label="Eligible tasks">
      <li
        v-for="task in filteredTasks"
        :key="task.id"
        role="option"
        :aria-selected="store.selectedTaskId === task.id"
      >
        <button
          class="task-row"
          :class="{ selected: store.selectedTaskId === task.id }"
          @click="onSelect(task.id)"
        >
          <span class="check-icon" aria-hidden="true">
            <Check
              v-if="store.selectedTaskId === task.id"
              :size="15"
              :stroke-width="2.5"
            />
          </span>
          <span class="task-info">
            <span class="task-title">{{ task.title }}</span>
            <span class="task-meta">
              <span v-if="task.projectId" class="project-name">
                {{ findProjectById(task.projectId)?.name }}
              </span>
              <span v-if="task.priority" class="priority">
                {{ PRIORITY_LABELS[task.priority] }}
              </span>
            </span>
          </span>
        </button>
      </li>
    </ul>
  </div>
</template>

<style scoped>
.task-selector {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.no-results {
  text-align: center;
  padding: var(--space-6) var(--space-4);
}

.no-title {
  font-size: var(--text-md);
  font-weight: 500;
  color: var(--text-secondary);
}

.no-desc {
  margin-top: var(--space-1);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.task-list {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.task-row {
  display: flex;
  align-items: flex-start;
  gap: var(--space-3);
  width: 100%;
  padding: var(--space-4);
  border-radius: var(--radius-md);
  text-align: left;
  transition:
    background-color var(--duration-fast) var(--ease-out);
}

.task-row:hover {
  background: var(--surface-2);
}

.task-row.selected {
  background: var(--accent-soft);
  border: 1px solid var(--accent-border);
}

.check-icon {
  display: grid;
  place-items: center;
  width: 20px;
  height: 20px;
  flex-shrink: 0;
  margin-top: 1px;
  border-radius: var(--radius-full);
  border: 1.5px solid var(--border-strong);
  color: transparent;
}

.task-row.selected .check-icon {
  border-color: var(--accent);
  background: var(--accent);
  color: #0b0e18;
}

.task-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.task-title {
  font-size: var(--text-lg);
  font-weight: 550;
  letter-spacing: -0.01em;
  color: var(--text-primary);
}

.task-meta {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.project-name {
  color: var(--text-secondary);
}

.priority {
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}
</style>
