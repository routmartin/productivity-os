<script setup lang="ts">
import { computed, nextTick, reactive, ref, watch } from 'vue'
import { Clock, Flag, Folder, Sparkles, Target } from 'lucide-vue-next'

import UiButton from '@/components/ui/UiButton.vue'
import UiDialog from '@/components/ui/UiDialog.vue'
import UiInput from '@/components/ui/UiInput.vue'
import UiSelect from '@/components/ui/UiSelect.vue'
import UiTextarea from '@/components/ui/UiTextarea.vue'
import { useGoalsStore } from '@/features/goals/store'
import { useProjectsStore } from '@/features/projects/store'
import { useMock } from '@/lib/mock'

import type { NewTaskDraft, Priority, Task } from '../types'

type Destination = NonNullable<NewTaskDraft['destination']>

const props = withDefaults(
  defineProps<{
    open: boolean
    editing?: Task | null
    initial?: Partial<NewTaskDraft> | null
    size?: 'md' | 'lg' | 'xl' | 'full'
  }>(),
  { size: 'full', initial: null },
)

const emit = defineEmits<{
  close: []
  create: [draft: NewTaskDraft]
  update: [taskId: string, draft: NewTaskDraft]
}>()

const isEdit = computed(() => props.editing != null)

const goalsStore = useGoalsStore()
const projectsStore = useProjectsStore()
/** scheduledTime/recurrence exist only in mock mode — the backend has no
 *  such fields, so the selects are hidden when running against the API. */
const mockMode = useMock('TASKS')

const emptyDraft = (): NewTaskDraft => ({
  title: '',
  description: '',
  projectId: null,
  priority: null,
  dueDate: null,
  estimatedMinutes: null,
  scheduledTime: null,
  recurrence: null,
})

const draft = reactive<NewTaskDraft>(emptyDraft())
/** Creation destination (Tasks & Inbox UI spec §12.1) — create mode only;
 *  the store chains sanctioned plan/start transitions after create. */
const destination = ref<Destination>('PLANNED')
const isSubmitting = ref(false)
const titleInput = ref<{ $el: HTMLElement } | null>(null)

const projectOptions = computed(() => [
  { value: '', label: 'No project', color: undefined as string | undefined },
  ...projectsStore.projects.map((p) => ({ value: p.id, label: p.name, color: p.color })),
])

const goalOptions = computed(() => {
  const activeOrDraft = goalsStore.goals.filter(
    (goal) => goal.status === 'ACTIVE' || goal.status === 'DRAFT',
  )
  const currentGoalId = goalValue.value
  const hasCurrent = activeOrDraft.some((g) => g.id === currentGoalId)
  const currentGoal = currentGoalId && !hasCurrent ? goalsStore.goalById(currentGoalId) : null

  const list = [...activeOrDraft]
  if (currentGoal) {
    list.push(currentGoal)
  }

  return [
    { value: '', label: 'No goal' },
    ...list.map((goal) => ({ value: goal.id, label: goal.title })),
  ]
})

const durationOptions = [
  { value: '', label: 'No estimate' },
  { value: '15', label: '15m' },
  { value: '30', label: '30m' },
  { value: '45', label: '45m' },
  { value: '60', label: '1h' },
  { value: '90', label: '1h 30m' },
  { value: '120', label: '2h' },
]

const durationChips = computed(() => {
  const options = [...durationOptions]
  if (durationValue.value && !options.some((o) => o.value === durationValue.value)) {
    options.push({
      value: durationValue.value,
      label: `${durationValue.value}m`,
    })
  }
  return options
})

const timeOptions = [
  { value: '', label: 'No time' },
  { value: '07:00', label: '7:00 AM' },
  { value: '08:00', label: '8:00 AM' },
  { value: '09:00', label: '9:00 AM' },
  { value: '10:00', label: '10:00 AM' },
  { value: '11:00', label: '11:00 AM' },
  { value: '12:00', label: '12:00 PM' },
  { value: '13:00', label: '1:00 PM' },
  { value: '14:00', label: '2:00 PM' },
  { value: '15:00', label: '3:00 PM' },
  { value: '16:00', label: '4:00 PM' },
  { value: '17:00', label: '5:00 PM' },
  { value: '18:00', label: '6:00 PM' },
  { value: '19:00', label: '7:00 PM' },
  { value: '20:00', label: '8:00 PM' },
]

