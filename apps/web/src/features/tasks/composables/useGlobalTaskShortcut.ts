import { onBeforeUnmount, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'

import { hasOpenDialog } from '@/components/ui/UiDialog.vue'
import { useSearchStore } from '@/features/search/store'
import { isTaskCreationKey, isTypingTarget } from '@/lib/utils/keyboard'
import { useTasksStore } from '../store'

/**
 * Registers the global 'c' single-key shortcut to open the task creation dialog.
 * Evaluates typing target guards, modifier guards, and modal/search stacking guards.
 * Closes the dialog automatically when navigating across routes (AC-001 - AC-008).
 */
export function useGlobalTaskShortcut(): void {
  const route = useRoute()
  const tasksStore = useTasksStore()
  const searchStore = useSearchStore()

  function onKeydown(event: KeyboardEvent) {
    if (!isTaskCreationKey(event)) return
    if (isTypingTarget(event.target)) return
    if (hasOpenDialog() || searchStore.open || tasksStore.isCreateDialogOpen) return

    event.preventDefault()
    tasksStore.openCreateDialog()
  }

  watch(
    () => route.fullPath,
    () => {
      if (tasksStore.isCreateDialogOpen) {
        tasksStore.closeCreateDialog()
      }
    },
  )

  onMounted(() => {
    window.addEventListener('keydown', onKeydown)
  })

  onBeforeUnmount(() => {
    window.removeEventListener('keydown', onKeydown)
  })
}
