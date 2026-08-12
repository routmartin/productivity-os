<script setup lang="ts">
import { computed } from 'vue'
import { CalendarCheck2, Check } from 'lucide-vue-next'

import EmptyState from '@/components/shared/EmptyState.vue'
import SurfaceCard from '@/components/shared/SurfaceCard.vue'
import UiPill from '@/components/ui/UiPill.vue'
import { findProjectById, findTaskById } from '@/features/tasks/mock'
import type { Task } from '@/features/tasks/types'

import type { TopThreeEntry } from '../types'

const props = defineProps<{
  entries: TopThreeEntry[]
  activeTaskId?: string | null
}>()

const emit = defineEmits<{ select: [taskId: string] }>()

interface TopThreeRow {
  position: number
  task: Task
  projectName: string | null
}

const rows = computed<TopThreeRow[]>(() =>
  props.entries
    .slice()
    .sort((a, b) => a.position - b.position)
    .flatMap((entry) => {
      const task = findTaskById(entry.taskId)
      if (!task) return []
      return [
        {
          position: entry.position,
          task,
          projectName: findProjectById(task.projectId)?.name ?? null,
        },
      ]
    }),
)

function statusPill(task: Task): { label: string; tone: 'info' | 'warning' | 'success' | 'neutral' } {
  switch (task.status) {
    case 'IN_PROGRESS':
      return { label: 'In progress', tone: 'info' }
    case 'COMPLETED':
      return { label: 'Completed', tone: 'success' }
    case 'PLANNED':
      return { label: 'Planned', tone: 'warning' }
    default:
      return { label: 'Planned', tone: 'neutral' }
  }
}

function onKeydown(event: KeyboardEvent, taskId: string) {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    emit('select', taskId)
  }
}
</script>

<template>
  <SurfaceCard title="Today's Top 3">
    <template #actions>
      <button class="header-action" type="button" title="Editing priorities arrives in Milestone 2">
        Edit
      </button>
    </template>

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
        <span class="position tnum" :class="`position-${row.position}`">{{ row.position }}</span>

        <span class="body">
          <span class="title">{{ row.task.title }}</span>
          <span v-if="row.projectName" class="project">{{ row.projectName }}</span>
        </span>

        <UiPill :tone="statusPill(row.task).tone" class="status-pill">
          {{ statusPill(row.task).label }}
        </UiPill>

        <span
          class="complete-circle"
          :class="{ checked: row.task.status === 'COMPLETED' }"
          role="button"
          tabindex="-1"
          aria-label="Mark complete (arrives in Milestone 2)"
          title="Completing tasks arrives in Milestone 2"
          @click.stop
        >
          <Check v-if="row.task.status === 'COMPLETED'" :size="12" :stroke-width="2.5" />
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
  </SurfaceCard>
</template>

<style scoped>
.header-action {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-tertiary);
  padding: 4px var(--space-3);
  border-radius: var(--radius-md);
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.header-action:hover {
  background: var(--surface-2);
  color: var(--text-primary);
}

.rows {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.row {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  padding: var(--space-3) var(--space-4);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  background: var(--surface-2);
  cursor: pointer;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.row:hover {
  border-color: var(--border-strong);
}

.row.active {
  border-color: var(--accent-border);
}

/* Position rings: indigo, amber, orange — as in the approved reference. */
.position {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  border: 1.5px solid var(--text-disabled);
  color: var(--text-secondary);
  font-size: var(--text-sm);
  font-weight: 600;
}

.position-1 {
  border-color: var(--accent);
  color: var(--accent-strong);
  background: var(--accent-soft);
}

.position-2 {
  border-color: var(--warning);
  color: var(--warning);
  background: var(--warning-soft);
}

.position-3 {
  border-color: var(--orange);
  color: var(--orange);
  background: var(--orange-soft);
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

.done .title {
  color: var(--text-tertiary);
  text-decoration: line-through;
  text-decoration-color: var(--text-disabled);
}

.project {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.status-pill {
  text-transform: uppercase;
  letter-spacing: 0.05em;
  font-size: 10px;
  font-weight: 600;
}

.complete-circle {
  display: grid;
  place-items: center;
  width: 20px;
  height: 20px;
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
