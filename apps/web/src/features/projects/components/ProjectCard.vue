<script setup lang="ts">
import { computed } from 'vue'
import { Target } from 'lucide-vue-next'

import SegmentedProgress from '@/components/shared/SegmentedProgress.vue'
import UiPill from '@/components/ui/UiPill.vue'
import { useGoalsStore } from '@/features/goals/store'

import type { ProjectTaskStats } from '../store'
import type { Project } from '../types'

const props = defineProps<{
  project: Project
  stats: ProjectTaskStats
  active?: boolean
}>()

const emit = defineEmits<{ select: [projectId: string] }>()

const goalsStore = useGoalsStore()

const goal = computed(() =>
  props.project.goalId ? goalsStore.goalById(props.project.goalId) : undefined,
)

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
      <SegmentedProgress
        :value="stats.progress"
        :color="project.color"
        :label="`${project.name} progress`"
      />
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
  gap: var(--space-4);
  padding: var(--space-6);
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
  width: 10px;
  height: 10px;
  border-radius: var(--radius-full);
  flex-shrink: 0;
}

.name {
  font-size: var(--text-xl);
  font-weight: 600;
  letter-spacing: -0.015em;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.description {
  font-size: var(--text-md);
  line-height: 1.55;
  color: var(--text-secondary);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: 3.1em;
}

.goal {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
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

.progress-row :first-child {
  flex: 1;
}

.pct {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--text-secondary);
  flex-shrink: 0;
}

.counts {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}
</style>
