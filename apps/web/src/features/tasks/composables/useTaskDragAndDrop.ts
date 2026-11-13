import { getCurrentInstance, nextTick, onUnmounted, ref } from 'vue'

import { useTasksStore } from '../store'
import type { BoardColumnId, Task, TaskStatus } from '../types'

const COLUMN_ORDER: BoardColumnId[] = ['PLANNED', 'IN_PROGRESS', 'COMPLETED']
const DRAG_THRESHOLD_PX = 4

export function useTaskDragAndDrop(onSelectTask: (taskId: string) => void) {
  const store = useTasksStore()

  // Pointer drag state
  const isDragging = ref(false)
  const draggedTask = ref<Task | null>(null)
  const hoveredColumn = ref<BoardColumnId | null>(null)
  const pointerPos = ref({ x: 0, y: 0 })
  const previewOffset = ref({ x: 0, y: 0 })
  const previewSize = ref({ width: 0, height: 0 })

  // Keyboard grab-move-drop state
  const grabbedTaskId = ref<string | null>(null)
  const announcement = ref('')
  let originalGrabStatus: TaskStatus | null = null

  let startPos = { x: 0, y: 0 }
  let activeTask: Task | null = null

  function announce(message: string) {
    announcement.value = message
  }

  function isBoardColumnId(value: string | null): value is BoardColumnId {
    return value !== null && COLUMN_ORDER.includes(value as BoardColumnId)
  }

  function detectColumnUnderPointer(clientX: number, clientY: number): BoardColumnId | null {
    if (typeof document === 'undefined' || !document.elementsFromPoint) return null
    const elements = document.elementsFromPoint(clientX, clientY)
    for (const el of elements) {
      const dropZone = el.closest<HTMLElement>('[data-drop-zone], [data-column-id]')
      if (dropZone) {
        const colId = dropZone.getAttribute('data-drop-zone') ?? dropZone.getAttribute('data-column-id')
        if (isBoardColumnId(colId)) return colId
      }
    }
    return null
  }

  function onPointerMove(event: PointerEvent) {
    if (!activeTask) return

    const distance = Math.hypot(event.clientX - startPos.x, event.clientY - startPos.y)

    if (!isDragging.value && distance > DRAG_THRESHOLD_PX) {
      isDragging.value = true
      draggedTask.value = activeTask
      announce(`Picked up ${activeTask.title}. Dragging across columns.`)
    }

    if (isDragging.value) {
      pointerPos.value = {
        x: event.clientX - previewOffset.value.x,
        y: event.clientY - previewOffset.value.y,
      }
      hoveredColumn.value = detectColumnUnderPointer(event.clientX, event.clientY)
    }
  }

  function onPointerUp() {
    if (typeof window !== 'undefined') {
      window.removeEventListener('pointermove', onPointerMove)
      window.removeEventListener('pointerup', onPointerUp)
      window.removeEventListener('pointercancel', onPointerUp)
      window.removeEventListener('keydown', onWindowKeyDown)
    }

    if (!activeTask) return

    if (!isDragging.value) {
      // Threshold not reached: user clicked the card
      onSelectTask(activeTask.id)
    } else {
      // Completed drag
      const task = activeTask
      const target = hoveredColumn.value

      if (target && target !== task.status) {
        void store.transitionTaskStatus(task.id, target as TaskStatus)
        announce(`Moved task "${task.title}" to ${target.replace('_', ' ').toLowerCase()}.`)
      }
    }

    isDragging.value = false
    draggedTask.value = null
    hoveredColumn.value = null
    activeTask = null
  }

  function onWindowKeyDown(event: KeyboardEvent) {
    if (event.key === 'Escape' && isDragging.value) {
      isDragging.value = false
      draggedTask.value = null
      hoveredColumn.value = null
      activeTask = null
      announce('Drag cancelled.')
    }
  }

  function startPointerDrag(event: PointerEvent, task: Task) {
    if (event.button !== 0) return

    activeTask = task
    startPos = { x: event.clientX, y: event.clientY }

    const targetEl = (event.currentTarget as HTMLElement | null) ?? (event.target as HTMLElement)
    const rect = targetEl?.getBoundingClientRect?.() ?? { left: 0, top: 0, width: 300, height: 100 }

    previewOffset.value = {
      x: event.clientX - rect.left,
      y: event.clientY - rect.top,
    }
    previewSize.value = {
      width: rect.width,
      height: rect.height,
    }
    pointerPos.value = {
      x: rect.left,
      y: rect.top,
    }

    if (typeof window !== 'undefined') {
      window.addEventListener('pointermove', onPointerMove)
      window.addEventListener('pointerup', onPointerUp)
      window.addEventListener('pointercancel', onPointerUp)
      window.addEventListener('keydown', onWindowKeyDown)
    }
  }

  function handleKeydown(event: KeyboardEvent, task: Task) {
    if (event.key === ' ' || event.key === 'Enter') {
      event.preventDefault()
      if (grabbedTaskId.value === task.id) {
        // Drop grabbed task
        grabbedTaskId.value = null
        originalGrabStatus = null
        announce(`Dropped "${task.title}".`)
      } else {
        // Pick up task
        grabbedTaskId.value = task.id
        originalGrabStatus = task.status
        announce(
          `Grabbed "${task.title}". Use Left and Right arrow keys to change status column, Space or Enter to drop, Escape to cancel.`,
        )
      }
      return
    }

    if (grabbedTaskId.value === task.id) {
      if (event.key === 'Escape') {
        event.preventDefault()
        if (originalGrabStatus && originalGrabStatus !== task.status) {
          void store.transitionTaskStatus(task.id, originalGrabStatus)
        }
        grabbedTaskId.value = null
        originalGrabStatus = null
        announce('Move cancelled.')
        void nextTick(() => {
          if (typeof document !== 'undefined') {
            const el = document.querySelector<HTMLElement>(`[data-task-id="${task.id}"]`)
            el?.focus({ preventScroll: true })
          }
        })
        return
      }

      if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
        event.preventDefault()
        return
      }

      const currentIndex = COLUMN_ORDER.indexOf(
        task.status === 'INBOX' ? 'PLANNED' : (task.status as BoardColumnId),
      )

      if (event.key === 'ArrowRight' && currentIndex < COLUMN_ORDER.length - 1) {
        event.preventDefault()
        const nextCol = COLUMN_ORDER[currentIndex + 1]
        void store.transitionTaskStatus(task.id, nextCol)
        announce(`Moved "${task.title}" to ${nextCol.replace('_', ' ').toLowerCase()}.`)
        void nextTick(() => {
          if (typeof document !== 'undefined') {
            const el = document.querySelector<HTMLElement>(`[data-task-id="${task.id}"]`)
            el?.focus({ preventScroll: true })
          }
        })
      } else if (event.key === 'ArrowLeft' && currentIndex > 0) {
        event.preventDefault()
        const prevCol = COLUMN_ORDER[currentIndex - 1]
        void store.transitionTaskStatus(task.id, prevCol)
        announce(`Moved "${task.title}" to ${prevCol.replace('_', ' ').toLowerCase()}.`)
        void nextTick(() => {
          if (typeof document !== 'undefined') {
            const el = document.querySelector<HTMLElement>(`[data-task-id="${task.id}"]`)
            el?.focus({ preventScroll: true })
          }
        })
      }
    }
  }

  if (getCurrentInstance()) {
    onUnmounted(() => {
      if (typeof window !== 'undefined') {
        window.removeEventListener('pointermove', onPointerMove)
        window.removeEventListener('pointerup', onPointerUp)
        window.removeEventListener('pointercancel', onPointerUp)
        window.removeEventListener('keydown', onWindowKeyDown)
      }
    })
  }

  return {
    isDragging,
    draggedTask,
    hoveredColumn,
    pointerPos,
    previewSize,
    grabbedTaskId,
    announcement,
    startPointerDrag,
    handleKeydown,
  }
}
