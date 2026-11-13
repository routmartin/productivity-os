<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  CalendarDays,
  Columns3,
  FolderKanban,
  List,
  ListChecks,
  Plus,
  Search,
  SearchX,
  X,
} from 'lucide-vue-next'

import { useContextPanelStore } from '@/app/layouts/contextPanelStore'
import EmptyState from '@/components/shared/EmptyState.vue'
import ErrorState from '@/components/shared/ErrorState.vue'
import SectionHeader from '@/components/shared/SectionHeader.vue'
import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import UiButton from '@/components/ui/UiButton.vue'
import type { PreviewState } from '@/features/planning/types'
import TaskBoardCard from '@/features/tasks/components/TaskBoardCard.vue'
import TaskBoardColumn from '@/features/tasks/components/TaskBoardColumn.vue'
import TaskDateSegments from '@/features/tasks/components/TaskDateSegments.vue'
import TaskFilters from '@/features/tasks/components/TaskFilters.vue'
import TaskListRow from '@/features/tasks/components/TaskListRow.vue'
import { useTaskDragAndDrop } from '@/features/tasks/composables/useTaskDragAndDrop'
import { useProjectsStore } from '@/features/projects/store'
import { useTasksStore } from '@/features/tasks/store'
import type { BoardColumnId, DateSegment, Task, TaskStatus } from '@/features/tasks/types'

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

type ViewMode = 'list' | 'board'
type GroupMode = 'date' | 'project'

const viewMode = ref<ViewMode>('list')
const groupMode = ref<GroupMode>('project')
const userOverrodeGrouping = ref(false)

function setManualGroupMode(mode: GroupMode) {
  userOverrodeGrouping.value = true
  groupMode.value = mode
}

