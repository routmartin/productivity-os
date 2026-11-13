<script setup lang="ts">
import { ref } from 'vue'
import { CornerDownLeft, Plus } from 'lucide-vue-next'

import UiButton from '@/components/ui/UiButton.vue'
import { useTodayStore } from '@/features/planning/todayStore'
import { useTasksStore } from '../store'
import type { Task } from '../types'

const emit = defineEmits<{
  capture: [title: string]
  created: [task: Task | null]
}>()

const tasksStore = useTasksStore()
const todayStore = useTodayStore()

const title = ref('')
const inputRef = ref<HTMLInputElement | null>(null)

function onSubmit() {
  const value = title.value.trim()
  if (!value) return

  const created = tasksStore.addTask({ title: value, status: 'INBOX' })
  if (created) {
    todayStore.recordTask(created)
  }
  emit('capture', value)
  emit('created', created)
  title.value = ''
}

function onEscape() {
  title.value = ''
  inputRef.value?.blur()
}
</script>

<template>
  <form class="quick-capture" @submit.prevent="onSubmit">
    <span class="prompt" aria-hidden="true">
      <Plus :size="16" :stroke-width="2" />
    </span>
    <input
      ref="inputRef"
      v-model="title"
      class="input"
      type="text"
      data-quick-capture-input
      placeholder="Capture a task or thought... (Press Enter to save)"
      aria-label="Capture a task or thought... (Press Enter to save)"
      @keydown.esc="onEscape"
    />
    <span class="hint" aria-hidden="true" title="Press c to focus or Enter to save">
      <kbd class="kbd tnum">c</kbd>
      <kbd class="kbd tnum enter-kbd"><CornerDownLeft :size="11" /></kbd>
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
  font-size: var(--text-base);
  font-weight: 500;
  letter-spacing: -0.01em;
  color: var(--text-primary);
}

.input::placeholder {
  color: var(--text-disabled);
}

.hint {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  flex-shrink: 0;
}

.kbd {
  display: grid;
  place-items: center;
  min-width: 20px;
  height: 20px;
  padding: 0 4px;
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  background: var(--surface-2);
  color: var(--text-tertiary);
  font-size: var(--text-xs);
  font-weight: 550;
  line-height: 1;
}

.enter-kbd {
  color: var(--text-disabled);
}
</style>
