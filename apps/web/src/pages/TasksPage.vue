<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import {
  CalendarDays,
  Check,
  CheckCircle2,
  Clock,
  FolderKanban,
  LayoutGrid,
  List,
  ListChecks,
  Plus,
  Repeat,
  Search,
  SearchX,
  Undo2,
  X,
} from 'lucide-vue-next'

import { useContextPanelStore } from '@/app/layouts/contextPanelStore'
import EmptyState from '@/components/shared/EmptyState.vue'
import ErrorState from '@/components/shared/ErrorState.vue'
import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import SurfaceCard from '@/components/shared/SurfaceCard.vue'
import UiButton from '@/components/ui/UiButton.vue'
import { formatClockTime, toISODate } from '@/lib/utils/date'
import { formatMinutes } from '@/lib/utils/duration'
import type { PreviewState } from '@/features/planning/types'
import NewTaskDialog from '@/features/tasks/components/NewTaskDialog.vue'
import TaskFilters from '@/features/tasks/components/TaskFilters.vue'
import TaskListRow from '@/features/tasks/components/TaskListRow.vue'
import TaskPrioritySegments from '@/features/tasks/components/TaskPrioritySegments.vue'
import { useProjectsStore } from '@/features/projects/store'
import { useTasksStore } from '@/features/tasks/store'
import type { Task } from '@/features/tasks/types'
import { showPreviewNote } from '@/lib/preview'

const route = useRoute()
const store = useTasksStore()
const projectsStore = useProjectsStore()
const panel = useContextPanelStore()

/** `?preview=loading|error|empty` forces a UI state for design review. */
function previewFromQuery(): PreviewState {
  const value = route.query.preview
  return value === 'loading' || value === 'error' || value === 'empty' ? value : null
}

/** `?open=<id>` lands here from global search (spec: global-search AC-010). */
const openTaskId = computed(() => {
  const value = route.query.open
  return typeof value === 'string' && value ? value : null
})

/** Lands the workspace with the first task's detail open. While loading, a
 *  skeleton reserves the panel so the workspace doesn't reflow on ready. */
async function loadAndSelect(preview: PreviewState) {
  if (!panel.isOpen) panel.openSkeleton()
  await store.load(preview)
  // Project names for grouping come from the projects store — load once.
  if (projectsStore.status === 'idle') void projectsStore.load()

  // A search result wins over the default first item.
  if (openTaskId.value && store.taskById(openTaskId.value)) {
    panel.openTask(openTaskId.value)
    return
  }

  if (preview === 'loading' || !panel.isSkeleton) return
  if (store.status === 'ready' && store.visibleTasks.length > 0) {
    panel.openTask(store.visibleTasks[0].id)
  } else {
    panel.close()
  }
}

onMounted(() => loadAndSelect(previewFromQuery()))
watch(
  () => route.query.preview,
  () => loadAndSelect(previewFromQuery()),
)

