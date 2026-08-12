<script setup lang="ts" generic="T extends string">
export interface FilterOption<T> {
  key: T
  label: string
  count?: number
}

defineProps<{
  options: FilterOption<T>[]
  active: T
  label: string
}>()

const emit = defineEmits<{ change: [key: T] }>()
</script>

<template>
  <div class="filters" role="tablist" :aria-label="label">
    <button
      v-for="option in options"
      :key="option.key"
      class="chip"
      :class="{ active: option.key === active }"
      role="tab"
      :aria-selected="option.key === active"
      type="button"
      @click="emit('change', option.key)"
    >
      {{ option.label }}
      <span v-if="option.count !== undefined" class="count tnum">{{ option.count }}</span>
    </button>
  </div>
</template>

<style scoped>
.filters {
  display: flex;
  align-items: center;
  gap: var(--space-1);
}

.chip {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  height: 28px;
  padding: 0 var(--space-3);
  border-radius: var(--radius-full);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.chip:hover {
  color: var(--text-secondary);
  background: var(--surface-2);
}

.chip.active {
  background: var(--surface-2);
  color: var(--text-primary);
  font-weight: 500;
}

.count {
  font-size: var(--text-xs);
  color: var(--text-disabled);
}

.chip.active .count {
  color: var(--text-tertiary);
}
</style>
