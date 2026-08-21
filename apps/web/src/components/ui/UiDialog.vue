<script lang="ts">
/** Dialogs opened in stacking order (nested/overlay dialogs). Escape closes
 *  the topmost one only, so an overlay doesn't dismiss the dialog beneath. */
const openDialogs: symbol[] = []

function registerDialog(id: symbol, open: boolean): void {
  const index = openDialogs.indexOf(id)
  if (open && index === -1) openDialogs.push(id)
  if (!open && index !== -1) openDialogs.splice(index, 1)
}

function isTopmost(id: symbol): boolean {
  return openDialogs[openDialogs.length - 1] === id
}
</script>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, watch } from 'vue'
import { X } from 'lucide-vue-next'

const props = withDefaults(
  defineProps<{
    open: boolean
    title: string
    /** `lg` renders a wider dialog for content-dense details. */
    size?: 'md' | 'lg'
  }>(),
  { size: 'md' },
)

const emit = defineEmits<{ close: [] }>()

const id = Symbol('dialog')

watch(
  () => props.open,
  (open) => registerDialog(id, open),
  { immediate: true },
)

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape' && props.open && isTopmost(id)) emit('close')
}

/** Global search takes over any open overlay (spec: global-search, Edge
 *  Cases — ⌘K closes other dialogs). */
function onCloseOverlays() {
  emit('close')
}

onMounted(() => {
  window.addEventListener('keydown', onKeydown)
  window.addEventListener('app:close-overlays', onCloseOverlays)
})
onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKeydown)
  window.removeEventListener('app:close-overlays', onCloseOverlays)
  registerDialog(id, false)
})
</script>

<template>
  <Transition name="dialog">
    <div
      v-if="open"
      class="overlay"
      role="presentation"
      @click.self="emit('close')"
    >
      <div class="dialog" :class="size" role="dialog" aria-modal="true" :aria-label="title">
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

.dialog.lg {
  max-width: 820px;
  max-height: calc(100vh - 64px);
  padding: var(--space-8);
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

.dialog-enter-active {
  transition: opacity var(--motion-standard) var(--ease-out);
}

.dialog-leave-active {
  transition: opacity var(--motion-fast) var(--ease-in);
}

.dialog-enter-active .dialog {
  transition:
    transform var(--motion-standard) var(--ease-out),
    opacity var(--motion-standard) var(--ease-out);
}

.dialog-leave-active .dialog {
  transition:
    transform var(--motion-fast) var(--ease-in),
    opacity var(--motion-fast) var(--ease-in);
}

.dialog-enter-from,
.dialog-leave-to {
  opacity: 0;
}

.dialog-enter-from .dialog,
.dialog-leave-to .dialog {
  transform: translateY(10px) scale(0.98);
  opacity: 0;
}
</style>
