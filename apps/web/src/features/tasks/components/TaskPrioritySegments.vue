<script setup lang="ts">
import { computed } from 'vue'

import { PRIORITY_LABELS, type Priority } from '../types'

/** Compact 3-segment priority indicator (inspired by the task reference):
 *  filled segments encode level — LOW 1 green, MEDIUM 2 amber, HIGH 3 red. */
const props = defineProps<{ priority: Priority | null }>()

const filled = computed(() => {
  switch (props.priority) {
    case 'HIGH':
      return 3
    case 'MEDIUM':
      return 2
    case 'LOW':
      return 1
    default:
      return 0
  }
})

const label = computed(() =>
  props.priority ? `${PRIORITY_LABELS[props.priority]} priority` : 'No priority',
)
</script>

<template>
  <span
    class="segments"
    :class="priority ? `priority-${priority.toLowerCase()}` : 'priority-none'"
    role="img"
    :aria-label="label"
    :title="label"
  >
    <span v-for="i in 3" :key="i" class="segment" :class="{ on: i <= filled }" />
  </span>
</template>

<style scoped>
.segments {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  flex-shrink: 0;
}

.segment {
  width: 7px;
  height: 4px;
  border-radius: 2px;
  background: var(--surface-3);
  transition: background-color var(--duration-fast) var(--ease-out);
}

.priority-high .segment.on {
  background: var(--danger);
}

.priority-medium .segment.on {
  background: var(--warning);
}

.priority-low .segment.on {
  background: var(--success);
}
</style>
