<script setup lang="ts">
import { computed } from 'vue'
import { AlertCircle, Check, Clock, GripVertical, Repeat } from 'lucide-vue-next'

import { formatShortDate, formatClockTime } from '@/lib/utils/date'
import { formatMinutes } from '@/lib/utils/duration'
import { useProjectsStore } from '@/features/projects/store'
import { useTasksStore } from '../store'
import type { Task } from '../types'
import TaskPrioritySegments from './TaskPrioritySegments.vue'

const props = withDefaults(
  defineProps<{
    task: Task
    active?: boolean
    isDragging?: boolean
    isGrabbed?: boolean
  }>(),
  {
    active: false,
    isDragging: false,
    isGrabbed: false,
  },
)

const emit = defineEmits<{
  select: [taskId: string]
  pointerdown: [event: PointerEvent, task: Task]
  keydown: [event: KeyboardEvent, task: Task]
}>()

const store = useTasksStore()
const projectsStore = useProjectsStore()

const project = computed(() =>
  props.task.projectId
    ? projectsStore.projectById(props.task.projectId)
    : undefined,
)

const isCompleted = computed(() => props.task.status === 'COMPLETED')
const isInProgress = computed(() => props.task.status === 'IN_PROGRESS')

const isOverdue = computed(() => {
  if (!props.task.dueDate || props.task.status === 'COMPLETED' || props.task.status === 'CANCELLED') {
    return false
  }
  return props.task.dueDate < store.todayISO
})

const dueLabel = computed(() => {
  if (!props.task.dueDate) return null
  if (props.task.dueDate === store.todayISO) return 'Today'
  if (props.task.dueDate === store.tomorrowISO) return 'Tomorrow'
  return formatShortDate(new Date(`${props.task.dueDate}T00:00:00`))
})

function onToggleCheck(event: MouseEvent) {
  event.stopPropagation()
  store.toggleTaskComplete(props.task.id)
}

function onPointerDown(event: PointerEvent) {
  // Only start drag on primary button
  if (event.button !== 0) return
  emit('pointerdown', event, props.task)
}

function onKeyDown(event: KeyboardEvent) {
  emit('keydown', event, props.task)
}
</script>

<template>
  <div
    class="board-card"
    :class="{
      active,
      completed: isCompleted,
      'in-progress': isInProgress,
      dragging: isDragging,
      grabbed: isGrabbed,
    }"
    role="button"
    tabindex="0"
    :aria-roledescription="'sortable task card'"
    :aria-pressed="isGrabbed"
    :aria-label="`${task.title}, ${task.status}`"
    :data-task-id="task.id"
    @pointerdown="onPointerDown"
    @keydown="onKeyDown"
  >
    <!-- Top Row: Project and Priority -->
    <div class="card-top">
      <div v-if="project" class="card-project">
        <span
          class="project-dot"
          :style="{ background: project.color ?? 'var(--text-disabled)' }"
        />
        <span class="project-name">{{ project.name }}</span>
      </div>
      <div v-else class="card-project-placeholder" />

      <div class="card-top-right">
        <TaskPrioritySegments
          v-if="task.priority"
          :priority="task.priority"
          class="card-priority"
        />
        <GripVertical :size="13" :stroke-width="2" class="grip-icon" aria-hidden="true" />
      </div>
    </div>

    <!-- Middle Row: Checkbox and Title -->
    <div class="card-body">
      <button
        class="card-check"
        :class="{ checked: isCompleted }"
        type="button"
        role="checkbox"
        :aria-checked="isCompleted"
        :aria-label="isCompleted ? `Reopen ${task.title}` : `Complete ${task.title}`"
        @click="onToggleCheck"
        @pointerdown.stop
      >
        <Check v-if="isCompleted" :size="11" :stroke-width="3" />
      </button>

      <div class="card-title-wrap">
        <span class="card-title">{{ task.title }}</span>
      </div>
    </div>

    <!-- Bottom Row: Metadata Chips -->
    <div v-if="task.dueDate || task.estimatedMinutes || task.scheduledTime || task.recurrence" class="card-meta">
      <span
        v-if="dueLabel"
        class="chip tnum"
        :class="{ overdue: isOverdue }"
      >
        <AlertCircle v-if="isOverdue" :size="11" :stroke-width="2" class="chip-alert" />
        <Clock v-else :size="11" :stroke-width="1.75" />
        <span>{{ isOverdue ? `Overdue · ${dueLabel}` : dueLabel }}</span>
      </span>

      <span v-if="task.scheduledTime" class="chip tnum">
        <Clock :size="11" :stroke-width="1.75" />
        <span>{{ formatClockTime(task.scheduledTime) }}</span>
      </span>

      <span v-if="task.estimatedMinutes" class="chip tnum">
        <span>{{ formatMinutes(task.estimatedMinutes) }}</span>
      </span>

      <span v-if="task.recurrence" class="chip">
        <Repeat :size="11" :stroke-width="1.75" />
        <span>{{ task.recurrence }}</span>
      </span>
    </div>
  </div>
