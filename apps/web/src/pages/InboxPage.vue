<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Inbox, Plus, SlidersHorizontal } from 'lucide-vue-next'

import { useContextPanelStore } from '@/app/layouts/contextPanelStore'
import EmptyState from '@/components/shared/EmptyState.vue'
import ErrorState from '@/components/shared/ErrorState.vue'
import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import UiButton from '@/components/ui/UiButton.vue'
import type { PreviewState } from '@/features/planning/types'
import InboxTaskCard from '@/features/tasks/components/InboxTaskCard.vue'
import QuickCapture from '@/features/tasks/components/QuickCapture.vue'
import { useTasksStore } from '@/features/tasks/store'
import type { Task } from '@/features/tasks/types'
import { showPreviewNote } from '@/lib/preview'

const route = useRoute()
const store = useTasksStore()
const panel = useContextPanelStore()

function previewFromQuery(): PreviewState {
  const value = route.query.preview
  return value === 'loading' || value === 'error' || value === 'empty' ? value : null
}

/** Lands the workspace with the newest captured item's detail open. While
 *  loading, a skeleton reserves the panel so the workspace doesn't reflow. */
async function loadAndSelect(preview: PreviewState) {
  if (!panel.isOpen) panel.openSkeleton()
  await store.load(preview)
  if (preview === 'loading' || !panel.isSkeleton) return
  if (store.status === 'ready' && store.inboxTasks.length > 0) {
    panel.openTask(store.inboxTasks[0].id)
  } else {
    panel.close()
  }
}

onMounted(() => loadAndSelect(previewFromQuery()))
watch(
  () => route.query.preview,
  () => loadAndSelect(previewFromQuery()),
)

const isLoading = computed(() => store.status === 'loading' || store.status === 'idle')

const subtitle = computed(() => {
  const count = store.inboxTasks.length
  if (count === 0) return "Things you've captured but haven't organized yet."
  return `${count} thing${count === 1 ? '' : 's'} waiting for your attention.`
})

/* ---------------- Tabs: segment captured items by recency ---------------- */

type InboxTab = 'all' | 'today' | 'earlier'

const activeTab = ref<InboxTab>('all')

const DAY_MS = 86_400_000

function isToday(task: Task): boolean {
  return Date.now() - new Date(task.createdAt).getTime() < DAY_MS
}

const tabs = computed(() => {
  const all = store.inboxTasks
  const today = all.filter(isToday)
  return [
    { key: 'all' as InboxTab, label: 'All', count: all.length },
    { key: 'today' as InboxTab, label: 'Today', count: today.length },
    { key: 'earlier' as InboxTab, label: 'Earlier', count: all.length - today.length },
  ]
})

const visibleTasks = computed(() => {
  if (activeTab.value === 'today') return store.inboxTasks.filter(isToday)
  if (activeTab.value === 'earlier') return store.inboxTasks.filter((t) => !isToday(t))
  return store.inboxTasks
})

/* ---------------- Interactions ---------------- */

const captureRef = ref<InstanceType<typeof QuickCapture> | null>(null)

function onCapture(title: string) {
  store.addInboxTask(title)
  showPreviewNote('Captured locally — it will sync once the Task API is connected.')
}

function onAddNew() {
  const input = captureRef.value?.$el.querySelector('input')
  input?.focus()
  input?.scrollIntoView({ behavior: 'smooth', block: 'center' })
}

