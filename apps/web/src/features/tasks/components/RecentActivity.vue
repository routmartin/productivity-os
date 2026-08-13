<script setup lang="ts">
import { ArrowRight, CheckCircle2, FilePlus2, History } from 'lucide-vue-next'

import EmptyState from '@/components/shared/EmptyState.vue'
import SectionHeader from '@/components/shared/SectionHeader.vue'
import { relativeTime } from '@/lib/utils/date'

/** One activity row: an action applied to a task at a point in time. */
export interface ActivityItem {
  id: string
  taskId: string
  kind: 'completed' | 'created'
  title: string
  /** ISO instant used for the relative time label. */
  at: string
}

defineProps<{ items: ActivityItem[] }>()

const emit = defineEmits<{ select: [taskId: string] }>()

function onKeydown(event: KeyboardEvent, taskId: string) {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    emit('select', taskId)
  }
}
</script>

<template>
  <section class="activity panel">
    <SectionHeader title="Recent Activity">
      <template #actions>
        <RouterLink :to="{ name: 'tasks' }" class="header-link">
          View all activity
          <ArrowRight :size="14" :stroke-width="2" />
        </RouterLink>
      </template>
    </SectionHeader>

    <ul v-if="items.length > 0" class="items">
      <li
        v-for="item in items"
        :key="item.id"
        class="item"
        role="button"
        tabindex="0"
        @click="emit('select', item.taskId)"
        @keydown="onKeydown($event, item.taskId)"
      >
        <span class="icon" :class="`kind-${item.kind}`" aria-hidden="true">
          <CheckCircle2 v-if="item.kind === 'completed'" :size="16" :stroke-width="2" />
          <FilePlus2 v-else :size="15" :stroke-width="1.75" />
        </span>
        <span class="body">
          <span class="text">
            {{ item.kind === 'completed' ? 'Completed' : 'Created new task' }}
            <span class="object">“{{ item.title }}”</span>
          </span>
          <span class="when tnum">{{ relativeTime(item.at) }}</span>
        </span>
      </li>
    </ul>

    <EmptyState
      v-else
      :icon="History"
      title="No recent activity"
      description="Completed and captured work will show up here."
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

.items {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.item {
  display: flex;
  align-items: flex-start;
  gap: var(--space-3);
  padding: var(--space-3);
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.item:hover {
  background: var(--surface-2);
}

.icon {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
}

.icon.kind-completed {
  background: var(--accent-soft);
  color: var(--accent-strong);
}

.icon.kind-created {
  background: var(--blue-soft);
  color: var(--blue-strong);
}

.body {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
  flex: 1;
}

.text {
  font-size: var(--text-md);
  line-height: 1.45;
  color: var(--text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.object {
  color: var(--text-primary);
  font-weight: 500;
}

.when {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}
</style>
