<script setup lang="ts">
import { computed, onBeforeUnmount, watch } from 'vue'
import { useRoute } from 'vue-router'
import { X } from 'lucide-vue-next'

import GoalDetailPanel from '@/features/goals/components/GoalDetailPanel.vue'
import ProjectDetailPanel from '@/features/projects/components/ProjectDetailPanel.vue'
import TaskDetailPanel from '@/features/tasks/components/TaskDetailPanel.vue'

import { useContextPanelStore } from './contextPanelStore'

const panel = useContextPanelStore()
const route = useRoute()

const panelTitle = computed(() => {
  if (panel.content?.kind === 'project') return 'Project'
  if (panel.content?.kind === 'goal') return 'Goal'
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
        <TaskDetailPanel
          v-if="panel.content.kind === 'task'"
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
  padding: var(--space-4) var(--space-5);
  border-bottom: 1px solid var(--border-subtle);
  flex-shrink: 0;
}

.panel-title {
  font-size: var(--text-xs);
  font-weight: 600;
  letter-spacing: 0.09em;
  text-transform: uppercase;
  color: var(--text-tertiary);
}

.close {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
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
  padding: var(--space-5);
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
