<script setup lang="ts">
import { useId } from 'vue'
import { ChevronDown } from 'lucide-vue-next'

export interface SelectOption {
  value: string
  label: string
}

defineProps<{
  modelValue: string
  label: string
  options: SelectOption[]
  disabled?: boolean
}>()

const emit = defineEmits<{ 'update:modelValue': [value: string] }>()

const id = useId()

function onChange(event: Event) {
  emit('update:modelValue', (event.target as HTMLSelectElement).value)
}
</script>

<template>
  <div class="ui-select">
    <label class="label" :for="id">{{ label }}</label>
    <div class="field-wrap">
      <select
        :id="id"
        class="field"
        :value="modelValue"
        :disabled="disabled"
        @change="onChange"
      >
        <option v-for="option in options" :key="option.value" :value="option.value">
          {{ option.label }}
        </option>
      </select>
      <ChevronDown :size="14" :stroke-width="1.75" class="chevron" aria-hidden="true" />
    </div>
  </div>
</template>

<style scoped>
.ui-select {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  min-width: 0;
}

.label {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-secondary);
}

.field-wrap {
  position: relative;
}

.field {
  width: 100%;
  height: 40px;
  padding: 0 var(--space-8) 0 var(--space-3);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  color: var(--text-primary);
  font-size: var(--text-md);
  appearance: none;
  cursor: pointer;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
  color-scheme: dark;
}

.field:hover:not(:disabled) {
  border-color: var(--border-strong);
}

.field:focus {
  outline: none;
  border-color: var(--accent-border);
  background: var(--surface-1);
}

.chevron {
  position: absolute;
  right: var(--space-3);
  top: 50%;
  transform: translateY(-50%);
  color: var(--text-tertiary);
  pointer-events: none;
}
</style>
