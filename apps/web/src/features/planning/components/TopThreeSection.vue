<script setup lang="ts">
import { computed } from 'vue'
import { ArrowRight, CalendarCheck2, Check, Flag } from 'lucide-vue-next'

import EmptyState from '@/components/shared/EmptyState.vue'
import SectionHeader from '@/components/shared/SectionHeader.vue'
import { useProjectsStore } from '@/features/projects/store'
import { useTasksStore } from '@/features/tasks/store'
import type { Priority, Task } from '@/features/tasks/types'

import type { TopThreeEntry } from '../types'

const props = defineProps<{
  entries: TopThreeEntry[]
  activeTaskId?: string | null
}>()

const emit = defineEmits<{ select: [taskId: string] }>()

const tasksStore = useTasksStore()
const projectsStore = useProjectsStore()

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
</script>

<template>
  <section class="priorities panel">
    <SectionHeader title="Top Priorities">
      <template #actions>
        <RouterLink :to="{ name: 'tasks' }" class="header-link">
          View all tasks
          <ArrowRight :size="14" :stroke-width="2" />
        </RouterLink>
      </template>
    </SectionHeader>

    <ol v-if="rows.length > 0" class="rows">
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

        <span
          class="complete-circle"
          :class="{ checked: row.task.status === 'COMPLETED' }"
          role="button"
          tabindex="-1"
          aria-label="Mark complete (arrives in a later milestone)"
          title="Completing tasks arrives in a later milestone"
          @click.stop
        >
          <Check v-if="row.task.status === 'COMPLETED'" :size="13" :stroke-width="2.5" />
        </span>
      </li>
    </ol>

    <EmptyState
      v-else
      :icon="CalendarCheck2"
      title="No priorities chosen yet"
      description="Pick up to three tasks that would make today a win."
      compact
    />
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
  padding: var(--space-4) var(--space-3);
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

.complete-circle {
  display: grid;
  place-items: center;
  width: 22px;
  height: 22px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  border: 1.5px solid var(--text-disabled);
  color: #fff;
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
</style>
