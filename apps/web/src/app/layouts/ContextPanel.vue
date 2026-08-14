<script setup lang="ts">
import { computed, onBeforeUnmount, watch } from 'vue'
import { useRoute } from 'vue-router'
import { X } from 'lucide-vue-next'

import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import GoalDetailPanel from '@/features/goals/components/GoalDetailPanel.vue'
import ProjectDetailPanel from '@/features/projects/components/ProjectDetailPanel.vue'
import TaskDetailPanel from '@/features/tasks/components/TaskDetailPanel.vue'

import { useContextPanelStore } from './contextPanelStore'

const panel = useContextPanelStore()
const route = useRoute()

const panelTitle = computed(() => {
  if (panel.content?.kind === 'project') return 'Project'
  if (panel.content?.kind === 'goal') return 'Goal'
  if (panel.content?.kind === 'skeleton') return 'Details'
  return 'Task'
})

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape' && panel.isOpen) {
    panel.close()
  }
}

watch(
  () => panel.isOpen,
  (open) => {
    if (open) {
      window.addEventListener('keydown', onKeydown)
    } else {
      window.removeEventListener('keydown', onKeydown)
    }
  },
)

// Navigating to another section closes the panel — its content is
// contextual to the workspace it was opened from.
watch(
  () => route.name,
  () => panel.close(),
)

onBeforeUnmount(() => window.removeEventListener('keydown', onKeydown))
</script>

<template>
  <Transition name="fade">
    <div
      v-if="panel.isOpen"
      class="backdrop"
      aria-hidden="true"
      @click="panel.close()"
    />
  </Transition>

  <Transition name="panel">
    <aside
      v-if="panel.isOpen && panel.content"
      class="context-panel"
      role="complementary"
      :aria-label="`${panelTitle} details`"
    >
      <div class="panel-header">
        <span class="panel-title">{{ panelTitle }}</span>
        <button class="close" type="button" aria-label="Close panel" @click="panel.close()">
          <X :size="16" :stroke-width="1.75" />
        </button>
      </div>
      <div class="panel-body">
        <div v-if="panel.content.kind === 'skeleton'" class="panel-skeleton" aria-busy="true">
          <SkeletonBlock height="28px" width="65%" rounded="md" />
          <SkeletonBlock height="16px" width="40%" rounded="md" />
          <SkeletonBlock height="96px" rounded="lg" />
          <SkeletonBlock v-for="i in 3" :key="i" height="56px" rounded="md" />
        </div>
        <TaskDetailPanel
          v-else-if="panel.content.kind === 'task'"
          :key="`task-${panel.content.taskId}`"
          :task-id="panel.content.taskId"
        />
        <ProjectDetailPanel
          v-else-if="panel.content.kind === 'project'"
          :key="`project-${panel.content.projectId}`"
          :project-id="panel.content.projectId"
        />
        <GoalDetailPanel
          v-else
          :key="`goal-${panel.content.goalId}`"
          :goal-id="panel.content.goalId"
        />
      </div>
    </aside>
  </Transition>
</template>

<style scoped>
.context-panel {
  width: var(--panel-width);
  height: 100%;
  display: flex;
  flex-direction: column;
  background: var(--surface-1);
  border-left: 1px solid var(--border-subtle);
  overflow: hidden;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-5) var(--space-6);
  border-bottom: 1px solid var(--border-subtle);
  flex-shrink: 0;
}

.panel-title {
  font-size: var(--text-sm);
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-tertiary);
}

.close {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  border-radius: var(--radius-md);
  color: var(--text-tertiary);
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.close:hover {
  background: var(--surface-2);
  color: var(--text-primary);
}

.panel-body {
  flex: 1;
  overflow-y: auto;
  padding: var(--space-6);
}

.panel-skeleton {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.backdrop {
  display: none;
}

/* Below this width the panel floats above the workspace instead of
   displacing it — the workspace keeps priority. */
@media (max-width: 1100px) {
  .context-panel {
    position: fixed;
    top: 0;
    right: 0;
    bottom: 0;
    z-index: 40;
    box-shadow: var(--shadow-panel);
  }

  .backdrop {
    display: block;
    position: fixed;
    inset: 0;
    z-index: 30;
    background: var(--surface-overlay);
  }
}
</style>
