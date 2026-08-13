<script setup lang="ts">
import { computed } from 'vue'
import { Archive, CheckCircle2, CheckSquare, SearchX, Target } from 'lucide-vue-next'

import EmptyState from '@/components/shared/EmptyState.vue'
import SegmentedProgress from '@/components/shared/SegmentedProgress.vue'
import UiButton from '@/components/ui/UiButton.vue'
import UiPill from '@/components/ui/UiPill.vue'
import { useContextPanelStore } from '@/app/layouts/contextPanelStore'
import TaskRow from '@/features/tasks/components/TaskRow.vue'
import { findGoalById } from '@/features/tasks/mock'
import { relativeTime } from '@/lib/utils/date'
import { showPreviewNote } from '@/lib/preview'

import { useProjectsStore } from '../store'
import { PROJECT_STATUS_LABELS } from '../types'

const props = defineProps<{ projectId: string }>()

const projects = useProjectsStore()
const panel = useContextPanelStore()

const project = computed(() => projects.projectById(props.projectId))
const goal = computed(() => findGoalById(project.value?.goalId ?? null))
const stats = computed(() => projects.statsForProject(props.projectId))
const taskLists = computed(() => projects.tasksForProject(props.projectId))

type PillTone = 'neutral' | 'accent' | 'success'

const statusTone = computed<PillTone>(() => {
  switch (project.value?.status) {
    case 'ACTIVE':
      return 'accent'
    case 'COMPLETED':
      return 'success'
    default:
      return 'neutral'
  }
})

function onAction(label: string) {
  showPreviewNote(`“${label}” will call the Project API in a later milestone — visual only for now.`)
}
</script>

<template>
  <div v-if="project" class="project-detail">
    <div class="pills">
      <UiPill :tone="statusTone">
        <span class="status-dot" :style="{ background: project.color }" />
        {{ PROJECT_STATUS_LABELS[project.status] }}
      </UiPill>
    </div>

    <h2 class="title">
      <span class="dot" :style="{ background: project.color }" />
      {{ project.name }}
    </h2>

    <p v-if="project.description" class="description">{{ project.description }}</p>
    <p v-else class="description muted">No description yet.</p>

    <div class="goal-row">
      <Target :size="14" :stroke-width="1.75" />
      <span v-if="goal">{{ goal.title }}</span>
      <span v-else class="muted">No goal — standalone project</span>
    </div>

    <div class="progress-block">
      <div class="progress-meta">
        <span class="progress-label">Progress</span>
        <span class="pct tnum">{{ stats.progress }}%</span>
      </div>
      <SegmentedProgress
        :value="stats.progress"
        :color="project.color"
        :label="`${project.name} progress`"
      />
      <p class="counts tnum">
        {{ stats.total }} tasks · {{ stats.completed }} completed · {{ stats.remaining }} remaining
      </p>
    </div>

    <section class="task-section">
      <h3 class="section-label">Active tasks</h3>
      <div v-if="taskLists.active.length > 0" class="task-list">
        <TaskRow
          v-for="task in taskLists.active"
          :key="task.id"
          :task="task"
          @select="panel.openTask($event)"
        />
      </div>
      <p v-else class="empty-line">No active tasks in this project.</p>
    </section>

    <section v-if="taskLists.completed.length > 0" class="task-section">
      <h3 class="section-label">Recently completed</h3>
      <ul class="completed-list">
        <li v-for="task in taskLists.completed" :key="task.id">
          <button class="completed-item" type="button" @click="panel.openTask(task.id)">
            <CheckSquare :size="13" :stroke-width="1.75" class="check" />
            <span class="completed-title">{{ task.title }}</span>
            <span class="when tnum">{{ relativeTime(task.completedAt ?? task.updatedAt) }}</span>
          </button>
        </li>
      </ul>
    </section>

    <div class="actions">
      <UiButton
        v-if="project.status === 'ACTIVE'"
        variant="ghost"
        full-width
        @click="onAction('Complete project')"
      >
        <CheckCircle2 :size="15" :stroke-width="1.75" />
        Complete project
      </UiButton>
      <UiButton
        v-if="project.status === 'ACTIVE'"
        variant="ghost"
        full-width
        @click="onAction('Archive project')"
      >
        <Archive :size="15" :stroke-width="1.75" />
        Archive project
      </UiButton>
      <UiButton v-else variant="ghost" full-width @click="onAction('Restore project')">
        <Archive :size="15" :stroke-width="1.75" />
        Restore project
      </UiButton>
    </div>

    <footer class="footer tnum">
      <span>Created {{ relativeTime(project.createdAt) }}</span>
      <span v-if="project.completedAt">Completed {{ relativeTime(project.completedAt) }}</span>
    </footer>
  </div>

  <EmptyState
    v-else
    :icon="SearchX"
    title="Project unavailable"
    description="This project could not be found. It may have been deleted."
    compact
  />
</template>

<style scoped>
.project-detail {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.pills {
  display: flex;
  gap: var(--space-2);
}

.status-dot {
  width: 6px;
  height: 6px;
  border-radius: var(--radius-full);
}

.title {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  font-size: var(--text-xl);
  letter-spacing: -0.02em;
}

.dot {
  width: 10px;
  height: 10px;
  border-radius: var(--radius-full);
  flex-shrink: 0;
}

.description {
  font-size: var(--text-md);
  color: var(--text-secondary);
  line-height: 1.6;
}

.muted {
  color: var(--text-tertiary);
}

.description.muted {
  font-style: italic;
}

.goal-row {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--text-secondary);
}

.goal-row svg {
  color: var(--text-tertiary);
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
  color: var(--text-primary);
}

.counts {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.task-section {
  min-width: 0;
}

.section-label {
  font-size: var(--text-xs);
  font-weight: 600;
  letter-spacing: 0.09em;
  text-transform: uppercase;
  color: var(--text-tertiary);
  margin-bottom: var(--space-2);
}

.task-list {
  display: flex;
  flex-direction: column;
}

.empty-line {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  padding: var(--space-2) 0;
}

.completed-list {
  display: flex;
  flex-direction: column;
}

.completed-item {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  width: 100%;
  padding: var(--space-2);
  border-radius: var(--radius-md);
  text-align: left;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.completed-item:hover {
  background: var(--surface-2);
}

.check {
  color: var(--success);
  flex-shrink: 0;
}

.completed-title {
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