const recurrenceOptions = [
  { value: '', label: 'Does not repeat' },
  { value: 'Mon, Tue, Wed', label: 'Mon · Tue · Wed' },
  { value: 'Mon, Wed, Fri', label: 'Mon · Wed · Fri' },
  { value: 'Tue, Thu', label: 'Tue · Thu' },
  { value: 'Weekdays', label: 'Weekdays' },
  { value: 'Every day', label: 'Every day' },
  { value: 'Weekly', label: 'Weekly' },
]

const PRIORITIES: { value: Priority; label: string }[] = [
  { value: 'LOW', label: 'Low' },
  { value: 'MEDIUM', label: 'Medium' },
  { value: 'HIGH', label: 'High' },
]

const DESTINATIONS: { value: Destination; label: string }[] = [
  { value: 'PLANNED', label: 'Planned' },
  { value: 'IN_PROGRESS', label: 'Start now' },
]

// Selects keep string values; map empty string to null on read.
// Goal is a local form value only: on the backend a task reaches its goal
// through its project, so the mock does not persist a task-level goal.
const projectValue = ref('')
const goalValue = ref('')
const dueValue = ref('')
const durationValue = ref('')
const timeValue = ref('')
const recurrenceValue = ref('')

let isInitializing = false

watch(
  () => props.open,
  async (isOpen) => {
    if (isOpen) {
      isInitializing = true
      Object.assign(draft, emptyDraft())
      destination.value = 'PLANNED'
      projectValue.value = ''
      goalValue.value = ''
      dueValue.value = ''
      durationValue.value = ''
      timeValue.value = ''
      recurrenceValue.value = ''

      const task = props.editing
      if (task) {
        Object.assign(draft, {
          title: task.title,
          description: task.description ?? '',
          projectId: task.projectId,
          priority: task.priority,
          dueDate: task.dueDate,
          estimatedMinutes: task.estimatedMinutes,
          scheduledTime: task.scheduledTime ?? null,
          recurrence: task.recurrence ?? null,
        })
        projectValue.value = task.projectId ?? ''

        const initialGoalId = (task as { goalId?: string | null }).goalId
        if (initialGoalId) {
          goalValue.value = initialGoalId
        } else if (task.projectId) {
          const project = projectsStore.projects.find((p) => p.id === task.projectId)
          if (project?.goalId) {
            goalValue.value = project.goalId
          }
        }

        dueValue.value = task.dueDate ?? ''
        durationValue.value = task.estimatedMinutes ? String(task.estimatedMinutes) : ''
        timeValue.value = task.scheduledTime ?? ''
        recurrenceValue.value = task.recurrence ?? ''
      } else if (props.initial) {
        if (props.initial.dueDate !== undefined) {
          draft.dueDate = props.initial.dueDate
          dueValue.value = props.initial.dueDate ?? ''
        }
        if (props.initial.title) {
          draft.title = props.initial.title
        }
        if (props.initial.projectId) {
          draft.projectId = props.initial.projectId
          projectValue.value = props.initial.projectId
        }
      }

      isSubmitting.value = false
      // Options come from the server — load once if never loaded.
      if (projectsStore.status === 'idle') void projectsStore.load()
      if (goalsStore.status === 'idle') void goalsStore.load()
      await nextTick()
      isInitializing = false
      titleInput.value?.$el.querySelector('input')?.focus()
    }
  },
  { immediate: true },
)

// When the user selects a project, look up the selected project in
// projectsStore.projects. If it has an associated goal, automatically
// select that goal.
watch(projectValue, (newProjectId) => {
  if (isInitializing || !props.open) return
  const project = projectsStore.projects.find((p) => p.id === newProjectId)
  if (project?.goalId) {
    goalValue.value = project.goalId
  }
})