// A search result picked while already on this page opens the panel live.
watch(
  () => route.query.open,
  (value) => {
    const id = typeof value === 'string' && value ? value : null
    if (id && store.status === 'ready' && store.taskById(id)) panel.openTask(id)
  },
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
      description: `Nothing matches "${store.searchQuery.trim()}". Try a different search.`,
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

/* ---------------- View & grouping controls ---------------- */

type ViewMode = 'list' | 'grid'
type GroupMode = 'date' | 'project'

const viewMode = ref<ViewMode>('list')
const groupMode = ref<GroupMode>('date')

/* ---------------- Grouping (shared by list + grid) ---------------- */

const todayISO = computed(() => toISODate(new Date()))

function dayLabelFor(iso: string): { dayLabel: string; isToday: boolean } {
  const today = todayISO.value
  if (iso === today) return { dayLabel: 'Today', isToday: true }
  const tomorrow = new Date()
  tomorrow.setDate(tomorrow.getDate() + 1)
  if (iso === toISODate(tomorrow)) return { dayLabel: 'Tomorrow', isToday: false }
  const date = new Date(`${iso}T00:00:00`)
  const weekday = new Intl.DateTimeFormat('en-US', { weekday: 'long' }).format(date)
  return { dayLabel: weekday, isToday: false }
}

interface DateGroup {
  key: string
  /** "Today" / "Tomorrow" / weekday label */
  dayLabel: string
  dateLabel: string
  date: string // ISO
  isToday: boolean
  tasks: Task[]
}

const dateGroups = computed<DateGroup[]>(() => {
  const byDate = new Map<string, Task[]>()
  const noDate: Task[] = []
  for (const task of store.visibleTasks) {
    const due = task.dueDate
    if (due) {
      const bucket = byDate.get(due)
      if (bucket) bucket.push(task)
      else byDate.set(due, [task])
    } else {
      noDate.push(task)
    }
  }

  const groups: DateGroup[] = []
  for (const [iso, tasks] of byDate) {
    const label = dayLabelFor(iso)
    groups.push({
      key: iso,
      date: iso,
      dayLabel: label.dayLabel,
      dateLabel: new Intl.DateTimeFormat('en-US', {
        month: 'short',
        day: 'numeric',
      }).format(new Date(`${iso}T00:00:00`)),
      isToday: label.isToday,
      tasks,
    })
  }
  groups.sort((a, b) => a.date.localeCompare(b.date))

  if (noDate.length > 0) {
    groups.push({ key: 'none', dayLabel: 'Unscheduled', dateLabel: 'No due date', date: '', isToday: false, tasks: noDate })
  }
  return groups
})

interface ProjectGroup {
  key: string
  name: string
  color: string | null
  tasks: Task[]
}

const projectGroups = computed<ProjectGroup[]>(() => {
  const byProject = new Map<string, Task[]>()
  for (const task of store.visibleTasks) {
    const key = task.projectId ?? 'none'
    const bucket = byProject.get(key)
    if (bucket) bucket.push(task)
    else byProject.set(key, [task])
  }

  const ordered: ProjectGroup[] = []
  for (const project of projectsStore.projects) {
    const tasks = byProject.get(project.id)
    if (tasks?.length) {
      ordered.push({ key: project.id, name: project.name, color: project.color, tasks })
      byProject.delete(project.id)
    }
  }
  for (const [key, tasks] of byProject) {
    ordered.push({ key, name: 'No project', color: null, tasks })
  }
  return ordered
})

/** Unified grouping — returns date or project groups depending on mode. */
const groups = computed(() =>
  groupMode.value === 'date' ? dateGroups.value : projectGroups.value,
)

/* ---------------- Row rendering ---------------- */

function sortTasks(list: Task[]): Task[] {
  const order: Record<Task['status'], number> = {
    IN_PROGRESS: 0,
    PLANNED: 1,
    INBOX: 2,
    COMPLETED: 3,
    CANCELLED: 4,
  }
  return list
    .slice()
    .sort((a, b) => order[a.status] - order[b.status] || a.title.localeCompare(b.title))
}

/* ---------------- Interactions ---------------- */

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

/* ---------------- Completion toast ---------------- */

interface ToastState {
  title: string
  kind: 'complete' | 'reopen' | 'create'
}

const toast = ref<ToastState | null>(null)
let toastTimer: ReturnType<typeof setTimeout> | undefined
let toastWatchStopped = false

watch(
  () => store.lastUndoable,
  (last) => {
    if (!last || toastWatchStopped) return
    if (last.kind === 'complete') {
      showToast({ title: last.task.title, kind: 'complete' })
    } else if (last.kind === 'reopen') {
      showToast({ title: last.task.title, kind: 'reopen' })
    }
  },
)

function showToast(state: ToastState) {
  toast.value = state
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => (toast.value = null), 5000)
}

function onUndo() {
  toastWatchStopped = true
  store.undoLast()
  toast.value = null
  setTimeout(() => (toastWatchStopped = false), 0)
}
</script>

