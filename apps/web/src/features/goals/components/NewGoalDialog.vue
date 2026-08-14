<script setup lang="ts">
import { computed, nextTick, reactive, ref, watch } from 'vue'

import UiButton from '@/components/ui/UiButton.vue'
import UiDialog from '@/components/ui/UiDialog.vue'
import UiInput from '@/components/ui/UiInput.vue'
import UiSelect from '@/components/ui/UiSelect.vue'
import UiTextarea from '@/components/ui/UiTextarea.vue'

import type { Goal, NewGoalDraft } from '../types'

const props = defineProps<{ open: boolean; editing?: Goal | null }>()

const emit = defineEmits<{
  close: []
  create: [draft: NewGoalDraft]
  update: [goalId: string, draft: NewGoalDraft]
}>()

const isEdit = computed(() => props.editing != null)

const emptyDraft = () => ({
  title: '',
  description: '',
  deadline: '',
  status: 'DRAFT' as 'DRAFT' | 'ACTIVE',
})

const draft = reactive(emptyDraft())
const isSubmitting = ref(false)
const titleInput = ref<{ $el: HTMLElement } | null>(null)

const statusOptions = [
  { value: 'DRAFT', label: 'Draft — define now, pursue later' },
  { value: 'ACTIVE', label: 'Active — start pursuing now' },
]

watch(
  () => props.open,
  async (isOpen) => {
    if (isOpen) {
      Object.assign(draft, emptyDraft())

      const goal = props.editing
      if (goal) {
        Object.assign(draft, {
          title: goal.title,
          description: goal.description ?? '',
          deadline: goal.deadline ?? '',
        })
      }

      isSubmitting.value = false
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
    deadline: draft.deadline || null,
    status: draft.status,
  }

  // Emits the draft; the goals store performs the real API call.
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
  <UiDialog :open="open" :title="isEdit ? 'Edit Goal' : 'New Goal'" @close="emit('close')">
    <form class="form" @submit.prevent="onSubmit">
      <UiInput
        ref="titleInput"
        v-model="draft.title"
        label="Title"
        placeholder="What do you want to achieve?"
        :disabled="isSubmitting"
      />

      <UiTextarea
        v-model="draft.description"
        label="Description"
        placeholder="Why does this matter?"
        :rows="2"
        :disabled="isSubmitting"
      />

      <div class="field-row">
        <UiInput
          v-model="draft.deadline"
          label="Target date (optional)"
          type="date"
          :disabled="isSubmitting"
        />
        <UiSelect
          v-if="!isEdit"
          v-model="draft.status"
          label="Initial state"
          :options="statusOptions"
          :disabled="isSubmitting"
        />
      </div>
    </form>

    <template #footer>
      <span v-if="!isEdit" class="note">Saved locally — preview only</span>
      <div class="footer-actions">
        <UiButton variant="ghost" type="button" :disabled="isSubmitting" @click="emit('close')">
          Cancel
        </UiButton>
        <UiButton
          variant="primary"
          type="submit"
          :loading="isSubmitting"
          :disabled="!draft.title.trim()"
          @click="onSubmit"
        >
          {{ isEdit ? 'Save changes' : 'Create goal' }}
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

.note {
  font-size: var(--text-xs);
  color: var(--text-disabled);
}

.footer-actions {
  display: flex;
  gap: var(--space-2);
}
</style>
