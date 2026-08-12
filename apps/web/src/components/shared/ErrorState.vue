<script setup lang="ts">
import { AlertCircle } from 'lucide-vue-next'

import UiButton from '@/components/ui/UiButton.vue'

withDefaults(
  defineProps<{
    title?: string
    description?: string
  }>(),
  {
    title: 'Something went wrong',
    description: 'We could not load this view. Please try again.',
  },
)

const emit = defineEmits<{ retry: [] }>()
</script>

<template>
  <div class="error-state" role="alert">
    <div class="icon-wrap">
      <AlertCircle :size="20" :stroke-width="1.5" />
    </div>
    <p class="title">{{ title }}</p>
    <p class="description">{{ description }}</p>
    <UiButton variant="ghost" size="sm" class="retry" @click="emit('retry')">Try again</UiButton>
  </div>
</template>

<style scoped>
.error-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: var(--space-12) var(--space-6);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  background: var(--surface-1);
}

.icon-wrap {
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  border-radius: var(--radius-md);
  background: var(--danger-soft);
  color: var(--danger);
  margin-bottom: var(--space-3);
}

.title {
  font-size: var(--text-md);
  font-weight: 500;
  color: var(--text-primary);
}

.description {
  margin-top: var(--space-1);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  max-width: 340px;
}

.retry {
  margin-top: var(--space-4);
}
</style>
