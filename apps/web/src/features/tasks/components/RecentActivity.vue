<script setup lang="ts">
import { CheckSquare, History, MoreHorizontal } from 'lucide-vue-next'

import EmptyState from '@/components/shared/EmptyState.vue'
import SectionHeader from '@/components/shared/SectionHeader.vue'
import UiPill from '@/components/ui/UiPill.vue'
import { relativeTime } from '@/lib/utils/date'

import { findProjectById } from '../mock'
import type { Task } from '../types'

defineProps<{ tasks: Task[] }>()

const emit = defineEmits<{ select: [taskId: string] }>()

function projectName(task: Task): string | null {
  return findProjectById(task.projectId)?.name ?? null
}
</script>

<template>
  <section class="recent-activity">
    <SectionHeader title="Recent Tasks" />

    <ul v-if="tasks.length > 0" class="items">
      <li
        v-for="task in tasks"
        :key="task.id"
        class="item"
        role="button"
        tabindex="0"
        @click="emit('select', task.id)"
        @keydown.enter="emit('select', task.id)"
      >
        <CheckSquare :size="16" :stroke-width="1.75" class="check" />
        <span class="body">
          <span class="title">{{ task.title }}</span>
          <span v-if="projectName(task)" class="project">{{ projectName(task) }}</span>
        </span>
        <UiPill tone="success" class="status-pill">Completed</UiPill>
        <span class="when tnum">{{ relativeTime(task.completedAt ?? task.updatedAt) }}</span>
        <button
          class="more"
          type="button"
          aria-label="More actions"
          title="Task actions arrive in Milestone 2"
          @click.stop
        >
          <MoreHorizontal :size="15" :stroke-width="1.75" />
        </button>
      </li>
    </ul>

    <EmptyState
      v-else
      :icon="History"
      title="No recent activity"
      description="Completed tasks will show up here."
      compact
    />
  </section>
</template>

<style scoped>
.items {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.item {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  background: var(--surface-1);
  cursor: pointer;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.item:hover {
  background: var(--surface-2);
  border-color: var(--border-strong);
}

.check {
  color: var(--success);
  flex-shrink: 0;
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
  color: var(--text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.item:hover .title {
  color: var(--text-primary);
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

.when {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  flex-shrink: 0;
}

.more {
  display: grid;
  place-items: center;
  width: 26px;
  height: 26px;
  border-radius: var(--radius-sm);
  color: var(--text-disabled);
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.more:hover {
  background: var(--surface-3);
  color: var(--text-secondary);
}
</style>
