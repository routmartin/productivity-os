<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  CalendarDays,
  Check,
  Clock,
  FolderKanban,
  LayoutGrid,
  List,
  ListChecks,
  Plus,
  Repeat,
  Search,
  SearchX,
  X,
} from 'lucide-vue-next'

import { useContextPanelStore } from '@/app/layouts/contextPanelStore'
import EmptyState from '@/components/shared/EmptyState.vue'
import ErrorState from '@/components/shared/ErrorState.vue'
import SectionHeader from '@/components/shared/SectionHeader.vue'
import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import SurfaceCard from '@/components/shared/SurfaceCard.vue'
import UiButton from '@/components/ui/UiButton.vue'
import { formatClockTime } from '@/lib/utils/date'
import { formatMinutes } from '@/lib/utils/duration'
import type { PreviewState } from '@/features/planning/types'
import TaskDateSegments from '@/features/tasks/components/TaskDateSegments.vue'
import TaskFilters from '@/features/tasks/components/TaskFilters.vue'
import TaskListRow from '@/features/tasks/components/TaskListRow.vue'
import TaskPrioritySegments from '@/features/tasks/components/TaskPrioritySegments.vue'
import { useProjectsStore } from '@/features/projects/store'
import { useTasksStore } from '@/features/tasks/store'
import type { DateSegment, Task } from '@/features/tasks/types'

const route = useRoute()
const router = useRouter()
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

/* ---------------- View & grouping controls ---------------- */

type ViewMode = 'list' | 'grid'
type GroupMode = 'date' | 'project'

const viewMode = ref<ViewMode>('list')
const groupMode = ref<GroupMode>('project')
const userOverrodeGrouping = ref(false)

function setManualGroupMode(mode: GroupMode) {
  userOverrodeGrouping.value = true
  groupMode.value = mode
}

function applyAdaptiveGrouping(segment: DateSegment) {
  if (userOverrodeGrouping.value) return
  if (segment === 'UPCOMING') {
    groupMode.value = 'date'
  } else if (segment === 'BACKLOG') {
    groupMode.value = 'project'
  } else if (segment === 'TODAY') {
    groupMode.value = 'project'
  } else if (segment === 'ALL') {
    groupMode.value = 'project'
  }
}

function parseSegmentQuery(param: unknown): DateSegment | null {
  if (typeof param !== 'string') return null
  const lower = param.toLowerCase()
  if (lower === 'all') return 'ALL'
  if (lower === 'today') return 'TODAY'
  if (lower === 'upcoming') return 'UPCOMING'
  if (lower === 'backlog') return 'BACKLOG'
  return null
}

function onSegmentChange(segment: DateSegment) {
  store.setDateSegment(segment)
  applyAdaptiveGrouping(segment)
  const currentQuery = typeof route.query.segment === 'string' ? route.query.segment.toLowerCase() : null
  if (currentQuery !== segment.toLowerCase()) {
    void router.replace({
      query: {
        ...route.query,
        segment: segment.toLowerCase(),
      },
    })
  }
}

/** `?preview=loading|error|empty` forces a UI state for design review.
 *  No task is auto-opened on arrival — the panel only opens when the user
 *  picks one or lands here from global search (`?open=<id>`). */
async function loadAndSelect(preview: PreviewState) {
  if (preview === 'loading') {
    panel.openSkeleton()
  } else {
    panel.close()
  }
  await store.load(preview)
  // Project names for grouping come from the projects store — load once.
  if (projectsStore.status === 'idle') void projectsStore.load()

  // A search result wins — open it explicitly when present.
  if (openTaskId.value && store.taskById(openTaskId.value)) {
    panel.openTask(openTaskId.value)
  }
}

onMounted(() => {
  const querySegment = parseSegmentQuery(route.query.segment)
  if (querySegment) {
    store.setDateSegment(querySegment)
    applyAdaptiveGrouping(querySegment)
  } else {
    // D2: Default to TODAY
    store.setDateSegment('TODAY')
    applyAdaptiveGrouping('TODAY')
  }
  void loadAndSelect(previewFromQuery())
})

watch(
  () => route.query.preview,
  () => loadAndSelect(previewFromQuery()),
)

// Synchronize URL query parameter with segment tab changes
watch(
  () => route.query.segment,
  (newParam) => {
    const parsed = parseSegmentQuery(newParam)
    if (parsed && parsed !== store.dateSegment) {
      store.setDateSegment(parsed)
      applyAdaptiveGrouping(parsed)
    }
  },
)

