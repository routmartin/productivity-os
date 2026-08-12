<script setup lang="ts">
import { X } from 'lucide-vue-next'

defineProps<{
  open: boolean
  title: string
}>()

const emit = defineEmits<{ close: [] }>()

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') emit('close')
}
</script>

<template>
  <Transition name="dialog">
    <div
      v-if="open"
      class="overlay"
      role="presentation"
      @keydown="onKeydown"
      @click.self="emit('close')"
    >
      <div class="dialog" role="dialog" aria-modal="true" :aria-label="title">
        <header class="dialog-header">
          <h2 class="dialog-title">{{ title }}</h2>
          <button class="close" type="button" aria-label="Close" @click="emit('close')">
            <X :size="16" :stroke-width="1.75" />
          </button>
        </header>

        <slot />

        <footer v-if="$slots.footer" class="dialog-footer">
          <slot name="footer" />
        </footer>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  z-index: 70;
  display: grid;
  place-items: center;
  padding: var(--space-6);
  background: var(--surface-overlay);
  backdrop-filter: blur(4px);
}

.dialog {
  width: 100%;
  max-width: 520px;
  max-height: calc(100vh - 96px);
  overflow-y: auto;
  background: var(--surface-1);
  border: 1px solid var(--border-strong);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-panel);
  padding: var(--space-6);
}

.dialog-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-5);
}

.dialog-title {
  font-size: var(--text-xl);
  letter-spacing: -0.02em;
}

.close {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  border-radius: var(--radius-md);
  color: var(--text-tertiary);
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.close:hover {
  background: var(--surface-2);
  color: var(--text-primary);
}

.dialog-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  margin-top: var(--space-5);
}

.dialog-enter-active,
.dialog-leave-active {
  transition: opacity var(--duration-normal) var(--ease-out);
}

.dialog-enter-active .dialog,
.dialog-leave-active .dialog {
  transition:
    transform var(--duration-normal) var(--ease-out),
    opacity var(--duration-normal) var(--ease-out);
}

.dialog-enter-from,
.dialog-leave-to {
  opacity: 0;
}

.dialog-enter-from .dialog,
.dialog-leave-to .dialog {
  transform: translateY(10px) scale(0.99);
  opacity: 0;
}
</style>
