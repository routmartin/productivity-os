<script setup lang="ts">
import { computed, nextTick, reactive, ref, watch } from 'vue'

import UiButton from '@/components/ui/UiButton.vue'
import UiDialog from '@/components/ui/UiDialog.vue'
import UiInput from '@/components/ui/UiInput.vue'
import UiSelect from '@/components/ui/UiSelect.vue'
import UiTextarea from '@/components/ui/UiTextarea.vue'
import { useGoalsStore } from '@/features/goals/store'
import { useProjectsStore } from '@/features/projects/store'
import { useMock } from '@/lib/mock'

import type { NewTaskDraft, Priority, Task } from '../types'

const props = defineProps<{ open: boolean; editing?: Task | null }>()

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
const isSubmitting = ref(false)
const titleInput = ref<{ $el: HTMLElement } | null>(null)

const projectOptions = computed(() => [
  { value: '', label: 'No project' },
  ...projectsStore.projects.map((p) => ({ value: p.id, label: p.name })),
])

const goalOptions = computed(() => [
  { value: '', label: 'No goal' },
  ...goalsStore.goals
    .filter((goal) => goal.status === 'ACTIVE' || goal.status === 'DRAFT')
    .map((goal) => ({ value: goal.id, label: goal.title })),
])

const durationOptions = [
  { value: '', label: 'No estimate' },
  { value: '15', label: '15m' },
  { value: '30', label: '30m' },
  { value: '45', label: '45m' },
  { value: '60', label: '1h' },
  { value: '90', label: '1h 30m' },
  { value: '120', label: '2h' },
]

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

// Selects keep string values; map empty string to null on read.
// Goal is a local form value only: on the backend a task reaches its goal
// through its project, so the mock does not persist a task-level goal.
const projectValue = ref('')
const goalValue = ref('')
const dueValue = ref('')
const durationValue = ref('')
const timeValue = ref('')
const recurrenceValue = ref('')

watch(
  () => props.open,
  async (isOpen) => {
    if (isOpen) {
      Object.assign(draft, emptyDraft())
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
        dueValue.value = task.dueDate ?? ''
        durationValue.value = task.estimatedMinutes ? String(task.estimatedMinutes) : ''
        timeValue.value = task.scheduledTime ?? ''
        recurrenceValue.value = task.recurrence ?? ''
      }

      isSubmitting.value = false
      // Dropdowns come from the server — load once if never loaded.
      if (projectsStore.status === 'idle') void projectsStore.load()
      if (goalsStore.status === 'idle') void goalsStore.load()
      await nextTick()
      titleInput.value?.$el.querySelector('input')?.focus()
    }
  },
)

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

  // Emits the draft; the tasks store performs the real API call.
  setTimeout(() => {
    if (props.editing) {
      emit('update', props.editing.id, payload)
    } else {
      emit('create', payload)
    }
    emit('close')
  }, 400)
}

</script>

<template>
  <UiDialog :open="open" :title="isEdit ? 'Edit Task' : 'New Task'" @close="emit('close')">
    <form class="form" @submit.prevent="onSubmit">
          <UiInput
            ref="titleInput"
            v-model="draft.title"
            label="Title"
            placeholder="What needs to be done?"
            :disabled="isSubmitting"
          />

          <UiTextarea
            v-model="draft.description"
            label="Description"
            placeholder="Optional details…"
            :rows="3"
            :disabled="isSubmitting"
          />

          <div class="field-row">
            <UiSelect v-model="projectValue" label="Project" :options="projectOptions" :disabled="isSubmitting" />
            <UiSelect v-model="goalValue" label="Goal" :options="goalOptions" :disabled="isSubmitting" />
          </div>

          <div class="field">
            <span class="field-label">Priority</span>
            <div class="priority-group" role="group" aria-label="Priority">
              <button
                v-for="option in PRIORITIES"
                :key="option.value"
                type="button"
                class="priority-option"
                :class="{ selected: draft.priority === option.value }"
                @click="draft.priority = draft.priority === option.value ? null : option.value"
              >
                {{ option.label }}
              </button>
            </div>
          </div>

          <div class="field-row" v-if="mockMode">
            <UiInput v-model="dueValue" label="Due date" type="date" :disabled="isSubmitting" />
            <UiSelect v-model="timeValue" label="Time" :options="timeOptions" :disabled="isSubmitting" />
          </div>
          <UiInput v-else v-model="dueValue" label="Due date" type="date" :disabled="isSubmitting" />

          <div class="field-row">
            <UiSelect v-model="durationValue" label="Duration" :options="durationOptions" :disabled="isSubmitting" />
            <UiSelect v-if="mockMode" v-model="recurrenceValue" label="Repeat" :options="recurrenceOptions" :disabled="isSubmitting" />
          </div>

    </form>

    <template #footer>
      <span v-if="mockMode" class="note">Preview only — nothing changes</span>
      <div class="footer-actions">
        <UiButton variant="ghost" type="button" :disabled="isSubmitting" @click="emit('close')">
          Cancel
        </UiButton>
        <UiButton variant="primary" type="submit" :loading="isSubmitting" :disabled="!draft.title.trim()">
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
  gap: var(--space-4);
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

.field-label {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-secondary);
}

.priority-group {
  display: flex;
  gap: var(--space-2);
}

.priority-option {
  flex: 1;
  height: 36px;
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  background: var(--surface-2);
  font-size: var(--text-sm);
  color: var(--text-secondary);
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.priority-option:hover {
  border-color: var(--border-strong);
  color: var(--text-primary);
}

.priority-option.selected {
  border-color: var(--accent-border);
  background: var(--accent-soft);
  color: var(--accent-strong);
  font-weight: 500;
}

.note {
  font-size: var(--text-xs);
  color: var(--text-disabled);
}

.footer-actions {
  display: flex;
  gap: var(--space-2);
}
</style>
