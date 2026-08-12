<script setup lang="ts">
import { computed } from 'vue'

import type { TaskStatus } from '../types'

const props = withDefaults(
  defineProps<{
    status: TaskStatus
    size?: number
  }>(),
  { size: 16 },
)

const label = computed(() => {
  switch (props.status) {
    case 'INBOX':
      return 'In inbox'
    case 'PLANNED':
      return 'Planned'
    case 'IN_PROGRESS':
      return 'In progress'
    case 'COMPLETED':
      return 'Completed'
    case 'CANCELLED':
      return 'Cancelled'
    default:
      return 'Task'
  }
})
</script>

<template>
  <span class="status-icon" :class="`status-${status.toLowerCase()}`" :title="label" role="img" :aria-label="label">
    <svg :width="size" :height="size" viewBox="0 0 16 16" fill="none">
      <!-- Inbox: not yet triaged -->
      <circle
        v-if="status === 'INBOX'"
        cx="8" cy="8" r="6"
        stroke="currentColor" stroke-width="1.5" stroke-dasharray="2.6 2.4" stroke-linecap="round"
      />
      <!-- Planned -->
      <circle
        v-else-if="status === 'PLANNED'"
        cx="8" cy="8" r="6"
        stroke="currentColor" stroke-width="1.5"
      />
      <!-- In progress: half-filled -->
      <template v-else-if="status === 'IN_PROGRESS'">
        <circle cx="8" cy="8" r="6" stroke="currentColor" stroke-width="1.5" />
        <path d="M8 2a6 6 0 0 1 0 12V2Z" fill="currentColor" />
      </template>
      <!-- Completed -->
      <template v-else-if="status === 'COMPLETED'">
        <circle cx="8" cy="8" r="6.75" fill="currentColor" fill-opacity="0.16" />
        <circle cx="8" cy="8" r="6" stroke="currentColor" stroke-width="1.5" />
        <path d="M5.4 8.2 7.2 10 10.7 6.2" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
      </template>
      <!-- Cancelled -->
      <template v-else>
        <circle cx="8" cy="8" r="6" stroke="currentColor" stroke-width="1.5" />
        <path d="M6 6l4 4M10 6l-4 4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
      </template>
    </svg>
  </span>
</template>

<style scoped>
.status-icon {
  display: inline-flex;
  flex-shrink: 0;
  color: var(--text-tertiary);
}

.status-in_progress {
  color: var(--accent-strong);
}

.status-completed {
  color: var(--success);
}

.status-cancelled {
  color: var(--text-disabled);
}
</style>