// If projects finish loading while the dialog is open and a project is selected
// but no goal is selected yet, populate the goal from the loaded project.
watch(
  () => projectsStore.projects,
  (projects) => {
    if (!props.open || !projectValue.value || goalValue.value) return
    const project = projects.find((p) => p.id === projectValue.value)
    if (project?.goalId) {
      goalValue.value = project.goalId
    }
  },
)

function selectProject(val: string) {
  if (val === '') {
    projectValue.value = ''
  } else {
    projectValue.value = projectValue.value === val ? '' : val
  }
}

function selectGoal(val: string) {
  if (val === '') {
    goalValue.value = ''
  } else {
    goalValue.value = goalValue.value === val ? '' : val
  }
}

function selectDuration(val: string) {
  if (val === '') {
    durationValue.value = ''
  } else {
    durationValue.value = durationValue.value === val ? '' : val
  }
}

defineExpose({
  projectValue,
  goalValue,
  durationValue,
  selectProject,
  selectGoal,
  selectDuration,
})

function onSubmit() {
  if (!draft.title.trim() || isSubmitting.value) return
  isSubmitting.value = true

  const payload = {
    title: draft.title.trim(),
    description: draft.description.trim(),
    projectId: projectValue.value || null,
    priority: draft.priority,
    dueDate: dueValue.value || null,
    estimatedMinutes: durationValue.value ? Number(durationValue.value) : null,
    scheduledTime: timeValue.value || null,
    recurrence: recurrenceValue.value || null,
  }

  // Emits the draft; the tasks store performs the real API call. Destination
  // is a create-only concern — edits never touch lifecycle state.
  setTimeout(() => {
    if (props.editing) {
      emit('update', props.editing.id, payload)
    } else {
      emit('create', { ...payload, destination: destination.value })
    }
    emit('close')
  }, 400)
}
</script>

