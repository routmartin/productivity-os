<script setup lang="ts">
import type { LucideIcon } from 'lucide-vue-next'

defineProps<{
  icon: LucideIcon
  title: string
  description?: string
  compact?: boolean
}>()
</script>

<template>
  <div class="empty-state" :class="{ compact }">
    <div class="icon-wrap">
      <component :is="icon" :size="compact ? 16 : 20" :stroke-width="1.5" />
    </div>
    <p class="title">{{ title }}</p>
    <p v-if="description" class="description">{{ description }}</p>
    <slot />
  </div>
</template>

<style scoped>
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: var(--space-10) var(--space-6);
  border: 1px dashed var(--border-strong);
  border-radius: var(--radius-lg);
}

.empty-state.compact {
  padding: var(--space-6) var(--space-4);
}

.icon-wrap {
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  border-radius: var(--radius-md);
  background: var(--surface-2);
  color: var(--text-tertiary);
  margin-bottom: var(--space-3);
}

.compact .icon-wrap {
  width: 32px;
  height: 32px;
}

.title {
  font-size: var(--text-md);
  font-weight: 500;
  color: var(--text-secondary);
}

.description {
  margin-top: var(--space-1);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  max-width: 320px;
}
</style>
