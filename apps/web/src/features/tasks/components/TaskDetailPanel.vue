<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  CalendarDays,
  CheckCircle2,
  CircleSlash,
  Clock,
  Flag,
  Folder,
  SearchX,
  Target,
  Timer,
  Zap,
} from 'lucide-vue-next'

import EmptyState from '@/components/shared/EmptyState.vue'
import UiButton from '@/components/ui/UiButton.vue'
import UiPill from '@/components/ui/UiPill.vue'
import { formatLongDate, relativeTime } from '@/lib/utils/date'
import { formatMinutes } from '@/lib/utils/duration'

import { findProjectById, goalForTask } from '../mock'
import { useTasksStore } from '../store'
import { ENERGY_LABELS, PRIORITY_LABELS, TASK_STATUS_LABELS } from '../types'
import TaskStatusIcon from './TaskStatusIcon.vue'

const props = defineProps<{ taskId: string }>()

const store = useTasksStore()

const task = computed(() => store.taskById(props.taskId))
const project = computed(() => findProjectById(task.value?.projectId ?? null))
const goal = computed(() => (task.value ? goalForTask(task.value) : undefined))

type PillTone = 'neutral' | 'accent' | 'success' | 'warning' | 'danger'

const statusTone = computed<PillTone>(() => {
  switch (task.value?.status) {
    case 'IN_PROGRESS':
      return 'accent'
    case 'COMPLETED':
      return 'success'
    case 'CANCELLED':
      return 'neutral'
    default:
      return 'neutral'
  }
})

const priorityTone = computed<PillTone>(() => {
  switch (task.value?.priority) {
    case 'HIGH':
      return 'warning'
    case 'MEDIUM':
      return 'accent'
    default:
      return 'neutral'
  }
})

const dueLabel = computed(() => {
  const due = task.value?.dueDate
  if (!due) return null
  return formatLongDate(new Date(`${due}T00:00:00`))
})

/** Milestone 1: panel actions are visual only. Pressing one explains that
 * honestly instead of pretending a mutation happened. */
const previewNote = ref<string | null>(null)
let noteTimer: ReturnType<typeof setTimeout> | undefined

function showPreviewNote(action: string) {
  previewNote.value = `${action} arrives with the Focus module in Milestone 2 — this preview is visual only.`
  clearTimeout(noteTimer)
  noteTimer = setTimeout(() => (previewNote.value = null), 3200)
}
</script>

<template>
  <div v-if="task" class="task-detail">
    <div class="pills">
      <UiPill :tone="statusTone">
        <TaskStatusIcon :status="task.status" :size="12" />
        {{ TASK_STATUS_LABELS[task.status] }}
      </UiPill>
      <UiPill v-if="task.priority" :tone="priorityTone">
        <Flag :size="11" :stroke-width="2" />
        {{ PRIORITY_LABELS[task.priority] }} priority
      </UiPill>
    </div>

    <h2 class="title">{{ task.title }}</h2>

    <p v-if="task.description" class="description">{{ task.description }}</p>
    <p v-else class="description muted">No description yet.</p>

    <dl class="meta-list">
      <div v-if="project" class="meta-row">
        <dt><Folder :size="14" :stroke-width="1.75" /> Project</dt>
        <dd>
          <span class="project-dot" :style="{ background: project.color }" />
          {{ project.name }}
        </dd>
      </div>
      <div v-if="goal" class="meta-row">
        <dt><Target :size="14" :stroke-width="1.75" /> Goal</dt>
        <dd>{{ goal.name }}</dd>
      </div>
      <div v-if="dueLabel" class="meta-row">
        <dt><CalendarDays :size="14" :stroke-width="1.75" /> Due</dt>
        <dd>{{ dueLabel }}</dd>
      </div>
      <div v-if="task.estimatedMinutes" class="meta-row">
        <dt><Clock :size="14" :stroke-width="1.75" /> Estimate</dt>
        <dd class="tnum">{{ formatMinutes(task.estimatedMinutes) }}</dd>
      </div>
      <div v-if="task.energy" class="meta-row">
        <dt><Zap :size="14" :stroke-width="1.75" /> Energy</dt>
        <dd>{{ ENERGY_LABELS[task.energy] }}</dd>
      </div>
    </dl>

    <div class="actions">
      <UiButton variant="primary" full-width @click="showPreviewNote('Focus sessions')">
        <Timer :size="15" :stroke-width="1.75" />
        Start focus session
      </UiButton>
      <UiButton
        v-if="task.status !== 'COMPLETED'"
        variant="ghost"
        full-width
        @click="showPreviewNote('Completing tasks')"
      >
        <CheckCircle2 :size="15" :stroke-width="1.75" />
        Mark complete
      </UiButton>
      <Transition name="fade">
        <p v-if="previewNote" class="preview-note" role="status">
          <CircleSlash :size="13" :stroke-width="1.75" />
          {{ previewNote }}
        </p>
      </Transition>
    </div>

    <footer class="footer tnum">
      <span>Created {{ relativeTime(task.createdAt) }}</span>
      <span v-if="task.completedAt">Completed {{ relativeTime(task.completedAt) }}</span>
      <span v-else>Updated {{ relativeTime(task.updatedAt) }}</span>
    </footer>
  </div>

  <EmptyState
    v-else
    :icon="SearchX"
    title="Task unavailable"
    description="This task could not be found. It may have been deleted."
    compact
  />
</template>

<style scoped>
.task-detail {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.pills {
  display: flex;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.title {
  font-size: var(--text-xl);
  letter-spacing: -0.02em;
}

.description {
  font-size: var(--text-md);
  color: var(--text-secondary);
  line-height: 1.6;
}

.description.muted {
  color: var(--text-tertiary);
  font-style: italic;
}

.meta-list {
  display: flex;
  flex-direction: column;
  border-top: 1px solid var(--border-subtle);
}

.meta-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  padding: var(--space-3) 0;
  border-bottom: 1px solid var(--border-subtle);
}

.meta-row dt {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.meta-row dd {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--text-primary);
  text-align: right;
}

.project-dot {
  width: 7px;
  height: 7px;
  border-radius: var(--radius-full);
}

.actions {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.preview-note {
  display: flex;
  align-items: flex-start;
  gap: var(--space-2);
  padding: var(--space-3);
  border-radius: var(--radius-md);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  line-height: 1.5;
}

.preview-note svg {
  flex-shrink: 0;
  margin-top: 1px;
}

.footer {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
  padding-top: var(--space-4);
  border-top: 1px solid var(--border-subtle);
  font-size: var(--text-xs);
  color: var(--text-disabled);
}
</style>
