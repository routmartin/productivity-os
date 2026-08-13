<script setup lang="ts">
import { computed, ref } from 'vue'
import { Archive, CalendarDays, CheckSquare, RotateCcw, SearchX } from 'lucide-vue-next'

import { useContextPanelStore } from '@/app/layouts/contextPanelStore'
import EmptyState from '@/components/shared/EmptyState.vue'
import SegmentedProgress from '@/components/shared/SegmentedProgress.vue'
import UiButton from '@/components/ui/UiButton.vue'
import UiPill from '@/components/ui/UiPill.vue'
import { useProjectsStore } from '@/features/projects/store'
import { formatLongDate, relativeTime } from '@/lib/utils/date'
import { showPreviewNote } from '@/lib/preview'

import { useGoalsStore } from '../store'
import { GOAL_STATUS_LABELS } from '../types'
import CompleteGoalDialog from './CompleteGoalDialog.vue'
import ReopenGoalDialog from './ReopenGoalDialog.vue'

const props = defineProps<{ goalId: string }>()

const goals = useGoalsStore()
const projectsStore = useProjectsStore()
const panel = useContextPanelStore()

const goal = computed(() => goals.goalById(props.goalId))
const projects = computed(() => goals.projectsForGoal(props.goalId))
const progress = computed(() => goals.progressForGoal(props.goalId))
const activity = computed(() => goals.recentActivityForGoal(props.goalId))

const completeOpen = ref(false)
const reopenOpen = ref(false)

type PillTone = 'neutral' | 'accent' | 'success'

const statusTone = computed<PillTone>(() => {
  switch (goal.value?.status) {
    case 'ACTIVE':
      return 'accent'
    case 'COMPLETED':
      return 'success'
    default:
      return 'neutral'
  }
})

const deadlineLabel = computed(() => {
  const deadline = goal.value?.deadline
  if (!deadline) return null
  return formatLongDate(new Date(`${deadline}T00:00:00`))
})

function progressOf(projectId: string): number {
  return projectsStore.statsForProject(projectId).progress
}

function onSimpleAction(label: string) {
  showPreviewNote(`“${label}” will call the Goal API in a later milestone — visual only for now.`)
}
</script>

<template>
  <div v-if="goal" class="goal-detail">
    <div class="pills">
      <UiPill :tone="statusTone">{{ GOAL_STATUS_LABELS[goal.status] }}</UiPill>
      <UiPill v-if="deadlineLabel" tone="neutral">
        <CalendarDays :size="11" :stroke-width="2" />
        Target {{ deadlineLabel }}
      </UiPill>
    </div>

    <h2 class="title">{{ goal.title }}</h2>

    <p v-if="goal.description" class="description">{{ goal.description }}</p>
    <p v-else class="description muted">No description yet.</p>

    <div v-if="progress !== null" class="progress-block">
      <div class="progress-meta">
        <span class="progress-label">Progress</span>
        <span class="pct tnum">{{ progress }}%</span>
      </div>
      <SegmentedProgress :value="progress" :label="`${goal.title} progress`" />
    </div>

    <section class="section">
      <h3 class="section-label">Projects</h3>
      <div v-if="projects.length > 0" class="project-list">
        <button
          v-for="project in projects"
          :key="project.id"
          class="project-row"
          type="button"
          @click="panel.openProject(project.id)"
        >
          <span class="dot" :style="{ background: project.color }" />
          <span class="project-name">{{ project.name }}</span>
          <span class="mini-progress">
            <span class="mini-fill" :style="{ width: `${progressOf(project.id)}%` }" />
          </span>
          <span class="project-pct tnum">{{ progressOf(project.id) }}%</span>
        </button>
      </div>
      <p v-else class="projectless">
        No projects connected yet.
        <span class="projectless-sub">You can still work toward this goal directly.</span>
      </p>
    </section>

    <section v-if="activity.length > 0" class="section">
      <h3 class="section-label">Recent progress</h3>
      <ul class="activity-list">
        <li v-for="task in activity" :key="task.id">
          <button class="activity-item" type="button" @click="panel.openTask(task.id)">
            <CheckSquare :size="13" :stroke-width="1.75" class="check" />
            <span class="activity-title">{{ task.title }}</span>
            <span class="when tnum">{{ relativeTime(task.completedAt ?? task.updatedAt) }}</span>
          </button>
        </li>
      </ul>
    </section>

    <div class="actions">
      <UiButton
        v-if="goal.status === 'ACTIVE' || goal.status === 'DRAFT'"
        variant="primary"
        full-width
        @click="completeOpen = true"
      >
        Complete goal
      </UiButton>
      <UiButton
        v-if="goal.status === 'DRAFT'"
        variant="ghost"
        full-width
        @click="onSimpleAction('Activate goal')"
      >
        Activate goal
      </UiButton>
      <UiButton
        v-if="goal.status === 'COMPLETED'"
        variant="primary"
        full-width
        @click="reopenOpen = true"
      >
        <RotateCcw :size="15" :stroke-width="1.75" />
        Reopen goal
      </UiButton>
      <UiButton
        v-if="goal.status === 'ACTIVE' || goal.status === 'DRAFT'"
        variant="ghost"
        full-width
        @click="onSimpleAction('Archive goal')"
      >
        <Archive :size="15" :stroke-width="1.75" />
        Archive goal
      </UiButton>
    </div>

    <footer class="footer tnum">
      <span>Created {{ relativeTime(goal.createdAt) }}</span>
      <span v-if="goal.completedAt">Completed {{ relativeTime(goal.completedAt) }}</span>
    </footer>

    <CompleteGoalDialog :open="completeOpen" :goal="goal" @close="completeOpen = false" />
    <ReopenGoalDialog :open="reopenOpen" :goal="goal" @close="reopenOpen = false" />
  </div>

  <EmptyState
    v-else
    :icon="SearchX"
    title="Goal unavailable"
    description="This goal could not be found. It may have been deleted."
    compact
  />
