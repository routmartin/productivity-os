<script setup lang="ts">
import { useId } from 'vue'

const props = withDefaults(
  defineProps<{
    modelValue: string
    label: string
    type?: string
    placeholder?: string
    error?: string | null
    autocomplete?: string
    disabled?: boolean
  }>(),
  {
    type: 'text',
    placeholder: '',
    error: null,
    autocomplete: 'off',
    disabled: false,
  },
)

const emit = defineEmits<{
  'update:modelValue': [value: string]
  blur: []
}>()

const id = useId()
const errorId = `${id}-error`

function onInput(event: Event) {
  emit('update:modelValue', (event.target as HTMLInputElement).value)
}
</script>

<template>
  <div class="ui-input" :class="{ 'has-error': Boolean(props.error) }">
    <label class="label" :for="id">{{ label }}</label>
    <input
      :id="id"
      class="field"
      :type="type"
      :value="modelValue"
      :placeholder="placeholder"
      :autocomplete="autocomplete"
      :disabled="disabled"
      :aria-invalid="Boolean(props.error) || undefined"
      :aria-describedby="props.error ? errorId : undefined"
      @input="onInput"
      @blur="emit('blur')"
    />
    <p v-if="props.error" :id="errorId" class="error" role="alert">{{ props.error }}</p>
  </div>
</template>

<style scoped>
.ui-input {
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
  height: 46px;
  padding: 0 var(--space-4);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  color: var(--text-primary);
  font-size: var(--text-md);
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

.field:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

.has-error .field {
  border-color: var(--danger);
}

.error {
  font-size: var(--text-sm);
  color: var(--danger);
}
</style>
