<script setup lang="ts">
withDefaults(
  defineProps<{
    tone?: 'neutral' | 'accent' | 'ai' | 'info' | 'success' | 'warning' | 'danger'
  }>(),
  { tone: 'neutral' },
)
</script>

<template>
  <span class="ui-pill" :class="`tone-${tone}`">
    <slot />
  </span>
</template>

<style scoped>
.ui-pill {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  height: 22px;
  padding: 0 var(--space-2);
  border-radius: var(--radius-full);
  font-size: var(--text-xs);
  font-weight: 500;
  letter-spacing: 0.01em;
  white-space: nowrap;
}

.tone-neutral {
  background: var(--surface-2);
  color: var(--text-secondary);
}

.tone-accent {
  background: var(--accent-soft);
  color: var(--accent-strong);
}

.tone-ai {
  background: var(--ai-soft);
  color: var(--ai-strong);
}

.tone-info {
  background: var(--blue-soft);
  color: var(--blue);
}

.tone-success {
  background: var(--success-soft);
  color: var(--success);
}

.tone-warning {
  background: var(--warning-soft);
  color: var(--warning);
}

.tone-danger {
  background: var(--danger-soft);
  color: var(--danger);
}
</style>