<template>
  <div class="tasks-page">
    <!-- Hero header — spacious, matches Today workspace aesthetic (spec §16, §22) -->
    <header class="hero">
      <div class="hero-text">
        <h1 class="hero-title">Tasks</h1>
        <p class="hero-sub">Everything you're working on.</p>
      </div>
      <div class="hero-actions">
        <div class="search" :class="{ filled: store.searchQuery.length > 0 }">
          <Search :size="16" :stroke-width="1.75" class="search-icon" />
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
            <X :size="14" :stroke-width="2" />
          </button>
        </div>
        <UiButton variant="primary" @click="dialogOpen = true">
          <Plus :size="16" :stroke-width="2" />
          New Task
        </UiButton>
      </div>
    </header>

    <!-- Toolbar: filters prominent, view controls subtle (spec §10: "Filters should not dominate") -->
    <div class="toolbar">
      <TaskFilters
        :active="store.statusFilter"
        :counts="store.filterCounts"
        @change="store.setFilter($event)"
      />

      <div class="view-controls" role="group" aria-label="Task view">
        <div class="seg-toggle" role="group" aria-label="Group tasks by">
          <button
            type="button"
            class="seg-btn"
            :class="{ active: groupMode === 'date' }"
            @click="groupMode = 'date'"
          >
            <CalendarDays :size="14" :stroke-width="1.75" />
            Date
          </button>
          <button
            type="button"
            class="seg-btn"
            :class="{ active: groupMode === 'project' }"
            @click="groupMode = 'project'"
          >
            <FolderKanban :size="14" :stroke-width="1.75" />
            Project
          </button>
        </div>

        <div class="seg-toggle" role="group" aria-label="Layout">
          <button
            type="button"
            class="seg-btn icon-only"
            :class="{ active: viewMode === 'list' }"
            title="List"
            aria-label="List layout"
            @click="viewMode = 'list'"
          >
            <List :size="15" :stroke-width="1.75" />
          </button>
          <button
            type="button"
            class="seg-btn icon-only"
            :class="{ active: viewMode === 'grid' }"
            title="Grid"
            aria-label="Grid layout"
            @click="viewMode = 'grid'"
          >
            <LayoutGrid :size="15" :stroke-width="1.75" />
          </button>
        </div>
      </div>
    </div>

    <!-- Loading — mirrors the hero, toolbar, and grouped rows -->
    <div v-if="isLoading" class="skeleton-page" aria-busy="true" aria-label="Loading tasks">
      <div class="skeleton-hero">
        <div class="skeleton-hero-text">
          <SkeletonBlock height="44px" width="220px" rounded="md" />
          <SkeletonBlock height="20px" width="300px" rounded="md" />
        </div>
        <SkeletonBlock height="44px" width="280px" rounded="md" />
      </div>
      <div class="skeleton-toolbar">
        <SkeletonBlock height="38px" width="380px" rounded="full" />
        <SkeletonBlock height="36px" width="220px" rounded="md" />
      </div>
      <div class="skeleton-list">
        <div v-for="i in 3" :key="i" class="skeleton-group">
          <SkeletonBlock height="20px" width="140px" rounded="sm" />
          <div class="skeleton-rows">
            <SkeletonBlock v-for="j in 4" :key="j" height="56px" rounded="md" />
          </div>
        </div>
      </div>
    </div>

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

    <!-- List view (default) — lightweight rows grouped by date or project (spec §8) -->
    <TransitionGroup v-else-if="viewMode === 'list'" name="row" tag="div" class="groups">
      <section v-for="group in groups" :key="group.key" class="group">
        <header class="group-header">
          <span
            v-if="groupMode === 'project'"
            class="group-dot"
            :style="{ background: (group as ProjectGroup).color ?? 'var(--text-disabled)' }"
            aria-hidden="true"
          />
          <h2 class="group-name">{{ groupMode === 'date' ? (group as DateGroup).dayLabel : (group as ProjectGroup).name }}</h2>
          <span v-if="groupMode === 'date'" class="group-date">{{ (group as DateGroup).dateLabel }}</span>
          <span class="group-count tnum">{{ group.tasks.length }}</span>
        </header>
        <TransitionGroup name="row" tag="div" class="rows">
          <TaskListRow
            v-for="task in sortTasks(group.tasks)"
            :key="task.id"
            :task="task"
            :active="task.id === panel.activeTaskId"
            hide-project
            @select="onSelectTask"
          />
        </TransitionGroup>
      </section>
    </TransitionGroup>

    <!-- Grid view (secondary) — organized column cards (spec §8, §26) -->
    <TransitionGroup v-else name="card" tag="div" class="day-grid">
      <SurfaceCard
        v-for="group in groups"
        :key="group.key"
        class="day-card"
        :class="{ today: groupMode === 'date' && (group as DateGroup).isToday }"
        :padded="false"
      >
        <header class="day-header">
          <div class="day-titles">
            <span
              v-if="groupMode === 'project'"
              class="project-dot"
              :style="{ background: (group as ProjectGroup).color ?? 'var(--text-disabled)' }"
            />
            <div class="day-label-stack">
              <h2 class="day-name">{{ groupMode === 'date' ? (group as DateGroup).dayLabel : (group as ProjectGroup).name }}</h2>
              <span v-if="groupMode === 'date'" class="day-date">{{ (group as DateGroup).dateLabel }}</span>
            </div>
          </div>
          <span class="day-count tnum">{{ group.tasks.length }}</span>
        </header>

        <div class="day-tasks">
          <div
            v-for="(task, idx) in sortTasks(group.tasks)"
            :key="task.id"
            class="day-task"
            :class="{
              completed: task.status === 'COMPLETED',
              'has-border': idx > 0,
            }"
            role="button"
            tabindex="0"
            :aria-pressed="task.id === panel.activeTaskId || undefined"
            @click="onSelectTask(task.id)"
            @keydown.enter.prevent="onSelectTask(task.id)"
            @keydown.space.prevent="onSelectTask(task.id)"
          >
            <button
              class="check"
              :class="{ checked: task.status === 'COMPLETED' }"
              type="button"
              role="checkbox"
              :aria-checked="task.status === 'COMPLETED'"
              :aria-label="task.status === 'COMPLETED' ? `Reopen ${task.title}` : `Complete ${task.title}`"
              @click.stop="store.toggleTaskComplete(task.id)"
            >
              <Check v-if="task.status === 'COMPLETED'" :size="11" :stroke-width="3" />
            </button>

            <div class="task-main">
              <span class="task-title">{{ task.title }}</span>
              <span class="task-meta">
                <span v-if="task.scheduledTime" class="chip tnum">
                  <Clock :size="11" :stroke-width="1.75" />
                  {{ formatClockTime(task.scheduledTime) }}
                </span>
                <span v-if="task.estimatedMinutes" class="chip tnum">
                  {{ formatMinutes(task.estimatedMinutes) }}
                </span>
                <span v-if="task.recurrence" class="chip">
                  <Repeat :size="11" :stroke-width="1.75" />
                  {{ task.recurrence }}
                </span>
              </span>
            </div>

            <TaskPrioritySegments v-if="task.priority" :priority="task.priority" class="prio" />
          </div>
        </div>
      </SurfaceCard>
    </TransitionGroup>

    <NewTaskDialog :open="dialogOpen" @close="dialogOpen = false" @create="onCreateTask" />

    <!-- Completion toast -->
    <Transition name="toast">
      <div v-if="toast" class="completion-toast" role="status">
        <span class="toast-icon">
          <CheckCircle2 v-if="toast.kind === 'complete'" :size="14" :stroke-width="2.5" />
          <Undo2 v-else :size="14" :stroke-width="2.5" />
        </span>
        <span class="toast-text">
          <strong>{{ toast.kind === 'complete' ? 'Task completed' : 'Task reopened' }}</strong>
          <span class="toast-title">{{ toast.title }}</span>
        </span>
        <button class="undo" type="button" @click="onUndo">Undo</button>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.tasks-page {
  max-width: var(--content-max);
  margin: 0 auto;
  padding: var(--space-6) var(--space-10) var(--space-16);
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

/* ---------- Hero header (spec §16: page hero is the largest type) ---------- */

.hero {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-6);
  margin-bottom: var(--space-2);
}

