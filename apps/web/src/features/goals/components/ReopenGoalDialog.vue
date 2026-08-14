<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Check, RotateCcw } from 'lucide-vue-next'

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

/** Projects archived when this goal was completed — the user chooses which
 * to reactivate (Goals UI spec §16). */
const archivedProjects = computed(() => goals.archivedProjectsForGoal(props.goal.id))

const selected = ref<Set<string>>(new Set())

watch(
  () => props.open,
  (isOpen) => {
    if (isOpen) {
      // Start with everything selected — the choice is visible and
      // entirely the user's to change.
      selected.value = new Set(archivedProjects.value.map((p) => p.id))
    }
  },
)

function toggle(projectId: string) {
  const next = new Set(selected.value)
  if (next.has(projectId)) {
    next.delete(projectId)
  } else {
    next.add(projectId)
  }
  selected.value = next
}

function onConfirm() {
  emit('close')
  goals.reopenGoal(props.goal.id, [...selected.value])
}
</script>

<template>
  <UiDialog :open="open" title="Reopen this goal?" @close="emit('close')">
    <div class="body">
      <p class="lead">
        <strong>{{ goal.title }}</strong>
      </p>

      <template v-if="archivedProjects.length > 0">
        <p class="explain">These projects were archived when the goal was completed.</p>
        <p class="explain muted">Choose which ones to reactivate:</p>

        <ul class="project-list" role="group" aria-label="Projects to reactivate">
          <li v-for="project in archivedProjects" :key="project.id">
            <button
              class="project-item"
              type="button"
              role="checkbox"
              :aria-checked="selected.has(project.id)"
              @click="toggle(project.id)"
            >
              <span class="checkbox" :class="{ checked: selected.has(project.id) }">
                <Check v-if="selected.has(project.id)" :size="11" :stroke-width="3" />
              </span>
              <span class="dot" :style="{ background: project.color }" />
              <span class="project-name">{{ project.name }}</span>
            </button>
          </li>
        </ul>
      </template>

      <p v-else class="explain">This goal has no archived projects — it will simply reopen.</p>
    </div>

    <template #footer>
      <span v-if="USE_MOCK" class="note">Preview only — nothing changes</span>
      <div class="footer-actions">
        <UiButton variant="ghost" type="button" @click="emit('close')">Cancel</UiButton>
        <UiButton variant="primary" type="button" @click="onConfirm">
          <RotateCcw :size="15" :stroke-width="1.75" />
          Reopen goal
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
  gap: var(--space-3);
  width: 100%;
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-md);
  border: 1px solid var(--border-subtle);
  background: var(--surface-2);
  text-align: left;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.project-item:hover {
  border-color: var(--border-strong);
}

.checkbox {
  display: grid;
  place-items: center;
  width: 16px;
  height: 16px;
  border-radius: var(--radius-sm);
  border: 1.5px solid var(--text-disabled);
  color: #fff;
  flex-shrink: 0;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    border-color var(--duration-fast) var(--ease-out);
}

.checkbox.checked {
  background: var(--accent);
  border-color: var(--accent);
}

.dot {
  width: 7px;
  height: 7px;
  border-radius: var(--radius-full);
  flex-shrink: 0;
}

.project-name {
  font-size: var(--text-sm);
  color: var(--text-primary);
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
