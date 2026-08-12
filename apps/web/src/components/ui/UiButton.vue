<script setup lang="ts">
import UiSpinner from './UiSpinner.vue'

withDefaults(
  defineProps<{
    variant?: 'primary' | 'ghost' | 'subtle' | 'ai' | 'outline-ai'
    size?: 'sm' | 'md' | 'lg'
    type?: 'button' | 'submit'
    loading?: boolean
    disabled?: boolean
    fullWidth?: boolean
  }>(),
  {
    variant: 'primary',
    size: 'md',
    type: 'button',
    loading: false,
    disabled: false,
    fullWidth: false,
  },
)
</script>

<template>
  <button
    class="ui-button"
    :class="[`variant-${variant}`, `size-${size}`, { 'is-loading': loading, 'full-width': fullWidth }]"
    :type="type"
    :disabled="disabled || loading"
    :aria-busy="loading || undefined"
  >
    <UiSpinner v-if="loading" :size="size === 'sm' ? 14 : 16" class="spinner" />
    <span class="content" :class="{ invisible: loading }">
      <slot />
    </span>
  </button>
</template>

<style scoped>
.ui-button {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  border-radius: var(--radius-md);
  font-weight: 500;
  letter-spacing: -0.005em;
  border: 1px solid transparent;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    border-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
  white-space: nowrap;
  user-select: none;
}

.ui-button:active:not(:disabled) {
  transform: translateY(0.5px);
}

.ui-button:disabled {
  cursor: not-allowed;
  opacity: 0.55;
}

/* Sizes */
.size-sm {
  height: 32px;
  padding: 0 var(--space-3);
  font-size: var(--text-sm);
}

.size-md {
  height: 38px;
  padding: 0 var(--space-4);
  font-size: var(--text-md);
}

.size-lg {
  height: 46px;
  padding: 0 var(--space-6);
  font-size: var(--text-lg);
}

/* Variants */
.variant-primary {
  background: var(--accent);
  color: #0b0e18;
  font-weight: 600;
}

.variant-primary:hover:not(:disabled) {
  background: var(--accent-strong);
}

.variant-ghost {
  background: transparent;
  color: var(--text-secondary);
  border-color: var(--border-strong);
}

.variant-ghost:hover:not(:disabled) {
  background: var(--surface-2);
  color: var(--text-primary);
}

.variant-subtle {
  background: var(--surface-2);
  color: var(--text-primary);
}

.variant-subtle:hover:not(:disabled) {
  background: var(--surface-3);
}

.variant-ai {
  background: var(--ai-soft);
  color: var(--ai-strong);
  border-color: var(--ai-border);
}

.variant-ai:hover:not(:disabled) {
  background: rgba(139, 92, 246, 0.2);
}

.variant-outline-ai {
  background: transparent;
  color: var(--ai-strong);
  border-color: var(--ai-border);
}

.variant-outline-ai:hover:not(:disabled) {
  background: var(--ai-soft);
}

.full-width {
  width: 100%;
}

.spinner {
  position: absolute;
}

.content.invisible {
  visibility: hidden;
}
</style>