.hero-title {
  font-size: var(--text-hero);
  font-weight: 700;
  letter-spacing: -0.03em;
  line-height: 1.12;
  color: var(--text-primary);
}

.hero-sub {
  margin-top: var(--space-3);
  font-size: var(--text-lg);
  color: var(--text-tertiary);
}

.hero-actions {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  flex-shrink: 0;
  padding-bottom: var(--space-1);
}

.search {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  width: 280px;
  height: 44px;
  padding: 0 var(--space-4);
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
  width: 22px;
  height: 22px;
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

/* ---------- Toolbar ---------- */

.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  flex-wrap: wrap;
}

.view-controls {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  flex-shrink: 0;
}

.seg-toggle {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  padding: 3px;
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
}

.seg-btn {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  height: 30px;
  padding: 0 var(--space-3);
  border: none;
  border-radius: calc(var(--radius-md) - 4px);
  background: transparent;
  color: var(--text-tertiary);
  font-size: var(--text-sm);
  font-weight: 500;
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.seg-btn:hover {
  color: var(--text-primary);
}

.seg-btn.active {
  background: var(--surface-3);
  color: var(--text-primary);
  box-shadow: var(--shadow-panel);
}

.seg-btn.icon-only {
  width: 30px;
  padding: 0;
  justify-content: center;
}

/* ---------- List groups (default view) ---------- */

.groups {
  display: flex;
  flex-direction: column;
  gap: var(--space-8);
}

.group {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.group-header {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: 0 var(--space-2);
  margin-bottom: var(--space-1);
}

.group-dot {
  width: 9px;
  height: 9px;
  border-radius: var(--radius-full);
  flex-shrink: 0;
}

.group-name {
  font-size: var(--text-xl);
  font-weight: 650;
  letter-spacing: -0.015em;
  color: var(--text-primary);
}

.group-date {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.group-count {
  display: inline-grid;
  place-items: center;
  min-width: 26px;
  height: 22px;
  padding: 0 8px;
  border-radius: var(--radius-full);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--text-tertiary);
}

.rows {
  display: flex;
  flex-direction: column;
}

/* ---------- Grid (secondary view) — organized columns ---------- */

.day-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: var(--space-5);
  align-items: start;
}

.day-card {
  padding: 0;
  overflow: hidden;
  transition:
    border-color var(--duration-normal) var(--ease-out),
    box-shadow var(--duration-normal) var(--ease-out);
}

.day-card.today {
  border-color: var(--accent-border);
}

.day-card:has(.day-task:hover) {
  border-color: var(--border-strong);
}

.day-card.today:has(.day-task:hover) {
  border-color: var(--accent-strong);
}

.day-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-3);
  padding: var(--space-5) var(--space-5) var(--space-4);
  border-bottom: 1px solid var(--border-subtle);
}