<template>
  <UiDialog :open="open" :title="isEdit ? 'Edit Task' : 'New Task'" :size="size" @close="emit('close')">
    <form id="new-task-form" class="form" @submit.prevent="onSubmit">
      <div class="form-columns">
        <!-- Left column: Primary Task Content -->
        <div class="form-main">
          <UiInput
            ref="titleInput"
            v-model="draft.title"
            label="Title"
            placeholder="What needs to be done?"
            class="title-input"
            :disabled="isSubmitting"
          />

          <UiTextarea
            v-model="draft.description"
            label="Description"
            placeholder="Optional details…"
            class="description-input"
            :rows="4"
            :disabled="isSubmitting"
          />

          <div class="field-row" v-if="mockMode">
            <UiInput v-model="dueValue" label="Due date" type="date" :disabled="isSubmitting" />
            <UiSelect v-model="timeValue" label="Time" :options="timeOptions" :disabled="isSubmitting" />
          </div>
          <UiInput v-else v-model="dueValue" label="Due date" type="date" :disabled="isSubmitting" />

          <UiSelect
            v-if="mockMode"
            v-model="recurrenceValue"
            label="Repeat"
            :options="recurrenceOptions"
            :disabled="isSubmitting"
          />

          <div v-if="!isEdit" class="field">
            <div class="field-header">
              <Sparkles :size="16" class="field-icon" aria-hidden="true" />
              <span class="field-label">Add to</span>
            </div>
            <div class="destination-group" role="radiogroup" aria-label="Add to">
              <button
                v-for="option in DESTINATIONS"
                :key="option.value"
                type="button"
                class="destination-chip"
                role="radio"
                :aria-checked="destination === option.value"
                :class="{ selected: destination === option.value }"
                :disabled="isSubmitting"
                @click="destination = option.value"
              >
                {{ option.label }}
              </button>
            </div>
          </div>
        </div>

        <!-- Right column: Quick Pick Choice Chips (Project, Goal, Duration, Priority) -->
        <div class="form-sidebar">
          <!-- Project Choice Chips -->
          <div class="field">
            <div class="field-header">
              <Folder :size="16" class="field-icon" aria-hidden="true" />
              <span class="field-label">Project</span>
              <span v-if="projectValue" class="field-active-hint">
                {{ projectOptions.find((p) => p.value === projectValue)?.label }}
              </span>
            </div>
            <div class="chips-group" role="radiogroup" aria-label="Project">
              <button
                v-for="option in projectOptions"
                :key="option.value"
                type="button"
                class="choice-chip"
                :class="{ selected: projectValue === option.value }"
                :disabled="isSubmitting"
                role="radio"
                :aria-checked="projectValue === option.value"
                @click="selectProject(option.value)"
              >
                <span
                  v-if="option.color"
                  class="chip-dot"
                  :style="{ backgroundColor: option.color }"
                />
                <span class="chip-label">{{ option.label }}</span>
              </button>
            </div>
          </div>

          <!-- Goal Choice Chips -->
          <div class="field">
            <div class="field-header">
              <Target :size="16" class="field-icon" aria-hidden="true" />
              <span class="field-label">Goal</span>
              <span v-if="goalValue" class="field-active-hint">
                {{ goalOptions.find((g) => g.value === goalValue)?.label }}
              </span>
            </div>
            <div class="chips-group" role="radiogroup" aria-label="Goal">
              <button
                v-for="option in goalOptions"
                :key="option.value"
                type="button"
                class="choice-chip"
                :class="{ selected: goalValue === option.value }"
                :disabled="isSubmitting"
                role="radio"
                :aria-checked="goalValue === option.value"
                @click="selectGoal(option.value)"
              >
                <span class="chip-label">{{ option.label }}</span>
              </button>
            </div>
          </div>

          <!-- Duration Choice Chips -->
          <div class="field">
            <div class="field-header">
              <Clock :size="16" class="field-icon" aria-hidden="true" />
              <span class="field-label">Duration</span>
              <span v-if="durationValue" class="field-active-hint">
                {{ durationChips.find((d) => d.value === durationValue)?.label }}
              </span>
            </div>
            <div class="chips-group" role="radiogroup" aria-label="Duration">
              <button
                v-for="option in durationChips"
                :key="option.value"
                type="button"
                class="choice-chip"
                :class="{ selected: durationValue === option.value }"
                :disabled="isSubmitting"
                role="radio"
                :aria-checked="durationValue === option.value"
                @click="selectDuration(option.value)"
              >
                <span class="chip-label">{{ option.label }}</span>
              </button>
            </div>
          </div>

          <!-- Priority Choice Chips -->
          <div class="field">
            <div class="field-header">
              <Flag :size="16" class="field-icon" aria-hidden="true" />
              <span class="field-label">Priority</span>
            </div>
            <div class="chips-group priority-chips" role="group" aria-label="Priority">
              <button
                v-for="option in PRIORITIES"
                :key="option.value"
                type="button"
                class="choice-chip"
                :class="[
                  `priority-${option.value.toLowerCase()}`,
                  { selected: draft.priority === option.value }
                ]"
                :disabled="isSubmitting"
                :aria-pressed="draft.priority === option.value"
                @click="draft.priority = draft.priority === option.value ? null : option.value"
              >
                <span class="chip-label">{{ option.label }}</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </form>

    <template #footer>
      <span v-if="mockMode" class="note">Preview only — nothing changes</span>
      <div class="footer-actions">
        <UiButton variant="ghost" size="lg" type="button" :disabled="isSubmitting" @click="emit('close')">
          Cancel
        </UiButton>
        <UiButton
          variant="primary"
          size="lg"
          type="submit"
          form="new-task-form"
          :loading="isSubmitting"
          :disabled="!draft.title.trim()"
        >
          {{ isEdit ? 'Save changes' : 'Add task' }}
        </UiButton>
      </div>
    </template>
  </UiDialog>
</template>

<style scoped>
.form {
  display: flex;
  flex-direction: column;
}

.form-columns {
  display: grid;
  grid-template-columns: 1.15fr 1fr;
  gap: var(--space-8);
  align-items: start;
}

@media (max-width: 860px) {
  .form-columns {
    grid-template-columns: 1fr;
    gap: var(--space-6);
  }
}

