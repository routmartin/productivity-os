<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { ListChecks, Plus, Search, SearchX, X } from 'lucide-vue-next'

import { useContextPanelStore } from '@/app/layouts/contextPanelStore'
import EmptyState from '@/components/shared/EmptyState.vue'
import ErrorState from '@/components/shared/ErrorState.vue'
import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import SurfaceCard from '@/components/shared/SurfaceCard.vue'
import UiButton from '@/components/ui/UiButton.vue'
import type { PreviewState } from '@/features/planning/types'
import NewTaskDialog from '@/features/tasks/components/NewTaskDialog.vue'
import TaskFilters from '@/features/tasks/components/TaskFilters.vue'
import TaskListRow from '@/features/tasks/components/TaskListRow.vue'
import { useTasksStore } from '@/features/tasks/store'
import { showPreviewNote } from '@/lib/preview'

const route = useRoute()
const store = useTasksStore()
const panel = useContextPanelStore()

/** `?preview=loading|error|empty` forces a UI state for design review. */
function previewFromQuery(): PreviewState {
  const value = route.query.preview
  return value === 'loading' || value === 'error' || value === 'empty' ? value : null
}

onMounted(() => store.load(previewFromQuery()))
watch(
  () => route.query.preview,
  () => store.load(previewFromQuery()),
)

const searchInput = ref<HTMLInputElement | null>(null)
const dialogOpen = ref(false)

const isLoading = computed(() => store.status === 'loading' || store.status === 'idle')

/** Which empty state to show, in priority order. */
const emptyKind = computed<'search' | 'filter' | null>(() => {
  if (store.visibleTasks.length > 0) return null
  return store.hasActiveSearch ? 'search' : 'filter'
})

const emptyCopy = computed(() => {
  if (emptyKind.value === 'search') {
    return {
      title: 'No tasks found.',
      description: `Nothing matches “${store.searchQuery.trim()}”. Try a different search.`,
    }
  }
  if (store.statusFilter === 'ALL') {
    return {
      title: 'No tasks yet.',
      description: "Capture something you're thinking about.",
    }
  }
  return {
    title: 'Nothing here.',
    description: 'No tasks with this status right now.',
  }
})

function onSelectTask(taskId: string) {
  panel.toggleTask(taskId)
}

function onClearSearch() {
  store.setSearch('')
  searchInput.value?.focus()
}

function onCreateTask(draft: Parameters<typeof store.addTask>[0]) {
  store.addTask(draft)
  showPreviewNote('Task captured locally — it will sync once the Task API is connected.')
}

function onRetry() {
  store.load(null)
}
</script>

<template>
  <div class="tasks-page">
    <header class="page-header">
      <div class="heading">
        <h1 class="title">Tasks</h1>
        <p class="subtitle">Everything you're working on.</p>
      </div>
      <div class="actions">
        <div class="search" :class="{ filled: store.searchQuery.length > 0 }">
          <Search :size="14" :stroke-width="1.75" class="search-icon" />
          <input
            ref="searchInput"
            :value="store.searchQuery"
            type="text"
            class="search-input"
            placeholder="Search tasks…"
            aria-label="Search tasks"
            @input="store.setSearch(($event.target as HTMLInputElement).value)"
          />
          <button
            v-if="store.searchQuery"
            class="clear"
            type="button"
            aria-label="Clear search"
            @click="onClearSearch"
          >
            <X :size="13" :stroke-width="2" />
          </button>
        </div>
        <UiButton variant="primary" @click="dialogOpen = true">
          <Plus :size="15" :stroke-width="2" />
          New Task
        </UiButton>
      </div>
    </header>

    <TaskFilters
      :active="store.statusFilter"
      :counts="store.filterCounts"
      @change="store.setFilter($event)"
    />

    <!-- Loading -->
    <SurfaceCard v-if="isLoading" class="list-card" aria-busy="true" aria-label="Loading tasks">
      <div class="skeleton-rows">
        <SkeletonBlock v-for="i in 8" :key="i" height="44px" rounded="md" />
      </div>
    </SurfaceCard>

    <!-- Error -->
    <ErrorState
      v-else-if="store.status === 'error'"
      title="Tasks didn't load"
      description="Your tasks could not be reached. Your data is safe — try loading them again."
      @retry="onRetry"
    />

    <!-- Empty / no results -->
    <EmptyState
      v-else-if="emptyKind"
      :icon="emptyKind === 'search' ? SearchX : ListChecks"
      :title="emptyCopy.title"
      :description="emptyCopy.description"
    >
      <UiButton
        v-if="emptyKind === 'search'"
        variant="ghost"
        size="sm"
        class="empty-action"
        @click="onClearSearch"
      >
        Clear search
      </UiButton>
      <UiButton v-else variant="primary" size="sm" class="empty-action" @click="dialogOpen = true">
        <Plus :size="14" :stroke-width="2" />
        New Task
      </UiButton>
    </EmptyState>

    <!-- List -->
    <SurfaceCard v-else class="list-card">
      <TransitionGroup name="row" tag="div" class="rows">
        <TaskListRow
          v-for="task in store.visibleTasks"
          :key="task.id"
          :task="task"
          :active="task.id === panel.activeTaskId"
          @select="onSelectTask"
        />
      </TransitionGroup>
    </SurfaceCard>

    <NewTaskDialog :open="dialogOpen" @close="dialogOpen = false" @create="onCreateTask" />
  </div>
</template>

<style scoped>
.tasks-page {
  max-width: 980px;
  margin: 0 auto;
  padding: var(--space-8) var(--space-8) var(--space-12);
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.page-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-6);
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

.actions {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  flex-shrink: 0;
}

.search {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  width: 220px;
  height: 36px;
  padding: 0 var(--space-3);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.search:focus-within {
  border-color: var(--accent-border);
  background: var(--surface-2);
}

.search-icon {
  color: var(--text-tertiary);
  flex-shrink: 0;
}

.search-input {
  flex: 1;
  min-width: 0;
  background: transparent;
  border: none;
  outline: none;
  font-size: var(--text-md);
  color: var(--text-primary);
}

.search-input::placeholder {
  color: var(--text-disabled);
}

.clear {
  display: grid;
  place-items: center;
  width: 20px;
  height: 20px;
  border-radius: var(--radius-sm);
  color: var(--text-tertiary);
  flex-shrink: 0;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.clear:hover {
  background: var(--surface-3);
  color: var(--text-primary);
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

.empty-action {
  margin-top: var(--space-4);
}

.row-move,
.row-enter-active,
.row-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.row-enter-from,
.row-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}

.row-leave-active {
  position: absolute;
}

@media (max-width: 900px) {
  .page-header {
    flex-direction: column;
    align-items: stretch;
    gap: var(--space-4);
  }

  .actions {
    justify-content: space-between;
  }

  .search {
    flex: 1;
  }
}
</style>
