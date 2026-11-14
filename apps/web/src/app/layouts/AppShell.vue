<script setup lang="ts">
import { RouterView } from 'vue-router'

import PreviewToast from '@/components/shared/PreviewToast.vue'
import SearchOverlay from '@/features/search/components/SearchOverlay.vue'
import NewTaskDialog from '@/features/tasks/components/NewTaskDialog.vue'
import UndoToast from '@/features/tasks/components/UndoToast.vue'
import { useGlobalTaskShortcut } from '@/features/tasks/composables/useGlobalTaskShortcut'
import { useTasksStore } from '@/features/tasks/store'
import type { NewTaskDraft } from '@/features/tasks/types'
import { useMock } from '@/lib/mock'
import { showPreviewNote } from '@/lib/preview'

import ContextPanel from './ContextPanel.vue'
import SideNav from './SideNav.vue'
import TopBar from './TopBar.vue'

const tasksStore = useTasksStore()
const mockMode = useMock('TASKS')

useGlobalTaskShortcut()

function handleCreateTask(draft: NewTaskDraft) {
  tasksStore.addTask(draft)
  tasksStore.closeCreateDialog()
  if (mockMode) {
    showPreviewNote('Task captured locally — it will sync once the Task API is connected.')
  }
}
</script>

<template>
  <div class="shell">
    <SideNav />
    <main class="workspace">
      <TopBar />
      <div class="scroll">
        <RouterView v-slot="{ Component }">
          <Transition name="page" mode="out-in">
            <component :is="Component" />
          </Transition>
        </RouterView>
      </div>
    </main>
    <ContextPanel />
    <PreviewToast />
    <SearchOverlay />
    <NewTaskDialog
      :open="tasksStore.isCreateDialogOpen"
      :initial="tasksStore.createDialogInitialDraft"
      @close="tasksStore.closeCreateDialog"
      @create="handleCreateTask"
    />
    <UndoToast />
  </div>
</template>

<style scoped>
.shell {
  display: grid;
  grid-template-columns: auto 1fr;
  height: 100vh;
  overflow: hidden;
}

.workspace {
  display: flex;
  flex-direction: column;
  min-width: 0;
  overflow: hidden;
  /* Pages respond to the real workspace width (sidebar and context panel
     already deducted) via @container queries. */
  container-type: inline-size;
  container-name: workspace;
}

.scroll {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
}
</style>