.day-card.today .day-header {
  background: linear-gradient(180deg, var(--accent-soft) 0%, transparent 100%);
}

.day-titles {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  min-width: 0;
}

.day-label-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.project-dot {
  width: 10px;
  height: 10px;
  border-radius: var(--radius-full);
  flex-shrink: 0;
  margin-top: 4px;
}

.day-name {
  font-size: var(--text-xl);
  font-weight: 650;
  letter-spacing: -0.015em;
  color: var(--text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  line-height: 1.2;
}

.day-date {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  white-space: nowrap;
  line-height: 1.3;
}

.day-count {
  display: inline-grid;
  place-items: center;
  min-width: 26px;
  height: 22px;
  padding: 0 8px;
  border-radius: var(--radius-full);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--text-tertiary);
  flex-shrink: 0;
  margin-top: 2px;
}

.day-card.today .day-count {
  background: var(--accent-soft);
  border-color: var(--accent-border);
  color: var(--accent-strong);
}

.day-tasks {
  display: flex;
  flex-direction: column;
  padding: var(--space-2) var(--space-3) var(--space-4);
}

.day-task {
  display: flex;
  align-items: flex-start;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-3);
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.day-task.has-border {
  border-top: 1px solid var(--border-subtle);
  border-radius: 0;
}

