<script setup lang="ts">
import { computed } from 'vue'

import type { TaskStatus } from '../types'

const props = withDefaults(
  defineProps<{
    status: TaskStatus
    size?: number
  }>(),
  { size: 18 },
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
    <svg :width="size" :height="size" viewBox="0 0 18 18" fill="none">
      <!-- Inbox: not yet triaged -->
      <rect
        v-if="status === 'INBOX'"
        x="2.5" y="2.5" width="13" height="13" rx="4.5"
        stroke="currentColor" stroke-width="1.5" stroke-dasharray="2.8 2.6" stroke-linecap="round"
      />
      <!-- Planned -->
      <rect
        v-else-if="status === 'PLANNED'"
        x="2.5" y="2.5" width="13" height="13" rx="4.5"
        stroke="currentColor" stroke-width="1.5"
      />
      <!-- In progress: half-filled -->
      <template v-else-if="status === 'IN_PROGRESS'">
        <rect
          x="2.5" y="2.5" width="13" height="13" rx="4.5"
          stroke="currentColor" stroke-width="1.5"
        />
        <path d="M4 4.5A1.5 1.5 0 0 1 5.5 3h3.5v12H5.5A1.5 1.5 0 0 1 4 13.5v-9Z" fill="currentColor" />
      </template>
      <!-- Completed: solid square, cut-out check -->
      <template v-else-if="status === 'COMPLETED'">
        <rect x="2" y="2" width="14" height="14" rx="5" fill="currentColor" />
        <path
          d="M5.6 9.2 7.9 11.5 12.5 6.6"
          stroke="var(--surface-1)" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"
        />
      </template>
      <!-- Cancelled -->
      <template v-else>
        <rect
          x="2.5" y="2.5" width="13" height="13" rx="4.5"
          stroke="currentColor" stroke-width="1.5"
        />
        <path d="M6.4 6.4l5.2 5.2M11.6 6.4l-5.2 5.2" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
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

.status-planned {
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
