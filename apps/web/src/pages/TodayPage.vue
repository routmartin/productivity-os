<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'

import { useContextPanelStore } from '@/app/layouts/contextPanelStore'
import ErrorState from '@/components/shared/ErrorState.vue'
import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import AiBriefing from '@/features/ai/components/AiBriefing.vue'
import FocusTipCard from '@/features/ai/components/FocusTipCard.vue'
import { mockBriefing } from '@/features/ai/mock'
import DailySummaryCard from '@/features/focus/components/DailySummaryCard.vue'
import FocusTodayCard from '@/features/focus/components/FocusTodayCard.vue'
import { useFocusStore } from '@/features/focus/store'
import TopThreeSection from '@/features/planning/components/TopThreeSection.vue'
import { useTodayStore } from '@/features/planning/todayStore'
import type { PreviewState } from '@/features/planning/types'
import RecentActivity, { type ActivityItem } from '@/features/tasks/components/RecentActivity.vue'
import { showPreviewNote } from '@/lib/preview'

const route = useRoute()
const today = useTodayStore()
const focusStore = useFocusStore()
const panel = useContextPanelStore()

/** `?preview=loading|error|empty` forces a UI state for design review. */
function previewFromQuery(): PreviewState {
  const value = route.query.preview
  return value === 'loading' || value === 'error' || value === 'empty' ? value : null
}

/** Lands the workspace with no auto-opened panel — Today stays quiet. */
async function loadAndSelect(preview: PreviewState) {
  await today.load(preview)
  // Focus Today / Daily Summary read real session history — without this
  // load, a fresh user would see the mock 2h47m seed data on the rail.
  await focusStore.load()
  if (preview === 'loading') return
  panel.close()
}

onMounted(() => loadAndSelect(previewFromQuery()))
watch(
  () => route.query.preview,
  () => loadAndSelect(previewFromQuery()),
)

const isLoading = computed(() => today.status === 'loading' || today.status === 'idle')

/** Recent work mixed with fresh captures, newest first — mirrors the
 *  reference's Completed / Created activity feed. */
const activityItems = computed<ActivityItem[]>(() => {
  const completed = today.recentTasks.map((task) => ({
    id: `completed-${task.id}`,
    taskId: task.id,
    kind: 'completed' as const,
    title: task.title,
    at: task.completedAt ?? task.updatedAt,
  }))
  const created = today.unplannedTasks.slice(0, 2).map((task) => ({
    id: `created-${task.id}`,
    taskId: task.id,
    kind: 'created' as const,
    title: task.title,
    at: task.createdAt,
  }))
  return [...completed, ...created]
    .sort((a, b) => b.at.localeCompare(a.at))
    .slice(0, 4)
})

function onSelectTask(taskId: string) {
  panel.toggleTask(taskId)
}

function onRetry() {
  today.load(null)
}

/** "Plan My Day" is AI-assisted planning — visual-only this milestone. */
function onPlanMyDay() {
  showPreviewNote('AI day planning arrives in a later milestone.')
}
</script>

<template>
  <div class="today-page">
    <!-- Loading -->
    <div v-if="isLoading" class="layout" aria-busy="true" aria-label="Loading today">
      <div class="main">
        <SkeletonBlock height="34px" width="420px" rounded="md" />
        <SkeletonBlock height="218px" rounded="lg" />
        <SkeletonBlock height="480px" rounded="lg" />
        <SkeletonBlock height="320px" rounded="lg" />
      </div>
      <div class="rail">
        <SkeletonBlock height="210px" rounded="lg" />
        <SkeletonBlock height="150px" rounded="lg" />
        <SkeletonBlock height="168px" rounded="lg" />
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="today.status === 'error'" class="content-narrow">
      <ErrorState
        title="Today didn't load"
        description="Your plan for today could not be reached. Your data is safe — try loading it again."
        @retry="onRetry"
      />
    </div>  

    <!-- Ready — composition follows the approved visual reference -->
    <template v-else>
      <header class="hero">
        <h1 class="hero-title">Let's make today count.</h1>
        <p class="hero-sub">Focus on your priorities and progress will follow.</p>
      </header>

      <div class="layout">
        <div class="main">
          <AiBriefing :briefing="mockBriefing" @plan="onPlanMyDay" />
          <TopThreeSection
            :entries="today.topThree"
            :active-task-id="panel.activeTaskId"
            @select="onSelectTask"
          />
          <RecentActivity :items="activityItems" @select="onSelectTask" />
        </div>

        <div class="rail">
          <FocusTodayCard />
          <DailySummaryCard />
          <FocusTipCard />
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.today-page {
  max-width: var(--content-max);
  margin: 0 auto;
  padding: var(--space-6) var(--space-10) var(--space-16);
}

.content-narrow {
  max-width: 760px;
  margin: 0 auto;
  padding-top: var(--space-10);
}

/* Hero — the largest type on the page (spec §16) */
.hero {
  margin-bottom: var(--space-8);
}

.hero-title {
  font-size: var(--text-hero);
  font-weight: 700;
  letter-spacing: -0.03em;
  line-height: 1.12;
  color: var(--text-primary);
}

.hero-sub {
  margin-top: var(--space-3);
  font-size: var(--text-lg);
  color: var(--text-tertiary);
}

/* Main workspace + narrower right context column (spec §17) */
.layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) var(--rail-width);
  gap: var(--space-6);
  align-items: start;
}

.main {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
  min-width: 0;
}

.rail {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
  min-width: 0;
}

/* Container queries keyed off the workspace, so opening the context panel
   also collapses columns instead of squeezing them (spec §32: reduce
   secondary content first — typography stays readable throughout). */

/* Collapse the right rail under the main workspace. */
@container workspace (max-width: 980px) {
  .layout {
    grid-template-columns: minmax(0, 1fr);
  }

  .rail {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    align-items: start;
  }
}

@container workspace (max-width: 640px) {
  .rail {
    grid-template-columns: minmax(0, 1fr);
  }

  .hero-title {
    font-size: var(--text-3xl);
  }
}
</style>
