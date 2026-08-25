<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  CalendarDays,
  CalendarPlus,
  CheckCircle2,
  CircleSlash,
  Clock,
  Flag,
  Folder,
  Pin,
  Pencil,
  Play,
  RotateCcw,
  SearchX,
  Target,
  Timer,
  Trash2,
  XCircle,
  Zap,
} from 'lucide-vue-next'

import EmptyState from '@/components/shared/EmptyState.vue'
import UiButton from '@/components/ui/UiButton.vue'
import UiPill from '@/components/ui/UiPill.vue'
import { useContextPanelStore } from '@/app/layouts/contextPanelStore'
import { useRouter } from 'vue-router'
import { formatLongDate, relativeTime } from '@/lib/utils/date'
import { formatMinutes } from '@/lib/utils/duration'

import { useFocusStore } from '@/features/focus/store'
import { useGoalsStore } from '@/features/goals/store'
import { useProjectsStore } from '@/features/projects/store'
import { useTodayStore } from '@/features/planning/todayStore'
import { useMock } from '@/lib/mock'
import { useTasksStore } from '../store'
import { ENERGY_LABELS, PRIORITY_LABELS, TASK_STATUS_LABELS } from '../types'
import NewTaskDialog from './NewTaskDialog.vue'
import TaskStatusIcon from './TaskStatusIcon.vue'

const props = defineProps<{ taskId: string }>()

const store = useTasksStore()
const projectsStore = useProjectsStore()
const goalsStore = useGoalsStore()
const focusStore = useFocusStore()
const todayStore = useTodayStore()
const router = useRouter()
const panel = useContextPanelStore()

const task = computed(() => store.taskById(props.taskId))
/** Real project/goal from their stores — never the mock lists (real mode
 *  would otherwise show seed names or nothing for real links). */
const project = computed(() =>
  task.value?.projectId
    ? projectsStore.projectById(task.value.projectId)
    : undefined,
)
const goal = computed(() => {
  const p = project.value
  return p?.goalId ? goalsStore.goalById(p.goalId) : undefined
})

/** Backend completes tasks only from IN_PROGRESS (task domain lifecycle);
 *  mock mode keeps the design-review toggle + undo. */
const canToggle = computed(
  () => useMock('TASKS') || task.value?.status === 'IN_PROGRESS',
)

const editOpen = ref(false)
const confirmingAction = ref<'delete' | 'cancel' | null>(null)

type PillTone = 'neutral' | 'accent' | 'success' | 'warning' | 'danger'

const statusTone = computed<PillTone>(() => {
  switch (task.value?.status) {
    case 'IN_PROGRESS':
      return 'accent'
    case 'COMPLETED':
      return 'success'
    case 'CANCELLED':
      return 'neutral'
    default:
      return 'neutral'
  }
})

const priorityTone = computed<PillTone>(() => {
  switch (task.value?.priority) {
    case 'HIGH':
      return 'warning'
    case 'MEDIUM':
      return 'accent'
    default:
      return 'neutral'
  }
})

const dueLabel = computed(() => {
  const due = task.value?.dueDate
  if (!due) return null
  return formatLongDate(new Date(`${due}T00:00:00`))
})

const previewNote = ref<string | null>(null)
let noteTimer: ReturnType<typeof setTimeout> | undefined

function showNote(message: string) {
  previewNote.value = message
  clearTimeout(noteTimer)
  noteTimer = setTimeout(() => (previewNote.value = null), 3200)
}

/** Focus sessions require an IN_PROGRESS task (focus spec Rule 4). One-click
 *  Start (Tasks & Inbox UI spec §15.1): an active task not yet in progress is
 *  started here, then the panel hands off to the Focus workspace instead of
 *  dead-ending with a message. */
const starting = ref(false)

async function onStartFocus() {
  const current = task.value
  if (!current || starting.value) return
  if (current.status === 'COMPLETED' || current.status === 'CANCELLED') {
    showNote(
      'This task is no longer active — reopen or restore it before focusing.',
    )
    return
  }
  starting.value = true
  try {
    if (current.status !== 'IN_PROGRESS') {
      await store.startTaskNow(current.id)
      if (store.lastError) return
    }
    focusStore.selectTask(current.id)
    void router.push({ name: 'focus' })
  } finally {
    starting.value = false
  }
}

function onPlan() {
  const current = task.value
  if (current) store.planTask(current.id)
}

function onStart() {
  const current = task.value
  if (current) void store.startTaskNow(current.id)
}

function onComplete() {
  const current = task.value
  if (current) store.toggleTaskComplete(current.id)
}

