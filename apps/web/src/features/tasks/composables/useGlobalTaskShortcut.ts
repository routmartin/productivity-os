import { getCurrentInstance, onBeforeUnmount, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'

import { hasOpenDialog } from '@/components/ui/UiDialog.vue'
import { useSearchStore } from '@/features/search/store'
import { isTaskCreationKey, isTypingTarget } from '@/lib/utils/keyboard'
import { useTasksStore } from '../store'

/**
 * Registers the global 'c' single-key shortcut to open the task creation dialog.
 * Evaluates typing target guards, modifier guards, and modal/search stacking guards.
 * Closes the dialog automatically when navigating across routes (AC-001 - AC-008).
 * When on the 'today' route, delegates 'c' to focus the inline Quick Capture input (Plan 018 / AC-007).
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

    // When on the Today view, focus the inline Quick Capture input without opening dialog (AC-007)
    const isToday = route?.name === 'today' || route?.path === '/today'
    if (isToday) {
      const inlineInput = document.querySelector<HTMLInputElement>('[data-quick-capture-input]')
      if (inlineInput) {
        inlineInput.focus()
      }
      return
    }

    tasksStore.openCreateDialog()
  }

  watch(
    () => route?.fullPath,
    () => {
      if (tasksStore.isCreateDialogOpen) {
        tasksStore.closeCreateDialog()
      }
    },
  )

  if (getCurrentInstance()) {
    onMounted(() => {
      window.addEventListener('keydown', onKeydown)
    })

    onBeforeUnmount(() => {
      window.removeEventListener('keydown', onKeydown)
    })
  } else {
    window.addEventListener('keydown', onKeydown)
  }
}
