<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Plus, Target } from 'lucide-vue-next'

import { useContextPanelStore } from '@/app/layouts/contextPanelStore'
import EmptyState from '@/components/shared/EmptyState.vue'
import ErrorState from '@/components/shared/ErrorState.vue'
import FilterChips from '@/components/shared/FilterChips.vue'
import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import UiButton from '@/components/ui/UiButton.vue'
import GoalCard from '@/features/goals/components/GoalCard.vue'
import NewGoalDialog from '@/features/goals/components/NewGoalDialog.vue'
import {
  GOAL_FILTER_LABELS,
  useGoalsStore,
  type GoalFilter,
} from '@/features/goals/store'
import type { NewGoalDraft } from '@/features/goals/types'
import type { PreviewState } from '@/features/planning/types'
import { showPreviewNote } from '@/lib/preview'

const route = useRoute()
const store = useGoalsStore()
const panel = useContextPanelStore()

/** `?preview=loading|error|empty` forces a UI state for design review. */
function previewFromQuery(): PreviewState {
  const value = route.query.preview
  return value === 'loading' || value === 'error' || value === 'empty' ? value : null
}

/** `?open=<id>` lands here from global search (spec: global-search AC-010). */
const openGoalId = computed(() => {
  const value = route.query.open
  return typeof value === 'string' && value ? value : null
})

/** Lands the workspace with the first goal's detail open. While loading, a
 *  skeleton reserves the panel so the workspace doesn't reflow on ready. */
async function loadAndSelect(preview: PreviewState) {
  if (!panel.isOpen) panel.openSkeleton()
  await store.load(preview)

  // A search result wins over the default first item.
  if (openGoalId.value && store.goalById(openGoalId.value)) {
    panel.openGoal(openGoalId.value)
    return
  }

  if (preview === 'loading' || !panel.isSkeleton) return
  if (store.status === 'ready' && store.visibleGoals.length > 0) {
    panel.openGoal(store.visibleGoals[0].id)
  } else {
    panel.close()
  }
}

onMounted(() => loadAndSelect(previewFromQuery()))
watch(
  () => route.query.preview,
  () => loadAndSelect(previewFromQuery()),
)

// A search result picked while already on this page opens the panel live.
watch(
  () => route.query.open,
  (value) => {
    const id = typeof value === 'string' && value ? value : null
    if (id && store.status === 'ready' && store.goalById(id)) panel.openGoal(id)
  },
)

const dialogOpen = ref(false)

const isLoading = computed(() => store.status === 'loading' || store.status === 'idle')

const filterOptions = computed(() =>
  (Object.keys(GOAL_FILTER_LABELS) as GoalFilter[]).map((key) => ({
    key,
    label: GOAL_FILTER_LABELS[key],
    count: store.filterCounts[key],
  })),
)

const emptyCopy = computed(() => {
  switch (store.statusFilter) {
    case 'ACTIVE':
      return {
        title: "You're clear.",
        description: 'There are no active goals right now.',
      }
    case 'COMPLETED':
      return {
        title: 'No completed goals yet.',
        description: 'Achieved goals land here — quiet proof of progress.',
      }
    case 'ARCHIVED':
      return {
        title: 'No archived goals.',
        description: 'Archived goals are kept out of the way here.',
      }
    default:
      return {
        title: 'No goals yet.',
        description: 'Decide what you want to achieve.',
      }
  }
})

function onSelectGoal(goalId: string) {
  panel.toggleGoal(goalId)
}

function onCreateGoal(draft: NewGoalDraft) {
  store.addGoal(draft)
  showPreviewNote('Goal created locally — it will sync once the Goal API is connected.')
}

function onRetry() {
  store.load(null)
}
</script>

<template>
  <div class="goals-page">
    <header class="page-header">
      <div class="heading">
        <h1 class="title">Goals</h1>
        <p class="subtitle">What you're working toward.</p>
      </div>
      <UiButton variant="primary" @click="dialogOpen = true">
        <Plus :size="15" :stroke-width="2" />
        New Goal
      </UiButton>
    </header>

    <FilterChips
      :options="filterOptions"
      :active="store.statusFilter"
      label="Filter goals by status"
      @change="store.setFilter($event)"
    />

    <!-- Loading — mirrors the header, filter chips, and goal list -->
    <div v-if="isLoading" class="skeleton-page" aria-busy="true" aria-label="Loading goals">
      <div class="skeleton-header">
        <div class="skeleton-heading">
          <SkeletonBlock height="30px" width="160px" rounded="md" />
          <SkeletonBlock height="18px" width="260px" rounded="md" />
        </div>
        <SkeletonBlock height="44px" width="140px" rounded="md" />
      </div>
      <SkeletonBlock height="38px" width="360px" rounded="full" />
      <div class="list">
        <SkeletonBlock v-for="i in 3" :key="i" height="148px" rounded="lg" />
      </div>
    </div>

    <!-- Error -->
    <ErrorState
      v-else-if="store.status === 'error'"
      title="Goals didn't load"
      description="Your goals could not be reached. Your data is safe — try loading them again."
      @retry="onRetry"
    />

    <!-- Empty -->
    <EmptyState
      v-else-if="store.visibleGoals.length === 0"
      :icon="Target"
      :title="emptyCopy.title"
      :description="emptyCopy.description"
    >
      <UiButton
        v-if="store.statusFilter === 'ACTIVE'"
        variant="primary"
        size="sm"
        class="empty-action"
        @click="dialogOpen = true"
      >
        <Plus :size="14" :stroke-width="2" />
        New Goal
      </UiButton>
    </EmptyState>

    <!-- List -->
    <div v-else class="list">
      <GoalCard
        v-for="goal in store.visibleGoals"
        :key="goal.id"
        :goal="goal"
        :projects="store.projectsForGoal(goal.id)"
        :progress="store.progressForGoal(goal.id)"
        :project-counts="store.projectCountsForGoal(goal.id)"
        :active="goal.id === panel.activeGoalId"
        @select="onSelectGoal"
      />
    </div>

    <NewGoalDialog :open="dialogOpen" @close="dialogOpen = false" @create="onCreateGoal" />
  </div>
</template>

<style scoped>
.goals-page {
  max-width: 980px;
  margin: 0 auto;
  padding: var(--space-8) var(--space-10) var(--space-16);
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.page-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-6);
  margin-bottom: var(--space-1);
}

.title {
  font-size: var(--text-3xl);
  font-weight: 700;
  letter-spacing: -0.025em;
}

.subtitle {
  margin-top: var(--space-2);
  font-size: var(--text-lg);
  color: var(--text-tertiary);
}

.list {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.empty-action {
  margin-top: var(--space-4);
}

.skeleton-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.skeleton-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-6);
}

.skeleton-heading {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}
</style>
