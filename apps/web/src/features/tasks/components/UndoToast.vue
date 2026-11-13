<script setup lang="ts">
import { CheckCircle2, Undo2 } from 'lucide-vue-next'
import { useTasksStore } from '../store'

const store = useTasksStore()

function onUndo() {
  store.undoLast()
}
</script>

<template>
  <Transition name="toast">
    <div v-if="store.toast" class="undo-toast" role="status" aria-live="polite">
      <div class="toast-body">
        <span class="toast-icon">
          <CheckCircle2 v-if="store.toast.kind === 'complete'" :size="15" :stroke-width="2.5" />
          <Undo2 v-else :size="15" :stroke-width="2.5" />
        </span>
        <div class="toast-text">
          <strong class="toast-action">
            {{ store.toast.message ?? (store.toast.kind === 'complete' ? 'Task completed' : store.toast.kind === 'reopen' ? 'Task reopened' : 'Action completed') }}
          </strong>
          <span class="toast-title">{{ store.toast.title }}</span>
        </div>
        <button class="undo-btn" type="button" @click="onUndo">
          Undo
        </button>
      </div>
      <!-- Animated 5-second visual countdown progress bar (AC-UI-004) -->
      <div class="progress-track" aria-hidden="true">
        <div class="progress-bar" />
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.undo-toast {
  position: fixed;
  bottom: var(--space-8);
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  flex-direction: column;
  background: var(--surface-3);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg), 0 8px 32px rgba(0, 0, 0, 0.28);
  z-index: 100;
  overflow: hidden;
  min-width: 320px;
  max-width: 440px;
}

.toast-body {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
}

.toast-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: var(--accent-subtle);
  color: var(--accent);
  flex-shrink: 0;
}

.toast-text {
  display: flex;
  flex-direction: column;
  gap: 1px;
  flex: 1;
  min-width: 0;
  font-size: var(--text-sm);
}

.toast-action {
  color: var(--text-primary);
  font-weight: 600;
  line-height: 1.2;
}

.toast-title {
  color: var(--text-tertiary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  font-size: var(--text-xs);
}

.undo-btn {
  background: transparent;
  border: 1px solid var(--border-default);
  color: var(--text-primary);
  padding: var(--space-1) var(--space-3);
  border-radius: var(--radius-md);
  font-size: var(--text-xs);
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
  flex-shrink: 0;
}

.undo-btn:hover {
  background: var(--surface-1);
  border-color: var(--accent);
  color: var(--accent);
}

.progress-track {
  width: 100%;
  height: 3px;
  background: rgba(255, 255, 255, 0.08);
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  background: var(--accent);
  width: 100%;
  animation: shrink 5s linear forwards;
}

@keyframes shrink {
  from {
    width: 100%;
  }
  to {
    width: 0%;
  }
}

.toast-enter-active,
.toast-leave-active {
  transition: all 0.22s cubic-bezier(0.16, 1, 0.3, 1);
}

.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translate(-50%, 12px) scale(0.96);
}
</style>
