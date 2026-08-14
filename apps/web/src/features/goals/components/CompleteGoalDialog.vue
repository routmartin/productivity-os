<script setup lang="ts">
import { computed } from 'vue'
import { CheckCircle2 } from 'lucide-vue-next'

import UiButton from '@/components/ui/UiButton.vue'
import UiDialog from '@/components/ui/UiDialog.vue'

import { useGoalsStore, USE_MOCK } from '../store'
import type { Goal } from '../types'

const props = defineProps<{
  open: boolean
  goal: Goal
}>()

const emit = defineEmits<{ close: [] }>()

const goals = useGoalsStore()

/** Active projects that completing this goal would archive (domain rule:
 * completing a goal archives its projects). Shown so the consequence is
 * explicit before confirming. */
const activeProjects = computed(() =>
  goals
    .projectsForGoal(props.goal.id)
    .filter((p) => p.status === 'ACTIVE' || p.status === 'DRAFT'),
)

function onConfirm() {
  emit('close')
  goals.completeGoal(props.goal.id)
}
</script>

<template>
  <UiDialog :open="open" title="Complete this goal?" @close="emit('close')">
    <div class="body">
      <p class="lead">
        <strong>{{ goal.title }}</strong>
      </p>

      <template v-if="activeProjects.length > 0">
        <p class="explain">Completing this goal will archive its active projects:</p>
        <ul class="project-list">
          <li v-for="project in activeProjects" :key="project.id" class="project-item">
            <span class="dot" :style="{ background: project.color }" />
            {{ project.name }}
          </li>
        </ul>
        <p class="explain muted">They stay readable in the Completed and Archived views.</p>
      </template>

      <p v-else class="explain">
        This goal has no active projects — it will be completed directly.
      </p>
    </div>

    <template #footer>
      <span v-if="USE_MOCK" class="note">Preview only — nothing changes</span>
      <div class="footer-actions">
        <UiButton variant="ghost" type="button" @click="emit('close')">Cancel</UiButton>
        <UiButton variant="primary" type="button" @click="onConfirm">
          <CheckCircle2 :size="15" :stroke-width="1.75" />
          Complete goal
        </UiButton>
      </div>
    </template>
  </UiDialog>
</template>

<style scoped>
.body {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.lead {
  font-size: var(--text-lg);
  letter-spacing: -0.01em;
}

.explain {
  font-size: var(--text-sm);
  line-height: 1.5;
  color: var(--text-secondary);
}

.explain.muted {
  color: var(--text-tertiary);
}

.project-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.project-item {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--text-primary);
  padding: var(--space-1) 0;
}

.dot {
  width: 7px;
  height: 7px;
  border-radius: var(--radius-full);
}

.note {
  font-size: var(--text-xs);
  color: var(--text-disabled);
}

.footer-actions {
  display: flex;
  gap: var(--space-2);
}
</style>
