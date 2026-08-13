<script setup lang="ts">
import { computed } from 'vue'
import { CalendarDays, Check, Clock, FolderKanban, Inbox } from 'lucide-vue-next'

import { formatShortDate, relativeTime } from '@/lib/utils/date'
import { formatMinutes } from '@/lib/utils/duration'

import { findProjectById } from '../mock'
import { useTasksStore } from '../store'
import type { Task } from '../types'
import TaskActionMenu from './TaskActionMenu.vue'
import TaskPrioritySegments from './TaskPrioritySegments.vue'

const props = withDefaults(
  defineProps<{
    task: Task
    active?: boolean
  }>(),
  { active: false },
)

const emit = defineEmits<{ select: [taskId: string] }>()

const store = useTasksStore()

const project = computed(() => findProjectById(props.task.projectId))

/** Category pill tinted with the project color; quiet accent for plain inbox items. */
const pillStyle = computed(() => {
  const color = project.value?.color
  if (!color) return null
  return {
    background: `color-mix(in srgb, ${color} 14%, transparent)`,
    color,
  }
})

const isCompleted = computed(() => props.task.status === 'COMPLETED')

const description = computed(
  () => props.task.description ?? `Captured ${relativeTime(props.task.createdAt)}`,
)

const capturedDate = computed(() => formatShortDate(new Date(props.task.createdAt)))

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
</script>

<template>
  <article
    class="inbox-card"
    :class="{ active, completed: isCompleted }"
    role="button"
    tabindex="0"
    :aria-pressed="active || undefined"
    @click="emit('select', task.id)"
    @keydown="onKeydown"
  >
    <div class="card-top">
      <span class="category-pill" :style="pillStyle">{{ project?.name ?? 'Inbox' }}</span>
      <TaskActionMenu :task="task" />
    </div>

    <h3 class="card-title">{{ task.title }}</h3>
    <p class="card-desc">{{ description }}</p>

    <div class="resource-chip">
      <span class="resource-icon">
        <FolderKanban v-if="project" :size="15" :stroke-width="1.75" />
        <Inbox v-else :size="15" :stroke-width="1.75" />
      </span>
      <span class="resource-text">
        <span class="resource-name">{{ project?.name ?? 'Not organized yet' }}</span>
        <span class="resource-sub">{{ project ? 'Project' : 'Inbox' }}</span>
      </span>
      <span v-if="task.estimatedMinutes" class="resource-est tnum">
        <Clock :size="12" :stroke-width="1.75" />
        {{ formatMinutes(task.estimatedMinutes) }}
      </span>
    </div>

    <div class="card-footer">
      <button
        class="check"
        :class="{ checked: isCompleted }"
        type="button"
        role="checkbox"
        :aria-checked="isCompleted"
        :aria-label="isCompleted ? `Reopen ${task.title}` : `Complete ${task.title}`"
        :title="isCompleted ? 'Reopen task' : 'Mark complete'"
        @click="onToggle"
      >
        <Check v-if="isCompleted" :size="11" :stroke-width="3" />
      </button>
      <TaskPrioritySegments v-if="task.priority" :priority="task.priority" />
      <span class="date tnum">
        <CalendarDays :size="13" :stroke-width="1.75" />
        {{ capturedDate }}
      </span>
    </div>
  </article>
</template>

<style scoped>
.inbox-card {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  padding: var(--space-5);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  cursor: pointer;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    box-shadow var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.inbox-card:hover {
  border-color: var(--border-strong);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
  transform: translateY(-2px);
}

.inbox-card.active {
  border-color: var(--accent-border);
  box-shadow: 0 0 0 3px var(--accent-soft);
}

.card-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
}

.category-pill {
  display: inline-flex;
  align-items: center;
  height: 24px;
  padding: 0 10px;
  border-radius: var(--radius-full);
  background: var(--accent-soft);
  color: var(--accent-strong);
  font-size: var(--text-xs);
  font-weight: 600;
  letter-spacing: 0.01em;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.card-title {
  font-size: var(--text-lg);
  font-weight: 650;
  letter-spacing: -0.01em;
  line-height: 1.3;
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.completed .card-title {
  color: var(--text-tertiary);
  text-decoration: line-through;
  text-decoration-color: var(--text-disabled);
}

.card-desc {
  font-size: var(--text-sm);
  line-height: 1.5;
  color: var(--text-tertiary);
  /* Uniform 2-line block keeps the grid rows aligned */
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: calc(var(--text-sm) * 3);
}

.resource-chip {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3);
  background: var(--surface-2);
  border-radius: var(--radius-md);
}

.resource-icon {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  flex-shrink: 0;
  border-radius: var(--radius-sm);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  color: var(--text-tertiary);
}

.resource-text {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-width: 0;
}

.resource-name {
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.resource-sub {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.resource-est {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  margin-left: auto;
  flex-shrink: 0;
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.card-footer {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-top: auto;
  padding-top: var(--space-4);
  border-top: 1px solid var(--border-subtle);
}

.check {
  display: grid;
  place-items: center;
  width: 20px;
  height: 20px;
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

.check:hover {
  border-color: var(--accent-strong);
  transform: scale(1.08);
}

.check.checked {
  border-color: var(--success);
  background: var(--success);
  color: #07140e;
}

.date {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-left: auto;
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  white-space: nowrap;
}
</style>
