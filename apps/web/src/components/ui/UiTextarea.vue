<script setup lang="ts">
import { useId } from 'vue'

withDefaults(
  defineProps<{
    modelValue: string
    label: string
    placeholder?: string
    rows?: number
    disabled?: boolean
  }>(),
  { placeholder: '', rows: 3, disabled: false },
)

const emit = defineEmits<{ 'update:modelValue': [value: string] }>()

const id = useId()

function onInput(event: Event) {
  emit('update:modelValue', (event.target as HTMLTextAreaElement).value)
}
</script>

<template>
  <div class="ui-textarea">
    <label class="label" :for="id">{{ label }}</label>
    <textarea
      :id="id"
      class="field"
      :value="modelValue"
      :placeholder="placeholder"
      :rows="rows"
      :disabled="disabled"
      @input="onInput"
    />
  </div>
</template>

<style scoped>
.ui-textarea {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.label {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-secondary);
}

.field {
  padding: var(--space-3);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  color: var(--text-primary);
  font-size: var(--text-md);
  font-family: inherit;
  line-height: 1.5;
  resize: vertical;
  min-height: 72px;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.field::placeholder {
  color: var(--text-disabled);
}

.field:hover:not(:disabled) {
  border-color: var(--border-strong);
}

.field:focus {
  outline: none;
  border-color: var(--accent-border);
  background: var(--surface-1);
}
</style>
