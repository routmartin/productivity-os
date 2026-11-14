<script setup lang="ts">
import { computed } from 'vue'
import { ArrowRight, Check, Flag, Play, X } from 'lucide-vue-next'

import SectionHeader from '@/components/shared/SectionHeader.vue'
import { useFocusStore } from '@/features/focus/store'
import { useProjectsStore } from '@/features/projects/store'
import { useTasksStore } from '@/features/tasks/store'
import type { Priority, Task } from '@/features/tasks/types'

import { useTodayStore } from '../todayStore'
import type { TopThreeEntry } from '../types'

const props = defineProps<{
  entries: TopThreeEntry[]
  activeTaskId?: string | null
}>()

const emit = defineEmits<{ select: [taskId: string] }>()

const tasksStore = useTasksStore()
const projectsStore = useProjectsStore()
const todayStore = useTodayStore()
const focusStore = useFocusStore()

interface PriorityRow {
  position: number
  task: Task
  projectName: string | null
  priority: Priority | null
}

const rows = computed<PriorityRow[]>(() =>
  props.entries
    .slice()
    .sort((a, b) => a.position - b.position)
    .flatMap((entry) => {
      const task = tasksStore.taskById(entry.taskId)
      if (!task) return []
      return [
        {
          position: entry.position,
          task,
          projectName: task.projectId
            ? projectsStore.projectById(task.projectId)?.name ?? null
            : null,
          priority: task.priority,
        },
      ]
    }),
)

function onKeydown(event: KeyboardEvent, taskId: string) {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    emit('select', taskId)
  }
}

function onRemove(event: MouseEvent, taskId: string) {
  event.stopPropagation()
  void todayStore.removeFromTopThree(taskId)
}

async function onStartFocus(taskId: string) {
  const task = tasksStore.taskById(taskId)
  if (!task) return
  if (task.status !== 'IN_PROGRESS') {
    await tasksStore.startTaskNow(taskId)
  }
  focusStore.selectTask(taskId)
  focusStore.startFocus()
}
</script>

<template>
  <section v-if="rows.length > 0" class="priorities panel">
    <SectionHeader title="Top Priorities">
      <template #actions>
        <RouterLink :to="{ name: 'tasks' }" class="header-link">
          View all tasks
          <ArrowRight :size="14" :stroke-width="2" />
        </RouterLink>
      </template>
    </SectionHeader>

    <ol class="rows">
      <li
        v-for="row in rows"
        :key="row.task.id"
        class="row"
        :class="{ active: row.task.id === activeTaskId, done: row.task.status === 'COMPLETED' }"
        role="button"
        tabindex="0"
        @click="emit('select', row.task.id)"
        @keydown="onKeydown($event, row.task.id)"
      >
        <span class="rank tnum" :class="`rank-${row.position}`">{{ row.position }}</span>

        <span class="body">
          <span class="title">{{ row.task.title }}</span>
          <span v-if="row.projectName" class="project">{{ row.projectName }}</span>
        </span>

        <span v-if="row.priority" class="priority" :class="`priority-${row.priority.toLowerCase()}`">
          <Flag :size="13" :stroke-width="2" />
          {{ row.priority === 'HIGH' ? 'High' : row.priority === 'MEDIUM' ? 'Medium' : 'Low' }}
        </span>

        <!-- 1-Click direct focus launcher -->
        <button
          v-if="row.task.status !== 'COMPLETED'"
          class="focus-btn"
          type="button"
          aria-label="Start Focus session"
          title="Start Focus session on this task"
          @click.stop="onStartFocus(row.task.id)"
        >
          <Play :size="12" :stroke-width="2.5" />
          <span class="focus-btn-label">Focus</span>
        </button>

        <!-- Toggle task completion -->
        <button
          class="complete-circle"
          :class="{ checked: row.task.status === 'COMPLETED' }"
          type="button"
          :aria-label="row.task.status === 'COMPLETED' ? 'Mark incomplete' : 'Mark complete'"
          :title="row.task.status === 'COMPLETED' ? 'Mark incomplete' : 'Mark complete'"
          @click.stop="tasksStore.toggleTaskComplete(row.task.id)"
        >
          <Check v-if="row.task.status === 'COMPLETED'" :size="13" :stroke-width="2.5" />
        </button>

        <button
          class="remove-btn"
          type="button"
          aria-label="Remove from Top 3"
          title="Remove from Top 3"
          @click="onRemove($event, row.task.id)"
        >
          <X :size="14" :stroke-width="2" />
        </button>
      </li>
    </ol>
  </section>
</template>

<style scoped>
.panel {
  display: flex;
  flex-direction: column;
  padding: var(--space-6);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  background: var(--surface-1);
  min-width: 0;
}

.header-link {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--accent-strong);
  border-radius: var(--radius-sm);
}

.header-link:hover {
  opacity: 0.82;
}

.rows {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-3);
  border: 1px solid transparent;
  border-radius: var(--radius-md);
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    border-color var(--duration-fast) var(--ease-out);
}

.row:hover {
  background: var(--surface-2);
}

.row.active {
  background: var(--surface-2);
  border-color: var(--accent-border);
}

/* Rank badges: purple, blue, green — as in the approved reference. */
.rank {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  font-size: var(--text-sm);
  font-weight: 650;
  color: #fff;
}

.rank-1 {
  background: var(--accent);
  box-shadow: 0 3px 14px var(--accent-glow);
}

.rank-2 {
  background: var(--blue);
}

.rank-3 {
  background: var(--success);
}

.body {
  display: flex;
  flex-direction: column;
  gap: 2px;
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

.done .title {
  color: var(--text-tertiary);
  text-decoration: line-through;
  text-decoration-color: var(--text-disabled);
}

.project {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.priority {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  flex-shrink: 0;
  font-size: var(--text-sm);
  font-weight: 550;
}

.priority-high {
  color: var(--danger);
}

.priority-medium {
  color: var(--blue-strong);
}

.priority-low {
  color: var(--text-tertiary);
}

/* 1-Click Focus launcher button */
.focus-btn {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  padding: 4px 10px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--accent-border);
  background: var(--surface-3);
  color: var(--accent-strong);
  font-size: var(--text-xs);
  font-weight: 600;
  cursor: pointer;
  flex-shrink: 0;
  opacity: 0.88;
  transition:
    opacity var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.focus-btn:hover {
  opacity: 1;
  background: var(--surface-hover);
  transform: translateY(-1px);
}

.focus-btn-label {
  letter-spacing: 0.02em;
}

.complete-circle {
  display: grid;
  place-items: center;
  width: 22px;
  height: 22px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  border: 1.5px solid var(--text-disabled);
  background: transparent;
  color: #fff;
  cursor: pointer;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.complete-circle:hover {
  border-color: var(--success);
}

.complete-circle.checked {
  border-color: var(--success);
  background: var(--success);
}

.remove-btn {
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
  opacity: 0;
  transition:
    opacity var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.row:hover .remove-btn {
  opacity: 1;
}

.remove-btn:hover {
  color: var(--danger);
}
</style>
