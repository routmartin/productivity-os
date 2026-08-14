<script setup lang="ts">
import { onBeforeUnmount, ref, watch } from 'vue'
import { MoreHorizontal, Pencil, Trash2 } from 'lucide-vue-next'

import { useProjectsStore } from '../store'
import type { Project } from '../types'
import NewProjectDialog from './NewProjectDialog.vue'

const props = defineProps<{ project: Project }>()

const store = useProjectsStore()

const open = ref(false)
const menuRef = ref<HTMLElement | null>(null)
const confirmingDelete = ref(false)
const editOpen = ref(false)
const error = ref('')

function toggle(event: MouseEvent) {
  event.stopPropagation()
  confirmingDelete.value = false
  open.value = !open.value
}

function close() {
  open.value = false
  confirmingDelete.value = false
}

function onEdit(event: MouseEvent) {
  event.stopPropagation()
  close()
  editOpen.value = true
}

function onDeleteClick(event: MouseEvent) {
  event.stopPropagation()
  confirmingDelete.value = true
}

function confirmDelete(event: MouseEvent) {
  event.stopPropagation()
  close()
  store.deleteProject(props.project.id)
}

function onUpdate(projectId: string, draft: Parameters<typeof store.updateProject>[1]) {
  store.updateProject(projectId, draft)
  editOpen.value = false
}

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
      aria-label="Project actions"
      aria-haspopup="menu"
      :aria-expanded="open"
      @click="toggle"
    >
      <MoreHorizontal :size="15" :stroke-width="1.75" />
    </button>

    <Transition name="menu">
      <div v-if="open" class="menu" role="menu" @click.stop>
        <template v-if="confirmingDelete">
          <p class="confirm-copy">Delete this project?</p>
          <p class="confirm-hint">Its tasks stay in your inbox.</p>
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
          <button class="menu-item" role="menuitem" type="button" @click="onEdit($event)">
            <Pencil :size="14" :stroke-width="1.75" />
            Edit project
          </button>
          <button class="menu-item danger" role="menuitem" type="button" @click="onDeleteClick($event)">
            <Trash2 :size="14" :stroke-width="1.75" />
            Delete
          </button>
        </template>

        <p v-if="error && !confirmingDelete" class="menu-error">{{ error }}</p>
      </div>
    </Transition>

    <NewProjectDialog
      :open="editOpen"
      :editing="project"
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
  opacity: 0;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out),
    opacity var(--duration-fast) var(--ease-out);
}

:global(.project-card:hover) .trigger,
:global(.project-card:focus-visible) .trigger,
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

.confirm-copy {
  padding: var(--space-2) var(--space-3) var(--space-1);
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--danger);
}

.confirm-hint {
  padding: 0 var(--space-3);
  font-size: var(--text-xs);
  color: var(--text-tertiary);
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
