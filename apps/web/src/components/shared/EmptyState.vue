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
  padding: var(--space-12) var(--space-8);
  border: 1px dashed var(--border-strong);
  border-radius: var(--radius-lg);
}

.empty-state.compact {
  padding: var(--space-7) var(--space-5);
}

.icon-wrap {
  display: grid;
  place-items: center;
  width: 48px;
  height: 48px;
  border-radius: var(--radius-md);
  background: var(--surface-2);
  color: var(--text-tertiary);
  margin-bottom: var(--space-4);
}

.compact .icon-wrap {
  width: 40px;
  height: 40px;
}

.title {
  font-size: var(--text-xl);
  font-weight: 600;
  letter-spacing: -0.01em;
  color: var(--text-primary);
}

.compact .title {
  font-size: var(--text-lg);
}

.description {
  margin-top: var(--space-2);
  font-size: var(--text-md);
  line-height: 1.55;
  color: var(--text-tertiary);
  max-width: 380px;
}
</style>
