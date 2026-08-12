<script setup lang="ts">
import SectionHeader from './SectionHeader.vue'

defineProps<{
  title?: string
  meta?: string
  padded?: boolean
}>()
</script>

<template>
  <section class="surface-card" :class="{ padded: padded !== false }">
    <SectionHeader v-if="title" :title="title" :meta="meta">
      <template v-if="$slots.actions" #actions>
        <slot name="actions" />
      </template>
    </SectionHeader>
    <slot />
  </section>
</template>

<style scoped>
.surface-card {
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  min-width: 0;
  padding: var(--space-4);
}

.padded {
  padding: var(--space-5);
}
</style>
