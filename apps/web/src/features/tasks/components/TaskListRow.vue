<script setup lang="ts">
import { computed } from 'vue'
import { CalendarDays, Clock, Flag } from 'lucide-vue-next'

import UiPill from '@/components/ui/UiPill.vue'
import { formatShortDate, relativeTime } from '@/lib/utils/date'
import { formatMinutes } from '@/lib/utils/duration'

import { findProjectById } from '../mock'
import type { Task, TaskStatus } from '../types'
import TaskActionMenu from './TaskActionMenu.vue'
import TaskStatusIcon from './TaskStatusIcon.vue'

const props = withDefaults(
  defineProps<{
    task: Task
    active?: boolean
    /** Inbox presentation: "Captured 2h ago" instead of project metadata. */
    capturedStyle?: boolean
  }>(),
  { active: false, capturedStyle: false },
)

const emit = defineEmits<{ select: [taskId: string] }>()

const project = computed(() => findProjectById(props.task.projectId))

const subtitle = computed(() => {
  if (props.capturedStyle) {
    return `Captured ${relativeTime(props.task.createdAt)}`
  }
  return project.value?.name ?? null
})

const isCompleted = computed(() => props.task.status === 'COMPLETED')

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
    <TaskStatusIcon :status="task.status" class="status" />

    <span class="body">
      <span class="title">{{ task.title }}</span>
      <span v-if="subtitle" class="subtitle">{{ subtitle }}</span>
    </span>

    <span class="meta">
      <UiPill v-if="pill" :tone="pill.tone" class="status-pill">{{ pill.label }}</UiPill>
      <span v-if="task.priority === 'HIGH'" class="meta-item priority-high" title="High priority">
        <Flag :size="12" :stroke-width="1.75" />
        <span class="priority-label">High</span>
      </span>
      <span v-if="dueLabel" class="meta-item tnum">
        <CalendarDays :size="12" :stroke-width="1.75" />
        {{ dueLabel }}
      </span>
      <span v-if="task.estimatedMinutes" class="meta-item tnum">
        <Clock :size="12" :stroke-width="1.75" />
        {{ formatMinutes(task.estimatedMinutes) }}
      </span>
      <TaskActionMenu :task="task" />
    </span>
  </div>
</template>

<style scoped>
.task-list-row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-3);
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
  font-size: var(--text-md);
  font-weight: 500;
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
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.meta {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  flex-shrink: 0;
}

.status-pill {
  text-transform: uppercase;
  letter-spacing: 0.05em;
  font-size: 10px;
  font-weight: 600;
}

.meta-item {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  white-space: nowrap;
}

.priority-high {
  color: var(--warning);
}

/* Fold secondary metadata away as the workspace narrows */
@media (max-width: 1400px) {
  .priority-label {
    display: none;
  }
}

@media (max-width: 1250px) {
  .meta-item {
    display: none;
  }
}
</style>