.day-task.has-border:first-child {
  border-top: none;
}

.day-task:hover {
  background: var(--surface-2);
}

.day-task.has-border:hover {
  border-radius: var(--radius-md);
}

.day-task.completed .task-title {
  color: var(--text-tertiary);
  text-decoration: line-through;
  text-decoration-color: var(--text-disabled);
}

.check {
  display: grid;
  place-items: center;
  width: 20px;
  height: 20px;
  flex-shrink: 0;
  margin-top: 1px;
  border-radius: var(--radius-full);
  border: 1.5px solid var(--text-disabled);
  background: transparent;
  color: var(--surface-1);
  cursor: pointer;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out),
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

.task-main {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  min-width: 0;
  flex: 1;
}

.task-title {
  font-size: var(--text-lg);
  font-weight: 550;
  letter-spacing: -0.01em;
  color: var(--text-primary);
  line-height: 1.3;
}

.task-meta {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.chip {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 2px 9px;
  border-radius: var(--radius-full);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  font-size: var(--text-xs);
  font-weight: 500;
  color: var(--text-tertiary);
  white-space: nowrap;
}

.chip svg {
  color: var(--text-disabled);
}

.prio {
  flex-shrink: 0;
  margin-top: 5px;
}

/* ---------- Skeletons ---------- */

.skeleton-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.skeleton-hero {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-6);
}

.skeleton-hero-text {
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

.skeleton-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-8);
}

.skeleton-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.skeleton-rows {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

/* ---------- Toast ---------- */

.completion-toast {
  position: fixed;
  bottom: var(--space-6);
  left: 50%;
  transform: translateX(-50%);
  z-index: 70;
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  border: 1px solid var(--border-strong);
  border-radius: var(--radius-full);
  background: var(--surface-3);
  box-shadow: var(--shadow-panel);
  font-size: var(--text-sm);
  color: var(--text-secondary);
}

.toast-icon {
  display: grid;
  place-items: center;
  width: 24px;
  height: 24px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  background: var(--success-soft);
  color: var(--success);
}

.toast-text {
  display: flex;
  flex-direction: column;
  line-height: 1.35;
}

.toast-text strong {
  font-weight: 600;
  color: var(--text-primary);
}

.toast-title {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  max-width: 280px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.undo {
  margin-left: var(--space-2);
  padding: var(--space-2) var(--space-3);
  border: none;
  border-radius: var(--radius-md);
  background: var(--surface-2);
  color: var(--accent-strong);
  font-size: var(--text-sm);
  font-weight: 600;
  cursor: pointer;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.undo:hover {
  background: var(--surface-1);
}

/* ---------- Empty ---------- */

.empty-action {
  margin-top: var(--space-4);
}

/* ---------- Transitions ---------- */

.card-move,
.card-enter-active,
.card-leave-active {
  transition:
    opacity var(--duration-normal) var(--ease-out),
    transform var(--duration-normal) var(--ease-out);
}

.card-enter-from,
.card-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

.card-leave-active {
  position: absolute;
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

.toast-enter-active,
.toast-leave-active {
  transition:
    opacity var(--duration-normal) var(--ease-out),
    transform var(--duration-normal) var(--ease-out);
}

.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(12px);
}

/* ---------- Responsive ---------- */

@media (max-width: 900px) {
  .hero {
    flex-direction: column;
    align-items: stretch;
    gap: var(--space-4);
  }

  .hero-actions {
    justify-content: space-between;
  }

  .search {
    flex: 1;
  }
}
</style>