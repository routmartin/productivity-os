<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Sparkles } from 'lucide-vue-next'

import { useContextPanelStore } from '@/app/layouts/contextPanelStore'
import ErrorState from '@/components/shared/ErrorState.vue'
import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import UiButton from '@/components/ui/UiButton.vue'
import AiBriefing from '@/features/ai/components/AiBriefing.vue'
import AiInsights from '@/features/ai/components/AiInsights.vue'
import { mockBriefing, mockInsights } from '@/features/ai/mock'
import { useAuthStore } from '@/features/auth/store'
import FocusPanel from '@/features/focus/components/FocusPanel.vue'
import CalendarContext from '@/features/planning/components/CalendarContext.vue'
import TopThreeSection from '@/features/planning/components/TopThreeSection.vue'
import { useTodayStore } from '@/features/planning/todayStore'
import type { PreviewState } from '@/features/planning/types'
import RecentActivity from '@/features/tasks/components/RecentActivity.vue'
import TaskListSection from '@/features/tasks/components/TaskListSection.vue'
import { firstNameFromEmail, greetingFor } from '@/lib/utils/date'

const route = useRoute()
const auth = useAuthStore()
const today = useTodayStore()
const panel = useContextPanelStore()

/** `?preview=loading|error|empty` forces a UI state for design review. */
function previewFromQuery(): PreviewState {
  const value = route.query.preview
  return value === 'loading' || value === 'error' || value === 'empty' ? value : null
}

onMounted(() => today.load(previewFromQuery()))
watch(
  () => route.query.preview,
  () => today.load(previewFromQuery()),
)

const greeting = computed(() => {
  const name = firstNameFromEmail(auth.user?.email ?? '')
  return `${greetingFor(new Date(), auth.user?.timezone)}, ${name}`
})

const isLoading = computed(() => today.status === 'loading' || today.status === 'idle')

function onSelectTask(taskId: string) {
  panel.toggleTask(taskId)
}

function onRetry() {
  today.load(null)
}

/** "Plan My Day" is AI-assisted planning — visual-only this milestone. */
const planNoteVisible = ref(false)
let planNoteTimer: ReturnType<typeof setTimeout> | undefined

function onPlanMyDay() {
  planNoteVisible.value = true
  clearTimeout(planNoteTimer)
  planNoteTimer = setTimeout(() => (planNoteVisible.value = false), 3200)
}
</script>

<template>
  <div class="today-page">
    <!-- Loading -->
    <div v-if="isLoading" class="content" aria-busy="true" aria-label="Loading today">
      <header class="page-header">
        <SkeletonBlock width="300px" height="28px" rounded="md" />
        <SkeletonBlock width="220px" height="14px" class="skeleton-gap" />
      </header>
      <SkeletonBlock height="96px" rounded="lg" />
      <div class="two-col">
        <SkeletonBlock height="220px" rounded="lg" />
        <SkeletonBlock height="220px" rounded="lg" />
      </div>
      <SkeletonBlock height="140px" rounded="lg" />
    </div>

    <!-- Error -->
    <div v-else-if="today.status === 'error'" class="content">
      <ErrorState
        title="Today didn't load"
        description="Your plan for today could not be reached. Your data is safe — try loading it again."
        @retry="onRetry"
      />
    </div>

    <!-- Ready -->
    <template v-else>
      <header class="page-header">
        <div class="heading">
          <h1 class="greeting">{{ greeting }} <span aria-hidden="true">👋</span></h1>
          <p class="subtitle">Here's what matters today.</p>
        </div>
        <div class="header-actions">
          <UiButton variant="outline-ai" @click="onPlanMyDay">
            <Sparkles :size="14" :stroke-width="1.75" />
            Plan My Day
          </UiButton>
          <Transition name="fade">
            <p v-if="planNoteVisible" class="plan-note" role="status">
              AI day planning arrives in a later milestone.
            </p>
          </Transition>
        </div>
      </header>

      <div class="grid">
        <div class="main-col">
          <AiBriefing v-if="today.plan && today.plan.plannedMinutes > 0" :briefing="mockBriefing" />

          <div class="two-col">
            <TopThreeSection
              :entries="today.topThree"
              :active-task-id="panel.activeTaskId"
              @select="onSelectTask"
            />
            <TaskListSection
              title="Planned"
              :tasks="today.plannedTasks"
              :active-task-id="panel.activeTaskId"
              empty-title="Nothing planned"
              empty-description="Plan tasks from your inbox when you're ready."
              @select="onSelectTask"
            />
          </div>

          <TaskListSection
            title="Unplanned"
            :tasks="today.unplannedTasks"
            :active-task-id="panel.activeTaskId"
            empty-title="Inbox is clear"
            empty-description="New captures will land here, waiting to be planned."
            @select="onSelectTask"
          />

          <RecentActivity :tasks="today.recentTasks" @select="onSelectTask" />
        </div>

        <aside class="rail" aria-label="Context">
          <FocusPanel />
          <AiInsights :insights="mockInsights" />
          <CalendarContext />
        </aside>
      </div>
    </template>
  </div>
</template>

<style scoped>
.today-page {
  padding: var(--space-8) var(--space-8) var(--space-12);
}

.content {
  max-width: var(--content-max);
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.skeleton-gap {
  margin-top: var(--space-2);
}

.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-6);
  max-width: var(--content-max);
  margin: 0 auto var(--space-6);
}

.greeting {
  font-size: var(--text-3xl);
  font-weight: 650;
  letter-spacing: -0.025em;
}

.subtitle {
  margin-top: var(--space-1);
  font-size: var(--text-md);
  color: var(--text-tertiary);
}

.header-actions {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: var(--space-2);
  flex-shrink: 0;
}

.plan-note {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 320px;
  gap: var(--space-6);
  max-width: var(--content-max);
  margin: 0 auto;
  align-items: start;
}

.main-col {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
  min-width: 0;
}

.two-col {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: var(--space-6);
  /* Stretch so Today's Top 3 and Planned share a bottom edge. */
  align-items: stretch;
}

.rail {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
  position: sticky;
  top: var(--space-6);
}

/* The rail folds under the main column as width shrinks — the workspace
   keeps priority. */
@media (max-width: 1280px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }

  .rail {
    position: static;
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    align-items: start;
  }
}

@media (max-width: 900px) {
  .two-col {
    grid-template-columns: minmax(0, 1fr);
  }

  .page-header {
    flex-direction: column;
  }

  .header-actions {
    align-items: flex-start;
  }
}
</style>
