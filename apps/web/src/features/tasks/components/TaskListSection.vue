<script setup lang="ts">
import { ref } from 'vue'
import { Inbox, Plus } from 'lucide-vue-next'

import EmptyState from '@/components/shared/EmptyState.vue'
import SurfaceCard from '@/components/shared/SurfaceCard.vue'

import type { Task } from '../types'
import TaskRow from './TaskRow.vue'

withDefaults(
  defineProps<{
    title: string
    tasks: Task[]
    activeTaskId?: string | null
    emptyTitle?: string
    emptyDescription?: string
  }>(),
  {
    activeTaskId: null,
    emptyTitle: 'Nothing here yet',
    emptyDescription: undefined,
  },
)

const emit = defineEmits<{ select: [taskId: string] }>()

/** "+ Add Task" is visual-only in Milestone 1 — say so, don't pretend. */
const noteVisible = ref(false)
let noteTimer: ReturnType<typeof setTimeout> | undefined

function onAddTask() {
  noteVisible.value = true
  clearTimeout(noteTimer)
  noteTimer = setTimeout(() => (noteVisible.value = false), 2600)
}
</script>

<template>
  <SurfaceCard :title="title">
    <template #actions>
      <button class="add-task" type="button" title="Creating tasks arrives in Milestone 2" @click="onAddTask">
        <Plus :size="14" :stroke-width="2" />
        Add Task
      </button>
    </template>

    <Transition name="fade">
      <p v-if="noteVisible" class="preview-note" role="status">
        Quick-add arrives in Milestone 2 — this button is visual for now.
      </p>
    </Transition>

    <div v-if="tasks.length > 0" class="rows">
      <TaskRow
        v-for="task in tasks"
        :key="task.id"
        :task="task"
        :active="task.id === activeTaskId"
        @select="emit('select', $event)"
      />
    </div>

    <EmptyState
      v-else
      :icon="Inbox"
      :title="emptyTitle"
      :description="emptyDescription"
      compact
    />
  </SurfaceCard>
</template>

<style scoped>
.add-task {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  padding: 4px var(--space-2);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-tertiary);
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.add-task:hover {
  background: var(--surface-2);
  color: var(--text-primary);
}

.preview-note {
  margin-bottom: var(--space-2);
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.rows {
  display: flex;
  flex-direction: column;
  gap: 1px;
}
</style>
