<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Inbox } from 'lucide-vue-next'

import { useContextPanelStore } from '@/app/layouts/contextPanelStore'
import EmptyState from '@/components/shared/EmptyState.vue'
import ErrorState from '@/components/shared/ErrorState.vue'
import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import SurfaceCard from '@/components/shared/SurfaceCard.vue'
import type { PreviewState } from '@/features/planning/types'
import QuickCapture from '@/features/tasks/components/QuickCapture.vue'
import TaskListRow from '@/features/tasks/components/TaskListRow.vue'
import { useTasksStore } from '@/features/tasks/store'
import { showPreviewNote } from '@/lib/preview'

const route = useRoute()
const store = useTasksStore()
const panel = useContextPanelStore()

function previewFromQuery(): PreviewState {
  const value = route.query.preview
  return value === 'loading' || value === 'error' || value === 'empty' ? value : null
}

onMounted(() => store.load(previewFromQuery()))
watch(
  () => route.query.preview,
  () => store.load(previewFromQuery()),
)

const isLoading = computed(() => store.status === 'loading' || store.status === 'idle')

const subtitle = computed(() => {
  const count = store.inboxTasks.length
  if (count === 0) return "Things you've captured but haven't organized yet."
  return `${count} thing${count === 1 ? '' : 's'} waiting for your attention.`
})

function onCapture(title: string) {
  store.addInboxTask(title)
  showPreviewNote('Captured locally — it will sync once the Task API is connected.')
}

function onSelectTask(taskId: string) {
  panel.toggleTask(taskId)
}

function onRetry() {
  store.load(null)
}
</script>

<template>
  <div class="inbox-page">
    <header class="page-header">
      <h1 class="title">Inbox</h1>
      <p class="subtitle">{{ subtitle }}</p>
    </header>

    <QuickCapture @capture="onCapture" />

    <!-- Loading -->
    <SurfaceCard v-if="isLoading" class="list-card" aria-busy="true" aria-label="Loading inbox">
      <div class="skeleton-rows">
        <SkeletonBlock v-for="i in 5" :key="i" height="44px" rounded="md" />
      </div>
    </SurfaceCard>

    <!-- Error -->
    <ErrorState
      v-else-if="store.status === 'error'"
      title="Inbox didn't load"
      description="Your captured tasks could not be reached. Your data is safe — try loading them again."
      @retry="onRetry"
    />

    <!-- Empty -->
    <EmptyState
      v-else-if="store.inboxTasks.length === 0"
      :icon="Inbox"
      title="Your inbox is clear."
      description="Nothing waiting to be organized. Capture something above when it crosses your mind."
    />

    <!-- List -->
    <SurfaceCard v-else class="list-card">
      <TransitionGroup name="row" tag="div" class="rows">
        <TaskListRow
          v-for="task in store.inboxTasks"
          :key="task.id"
          :task="task"
          :active="task.id === panel.activeTaskId"
          captured-style
          @select="onSelectTask"
        />
      </TransitionGroup>
    </SurfaceCard>
  </div>
</template>

<style scoped>
.inbox-page {
  max-width: 760px;
  margin: 0 auto;
  padding: var(--space-8) var(--space-8) var(--space-12);
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.page-header {
  margin-bottom: var(--space-1);
}

.title {
  font-size: var(--text-2xl);
  font-weight: 650;
  letter-spacing: -0.02em;
}

.subtitle {
  margin-top: var(--space-1);
  font-size: var(--text-md);
  color: var(--text-tertiary);
}

.list-card {
  padding: var(--space-2);
}

.rows {
  display: flex;
  flex-direction: column;
}

.skeleton-rows {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-2);
}

.row-move,
.row-enter-active,
.row-leave-active {
  transition:
    opacity var(--duration-normal) var(--ease-out),
    transform var(--duration-normal) var(--ease-out);
}

.row-enter-from {
  opacity: 0;
  transform: translateY(-6px);
}

.row-leave-to {
  opacity: 0;
}
</style>