.form-main {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.title-input :deep(.field) {
  height: 52px;
  font-size: var(--text-lg);
  padding: 0 var(--space-4);
  border-radius: var(--radius-md);
}

.title-input :deep(.label) {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--text-primary);
}

.description-input :deep(.field) {
  font-size: var(--text-md);
  padding: var(--space-4);
  line-height: 1.6;
  border-radius: var(--radius-md);
}

.description-input :deep(.label) {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--text-primary);
}

.form-main :deep(.ui-input .label),
.form-main :deep(.ui-select .label) {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--text-primary);
}

.form-main :deep(.ui-input .field),
.form-main :deep(.ui-select .field) {
  height: 48px;
  font-size: var(--text-md);
}

.form-sidebar {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-xl);
  padding: var(--space-6);
}

.field-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-4);
}

.field {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.field-header {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-bottom: var(--space-1);
}

.field-icon {
  color: var(--accent-strong);
  flex-shrink: 0;
}

.field-label {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--text-primary);
  letter-spacing: -0.01em;
}

.field-active-hint {
  margin-left: auto;
  font-size: var(--text-sm);
  color: var(--accent-strong);
  font-weight: 600;
  padding: 2px 10px;
  background: var(--accent-soft);
  border-radius: var(--radius-full);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 170px;
}

.chips-group {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  max-height: 180px;
  overflow-y: auto;
  padding: 2px;
}

.choice-chip {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  min-height: 40px;
  padding: 0 var(--space-4);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-full);
  background: var(--surface-1);
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-secondary);
  cursor: pointer;
  user-select: none;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.choice-chip:hover {
  border-color: var(--border-strong);
  color: var(--text-primary);
  background: var(--surface-3);
  transform: translateY(-1px);
}

.choice-chip.selected {
  border-color: var(--accent-border);
  background: var(--accent-soft);
  color: var(--accent-strong);
  font-weight: 600;
  box-shadow: 0 0 0 1px var(--accent-border);
}

.choice-chip:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.chip-dot {
  width: 9px;
  height: 9px;
  border-radius: var(--radius-full);
  flex-shrink: 0;
}

.chip-label {
  line-height: 1;
}

/* Priority chips */
.priority-chips .choice-chip {
  flex: 1;
  min-height: 44px;
  justify-content: center;
  font-size: var(--text-md);
  font-weight: 600;
  border-radius: var(--radius-md);
}

.priority-chips .choice-chip.priority-low.selected {
  border-color: rgba(57, 197, 138, 0.45);
  background: var(--success-soft);
  color: var(--success);
  box-shadow: 0 0 0 1px rgba(57, 197, 138, 0.45);
}

.priority-chips .choice-chip.priority-medium.selected {
  border-color: rgba(244, 183, 64, 0.45);
  background: var(--warning-soft);
  color: var(--warning);
  box-shadow: 0 0 0 1px rgba(244, 183, 64, 0.45);
}

.priority-chips .choice-chip.priority-high.selected {
  border-color: rgba(240, 90, 90, 0.45);
  background: var(--danger-soft);
  color: var(--danger);
  box-shadow: 0 0 0 1px rgba(240, 90, 90, 0.45);
}

/* Destination group ("Add to") */
.destination-group {
  display: flex;
  gap: var(--space-3);
}

.destination-chip {
  flex: 1;
  min-height: 46px;
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  background: var(--surface-2);
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--text-secondary);
  cursor: pointer;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.destination-chip:hover {
  border-color: var(--border-strong);
  color: var(--text-primary);
}

.destination-chip.selected {
  border-color: var(--accent-border);
  background: var(--accent-soft);
  color: var(--accent-strong);
  font-weight: 600;
  box-shadow: 0 0 0 1px var(--accent-border);
}

.destination-chip:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.note {
  font-size: var(--text-sm);
  color: var(--text-disabled);
}

.footer-actions {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-left: auto;
}

.footer-actions :deep(.ui-button) {
  min-width: 140px;
  height: 50px;
  font-size: var(--text-md);
  font-weight: 600;
  border-radius: var(--radius-md);
}
</style>
