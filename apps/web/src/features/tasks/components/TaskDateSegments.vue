<script setup lang="ts">
import { ref } from 'vue'
import { DATE_SEGMENT_LABELS, type DateSegment } from '../types'

defineProps<{
  active: DateSegment
  counts: Record<DateSegment, number>
}>()

const emit = defineEmits<{ change: [segment: DateSegment] }>()

const segments: DateSegment[] = ['ALL', 'TODAY', 'UPCOMING', 'BACKLOG']
const tabRefs = ref<(HTMLButtonElement | null)[]>([])

function onKeyDown(event: KeyboardEvent, index: number) {
  let nextIndex: number | null = null

  if (event.key === 'ArrowRight' || event.key === 'ArrowDown') {
    event.preventDefault()
    nextIndex = (index + 1) % segments.length
  } else if (event.key === 'ArrowLeft' || event.key === 'ArrowUp') {
    event.preventDefault()
    nextIndex = (index - 1 + segments.length) % segments.length
  } else if (event.key === 'Home') {
    event.preventDefault()
    nextIndex = 0
  } else if (event.key === 'End') {
    event.preventDefault()
    nextIndex = segments.length - 1
  }

  if (nextIndex !== null) {
    const nextSegment = segments[nextIndex]
    emit('change', nextSegment)
    tabRefs.value[nextIndex]?.focus()
  }
}
</script>

<template>
  <div class="task-date-segments" role="tablist" aria-label="Task date segments">
    <button
      v-for="(segment, index) in segments"
      :key="segment"
      :ref="(el) => { tabRefs[index] = el as HTMLButtonElement | null }"
      class="segment-tab"
      :class="{ active: segment === active }"
      role="tab"
      :aria-selected="segment === active"
      :tabindex="segment === active ? 0 : -1"
      type="button"
      @click="emit('change', segment)"
      @keydown="onKeyDown($event, index)"
    >
      <span class="label">{{ DATE_SEGMENT_LABELS[segment] }}</span>
      <span class="badge tnum">{{ counts[segment] ?? 0 }}</span>
    </button>
  </div>
</template>

<style scoped>
.task-date-segments {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  background: var(--surface-1);
  padding: 3px;
  border-radius: var(--radius-full);
  border: 1px solid var(--border-subtle);
}

.segment-tab {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  height: 36px;
  padding: 0 var(--space-4);
  border-radius: var(--radius-full);
  border: none;
  background: transparent;
  color: var(--text-tertiary);
  font-size: var(--text-sm);
  font-weight: 500;
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out),
    box-shadow var(--duration-fast) var(--ease-out);
}

.segment-tab:hover {
  color: var(--text-secondary);
  background: var(--surface-2);
}

.segment-tab:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 1px;
}

.segment-tab.active {
  background: var(--surface-2);
  color: var(--text-primary);
  font-weight: 600;
  box-shadow: var(--shadow-sm);
}

.badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 18px;
  height: 18px;
  padding: 0 var(--space-1);
  border-radius: var(--radius-full);
  background: var(--surface-3);
  font-size: var(--text-xs);
  color: var(--text-disabled);
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.segment-tab.active .badge {
  background: var(--surface-3);
  color: var(--text-secondary);
  font-weight: 600;
}
</style>
