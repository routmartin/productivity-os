<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import {
  AlertTriangle,
  CalendarCheck,
  CalendarClock,
  CheckCircle2,
  Plus,
  RotateCcw,
  Sparkles,
} from 'lucide-vue-next'

import EmptyState from '@/components/shared/EmptyState.vue'
import ErrorState from '@/components/shared/ErrorState.vue'
import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import UiButton from '@/components/ui/UiButton.vue'
import ScheduleAddStepDialog from '@/features/planning/components/ScheduleAddStepDialog.vue'
import ScheduleContextPanel from '@/features/planning/components/ScheduleContextPanel.vue'
import ScheduleViewSwitcher from '@/features/planning/components/ScheduleViewSwitcher.vue'
import ScheduleJourneyLayout from '@/features/planning/components/layouts/ScheduleJourneyLayout.vue'
import ScheduleMatrixLayout from '@/features/planning/components/layouts/ScheduleMatrixLayout.vue'
import ScheduleSpineLayout from '@/features/planning/components/layouts/ScheduleSpineLayout.vue'
import { useScheduleStore } from '@/features/planning/scheduleStore'
import type { PreviewState } from '@/features/planning/types'

const route = useRoute()
const scheduleStore = useScheduleStore()

const isAddDialogOpen = ref(false)
const selectedPhaseForAdd = ref<string>('morning')

function onOpenAddStep(phaseId?: string) {
  selectedPhaseForAdd.value = phaseId ?? 'morning'
  isAddDialogOpen.value = true
}

function onCloseAddStep() {
  isAddDialogOpen.value = false
}

function previewFromQuery(): PreviewState {
  const value = route.query.preview
  return value === 'loading' || value === 'error' || value === 'empty' ? value : null
}

async function load(preview: PreviewState) {
  await scheduleStore.load(preview)
}

onMounted(() => load(previewFromQuery()))
watch(
  () => route.query.preview,
  () => load(previewFromQuery()),
)

const isLoading = computed(() => scheduleStore.status === 'loading' || scheduleStore.status === 'idle')
const isError = computed(() => scheduleStore.status === 'error')
const isEmpty = computed(() => scheduleStore.status === 'empty' || scheduleStore.nodes.length === 0)

const activeLayoutComponent = computed(() => {
  switch (scheduleStore.activeLayout) {
    case 'journey':
      return ScheduleJourneyLayout
    case 'matrix':
      return ScheduleMatrixLayout
    case 'spine':
    default:
      return ScheduleSpineLayout
  }
})

const formattedDate = computed(() => {
  return new Intl.DateTimeFormat('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
  }).format(new Date())
})

function onRetry() {
  scheduleStore.load(null)
}

function onLoadSample() {
  scheduleStore.load(null)
}
</script>