</template>

<style scoped>
.goal-detail {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.pills {
  display: flex;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.title {
  font-size: var(--text-xl);
  letter-spacing: -0.02em;
}

.description {
  font-size: var(--text-md);
  color: var(--text-secondary);
  line-height: 1.6;
}

.description.muted {
  color: var(--text-tertiary);
  font-style: italic;
}

.progress-block {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-4);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  background: var(--surface-2);
}

.progress-meta {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
}

.progress-label {
  font-size: var(--text-xs);
  font-weight: 600;
  letter-spacing: 0.09em;
  text-transform: uppercase;
  color: var(--text-tertiary);
}

.pct {
  font-size: var(--text-sm);
  font-weight: 600;
}

.section-label {
  font-size: var(--text-xs);
  font-weight: 600;
  letter-spacing: 0.09em;
  text-transform: uppercase;
  color: var(--text-tertiary);
  margin-bottom: var(--space-2);
}

.project-list {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.project-row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-2);
  border-radius: var(--radius-md);
  text-align: left;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.project-row:hover {
  background: var(--surface-2);
}

.dot {
  width: 7px;
  height: 7px;
  border-radius: var(--radius-full);
  flex-shrink: 0;
}

.project-name {
  flex: 1;
  min-width: 0;
  font-size: var(--text-sm);
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.mini-progress {
  width: 56px;
  height: 3px;
  border-radius: var(--radius-full);
  background: var(--surface-3);
  overflow: hidden;
  flex-shrink: 0;
}

.mini-fill {
  display: block;
  height: 100%;
  border-radius: inherit;
  background: var(--accent);
}

.project-pct {
  width: 32px;
  text-align: right;
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  flex-shrink: 0;
}

.projectless {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.projectless-sub {
  display: block;
  font-size: var(--text-xs);
  color: var(--text-disabled);
  margin-top: 2px;
}

.activity-list {
  display: flex;
  flex-direction: column;
}

.activity-item {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  width: 100%;
  padding: var(--space-2);
  border-radius: var(--radius-md);
  text-align: left;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.activity-item:hover {
  background: var(--surface-2);
}

.check {
  color: var(--success);
  flex-shrink: 0;
}

.activity-title {
  flex: 1;
  min-width: 0;
  font-size: var(--text-sm);
  color: var(--text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.when {
  font-size: var(--text-xs);
  color: var(--text-disabled);
  flex-shrink: 0;
}

.actions {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.footer {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
  padding-top: var(--space-4);
  border-top: 1px solid var(--border-subtle);
  font-size: var(--text-xs);
  color: var(--text-disabled);
}
</style>
