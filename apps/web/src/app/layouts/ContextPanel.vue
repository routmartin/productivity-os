<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRoute } from 'vue-router'

import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import UiDialog from '@/components/ui/UiDialog.vue'
import GoalDetailPanel from '@/features/goals/components/GoalDetailPanel.vue'
import ProjectDetailPanel from '@/features/projects/components/ProjectDetailPanel.vue'
import TaskDetailPanel from '@/features/tasks/components/TaskDetailPanel.vue'

import { useContextPanelStore } from './contextPanelStore'

const panel = useContextPanelStore()
const route = useRoute()

const panelTitle = computed(() => {
  if (panel.content?.kind === 'project') return 'Project details'
  if (panel.content?.kind === 'goal') return 'Goal details'
  if (panel.content?.kind === 'skeleton') return 'Details'
  return 'Task details'
})

// Navigating to another section closes the panel — its content is
// contextual to the workspace it was opened from.
watch(
  () => route.name,
  () => panel.close(),
)
</script>

<template>
  <UiDialog
    :open="panel.isOpen && Boolean(panel.content)"
    :title="panelTitle"
    size="lg"
    @close="panel.close()"
  >
    <div v-if="panel.content?.kind === 'skeleton'" class="panel-skeleton" aria-busy="true">
      <SkeletonBlock height="28px" width="65%" rounded="md" />
      <SkeletonBlock height="16px" width="40%" rounded="md" />
      <SkeletonBlock height="96px" rounded="lg" />
      <SkeletonBlock v-for="i in 3" :key="i" height="56px" rounded="md" />
    </div>
    <TaskDetailPanel
      v-else-if="panel.content?.kind === 'task'"
      :key="`task-${panel.content.taskId}`"
      :task-id="panel.content.taskId"
    />
    <ProjectDetailPanel
      v-else-if="panel.content?.kind === 'project'"
      :key="`project-${panel.content.projectId}`"
      :project-id="panel.content.projectId"
      @delete="panel.close()"
    />
    <GoalDetailPanel
      v-else-if="panel.content?.kind === 'goal'"
      :key="`goal-${panel.content.goalId}`"
      :goal-id="panel.content.goalId"
    />
  </UiDialog>
</template>

<style scoped>
.panel-skeleton {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}
</style>
