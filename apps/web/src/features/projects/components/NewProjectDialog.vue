<script setup lang="ts">
import { computed, nextTick, reactive, ref, watch } from 'vue'

import UiButton from '@/components/ui/UiButton.vue'
import UiDialog from '@/components/ui/UiDialog.vue'
import UiInput from '@/components/ui/UiInput.vue'
import UiSelect from '@/components/ui/UiSelect.vue'
import UiTextarea from '@/components/ui/UiTextarea.vue'
import { useGoalsStore } from '@/features/goals/store'
import { useMock } from '@/lib/mock'

import { PROJECT_COLORS } from '../mock'
import type { NewProjectDraft, Project } from '../types'

const props = defineProps<{ open: boolean; editing?: Project | null }>()

const emit = defineEmits<{
  close: []
  create: [draft: NewProjectDraft]
  update: [projectId: string, draft: NewProjectDraft]
}>()

const isEdit = computed(() => props.editing != null)

const goalsStore = useGoalsStore()
const mockMode = useMock('PROJECTS')

const emptyDraft = (): NewProjectDraft => ({
  name: '',
  description: '',
  goalId: null,
  deadline: null,
  color: PROJECT_COLORS[0],
})

const draft = reactive<NewProjectDraft>(emptyDraft())
const isSubmitting = ref(false)
const nameInput = ref<{ $el: HTMLElement } | null>(null)

/** Goals you can attach a project to — ACTIVE (incl. DRAFT) from the real
 *  goals store, matching the Goals workspace's Active view. */
const goalOptions = computed(() => [
  { value: '', label: 'No goal' },
  ...goalsStore.goals
    .filter((goal) => goal.status === 'ACTIVE' || goal.status === 'DRAFT')
    .map((goal) => ({ value: goal.id, label: goal.title })),
])

const goalValue = ref('')
const deadlineValue = ref('')

watch(
  () => props.open,
  async (isOpen) => {
    if (isOpen) {
      Object.assign(draft, emptyDraft())
      goalValue.value = ''
      deadlineValue.value = ''

      const project = props.editing
      if (project) {
        Object.assign(draft, {
          name: project.name,
          description: project.description ?? '',
          goalId: project.goalId,
          deadline: project.deadline,
        })
        goalValue.value = project.goalId ?? ''
        deadlineValue.value = project.deadline ?? ''
      }

      isSubmitting.value = false
      // Goal options come from the server — load once if never loaded.
      if (goalsStore.status === 'idle') void goalsStore.load()
      await nextTick()
      nameInput.value?.$el.querySelector('input')?.focus()
    }
  },
)

function onSubmit() {
  if (!draft.name.trim() || isSubmitting.value) return
  isSubmitting.value = true

  const payload = {
    name: draft.name.trim(),
    description: draft.description.trim(),
    goalId: goalValue.value || null,
    deadline: deadlineValue.value || null,
    color: draft.color,
  }

  // Emits the draft; the projects store performs the real API call.
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
  <UiDialog :open="open" :title="isEdit ? 'Edit Project' : 'New Project'" @close="emit('close')">
    <form class="form" @submit.prevent="onSubmit">
      <UiInput
        ref="nameInput"
        v-model="draft.name"
        label="Project name"
        placeholder="What are you building?"
        :disabled="isSubmitting"
      />

      <UiTextarea
        v-model="draft.description"
        label="Description"
        placeholder="What does done look like?"
        :rows="2"
        :disabled="isSubmitting"
      />

      <div class="field-row">
        <UiSelect v-model="goalValue" label="Goal" :options="goalOptions" :disabled="isSubmitting" />
        <UiInput v-model="deadlineValue" label="Deadline" type="date" :disabled="isSubmitting" />
      </div>

      <div class="field">
        <span class="field-label">Accent color</span>
        <div class="swatches" role="radiogroup" aria-label="Accent color">
          <button
            v-for="color in PROJECT_COLORS"
            :key="color"
            type="button"
            class="swatch"
            :class="{ selected: draft.color === color }"
            :style="{ background: color, color: color }"
            role="radio"
            :aria-checked="draft.color === color"
            :aria-label="`Color ${color}`"
            @click="draft.color = color"
          />
        </div>
      </div>
    </form>

    <template #footer>
      <span v-if="mockMode" class="note">Preview only — nothing changes</span>
      <div class="footer-actions">
        <UiButton variant="ghost" type="button" :disabled="isSubmitting" @click="emit('close')">
          Cancel
        </UiButton>
        <UiButton
          variant="primary"
          type="submit"
          :loading="isSubmitting"
          :disabled="!draft.name.trim()"
          @click="onSubmit"
        >
          {{ isEdit ? 'Save changes' : 'Create project' }}
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

.swatches {
  display: flex;
  gap: var(--space-2);
}

.swatch {
  width: 26px;
  height: 26px;
  border-radius: var(--radius-full);
  border: 2px solid transparent;
  cursor: pointer;
  transition:
    transform var(--duration-fast) var(--ease-out),
    box-shadow var(--duration-fast) var(--ease-out);
}

.swatch:hover {
  transform: scale(1.08);
}

.swatch.selected {
  box-shadow: 0 0 0 2px var(--surface-1), 0 0 0 4px currentColor;
  border-color: transparent;
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
