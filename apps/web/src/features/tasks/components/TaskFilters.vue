<script setup lang="ts">
import { computed } from 'vue'

import FilterChips from '@/components/shared/FilterChips.vue'

import { TASK_FILTER_LABELS, type TaskStatusFilter } from '../store'

const props = defineProps<{
  active: TaskStatusFilter
  counts: Record<TaskStatusFilter, number>
}>()

const emit = defineEmits<{ change: [filter: TaskStatusFilter] }>()

const options = computed(() =>
  (Object.keys(TASK_FILTER_LABELS) as TaskStatusFilter[]).map((key) => ({
    key,
    label: TASK_FILTER_LABELS[key],
    count: props.counts[key],
  })),
)
</script>

<template>
  <FilterChips
    :options="options"
    :active="active"
    label="Filter tasks by status"
    @change="emit('change', $event)"
  />
</template>