function onFilterSort() {
  showPreviewNote('Filter & sort options arrive with the Task API milestone — visual only for now.')
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

    <QuickCapture ref="captureRef" @capture="onCapture" />

    <!-- Toolbar: recency tabs with counts (left) + actions (right) -->
    <div class="toolbar">
      <div class="tabs" role="tablist" aria-label="Inbox segments">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          type="button"
          role="tab"
          class="tab"
          :class="{ active: activeTab === tab.key }"
          :aria-selected="activeTab === tab.key"
          @click="activeTab = tab.key"
        >
          {{ tab.label }}
          <span class="tab-count tnum">{{ tab.count }}</span>
        </button>
      </div>

      <div class="toolbar-actions">
        <UiButton variant="ghost" size="sm" @click="onFilterSort">
          <SlidersHorizontal :size="14" :stroke-width="1.75" />
          Filter & Sort
        </UiButton>
        <UiButton variant="primary" size="sm" @click="onAddNew">
          <Plus :size="14" :stroke-width="2" />
          Add New
        </UiButton>
      </div>
    </div>

    <!-- Loading — mirrors the header, quick capture, tabs, and card grid -->
    <div v-if="isLoading" class="skeleton-page" aria-busy="true" aria-label="Loading inbox">
      <div class="skeleton-heading">
        <SkeletonBlock height="30px" width="140px" rounded="md" />
        <SkeletonBlock height="18px" width="320px" rounded="md" />
      </div>
      <SkeletonBlock height="64px" rounded="lg" />
      <div class="skeleton-toolbar">
        <SkeletonBlock height="38px" width="300px" rounded="md" />
        <SkeletonBlock height="38px" width="220px" rounded="md" />
      </div>
      <div class="card-grid">
        <SkeletonBlock v-for="i in 8" :key="i" height="216px" rounded="lg" />
      </div>
    </div>

    <!-- Error -->
    <ErrorState
      v-else-if="store.status === 'error'"
      title="Inbox didn't load"
      description="Your captured tasks could not be reached. Your data is safe — try loading them again."
      @retry="onRetry"
    />

    <!-- Empty -->
    <EmptyState
      v-else-if="visibleTasks.length === 0"
      :icon="Inbox"
      :title="activeTab === 'all' ? 'Your inbox is clear.' : 'Nothing in this segment.'"
      description="Nothing waiting to be organized. Capture something above when it crosses your mind."
    />

    <!-- Card grid -->
    <TransitionGroup v-else name="card" tag="div" class="card-grid">
      <InboxTaskCard
        v-for="task in visibleTasks"
        :key="task.id"
        :task="task"
        :active="task.id === panel.activeTaskId"
        @select="onSelectTask"
      />
    </TransitionGroup>
  </div>
</template>

<style scoped>
.inbox-page {
  max-width: var(--content-max);
  margin: 0 auto;
  padding: var(--space-8) var(--space-10) var(--space-16);
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.page-header {
  margin-bottom: calc(var(--space-2) * -1);
}

.title {
  font-size: var(--text-3xl);
  font-weight: 650;
  letter-spacing: -0.025em;
}

.subtitle {
  margin-top: var(--space-2);
  font-size: var(--text-md);
  color: var(--text-tertiary);
}

/* ---------- Toolbar (reference: tabs left, actions right) ---------- */

.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  flex-wrap: wrap;
}

.tabs {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.tab {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  height: 38px;
  padding: 0 var(--space-4);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--text-tertiary);
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.tab:hover {
  color: var(--text-primary);
  background: var(--surface-1);
}

.tab.active {
  color: var(--text-primary);
  background: var(--surface-1);
  box-shadow: inset 0 0 0 1px var(--border-subtle);
}

.tab-count {
  display: inline-grid;
  place-items: center;
  min-width: 22px;
  height: 20px;
  padding: 0 6px;
  border-radius: var(--radius-full);
  background: var(--surface-2);
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--text-tertiary);
}

.tab.active .tab-count {
  background: var(--accent-soft);
  color: var(--accent-strong);
}

.toolbar-actions {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  flex-shrink: 0;
}

/* ---------- Card grid (reference: uniform white cards, 4-up on desktop) ---------- */

.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(272px, 1fr));
  gap: var(--space-5);
  align-items: stretch;
}

.skeleton-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.skeleton-heading {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.skeleton-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
}

.card-move,
.card-enter-active,
.card-leave-active {
  transition:
    opacity var(--duration-normal) var(--ease-out),
    transform var(--duration-normal) var(--ease-out);
}

.card-enter-from {
  opacity: 0;
  transform: translateY(8px);
}

.card-leave-to {
  opacity: 0;
}

.card-leave-active {
  position: absolute;
}
</style>
