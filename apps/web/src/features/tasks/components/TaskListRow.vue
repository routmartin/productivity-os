<script setup lang="ts">
import { computed } from 'vue'
import { CalendarDays, Check, Clock, Pin, Repeat } from 'lucide-vue-next'

import UiPill from '@/components/ui/UiPill.vue'
import { formatShortDate, formatClockTime, relativeTime } from '@/lib/utils/date'
import { formatMinutes } from '@/lib/utils/duration'

import { useProjectsStore } from '@/features/projects/store'
import { useMock } from '@/lib/mock'
import { useTasksStore } from '../store'
import type { Task, TaskStatus } from '../types'
import TaskPrioritySegments from './TaskPrioritySegments.vue'

const props = withDefaults(
  defineProps<{
    task: Task
    active?: boolean
    /** Inbox presentation: "Captured 2h ago" instead of project metadata. */
    capturedStyle?: boolean
    /** Grouped lists show the project in the group header — skip the repeat. */
    hideProject?: boolean
  }>(),
  { active: false, capturedStyle: false, hideProject: false },
)

const emit = defineEmits<{ select: [taskId: string] }>()

const store = useTasksStore()
const projectsStore = useProjectsStore()

/** Real project from the projects store — never the mock list. */
const project = computed(() =>
  props.task.projectId
    ? projectsStore.projectById(props.task.projectId)
    : undefined,
)

const subtitle = computed(() => {
  if (props.capturedStyle) {
    return `Captured ${relativeTime(props.task.createdAt)}`
  }
  if (props.hideProject) return null
  return project.value?.name ?? null
})

const isCompleted = computed(() => props.task.status === 'COMPLETED')

/** Backend completes tasks only from IN_PROGRESS; mock mode keeps the
 *  design-review toggle + undo. */
const canToggle = computed(
  () => useMock('TASKS') || props.task.status === 'IN_PROGRESS',
)

type PillTone = 'neutral' | 'accent' | 'info' | 'success' | 'warning'

function statusPill(status: TaskStatus): { label: string; tone: PillTone } | null {
  switch (status) {
    case 'IN_PROGRESS':
      return { label: 'In progress', tone: 'info' }
    case 'PLANNED':
      return { label: 'Planned', tone: 'warning' }
    case 'COMPLETED':
      return { label: 'Completed', tone: 'success' }
    default:
      return null // Inbox rows stay quiet — no pill
  }
}

const pill = computed(() => statusPill(props.task.status))

const dueLabel = computed(() => {
  if (!props.task.dueDate) return null
  return formatShortDate(new Date(`${props.task.dueDate}T00:00:00`))
})

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    emit('select', props.task.id)
  }
}

function onToggle(event: MouseEvent) {
  event.stopPropagation()
  store.toggleTaskComplete(props.task.id)
}

function onPin(event: MouseEvent) {
  event.stopPropagation()
  store.togglePin(props.task.id)
}
</script>

<template>
  <div
    class="task-list-row"
    :class="{ active, completed: isCompleted }"
    role="button"
    tabindex="0"
    :aria-pressed="active || undefined"
    @click="emit('select', task.id)"
    @keydown="onKeydown"
  >
    <button
      class="check"
      :class="{ checked: isCompleted }"
      type="button"
      role="checkbox"
      :aria-checked="isCompleted"
      :aria-label="isCompleted ? `Reopen ${task.title}` : `Complete ${task.title}`"
      :title="isCompleted ? 'Reopen task' : 'Mark complete'"
      :disabled="!canToggle"
      @click="onToggle"
    >
      <Check v-if="isCompleted" :size="11" :stroke-width="3" />
    </button>

    <button
      class="pin"
      :class="{ pinned: task.pinned }"
      type="button"
      :aria-label="task.pinned ? `Unpin ${task.title}` : `Pin ${task.title}`"
      :title="task.pinned ? 'Unpin' : 'Pin to top'"
      @click="onPin"
    >
      <Pin :size="13" :stroke-width="2" />
    </button>

    <span class="body">
      <span class="title">{{ task.title }}</span>
      <span v-if="subtitle" class="subtitle">{{ subtitle }}</span>
    </span>

    <span class="meta">
      <span v-if="task.recurrence" class="meta-item">
        <Repeat :size="13" :stroke-width="1.75" />
        {{ task.recurrence }}
      </span>
      <span v-if="task.scheduledTime" class="meta-item tnum">
        <Clock :size="13" :stroke-width="1.75" />
        {{ formatClockTime(task.scheduledTime) }}
      </span>
      <UiPill v-if="pill" :tone="pill.tone" class="status-pill">{{ pill.label }}</UiPill>
      <TaskPrioritySegments v-if="task.priority" :priority="task.priority" />
      <span v-if="dueLabel" class="meta-item tnum">
        <CalendarDays :size="13" :stroke-width="1.75" />
        {{ dueLabel }}
      </span>
      <span v-if="task.estimatedMinutes" class="meta-item tnum">
        <Clock :size="13" :stroke-width="1.75" />
        {{ formatMinutes(task.estimatedMinutes) }}
      </span>
    </span>
  </div>
</template>

<style scoped>
.task-list-row {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  padding: var(--space-4) var(--space-4);
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.task-list-row:hover {
  background: var(--surface-2);
}

.task-list-row.active {
  background: var(--surface-2);
  box-shadow: inset 0 0 0 1px var(--border-strong);
}

.check {
  display: grid;
  place-items: center;
  width: 22px;
  height: 22px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  border: 1.5px solid var(--text-disabled);
  background: transparent;
  color: var(--surface-1);
  cursor: pointer;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.check:hover {
  border-color: var(--accent-strong);
  transform: scale(1.08);
}

.check.checked {
  border-color: var(--success);
  background: var(--success);
  color: #07140e;
}

.task-list-row:hover .check {
  border-color: var(--text-tertiary);
}

.task-list-row:hover .check.checked {
  border-color: var(--success);
}

.pin {
  display: grid;
  place-items: center;
  width: 22px;
  height: 22px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  border: none;
  background: transparent;
  color: var(--text-disabled);
  cursor: pointer;
  transition: color var(--duration-fast) var(--ease-out);
}

.pin:hover {
  color: var(--text-tertiary);
}

.pin.pinned {
  color: var(--accent);
}

.task-list-row:hover .pin {
  color: var(--text-tertiary);
}

.task-list-row:hover .pin.pinned {
  color: var(--accent);
}

.status {
  flex-shrink: 0;
  margin-top: 2px;
  align-self: flex-start;
  padding-top: 2px;
}

.body {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-width: 0;
  flex: 1;
}

.title {
  font-size: var(--text-lg);
  font-weight: 550;
  letter-spacing: -0.01em;
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.completed .title {
  color: var(--text-tertiary);
  text-decoration: line-through;
  text-decoration-color: var(--text-disabled);
}

.subtitle {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.meta {
  display: flex;
  align-items: center;
  gap: var(--space-5);
  flex-shrink: 0;
}

.meta-item {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  white-space: nowrap;
}

/* Fold secondary metadata away as the workspace narrows */
@media (max-width: 1250px) {
  .meta-item {
    display: none;
  }
}
</style>
