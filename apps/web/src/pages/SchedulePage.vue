<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'

import ErrorState from '@/components/shared/ErrorState.vue'
import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import ScheduleTimeline from '@/features/planning/components/ScheduleTimeline.vue'
import { useTodayStore } from '@/features/planning/todayStore'
import type { PreviewState } from '@/features/planning/types'
import { useContextPanelStore } from '@/app/layouts/contextPanelStore'

const route = useRoute()
const today = useTodayStore()
const panel = useContextPanelStore()

function previewFromQuery(): PreviewState {
  const value = route.query.preview
  return value === 'loading' || value === 'error' || value === 'empty' ? value : null
}

async function load(preview: PreviewState) {
  await today.load(preview)
  if (preview !== 'loading') panel.close()
}

onMounted(() => load(previewFromQuery()))
watch(
  () => route.query.preview,
  () => load(previewFromQuery()),
)

const isLoading = computed(() => today.status === 'loading' || today.status === 'idle')

function onSelectTask(taskId: string) {
  panel.toggleTask(taskId)
}

function onRetry() {
  today.load(null)
}
</script>

<template>
  <div class="schedule-page">
    <div v-if="isLoading" class="loading" aria-busy="true" aria-label="Loading schedule">
      <SkeletonBlock height="34px" width="320px" rounded="md" />
      <SkeletonBlock height="480px" rounded="lg" />
    </div>

    <div v-else-if="today.status === 'error'" class="content-narrow">
      <ErrorState
        title="Schedule didn't load"
        description="Your plan for today could not be reached. Your data is safe — try loading it again."
        @retry="onRetry"
      />
    </div>

    <template v-else>
      <header class="page-header">
        <h1 class="page-title">Schedule</h1>
        <p class="page-subtitle">Your day, planned block by block.</p>
      </header>

      <ScheduleTimeline :entries="today.schedule" @select="onSelectTask" />
    </template>
  </div>
</template>

<style scoped>
.schedule-page {
  max-width: var(--content-max);
  margin: 0 auto;
  padding: var(--space-8) var(--space-10) var(--space-16);
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.content-narrow {
  max-width: 760px;
  margin: 0 auto;
  padding-top: var(--space-10);
}

.loading {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.page-header {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.page-title {
  font-size: var(--text-3xl);
  font-weight: 700;
  letter-spacing: -0.025em;
  color: var(--text-primary);
}

.page-subtitle {
  font-size: var(--text-lg);
  color: var(--text-tertiary);
}
</style>