</template>

<style scoped>
.board-card {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  padding: var(--space-4) var(--space-4) var(--space-3);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  cursor: grab;
  user-select: none;
  -webkit-user-select: none;
  touch-action: none;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    border-color var(--duration-fast) var(--ease-out),
    box-shadow var(--duration-fast) var(--ease-out),
    opacity var(--duration-fast) var(--ease-out);
}

.board-card:hover {
  background: var(--surface-3);
  border-color: var(--border-strong);
}

.board-card:hover .grip-icon {
  opacity: 0.7;
}

.board-card.active {
  border-color: var(--accent-strong);
  box-shadow: 0 0 0 1px var(--accent-border);
}

.board-card.in-progress {
  border-left: 3px solid var(--accent-strong);
}

.board-card.grabbed {
  border-color: var(--accent-strong);
  box-shadow: 0 0 0 2px var(--accent-glow), var(--shadow-panel);
  background: var(--surface-3);
}

.board-card.dragging {
  opacity: 0.35;
  border-style: dashed;
}

.card-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
  min-height: 18px;
}

.card-project {
  display: flex;
  align-items: center;
  gap: 6px;
  min-width: 0;
}

.project-dot {
  width: 7px;
  height: 7px;
  border-radius: var(--radius-full);
  flex-shrink: 0;
}

.project-name {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.card-project-placeholder {
  flex: 1;
}

.card-top-right {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-shrink: 0;
}

.grip-icon {
  color: var(--text-disabled);
  opacity: 0.3;
  transition: opacity var(--duration-fast) var(--ease-out);
}

.card-body {
  display: flex;
  align-items: flex-start;
  gap: var(--space-3);
}

.card-check {
  display: grid;
  place-items: center;
  width: 18px;
  height: 18px;
  margin-top: 2px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  border: 1.5px solid var(--text-disabled);
  background: transparent;
  color: var(--surface-1);
  cursor: pointer;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.card-check:hover {
  border-color: var(--accent-strong);
  transform: scale(1.08);
}

.card-check.checked {
  border-color: var(--success);
  background: var(--success);
  color: #07140e;
}

.card-title-wrap {
  flex: 1;
  min-width: 0;
}

.card-title {
  font-size: var(--text-md);
  font-weight: 550;
  line-height: 1.35;
  letter-spacing: -0.01em;
  color: var(--text-primary);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  word-break: break-word;
}

.board-card.completed .card-title {
  color: var(--text-tertiary);
  text-decoration: line-through;
  text-decoration-color: var(--text-disabled);
}

.card-meta {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
  padding-top: var(--space-1);
}

.chip {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 2px 8px;
  border-radius: var(--radius-full);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  font-size: var(--text-xs);
  font-weight: 500;
  color: var(--text-tertiary);
  white-space: nowrap;
}

.chip svg {
  color: var(--text-disabled);
}

.chip.overdue {
  background: var(--danger-soft);
  border-color: rgba(240, 90, 90, 0.28);
  color: var(--danger);
}

.chip.overdue .chip-alert {
  color: var(--danger);
}

@media (prefers-reduced-motion: reduce) {
  .board-card {
    transition: none;
  }
}
</style>
