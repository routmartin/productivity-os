<script setup lang="ts">
import { computed } from 'vue'
import { Compass, LayoutGrid, Map } from 'lucide-vue-next'

import type { ScheduleLayoutMode } from '../types'
import { useScheduleStore } from '../scheduleStore'

const props = defineProps<{
  modelValue?: ScheduleLayoutMode
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: ScheduleLayoutMode): void
}>()

const scheduleStore = useScheduleStore()

const currentMode = computed<ScheduleLayoutMode>({
  get: () => props.modelValue ?? scheduleStore.activeLayout,
  set: (val) => {
    scheduleStore.setLayout(val)
    emit('update:modelValue', val)
  },
})

interface ViewOption {
  id: ScheduleLayoutMode
  label: string
  icon: typeof Compass
  hint: string
}

const views: ViewOption[] = [
  { id: 'spine', label: 'Spine', icon: Compass, hint: 'Bilateral chronological rail' },
  { id: 'journey', label: 'Journey', icon: Map, hint: '4-phase serpentine narrative flow' },
  { id: 'matrix', label: 'Matrix', icon: LayoutGrid, hint: 'Multi-lane cross-category matrix' },
]

function select(id: ScheduleLayoutMode) {
  currentMode.value = id
}
</script>

<template>
  <div class="view-switcher" role="radiogroup" aria-label="Schedule layout projection">
    <button
      v-for="v in views"
      :key="v.id"
      type="button"
      role="radio"
      :aria-checked="currentMode === v.id"
      class="switch-btn"
      :class="{ active: currentMode === v.id }"
      :title="v.hint"
      @click="select(v.id)"
    >
      <component :is="v.icon" :size="15" class="btn-icon" />
      <span class="btn-label">{{ v.label }}</span>
    </button>
  </div>
</template>

<style scoped>
.view-switcher {
  display: inline-flex;
  align-items: center;
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-full);
  padding: 3px;
  gap: 2px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.switch-btn {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  padding: 6px 14px;
  border-radius: var(--radius-full);
  background: transparent;
  border: 1px solid transparent;
  color: var(--text-tertiary);
  font-size: var(--text-xs);
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s var(--ease-out);
  user-select: none;
}

.switch-btn:hover {
  color: var(--text-secondary);
  background: var(--surface-2);
}

.switch-btn.active {
  background: var(--surface-3);
  color: var(--text-primary);
  border-color: var(--border-strong);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  font-weight: 600;
}

.switch-btn.active .btn-icon {
  color: var(--accent-strong);
}

.btn-icon {
  flex-shrink: 0;
  color: var(--text-tertiary);
  transition: color 0.2s;
}

.btn-label {
  letter-spacing: 0.01em;
}
</style>