function onReopen() {
  const current = task.value
  if (current) store.reopenTask(current.id)
}

function onCancel() {
  const current = task.value
  if (current) {
    store.cancelTask(current.id)
    confirmingAction.value = null
  }
}

function onPin() {
  const current = task.value
  if (current) store.togglePin(current.id)
}

const inTopThree = computed(() => task.value ? todayStore.isInTopThree(task.value.id) : false)

function onAddToTopThree() {
  const current = task.value
  if (current) void todayStore.selectForTopThree(current.id)
}

function onRemoveFromTopThree() {
  const current = task.value
  if (current) void todayStore.removeFromTopThree(current.id)
}

function onDelete() {
  store.deleteTask(props.taskId)
  panel.close()
}

function onUpdate(taskId: string, draft: Parameters<typeof store.updateTask>[1]) {
  store.updateTask(taskId, draft)
  editOpen.value = false
}
</script>

<template>
  <div v-if="task" class="task-detail">
    <div class="pills">
      <UiPill :tone="statusTone">
        <TaskStatusIcon :status="task.status" :size="12" />
        {{ TASK_STATUS_LABELS[task.status] }}
      </UiPill>
      <UiPill v-if="task.priority" :tone="priorityTone">
        <Flag :size="11" :stroke-width="2" />
        {{ PRIORITY_LABELS[task.priority] }} priority
      </UiPill>
    </div>

    <h2 class="title">{{ task.title }}</h2>

    <p v-if="task.description" class="description">{{ task.description }}</p>
    <p v-else class="description muted">No description yet.</p>

    <dl class="meta-list">
      <div v-if="project" class="meta-row">
        <dt><Folder :size="14" :stroke-width="1.75" /> Project</dt>
        <dd>
          <span class="project-dot" :style="{ background: project.color }" />
          {{ project.name }}
        </dd>
      </div>
      <div v-if="goal" class="meta-row">
        <dt><Target :size="14" :stroke-width="1.75" /> Goal</dt>
        <dd>{{ goal.title }}</dd>
      </div>
      <div v-if="dueLabel" class="meta-row">
        <dt><CalendarDays :size="14" :stroke-width="1.75" /> Due</dt>
        <dd>{{ dueLabel }}</dd>
      </div>
      <div v-if="task.estimatedMinutes" class="meta-row">
        <dt><Clock :size="14" :stroke-width="1.75" /> Estimate</dt>
        <dd class="tnum">{{ formatMinutes(task.estimatedMinutes) }}</dd>
      </div>
      <div v-if="task.energy" class="meta-row">
        <dt><Zap :size="14" :stroke-width="1.75" /> Energy</dt>
        <dd>{{ ENERGY_LABELS[task.energy] }}</dd>
      </div>
    </dl>

    <div class="actions">
      <UiButton
        variant="primary"
        full-width
        :disabled="starting"
        @click="onStartFocus"
      >
        <Timer :size="15" :stroke-width="1.75" />
        {{ starting ? 'Starting…' : 'Start focus session' }}
      </UiButton>

      <UiButton
        variant="ghost"
        full-width
        @click="onPin"
      >
        <Pin :size="15" :stroke-width="1.75" />
        {{ task.pinned ? 'Unpin' : 'Pin to top' }}
      </UiButton>

      <UiButton
        v-if="!inTopThree"
        variant="ghost"
        full-width
        :disabled="todayStore.topThree.length >= 3"
        @click="onAddToTopThree"
      >
        <Flag :size="15" :stroke-width="1.75" />
        Add to Top 3
      </UiButton>

      <UiButton
        v-else
        variant="ghost"
        full-width
        @click="onRemoveFromTopThree"
      >
        <Flag :size="15" :stroke-width="1.75" />
        Remove from Top 3
      </UiButton>

      <UiButton
        v-if="task.status === 'INBOX'"
        variant="ghost"
        full-width
        @click="onPlan"
      >
        <CalendarPlus :size="15" :stroke-width="1.75" />
        Plan for today
      </UiButton>

      <UiButton
        v-if="task.status === 'INBOX' || task.status === 'PLANNED'"
        variant="ghost"
        full-width
        @click="onStart"
      >
        <Play :size="15" :stroke-width="1.75" />
        Start
      </UiButton>

      <UiButton
        v-if="task.status === 'IN_PROGRESS'"
        variant="ghost"
        full-width
        :disabled="!canToggle"
        @click="onComplete"
      >
        <CheckCircle2 :size="15" :stroke-width="1.75" />
        Mark complete
      </UiButton>

      <UiButton
        v-if="task.status === 'CANCELLED'"
        variant="ghost"
        full-width
        @click="onReopen"
      >
        <RotateCcw :size="15" :stroke-width="1.75" />
        Reopen
      </UiButton>

      <UiButton
        v-if="task.status !== 'COMPLETED'"
        variant="ghost"
        full-width
        @click="editOpen = true"
      >
        <Pencil :size="15" :stroke-width="1.75" />
        Edit task
      </UiButton>

      <UiButton
        v-if="task.status !== 'COMPLETED' && task.status !== 'CANCELLED'"
        variant="ghost"
        full-width
        class="danger-btn"
        @click="confirmingAction = 'cancel'"
      >
        <XCircle :size="15" :stroke-width="1.75" />
        Cancel task
      </UiButton>

      <template v-if="confirmingAction === 'cancel'">
        <div class="confirm-box">
          <p class="confirm-copy">Cancel "{{ task.title }}"? It moves to Cancelled and can be reopened later.</p>
          <div class="confirm-row">
            <UiButton variant="ghost" size="sm" full-width @click="confirmingAction = null">
              Keep it
            </UiButton>
            <UiButton variant="ghost" size="sm" full-width class="danger-btn" @click="onCancel">
              Cancel task
            </UiButton>
          </div>
        </div>
      </template>

      <UiButton
        v-if="confirmingAction !== 'cancel' && task.status !== 'COMPLETED' && task.status !== 'CANCELLED'"
        variant="ghost"
        full-width
        class="danger-btn"
        @click="confirmingAction = 'delete'"
      >
        <Trash2 :size="15" :stroke-width="1.75" />
        Delete task
      </UiButton>

      <template v-if="confirmingAction === 'delete'">
        <div class="confirm-box">
          <p class="confirm-copy">Delete "{{ task.title }}"? This can't be undone.</p>
          <div class="confirm-row">
            <UiButton variant="ghost" size="sm" full-width @click="confirmingAction = null">
              Cancel
            </UiButton>
            <UiButton variant="ghost" size="sm" full-width class="danger-btn" @click="onDelete">
              Delete
            </UiButton>
          </div>
        </div>
      </template>

      <Transition name="fade">
        <p v-if="previewNote" class="preview-note" role="status">
          <CircleSlash :size="13" :stroke-width="1.75" />
          {{ previewNote }}
        </p>
      </Transition>
    </div>

    <footer class="footer tnum">
      <span>Created {{ relativeTime(task.createdAt) }}</span>
      <span v-if="task.completedAt">Completed {{ relativeTime(task.completedAt) }}</span>
      <span v-else>Updated {{ relativeTime(task.updatedAt) }}</span>
    </footer>

    <NewTaskDialog
      :open="editOpen"
      :editing="task"
      @close="editOpen = false"
      @update="onUpdate"
    />
  </div>

  <EmptyState
    v-else
    :icon="SearchX"
    title="Task unavailable"
    description="This task could not be found. It may have been deleted."
    compact
  />
