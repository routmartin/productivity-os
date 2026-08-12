<script setup lang="ts">
import { Info } from 'lucide-vue-next'

import { previewMessage } from '@/lib/preview'
</script>

<template>
  <Transition name="toast">
    <div v-if="previewMessage" class="preview-toast" role="status">
      <Info :size="14" :stroke-width="1.75" />
      <span>{{ previewMessage }}</span>
    </div>
  </Transition>
</template>

<style scoped>
.preview-toast {
  position: fixed;
  bottom: var(--space-6);
  left: 50%;
  transform: translateX(-50%);
  z-index: 60;
  display: flex;
  align-items: center;
  gap: var(--space-2);
  max-width: 420px;
  padding: var(--space-3) var(--space-4);
  border: 1px solid var(--border-strong);
  border-radius: var(--radius-md);
  background: var(--surface-3);
  box-shadow: var(--shadow-panel);
  font-size: var(--text-sm);
  color: var(--text-secondary);
}

.preview-toast svg {
  flex-shrink: 0;
  color: var(--text-tertiary);
}

.toast-enter-active,
.toast-leave-active {
  transition:
    opacity var(--duration-normal) var(--ease-out),
    transform var(--duration-normal) var(--ease-out);
}

.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(8px);
}
</style>
