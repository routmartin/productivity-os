<script setup lang="ts">
import { computed } from 'vue'
import { Target } from 'lucide-vue-next'

import UiPill from '@/components/ui/UiPill.vue'
import { findGoalById } from '@/features/tasks/mock'

import type { ProjectTaskStats } from '../store'
import type { Project } from '../types'

const props = defineProps<{
  project: Project
  stats: ProjectTaskStats
  active?: boolean
}>()

const emit = defineEmits<{ select: [projectId: string] }>()

const goal = computed(() => findGoalById(props.project.goalId))

const isQuiet = computed(
  () => props.project.status === 'COMPLETED' || props.project.status === 'ARCHIVED',
)

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    emit('select', props.project.id)
  }
}
</script>

<template>
  <article
    class="project-card"
    :class="{ active, quiet: isQuiet }"
    role="button"
    tabindex="0"
    :aria-pressed="active || undefined"
    @click="emit('select', project.id)"
    @keydown="onKeydown"
  >
    <header class="top">
      <span class="name-row">
        <span class="dot" :style="{ background: project.color }" />
        <h3 class="name">{{ project.name }}</h3>
      </span>
      <UiPill v-if="project.status === 'COMPLETED'" tone="success">Completed</UiPill>
      <UiPill v-else-if="project.status === 'ARCHIVED'" tone="neutral">Archived</UiPill>
    </header>

    <p v-if="project.description" class="description">{{ project.description }}</p>

    <p class="goal">
      <Target :size="13" :stroke-width="1.75" />
      <span v-if="goal">{{ goal.title }}</span>
      <span v-else class="no-goal">No goal</span>
    </p>

    <div class="progress-row">
      <div
        class="progress"
        role="progressbar"
        :aria-valuenow="stats.progress"
        aria-valuemin="0"
        aria-valuemax="100"
        :aria-label="`${project.name} progress`"
      >
        <div
          class="progress-fill"
          :style="{ width: `${stats.progress}%`, background: project.color }"
        />
      </div>
      <span class="pct tnum">{{ stats.progress }}%</span>
    </div>

    <p class="counts tnum">
      {{ stats.total }} tasks · {{ stats.completed }} completed · {{ stats.remaining }} remaining
    </p>
  </article>
</template>

<style scoped>
.project-card {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  padding: var(--space-5);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  cursor: pointer;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.project-card:hover {
  border-color: var(--border-strong);
  background: var(--surface-2);
}

.project-card.active {
  border-color: var(--accent-border);
}

/* Completed and archived projects stay quieter (spec §14–15). */
.project-card.quiet {
  opacity: 0.72;
}

.project-card.quiet:hover {
  opacity: 1;
}

.top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-3);
}

.name-row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  min-width: 0;
}

.dot {
  width: 9px;
  height: 9px;
  border-radius: var(--radius-full);
  flex-shrink: 0;
}

.name {
  font-size: var(--text-lg);
  font-weight: 600;
  letter-spacing: -0.015em;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.description {
  font-size: var(--text-sm);
  line-height: 1.5;
  color: var(--text-secondary);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: 2.6em;
}

.goal {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.goal svg {
  flex-shrink: 0;
  color: var(--text-disabled);
}

.no-goal {
  color: var(--text-disabled);
}

.progress-row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-top: var(--space-1);
}

.progress {
  flex: 1;
  height: 4px;
  border-radius: var(--radius-full);
  background: var(--surface-3);
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  border-radius: inherit;
  transition: width var(--duration-normal) var(--ease-out);
}

.pct {
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--text-secondary);
  flex-shrink: 0;
}

.counts {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}
</style>
