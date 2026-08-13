<script setup lang="ts">
import { ref } from 'vue'
import { CornerDownLeft, Plus } from 'lucide-vue-next'

import UiButton from '@/components/ui/UiButton.vue'

const emit = defineEmits<{ capture: [title: string] }>()

const title = ref('')

function onSubmit() {
  const value = title.value.trim()
  if (!value) return
  emit('capture', value)
  title.value = ''
}
</script>

<template>
  <form class="quick-capture" @submit.prevent="onSubmit">
    <span class="prompt">
      <Plus :size="16" :stroke-width="2" />
    </span>
    <input
      v-model="title"
      class="input"
      type="text"
      placeholder="What needs to be done?"
      aria-label="What needs to be done?"
    />
    <span class="hint">
      <kbd class="kbd tnum"><CornerDownLeft :size="11" /></kbd>
    </span>
    <UiButton type="submit" variant="primary" :disabled="!title.trim()">Add</UiButton>
  </form>
</template>

<style scoped>
.quick-capture {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  min-height: 62px;
  padding: var(--space-3) var(--space-5);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out),
    box-shadow var(--duration-fast) var(--ease-out);
}

.quick-capture:focus-within {
  border-color: var(--accent-border);
  background: var(--surface-1);
  box-shadow: 0 0 0 3px var(--accent-soft);
}

.prompt {
  display: grid;
  place-items: center;
  color: var(--text-tertiary);
  flex-shrink: 0;
}

.input {
  flex: 1;
  min-width: 0;
  background: transparent;
  border: none;
  outline: none;
  font-size: var(--text-xl);
  font-weight: 500;
  letter-spacing: -0.01em;
  color: var(--text-primary);
}

.input::placeholder {
  color: var(--text-disabled);
}

.hint {
  flex-shrink: 0;
}

.kbd {
  display: grid;
  place-items: center;
  width: 22px;
  height: 20px;
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  background: var(--surface-2);
  color: var(--text-disabled);
}
</style>