function parseViewModeQuery(param: unknown): ViewMode | null {
  if (typeof param !== 'string') return null
  const lower = param.toLowerCase()
  if (lower === 'board') return 'board'
  if (lower === 'list') return 'list'
  return null
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

  const queryView = parseViewModeQuery(route.query.view)
  if (queryView) {
    viewMode.value = queryView
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

// Synchronize URL query parameter with view mode changes
watch(
  () => route.query.view,
  (newParam) => {
    const parsed = parseViewModeQuery(newParam)
    if (parsed && parsed !== viewMode.value) {
      viewMode.value = parsed
    }
  },
)

watch(
  () => viewMode.value,
  (newMode) => {
    const currentQuery = typeof route.query.view === 'string' ? route.query.view.toLowerCase() : null
    if (currentQuery !== newMode) {
      void router.replace({
        query: {
          ...route.query,
          view: newMode,
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

const {
  isDragging,
  draggedTask,
  hoveredColumn,
  pointerPos,
  previewSize,
  grabbedTaskId,
  announcement,
  startPointerDrag,
  handleKeydown,
} = useTaskDragAndDrop(onSelectTask)

function onCreateTaskForColumn(columnId: BoardColumnId | TaskStatus) {
  let dueDate: string | null = null
  if (store.dateSegment === 'TODAY') {
    dueDate = store.todayISO
  } else if (store.dateSegment === 'UPCOMING') {
    dueDate = store.tomorrowISO
  } else if (store.dateSegment === 'BACKLOG') {
    dueDate = null
  } else {
    dueDate = store.todayISO
  }

  const destination = columnId === 'IN_PROGRESS' ? 'IN_PROGRESS' : 'PLANNED'
  store.openCreateDialog({
    dueDate,
    destination,
  })
}

const isBoardEmptySearch = computed(() =>
  viewMode.value === 'board' &&
  store.hasActiveSearch &&
  store.boardColumns.PLANNED.length === 0 &&
  store.boardColumns.IN_PROGRESS.length === 0 &&
  store.boardColumns.COMPLETED.length === 0,
)

function onClearSearch() {
  store.setSearch('')
  searchInput.value?.focus()
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
          <div v-if="viewMode === 'list'" class="seg-toggle" role="group" aria-label="Group tasks by">
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
              title="List layout"
              aria-label="List layout"
              @click="viewMode = 'list'"
            >
              <List :size="15" :stroke-width="1.75" />
            </button>
            <button
              type="button"
              class="seg-btn icon-only"
              :class="{ active: viewMode === 'board' }"
              title="Board layout"
              aria-label="Board layout"
              @click="viewMode = 'board'"
            >
              <Columns3 :size="15" :stroke-width="1.75" />
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
    <!-- Empty / no results (AC-UI-015, AC-UI-023) -->
    <EmptyState
      v-else-if="(viewMode === 'list' && emptyState) || isBoardEmptySearch"
      :icon="emptyState?.icon ?? SearchX"
      :title="emptyState?.title ?? 'No tasks found.'"
      :description="emptyState?.description ?? 'Nothing matches your search query.'"
    >
      <UiButton
        v-if="emptyState?.actionKind === 'clear-search' || isBoardEmptySearch"
        variant="ghost"
        size="sm"
        class="empty-action"
        @click="onClearSearch"
      >
        Clear search
      </UiButton>
      <UiButton
        v-else-if="emptyState?.actionKind === 'clear-filter'"
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
        {{ emptyState?.actionLabel }}
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

    <!-- Board view (Kanban) — 3-column workflow (spec §8.1, AC-UI-018) -->
    <div v-else class="kanban-board" role="region" aria-label="Kanban board">
      <TaskBoardColumn
        column-id="PLANNED"
        title="To Do"
        :tasks="store.boardColumns.PLANNED"
        :active-task-id="panel.activeTaskId"
        :dragging-task-id="draggedTask?.id"
        :grabbed-task-id="grabbedTaskId"
        :is-over="hoveredColumn === 'PLANNED'"
        @select-task="onSelectTask"
        @pointerdown-task="startPointerDrag"
        @keydown-task="handleKeydown"
        @create-task="onCreateTaskForColumn"
      />

      <TaskBoardColumn
        column-id="IN_PROGRESS"
        title="In Progress"
        :tasks="store.boardColumns.IN_PROGRESS"
        :active-task-id="panel.activeTaskId"
        :dragging-task-id="draggedTask?.id"
        :grabbed-task-id="grabbedTaskId"
        :is-over="hoveredColumn === 'IN_PROGRESS'"
        @select-task="onSelectTask"
        @pointerdown-task="startPointerDrag"
        @keydown-task="handleKeydown"
        @create-task="onCreateTaskForColumn"
      />

      <TaskBoardColumn
        column-id="COMPLETED"
        title="Done"
        :tasks="store.boardColumns.COMPLETED"
        :active-task-id="panel.activeTaskId"
        :dragging-task-id="draggedTask?.id"
        :grabbed-task-id="grabbedTaskId"
        :is-over="hoveredColumn === 'COMPLETED'"
        @select-task="onSelectTask"
        @pointerdown-task="startPointerDrag"
        @keydown-task="handleKeydown"
        @create-task="onCreateTaskForColumn"
      />
    </div>

    <!-- Floating Drag Preview Card (AC-UI-021) -->
    <Teleport to="body">
      <div
        v-if="isDragging && draggedTask"
        class="floating-drag-preview"
        :style="{
          transform: `translate3d(${pointerPos.x}px, ${pointerPos.y}px, 0) scale(1.025) rotate(1.5deg)`,
          width: `${previewSize.width}px`,
        }"
        aria-hidden="true"
      >
        <TaskBoardCard
          :task="draggedTask"
          is-dragging
        />
      </div>
    </Teleport>

    <!-- Polite aria-live announcement for screen readers (AC-UI-022) -->
    <div
      class="visually-hidden"
      role="status"
      aria-live="polite"
      aria-atomic="true"
    >
      {{ announcement }}
    </div>
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

/* ---------- Kanban Board (Board view) ---------- */

.kanban-board {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--space-5);
  align-items: start;
}

@media (max-width: 1023px) {
  .kanban-board {
    display: flex;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
    gap: var(--space-4);
    padding-bottom: var(--space-4);
    -webkit-overflow-scrolling: touch;
  }

  .kanban-board > :deep(.board-column) {
    min-width: 320px;
    max-width: 360px;
    flex: 0 0 85vw;
    scroll-snap-align: start;
  }
}

/* ---------- Floating Drag Preview ---------- */

.floating-drag-preview {
  position: fixed;
  top: 0;
  left: 0;
  pointer-events: none;
  z-index: 1000;
  will-change: transform;
  filter: drop-shadow(0 12px 24px rgba(0, 0, 0, 0.25));
  transform-origin: top left;
}

.floating-drag-preview :deep(.board-card) {
  opacity: 1 !important;
  border-style: solid !important;
  border-color: var(--accent-border) !important;
  box-shadow: var(--shadow-panel) !important;
  cursor: grabbing !important;
  background: var(--surface-3) !important;
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

/* ---------- Empty ---------- */

.empty-action {
  margin-top: var(--space-4);
}

/* ---------- Transitions ---------- */

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