</template>

<style scoped>
.task-detail {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.pills {
  display: flex;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.title {
  font-size: var(--text-xl);
  letter-spacing: -0.02em;
}

.description {
  font-size: var(--text-md);
  color: var(--text-secondary);
  line-height: 1.6;
}

.description.muted {
  color: var(--text-tertiary);
  font-style: italic;
}

.meta-list {
  display: flex;
  flex-direction: column;
  border-top: 1px solid var(--border-subtle);
}

.meta-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  padding: var(--space-3) 0;
  border-bottom: 1px solid var(--border-subtle);
}

.meta-row dt {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.meta-row dd {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--text-primary);
  text-align: right;
}

.project-dot {
  width: 7px;
  height: 7px;
  border-radius: var(--radius-full);
}

.actions {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.danger-btn {
  color: var(--danger) !important;
}

.danger-btn:hover {
  background: var(--danger-soft);
}

.confirm-box {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-3);
  border: 1px solid var(--danger);
  border-radius: var(--radius-md);
  background: var(--danger-soft);
}

.confirm-copy {
  font-size: var(--text-sm);
  color: var(--text-secondary);
}

.confirm-row {
  display: flex;
  gap: var(--space-2);
}

.preview-note {
  display: flex;
  align-items: flex-start;
  gap: var(--space-2);
  padding: var(--space-3);
  border-radius: var(--radius-md);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  line-height: 1.5;
}

.preview-note svg {
  flex-shrink: 0;
  margin-top: 1px;
}

.footer {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
  padding-top: var(--space-4);
  border-top: 1px solid var(--border-subtle);
  font-size: var(--text-xs);
  color: var(--text-disabled);
}
</style>
