<script setup lang="ts">
import { nextTick, reactive, ref, watch } from 'vue'

import UiButton from '@/components/ui/UiButton.vue'
import UiDialog from '@/components/ui/UiDialog.vue'
import UiInput from '@/components/ui/UiInput.vue'
import UiSelect from '@/components/ui/UiSelect.vue'
import UiTextarea from '@/components/ui/UiTextarea.vue'

import { mockGoals, mockProjects } from '../mock'
import type { NewTaskDraft, Priority } from '../types'

const props = defineProps<{ open: boolean }>()

const emit = defineEmits<{
  close: []
  create: [draft: NewTaskDraft]
}>()

const emptyDraft = (): NewTaskDraft => ({
  title: '',
  description: '',
  projectId: null,
  priority: null,
  dueDate: null,
  estimatedMinutes: null,
})

const draft = reactive<NewTaskDraft>(emptyDraft())
const isSubmitting = ref(false)
const titleInput = ref<{ $el: HTMLElement } | null>(null)

const projectOptions = [
  { value: '', label: 'No project' },
  ...mockProjects.map((p) => ({ value: p.id, label: p.name })),
]

const goalOptions = [
  { value: '', label: 'No goal' },
  ...mockGoals.map((g) => ({ value: g.id, label: g.title })),
]

const durationOptions = [
  { value: '', label: 'No estimate' },
  { value: '15', label: '15m' },
  { value: '30', label: '30m' },
  { value: '45', label: '45m' },
  { value: '60', label: '1h' },
  { value: '90', label: '1h 30m' },
  { value: '120', label: '2h' },
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

watch(
  () => props.open,
  async (isOpen) => {
    if (isOpen) {
      Object.assign(draft, emptyDraft())
      projectValue.value = ''
      goalValue.value = ''
      dueValue.value = ''
      durationValue.value = ''
      isSubmitting.value = false
      await nextTick()
      titleInput.value?.$el.querySelector('input')?.focus()
    }
  },
)

function onSubmit() {
  if (!draft.title.trim() || isSubmitting.value) return
  isSubmitting.value = true

  // Simulated submission latency — the creation loading state is part of
  // the spec (§19); the real POST /api/v1/tasks plugs in later.
  setTimeout(() => {
    emit('create', {
      title: draft.title.trim(),
      description: draft.description.trim(),
      projectId: projectValue.value || null,
      priority: draft.priority,
      dueDate: dueValue.value || null,
      estimatedMinutes: durationValue.value ? Number(durationValue.value) : null,
    })
    emit('close')
  }, 400)
}

</script>

<template>
  <UiDialog :open="open" title="New Task" @close="emit('close')">
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

          <div class="field-row">
            <UiInput v-model="dueValue" label="Due date" type="date" :disabled="isSubmitting" />
            <UiSelect v-model="durationValue" label="Duration" :options="durationOptions" :disabled="isSubmitting" />
          </div>

    </form>

    <template #footer>
      <span class="note">Saved locally — preview only</span>
      <div class="footer-actions">
        <UiButton variant="ghost" type="button" :disabled="isSubmitting" @click="emit('close')">
          Cancel
        </UiButton>
        <UiButton variant="primary" type="submit" :loading="isSubmitting" :disabled="!draft.title.trim()">
          Add task
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