watch(
  () => store.dateSegment,
  (newSegment) => {
    const currentQuery = typeof route.query.segment === 'string' ? route.query.segment.toLowerCase() : null
    if (currentQuery !== newSegment.toLowerCase()) {
      void router.replace({
        query: {
          ...route.query,
          segment: newSegment.toLowerCase(),
        },
      })
    }
  },
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

const isLoading = computed(() => store.status === 'loading' || store.status === 'idle')

interface EmptyStateConfig {
  icon: typeof SearchX
  title: string
  description: string
  actionKind: 'clear-search' | 'clear-filter' | 'create'
  actionLabel: string
}

/** Segment-specific contextual empty states (AC-UI-015). */
const emptyState = computed<EmptyStateConfig | null>(() => {
  if (store.visibleTasks.length > 0) return null

  // 1. Search query active
  if (store.hasActiveSearch) {
    return {
      icon: SearchX,
      title: 'No tasks found.',
      description: `Nothing matches "${store.searchQuery.trim()}". Try a different search.`,
      actionKind: 'clear-search',
      actionLabel: 'Clear search',
    }
  }

  // 2. Status filter active within segment
  if (store.statusFilter !== 'ALL') {
    return {
      icon: ListChecks,
      title: 'Nothing here.',
      description: 'No tasks with this status right now.',
      actionKind: 'clear-filter',
      actionLabel: 'Clear filter',
    }
  }

  // 3. Date segment empty
  switch (store.dateSegment) {
    case 'TODAY':
      return {
        icon: CalendarDays,
        title: 'All caught up for today.',
        description: 'No tasks scheduled for today. Pull tasks from your backlog or enjoy the calm.',
        actionKind: 'create',
        actionLabel: 'Schedule for Today',
      }
    case 'UPCOMING':
      return {
        icon: CalendarDays,
        title: 'No upcoming tasks.',
        description: 'Your future schedule is clear. Plan ahead by scheduling dates on your tasks.',
        actionKind: 'create',
        actionLabel: 'Plan a Task',
      }
    case 'BACKLOG':
      return {
        icon: FolderKanban,
        title: 'Backlog is clear.',
        description: 'All your tasks are scheduled on the calendar. Capture new ideas anytime.',
        actionKind: 'create',
        actionLabel: 'Capture Task',
      }
    case 'ALL':
    default:
      return {
        icon: ListChecks,
        title: 'No tasks yet.',
        description: "Capture something you're thinking about.",
        actionKind: 'create',
        actionLabel: 'New Task',
      }
  }
})

function openCreateForCurrentSegment() {
  if (store.dateSegment === 'TODAY') {
    store.openCreateDialog({ dueDate: store.todayISO })
  } else if (store.dateSegment === 'UPCOMING') {
    store.openCreateDialog({ dueDate: store.tomorrowISO })
  } else if (store.dateSegment === 'BACKLOG') {
    store.openCreateDialog({ dueDate: null })
  } else {
    store.openCreateDialog({ dueDate: store.todayISO })
  }
}

/* ---------------- Grouping (shared by list + grid) ---------------- */

function dayLabelFor(iso: string): { dayLabel: string; isToday: boolean } {
  if (iso === store.todayISO) return { dayLabel: 'Today', isToday: true }
  if (iso === store.tomorrowISO) return { dayLabel: 'Tomorrow', isToday: false }
  if (iso < store.todayISO) return { dayLabel: 'Overdue', isToday: false }
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
  isToday: boolean
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
      ordered.push({
        key: project.id,
        name: project.name,
        color: project.color,
        tasks,
        isToday: tasks.some((t) => t.dueDate === store.todayISO),
      })
      byProject.delete(project.id)
    }
  }
  for (const [key, tasks] of byProject) {
    ordered.push({
      key,
      name: 'No project',
      color: null,
      tasks,
      isToday: tasks.some((t) => t.dueDate === store.todayISO),
    })
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

function canToggleComplete(task: Task): boolean {
  return task.status !== 'CANCELLED'
}

function onRetry() {
  store.load(null)
}
</script>

<template>
  <div class="tasks-page">
    <!-- Date Segments (Primary Temporal Navigation - §7.2, AC-UI-010) + New Task CTA -->
    <div class="top-nav-bar">
      <TaskDateSegments
        :active="store.dateSegment"
        :counts="store.segmentCounts"
        @change="onSegmentChange"
      />

      <div class="hero-actions">
        <UiButton variant="primary" @click="openCreateForCurrentSegment">
          <Plus :size="16" :stroke-width="2" />
          <span>New Task</span>
          <kbd class="kbd tnum">c</kbd>
        </UiButton>
      </div>
    </div>

    <!-- Toolbar: filters prominent on the left, search + view controls subtle on the right
         (spec §10: "Filters should not dominate") -->
    <div class="toolbar">
      <TaskFilters
        :active="store.statusFilter"
        :counts="store.filterCounts"
        @change="store.setFilter($event)"
      />

      <div class="search-view-row">
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

        <div class="view-controls" role="group" aria-label="Task view">
          <div class="seg-toggle" role="group" aria-label="Group tasks by">
            <button
              type="button"
              class="seg-btn"
              :class="{ active: groupMode === 'date' }"
              @click="setManualGroupMode('date')"
            >
              <CalendarDays :size="14" :stroke-width="1.75" />
              Date
            </button>
            <button
              type="button"
              class="seg-btn"
              :class="{ active: groupMode === 'project' }"
              @click="setManualGroupMode('project')"
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
    </div>

    <!-- Loading — mirrors the hero, toolbar, and grouped rows -->
    <div v-if="isLoading" class="skeleton-page" aria-busy="true" aria-label="Loading tasks">
      <div class="skeleton-hero">
        <div class="skeleton-hero-text">
          <SkeletonBlock height="44px" width="220px" rounded="md" />
          <SkeletonBlock height="20px" width="300px" rounded="md" />
        </div>
        <SkeletonBlock height="44px" width="160px" rounded="md" />
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

    <!-- Empty / no results (AC-UI-015) -->
    <EmptyState
      v-else-if="emptyState"
      :icon="emptyState.icon"
      :title="emptyState.title"
      :description="emptyState.description"
    >
      <UiButton
        v-if="emptyState.actionKind === 'clear-search'"
        variant="ghost"
        size="sm"
        class="empty-action"
        @click="onClearSearch"
      >
        Clear search
      </UiButton>
      <UiButton
        v-else-if="emptyState.actionKind === 'clear-filter'"
        variant="ghost"
        size="sm"
        class="empty-action"
        @click="store.setFilter('ALL')"
      >
        Clear filter
      </UiButton>
      <UiButton
        v-else
        variant="primary"
        size="sm"
        class="empty-action"
        @click="openCreateForCurrentSegment"
      >
        <Plus :size="14" :stroke-width="2" />
        {{ emptyState.actionLabel }}
      </UiButton>
    </EmptyState>

    <!-- List view (default) — lightweight rows grouped by date or project (spec §8) -->
    <TransitionGroup v-else-if="viewMode === 'list'" name="row" tag="div" class="groups">
      <section v-for="group in groups" :key="group.key" :class="{ today: group.isToday }" class="group">
        <SectionHeader
          :title="groupMode === 'date' ? (group as DateGroup).dayLabel : (group as ProjectGroup).name"
          :meta="String(group.tasks.length)"
        />
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
              :disabled="!canToggleComplete(task)"
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

/* ---------- Search & actions ---------- */

.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  flex-wrap: wrap;
}

