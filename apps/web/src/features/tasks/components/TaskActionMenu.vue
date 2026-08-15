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

import { useTasksStore } from '../store'
import type { Task } from '../types'
import NewTaskDialog from './NewTaskDialog.vue'

const props = defineProps<{ task: Task }>()

const store = useTasksStore()

const open = ref(false)
const menuRef = ref<HTMLElement | null>(null)
const confirmingDelete = ref(false)
const editOpen = ref(false)
const error = ref('')

interface MenuAction {
  key: string
  label: string
  icon: typeof Play
  danger?: boolean
  disabled?: boolean
}

const actions = (): MenuAction[] => [
  { key: 'plan', label: 'Plan for today', icon: CalendarPlus, disabled: props.task.status !== 'INBOX' },
  { key: 'start', label: 'Start', icon: Play, disabled: props.task.status !== 'PLANNED' },
  { key: 'complete', label: 'Mark complete', icon: CheckCircle2, disabled: props.task.status !== 'IN_PROGRESS' },
  { key: 'edit', label: 'Edit task', icon: Pencil },
  { key: 'delete', label: 'Delete', icon: Trash2, danger: true },
]

function toggle(event: MouseEvent) {
  event.stopPropagation()
  confirmingDelete.value = false
  open.value = !open.value
}

function close() {
  open.value = false
  confirmingDelete.value = false
}

function onAction(action: MenuAction, event: MouseEvent) {
  event.stopPropagation()
  if (action.disabled) return

  if (action.key === 'delete') {
    confirmingDelete.value = true
    return
  }

  if (action.key === 'edit') {
    close()
    editOpen.value = true
    return
  }

  close()
  switch (action.key) {
    case 'plan':
      store.planTask(props.task.id)
      break
    case 'start':
      store.startTask(props.task.id)
      break
    case 'complete':
      store.toggleTaskComplete(props.task.id)
      break
  }
}

function confirmDelete(event: MouseEvent) {
  event.stopPropagation()
  close()
  store.deleteTask(props.task.id)
}

function onUpdate(taskId: string, draft: Parameters<typeof store.updateTask>[1]) {
  store.updateTask(taskId, draft)
  editOpen.value = false
}

/** Surface the last failed mutation inside the menu (e.g. a 409 invalid
 *  transition) so the user knows the action didn't stick. */
let errorTimer: ReturnType<typeof setTimeout> | undefined
watch(
  () => store.lastError,
  (message) => {
    if (!message) return
    error.value = message
    clearTimeout(errorTimer)
    errorTimer = setTimeout(() => (error.value = ''), 5000)
  },
)

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
  clearTimeout(errorTimer)
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
        <template v-if="confirmingDelete">
          <p class="confirm-copy">Delete this task?</p>
          <div class="confirm-row">
            <button
              class="menu-item"
              role="menuitem"
              type="button"
              @click="confirmingDelete = false"
            >
              Cancel
            </button>
            <button
              class="menu-item danger"
              role="menuitem"
              type="button"
              @click="confirmDelete($event)"
            >
              Delete
            </button>
          </div>
        </template>

        <template v-else>
          <button
            v-for="action in actions()"
            :key="action.key"
            class="menu-item"
            :class="{ danger: action.danger, disabled: action.disabled }"
            role="menuitem"
            type="button"
            :disabled="action.disabled"
            @click="onAction(action, $event)"
          >
            <component :is="action.icon" :size="14" :stroke-width="1.75" />
            {{ action.label }}
          </button>
        </template>

        <p v-if="error && !confirmingDelete" class="menu-error">{{ error }}</p>
      </div>
    </Transition>

    <NewTaskDialog
      :open="editOpen"
      :editing="task"
      @close="editOpen = false"
      @update="onUpdate"
    />
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
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.trigger:hover,
.trigger[aria-expanded='true'] {
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

.confirm-copy {
  padding: var(--space-2) var(--space-3) var(--space-1);
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--danger);
}

.confirm-row {
  display: flex;
  gap: var(--space-1);
  padding: var(--space-1);
}

.confirm-row .menu-item {
  flex: 1;
  justify-content: center;
}

.menu-error {
  margin: var(--space-1) var(--space-2) var(--space-2);
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-sm);
  background: var(--danger-soft);
  color: var(--danger);
  font-size: var(--text-xs);
  line-height: 1.4;
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
