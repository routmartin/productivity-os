<script setup lang="ts">
import { computed } from 'vue'
import { Clock, Play, Radio, Target } from 'lucide-vue-next'

import type { ScheduleNode } from '../../types'
import { useScheduleStore } from '../../scheduleStore'

const props = withDefaults(
  defineProps<{
    node: ScheduleNode
    compact?: boolean
    selected?: boolean
  }>(),
  {
    compact: false,
    selected: false,
  },
)

const emit = defineEmits<{
  (e: 'select', nodeId: string): void
  (e: 'start-focus', taskId: string): void
}>()

const scheduleStore = useScheduleStore()

const isSelected = computed(() => props.selected || scheduleStore.selectedNodeId === props.node.id)
const isInFocus = computed(() => Boolean(props.node.inFocus))

const priorityClass = computed(() => {
  switch (props.node.priority) {
    case 'HIGH':
      return 'priority-high'
    case 'MEDIUM':
      return 'priority-medium'
    case 'LOW':
      return 'priority-low'
    default:
      return 'priority-neutral'
  }
})

const durationFormatted = computed(() => {
  const mins = props.node.durationMinutes ?? 0
  if (mins >= 60) {
    const h = Math.floor(mins / 60)
    const m = mins % 60
    return m > 0 ? `${h}h ${m}m` : `${h}h`
  }
  return `${mins}m`
})

function handleSelect() {
  scheduleStore.selectNode(props.node.id)
  emit('select', props.node.id)
}

function handleStartFocus(event: Event) {
  event.stopPropagation()
  if (!props.node.taskId) return
  scheduleStore.startFocus(props.node.taskId)
  emit('start-focus', props.node.taskId)
}
</script>

<template>
  <div
    class="task-node"
    :class="{
      selected: isSelected,
      'in-focus': isInFocus,
      compact: compact,
    }"
    role="button"
    tabindex="0"
    :aria-pressed="isSelected"
    :aria-label="`Task: ${node.title}, priority ${node.priority ?? 'standard'}, duration ${durationFormatted}`"
    @click="handleSelect"
    @keydown.enter.prevent="handleSelect"
  >
    <div class="task-top-row">
      <div class="task-badges">
        <span v-if="node.priority" class="badge-priority" :class="priorityClass">
          {{ node.priority }}
        </span>
        <span v-if="node.projectName" class="badge-project">
          {{ node.projectName }}
        </span>
      </div>

      <div class="task-time-meta">
        <span v-if="node.time" class="task-time">{{ node.time }}</span>
        <span class="task-duration">
          <Clock :size="11" class="clock-icon" />
          {{ durationFormatted }}
        </span>
      </div>
    </div>

    <div class="task-body">
      <div class="task-title-wrap">
        <h4 class="task-title">{{ node.title }}</h4>
      </div>
      <p v-if="node.subtitle && !compact" class="task-subtitle">
        {{ node.subtitle }}
      </p>
    </div>

    <div class="task-actions">
      <!-- Live In-Focus Active State -->
      <div v-if="isInFocus" class="in-focus-banner" title="Active Focus Session running">
        <Radio :size="14" class="pulse-icon" />
        <span class="in-focus-text">In Focus</span>
      </div>

      <!-- Start Focus Button -->
      <button
        v-else-if="node.taskId"
        type="button"
        class="start-focus-btn"
        :aria-label="`Start focus session for ${node.title}`"
        @click="handleStartFocus"
      >
        <Play :size="12" class="play-icon" />
        <span>{{ compact ? 'Focus' : 'Start Focus' }}</span>
      </button>

      <div v-else class="informational-tag">
        <Target :size="12" />
        <span>Planned Task</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.task-node {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-4);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  cursor: pointer;
  user-select: none;
  transition: all 0.2s var(--ease-out);
  position: relative;
  text-align: left;
}

.task-node:hover {
  background: var(--surface-2);
  border-color: var(--border-strong);
  transform: translateY(-1px);
}

.task-node.selected {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px var(--accent-border), 0 6px 20px rgba(108, 92, 231, 0.2);
  background: var(--surface-2);
}

.task-node.in-focus {
  border-color: var(--accent-strong);
  background: linear-gradient(135deg, var(--accent-soft), var(--surface-1));
  box-shadow: 0 0 0 1.5px var(--accent), 0 0 24px var(--accent-glow);
}

/* Compact matrix mode */
.task-node.compact {
  padding: var(--space-3);
  gap: var(--space-2);
}

.task-node.compact .task-title {
  font-size: var(--text-xs);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 170px;
}

/* Top metadata row */
.task-top-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
}

.task-badges {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.badge-priority {
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 2px 6px;
  border-radius: var(--radius-sm);
}

.priority-high {
  background: var(--danger-soft);
  color: var(--danger);
  border: 1px solid rgba(240, 90, 90, 0.25);
}

.priority-medium {
  background: var(--warning-soft);
  color: var(--warning);
  border: 1px solid rgba(244, 183, 64, 0.25);
}

.priority-low {
  background: var(--blue-soft);
  color: var(--blue-strong);
  border: 1px solid rgba(59, 130, 246, 0.25);
}

.priority-neutral {
  background: var(--surface-2);
  color: var(--text-tertiary);
  border: 1px solid var(--border-subtle);
}

.badge-project {
  font-size: 11px;
  color: var(--text-tertiary);
}

.task-time-meta {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.task-time {
  font-variant-numeric: tabular-nums;
  font-weight: 500;
}

.task-duration {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 2px 6px;
  background: var(--surface-2);
  border-radius: var(--radius-sm);
  font-variant-numeric: tabular-nums;
}

.clock-icon {
  color: var(--text-tertiary);
}

/* Body */
.task-body {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.task-title {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--text-primary);
  line-height: 1.3;
  margin: 0;
}

.task-subtitle {
  font-size: var(--text-xs);
  color: var(--text-secondary);
  margin: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Actions */
.task-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  margin-top: 2px;
}

.start-focus-btn {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  padding: 5px 12px;
  background: var(--surface-2);
  border: 1px solid var(--border-strong);
  border-radius: var(--radius-full);
  color: var(--text-primary);
  font-size: var(--text-xs);
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s var(--ease-out);
}

.start-focus-btn:hover {
  background: var(--accent);
  border-color: var(--accent);
  color: var(--on-accent);
  box-shadow: 0 2px 10px var(--accent-glow);
}

.play-icon {
  fill: currentColor;
}

.in-focus-banner {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 12px;
  background: var(--accent-soft);
  border: 1px solid var(--accent);
  border-radius: var(--radius-full);
  color: var(--accent-strong);
  font-size: var(--text-xs);
  font-weight: 600;
}

.pulse-icon {
  animation: radarPulse 1.8s infinite var(--ease-in-out);
}

@keyframes radarPulse {
  0% {
    transform: scale(0.9);
    opacity: 0.6;
  }
  50% {
    transform: scale(1.15);
    opacity: 1;
  }
  100% {
    transform: scale(0.9);
    opacity: 0.6;
  }
}

.informational-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: var(--text-tertiary);
}
</style>
