<script setup lang="ts">
import { onBeforeUnmount, ref, watch } from 'vue'
import {
  CalendarPlus,
  CheckCircle2,
  MoreHorizontal,
  Pencil,
  Play,
  Trash2,
} from 'lucide-vue-next'

import { showPreviewNote } from '@/lib/preview'

import type { Task } from '../types'

const props = defineProps<{ task: Task }>()

const open = ref(false)
const menuRef = ref<HTMLElement | null>(null)

const isCompleted = () => props.task.status === 'COMPLETED'

interface MenuAction {
  key: string
  label: string
  icon: typeof Play
  danger?: boolean
}

const actions: MenuAction[] = [
  { key: 'plan', label: 'Plan for today', icon: CalendarPlus },
  { key: 'start', label: 'Start', icon: Play },
  { key: 'complete', label: 'Mark complete', icon: CheckCircle2 },
  { key: 'edit', label: 'Edit task', icon: Pencil },
  { key: 'delete', label: 'Delete', icon: Trash2, danger: true },
]

function toggle(event: MouseEvent) {
  event.stopPropagation()
  open.value = !open.value
}

function close() {
  open.value = false
}

/** Milestone 2 UI: lifecycle operations belong to the backend (Task
 * Management spec §15) — the menu is wired, the calls arrive with the API. */
function onAction(action: MenuAction, event: MouseEvent) {
  event.stopPropagation()
  close()
  showPreviewNote(`“${action.label}” will call the Task API in a later milestone — visual only for now.`)
}

function onDocumentClick(event: MouseEvent) {
  if (menuRef.value && !menuRef.value.contains(event.target as Node)) {
    close()
  }
}

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') close()
}

watch(open, (isOpen) => {
  if (isOpen) {
    document.addEventListener('click', onDocumentClick)
    document.addEventListener('keydown', onKeydown)
  } else {
    document.removeEventListener('click', onDocumentClick)
    document.removeEventListener('keydown', onKeydown)
  }
})

onBeforeUnmount(() => {
  document.removeEventListener('click', onDocumentClick)
  document.removeEventListener('keydown', onKeydown)
})
</script>

<template>
  <span ref="menuRef" class="action-menu">
    <button
      class="trigger"
      type="button"
      aria-label="Task actions"
      aria-haspopup="menu"
      :aria-expanded="open"
      @click="toggle"
    >
      <MoreHorizontal :size="15" :stroke-width="1.75" />
    </button>

    <Transition name="menu">
      <div v-if="open" class="menu" role="menu" @click.stop>
        <button
          v-for="action in actions"
          :key="action.key"
          class="menu-item"
          :class="{ danger: action.danger, disabled: action.key === 'complete' && isCompleted() }"
          role="menuitem"
          type="button"
          :disabled="action.key === 'complete' && isCompleted()"
          @click="onAction(action, $event)"
        >
          <component :is="action.icon" :size="14" :stroke-width="1.75" />
          {{ action.label }}
        </button>
      </div>
    </Transition>
  </span>
</template>

<style scoped>
.action-menu {
  position: relative;
  flex-shrink: 0;
}

.trigger {
  display: grid;
  place-items: center;
  width: 26px;
  height: 26px;
  border-radius: var(--radius-sm);
  color: var(--text-disabled);
  opacity: 0;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out),
    opacity var(--duration-fast) var(--ease-out);
}

/* Revealed by the parent row's hover */
:global(.task-list-row:hover) .trigger,
:global(.inbox-row:hover) .trigger,
.trigger[aria-expanded='true'] {
  opacity: 1;
}

.trigger:hover {
  background: var(--surface-3);
  color: var(--text-secondary);
}

.menu {
  position: absolute;
  right: 0;
  top: calc(100% + 4px);
  z-index: 50;
  min-width: 180px;
  padding: var(--space-1);
  background: var(--surface-3);
  border: 1px solid var(--border-strong);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-panel);
}

.menu-item {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  width: 100%;
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-sm);
  font-size: var(--text-sm);
  color: var(--text-secondary);
  text-align: left;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.menu-item:hover:not(:disabled) {
  background: var(--surface-2);
  color: var(--text-primary);
}

.menu-item.danger:hover:not(:disabled) {
  color: var(--danger);
}

.menu-item:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.menu-enter-active,
.menu-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.menu-enter-from,
.menu-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}
</style>