<template>
  <div class="schedule-page">
    <!-- Loading Skeleton State -->
    <div v-if="isLoading" class="loading-state" aria-busy="true" aria-label="Loading schedule">
      <div class="skeleton-header">
        <SkeletonBlock height="24px" width="180px" rounded="md" />
        <SkeletonBlock height="40px" width="360px" rounded="lg" />
        <SkeletonBlock height="20px" width="440px" rounded="md" />
      </div>
      <div class="skeleton-switcher">
        <SkeletonBlock height="36px" width="280px" rounded="full" />
      </div>
      <SkeletonBlock height="540px" rounded="lg" />
    </div>

    <!-- Error State -->
    <div v-else-if="isError" class="content-narrow">
      <ErrorState
        title="Schedule didn't load"
        description="Your daily schedule link-map could not be loaded. Your data is safe — try loading it again."
        @retry="onRetry"
      />
    </div>

    <!-- Main Schedule Content -->
    <template v-else>
      <header class="schedule-header">
        <div class="header-left">
          <span class="date-badge">
            <CalendarCheck :size="13" />
            {{ formattedDate }}
          </span>

          <h1 class="page-title">Daily Schedule Link-Map</h1>
          <p class="page-subtitle">
            Connect morning-to-bedtime habits with deep focus blocks to protect your rest.
          </p>

          <!-- Top Status Summary Bar -->
          <div v-if="!isEmpty" class="status-summary-bar">
            <!-- Habits Progress -->
            <div class="summary-pill habits-pill" title="Habit Stack Execution">
              <CheckCircle2 :size="13" class="pill-icon success-icon" />
              <span class="pill-text">
                {{ scheduleStore.completedHabitsCount }}/{{ scheduleStore.totalHabitsCount }} Habits ({{ scheduleStore.habitProgressPercent }}%)
              </span>
            </div>

            <!-- Bedtime Protection Status -->
            <div
              class="summary-pill bedtime-pill"
              :class="{ 'bedtime-overflow': scheduleStore.isOverflowing }"
              :title="scheduleStore.bedtimeStatusMessage"
            >
              <AlertTriangle v-if="scheduleStore.isOverflowing" :size="13" class="pill-icon warning-icon" />
              <Sparkles v-else :size="13" class="pill-icon success-icon" />
              <span class="pill-text">
                <template v-if="scheduleStore.isOverflowing">
                  Bedtime: {{ scheduleStore.projectedBedtime }} (+{{ scheduleStore.overflowMinutes }}m overflow)
                </template>
                <template v-else>
                  Bedtime: {{ scheduleStore.targetBedtime }} (On track)
                </template>
              </span>
            </div>
          </div>
        </div>

        <div class="header-right">
          <UiButton variant="primary" size="sm" @click="onOpenAddStep()">
            <Plus :size="14" />
            <span>Add Step</span>
          </UiButton>
          <ScheduleViewSwitcher v-model="scheduleStore.activeLayout" />
        </div>
      </header>

      <!-- Empty State -->
      <div v-if="isEmpty" class="content-narrow">
        <EmptyState
          :icon="CalendarClock"
          title="No activities scheduled for today"
          description="Your link-map is clear. Populate your day with anchor rituals, Daily Top 3 focus tasks, and evening wind-down."
        >
          <div class="empty-actions">
            <UiButton variant="primary" @click="onLoadSample">
              <RotateCcw :size="14" />
              <span>Load Recommended Day Trajectory</span>
            </UiButton>
          </div>
        </EmptyState>
      </div>

      <!-- Active Layout Projection View (Spine | Journey | Matrix) -->
      <main v-else class="schedule-canvas">
        <Transition name="layout-fade" mode="out-in">
          <component :is="activeLayoutComponent" @add-step="onOpenAddStep" />
        </Transition>
      </main>

      <!-- Context Side Drawer for Node Details & Habit History -->
      <ScheduleContextPanel />

      <!-- Add Step Dialog (AC-007) -->
      <ScheduleAddStepDialog
        :open="isAddDialogOpen"
        :initial-phase="selectedPhaseForAdd"
        @close="onCloseAddStep"
      />
    </template>
  </div>
</template>

<style scoped>
.schedule-page {
  max-width: var(--content-max);
  margin: 0 auto;
  padding: var(--space-6) var(--space-8) var(--space-16);
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
  position: relative;
}

.content-narrow {
  max-width: 760px;
  margin: 0 auto;
  padding-top: var(--space-8);
  width: 100%;
}

/* Skeleton Loading */
.loading-state {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
  padding: var(--space-4) 0;
}

.skeleton-header {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.skeleton-switcher {
  display: flex;
  justify-content: flex-end;
}

/* Page Header */
.schedule-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-6);
  flex-wrap: wrap;
  padding-bottom: var(--space-4);
  border-bottom: 1px solid var(--border-subtle);
}

.header-left {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  flex: 1;
  min-width: 320px;
}

.date-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--accent-strong);
  letter-spacing: 0.02em;
  text-transform: uppercase;
}

.page-title {
  font-size: var(--text-3xl);
  font-weight: 700;
  letter-spacing: -0.025em;
  color: var(--text-primary);
  margin: 0;
  line-height: 1.2;
}

.page-subtitle {
  font-size: var(--text-md);
  color: var(--text-secondary);
  margin: 0;
  line-height: 1.45;
}

/* Summary Pills */
.status-summary-bar {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-top: var(--space-2);
  flex-wrap: wrap;
}

.summary-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 12px;
  border-radius: var(--radius-full);
  font-size: var(--text-xs);
  font-weight: 600;
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  color: var(--text-primary);
  transition: all 0.2s;
}

.habits-pill {
  border-color: color-mix(in srgb, var(--success) 30%, transparent);
  background: var(--success-soft);
}

.bedtime-pill {
  border-color: color-mix(in srgb, var(--success) 30%, transparent);
  background: var(--success-soft);
}

.bedtime-pill.bedtime-overflow {
  border-color: color-mix(in srgb, var(--warning) 40%, transparent);
  background: var(--warning-soft);
  color: var(--warning);
}

.pill-icon {
  flex-shrink: 0;
}

.success-icon {
  color: var(--success);
}

.warning-icon {
  color: var(--warning);
}

.header-right {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding-top: var(--space-2);
}

/* Canvas Area */
.schedule-canvas {
  width: 100%;
  position: relative;
}

/* Empty Actions */
.empty-actions {
  margin-top: var(--space-4);
}

/* Layout transition */
.layout-fade-enter-active,
.layout-fade-leave-active {
  transition: opacity 0.18s var(--ease-out);
}

.layout-fade-enter-from,
.layout-fade-leave-to {
  opacity: 0;
}
</style>
