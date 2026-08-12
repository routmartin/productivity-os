<script setup lang="ts">
import { TASK_FILTER_LABELS, type TaskStatusFilter } from '../store'

defineProps<{
  active: TaskStatusFilter
  counts: Record<TaskStatusFilter, number>
}>()

const emit = defineEmits<{ change: [filter: TaskStatusFilter] }>()

const FILTERS: TaskStatusFilter[] = ['ALL', 'INBOX', 'PLANNED', 'IN_PROGRESS', 'COMPLETED']
</script>

<template>
  <div class="filters" role="tablist" aria-label="Filter tasks by status">
    <button
      v-for="filter in FILTERS"
      :key="filter"
      class="chip"
      :class="{ active: filter === active }"
      role="tab"
      :aria-selected="filter === active"
      type="button"
      @click="emit('change', filter)"
    >
      {{ TASK_FILTER_LABELS[filter] }}
      <span class="count tnum">{{ counts[filter] }}</span>
    </button>
  </div>
</template>

<style scoped>
.filters {
  display: flex;
  align-items: center;
  gap: var(--space-1);
}

.chip {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  height: 28px;
  padding: 0 var(--space-3);
  border-radius: var(--radius-full);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.chip:hover {
  color: var(--text-secondary);
  background: var(--surface-2);
}

.chip.active {
  background: var(--surface-2);
  color: var(--text-primary);
  font-weight: 500;
}

.count {
  font-size: var(--text-xs);
  color: var(--text-disabled);
}

.chip.active .count {
  color: var(--text-tertiary);
}
</style>
