<script setup lang="ts">
defineProps<{
  title: string
  meta?: string
}>()
</script>

<template>
  <div class="section-header">
    <h2 class="title">{{ title }}</h2>
    <div class="side">
      <span v-if="meta" class="meta tnum">{{ meta }}</span>
      <slot name="actions" />
    </div>
  </div>
</template>

<style scoped>
.section-header {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: var(--space-4);
  margin-bottom: var(--space-4);
}

.title {
  font-size: var(--text-xl);
  font-weight: 600;
  letter-spacing: -0.015em;
  color: var(--text-primary);
}

.side {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.meta {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}
</style>
