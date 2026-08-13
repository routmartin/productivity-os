<script setup lang="ts">
import { computed } from 'vue'
import { CheckCircle2 } from 'lucide-vue-next'

import SegmentedProgress from '@/components/shared/SegmentedProgress.vue'
import UiPill from '@/components/ui/UiPill.vue'
import { useProjectsStore } from '@/features/projects/store'
import type { Project } from '@/features/projects/types'

import type { Goal } from '../types'

const props = defineProps<{
  goal: Goal
  projects: Project[]
  /** Mean of countable project progress; null when projectless. */
  progress: number | null
  projectCounts: { active: number; completed: number }
  active?: boolean
}>()

const emit = defineEmits<{ select: [goalId: string] }>()

const projectsStore = useProjectsStore()

const isQuiet = computed(
  () => props.goal.status === 'COMPLETED' || props.goal.status === 'ARCHIVED',
)

function progressOf(projectId: string): number {
  return projectsStore.statsForProject(projectId).progress
}

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    emit('select', props.goal.id)
  }
}
</script>

<template>
  <article
    class="goal-card"
    :class="{ active, quiet: isQuiet }"
    role="button"
    tabindex="0"
    :aria-pressed="active || undefined"
    @click="emit('select', goal.id)"
    @keydown="onKeydown"
  >
    <div class="main">
      <header class="top">
        <h3 class="title">
          <CheckCircle2 v-if="goal.status === 'COMPLETED'" :size="16" :stroke-width="2" class="done-icon" />
          {{ goal.title }}
        </h3>
        <UiPill v-if="goal.status === 'DRAFT'" tone="neutral">Draft</UiPill>
        <UiPill v-else-if="goal.status === 'COMPLETED'" tone="success">Completed</UiPill>
        <UiPill v-else-if="goal.status === 'ARCHIVED'" tone="neutral">Archived</UiPill>
      </header>

      <p v-if="goal.description" class="description">{{ goal.description }}</p>

      <div v-if="projects.length > 0" class="projects">
        <span v-for="project in projects" :key="project.id" class="project-chip">
          <span class="chip-dot" :style="{ background: project.color }" />
          {{ project.name }}
          <span class="chip-pct tnum">{{ progressOf(project.id) }}%</span>
        </span>
      </div>
      <p v-else class="projectless">
        No projects connected yet.
        <span class="projectless-sub">You can still work toward this goal directly.</span>
      </p>
    </div>

    <div class="side">
      <template v-if="progress !== null">
        <span class="pct tnum">{{ progress }}%</span>
        <SegmentedProgress :value="progress" :label="`${goal.title} progress`" />
        <span class="counts tnum">
          {{ projectCounts.active }} active · {{ projectCounts.completed }} completed
        </span>
      </template>
      <template v-else>
        <span class="no-progress">Direct goal</span>
      </template>
    </div>
  </article>
</template>

<style scoped>
.goal-card {
  display: flex;
  gap: var(--space-8);
  padding: var(--space-6) var(--space-7);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  cursor: pointer;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.goal-card:hover {
  border-color: var(--border-strong);
  background: var(--surface-2);
}

.goal-card.active {
  border-color: var(--accent-border);
}

.goal-card.quiet {
  opacity: 0.72;
}

.goal-card.quiet:hover {
  opacity: 1;
}

.main {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
}

.title {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-2xl);
  font-weight: 650;
  letter-spacing: -0.02em;
}

.done-icon {
  color: var(--success);
  flex-shrink: 0;
}

.description {
  font-size: var(--text-md);
  line-height: 1.55;
  color: var(--text-secondary);
}

.projects {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  margin-top: var(--space-1);
}

.project-chip {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  height: 30px;
  padding: 0 var(--space-3);
  border-radius: var(--radius-full);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  font-size: var(--text-sm);
  color: var(--text-secondary);
}

.chip-dot {
  width: 7px;
  height: 7px;
  border-radius: var(--radius-full);
}

.chip-pct {
  color: var(--text-tertiary);
  font-weight: 600;
}

.projectless {
  margin-top: var(--space-1);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.projectless-sub {
  color: var(--text-disabled);
}

.side {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  justify-content: center;
  gap: var(--space-2);
  width: 170px;
  flex-shrink: 0;
}

.pct {
  font-size: var(--text-2xl);
  font-weight: 650;
  letter-spacing: -0.02em;
  color: var(--text-primary);
}

.counts {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  white-space: nowrap;
}

.no-progress {
  font-size: var(--text-sm);
  color: var(--text-disabled);
}

@media (max-width: 720px) {
  .goal-card {
    flex-direction: column;
    gap: var(--space-4);
  }

  .side {
    width: 100%;
    align-items: flex-start;
  }
}
</style>
