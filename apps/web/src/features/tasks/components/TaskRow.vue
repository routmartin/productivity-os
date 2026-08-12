<script setup lang="ts">
import { computed } from 'vue'

import { formatMinutes } from '@/lib/utils/duration'

import type { Task } from '../types'

const props = defineProps<{
  task: Task
  active?: boolean
}>()

const emit = defineEmits<{ select: [taskId: string] }>()

const duration = computed(() =>
  props.task.estimatedMinutes ? formatMinutes(props.task.estimatedMinutes) : null,
)

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    emit('select', props.task.id)
  }
}
</script>

<template>
  <div
    class="task-row"
    :class="{ active }"
    role="button"
    tabindex="0"
    :aria-pressed="active || undefined"
    @click="emit('select', task.id)"
    @keydown="onKeydown"
  >
    <span
      class="checkbox"
      role="checkbox"
      aria-checked="false"
      aria-label="Mark complete (arrives in Milestone 2)"
      title="Completing tasks arrives in Milestone 2"
      tabindex="-1"
      @click.stop
    />
    <span class="title">{{ task.title }}</span>
    <span v-if="duration" class="duration tnum">{{ duration }}</span>
  </div>
</template>

<style scoped>
.task-row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  height: 38px;
  /* Negative margins keep the checkbox and duration exactly on the card's
     content grid while the hover background bleeds slightly past it. */
  margin: 0 calc(-1 * var(--space-2));
  padding: 0 var(--space-2);
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.task-row:hover {
  background: var(--surface-2);
}

.task-row.active {
  background: var(--surface-2);
  box-shadow: inset 0 0 0 1px var(--border-strong);
}

.checkbox {
  width: 16px;
  height: 16px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  border: 1.5px solid var(--text-disabled);
  transition: border-color var(--duration-fast) var(--ease-out);
}

.task-row:hover .checkbox {
  border-color: var(--text-tertiary);
}

.title {
  flex: 1;
  min-width: 0;
  font-size: var(--text-md);
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.duration {
  flex-shrink: 0;
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}
</style>