.hero-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: var(--space-3);
}

.hero-actions .kbd {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 18px;
  height: 18px;
  padding: 0 4px;
  margin-left: var(--space-1);
  border-radius: var(--radius-sm);
  background: rgba(255, 255, 255, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.3);
  color: var(--on-accent);
  font-family: inherit;
  font-size: 11px;
  font-weight: 600;
  line-height: 1;
  vertical-align: middle;
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

.search-view-row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  flex-wrap: wrap;
  justify-content: flex-end;
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
  padding: var(--space-6);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  background: var(--surface-1);
  min-width: 0;
}

.group.today {
  border-color: var(--accent-border);
}

.group.today :deep(.section-header .title) {
  color: var(--accent-strong);
}

.rows {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
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

.toast-enter-active {
  transition:
    opacity var(--motion-standard) var(--ease-out),
    transform var(--motion-standard) var(--ease-out);
}

.toast-leave-active {
  transition:
    opacity var(--motion-fast) var(--ease-in),
    transform var(--motion-fast) var(--ease-in);
}

.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(12px);
}

/* ---------- Responsive ---------- */

@media (max-width: 900px) {
  .toolbar,
  .search-view-row {
    flex-direction: column;
    align-items: stretch;
  }

  .search {
    flex: 1;
  }

  .view-controls {
    justify-content: flex-end;
  }
}
</style>
