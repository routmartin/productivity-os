import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createSSRApp, h } from 'vue'
import { createMemoryHistory, createRouter } from 'vue-router'
import { renderToString } from 'vue/server-renderer'

import TasksPage from '@/pages/TasksPage.vue'
import { tasksApi } from '../api'
import TaskBoardCard from '../components/TaskBoardCard.vue'
import TaskBoardColumn from '../components/TaskBoardColumn.vue'
import { useTaskDragAndDrop } from '../composables/useTaskDragAndDrop'
import { useTasksStore } from '../store'
import type { Task } from '../types'

function makeTask(overrides: Partial<Task> = {}): Task {
  return {
    id: 'test-task-1',
    title: 'Design Kanban layout',
    description: null,
    status: 'PLANNED',
    priority: 'HIGH',
    energy: 'HIGH',
    estimatedMinutes: 45,
    dueDate: '2026-11-13',
    projectId: null,
    completedAt: null,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    ...overrides,
  }
}

describe('Kanban Board Layout & Drag-and-Drop (AC-UI-018 - AC-UI-023)', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.restoreAllMocks()

    vi.spyOn(tasksApi, 'plan').mockImplementation(async (id) => ({
      id,
      ownerId: 'u1',
      title: 'Planned task',
      description: null,
      status: 'PLANNED',
      priority: null,
      energy: null,
      estimatedDurationMinutes: null,
      dueDate: null,
      projectId: null,
      completedAt: null,
      deletedAt: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    }))

    vi.spyOn(tasksApi, 'start').mockImplementation(async (id) => ({
      id,
      ownerId: 'u1',
      title: 'Started task',
      description: null,
      status: 'IN_PROGRESS',
      priority: null,
      energy: null,
      estimatedDurationMinutes: null,
      dueDate: null,
      projectId: null,
      completedAt: null,
      deletedAt: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    }))

    vi.spyOn(tasksApi, 'complete').mockImplementation(async (id) => ({
      id,
      ownerId: 'u1',
      title: 'Completed task',
      description: null,
      status: 'COMPLETED',
      priority: null,
      energy: null,
      estimatedDurationMinutes: null,
      dueDate: null,
      projectId: null,
      completedAt: new Date().toISOString(),
      deletedAt: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    }))

    vi.spyOn(tasksApi, 'uncomplete').mockImplementation(async (id, target) => ({
      id,
      ownerId: 'u1',
      title: 'Uncompleted task',
      description: null,
      status: target ?? 'PLANNED',
      priority: null,
      energy: null,
      estimatedDurationMinutes: null,
      dueDate: null,
      projectId: null,
      completedAt: null,
      deletedAt: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    }))
  })

  describe('AC-UI-018: 3-Column Kanban Board Layout Partitioning', () => {
    it('partitions tasks into PLANNED, IN_PROGRESS, and COMPLETED columns', () => {
      const store = useTasksStore()
      store.tasks = [
        makeTask({ id: '1', title: 'Task Planned', status: 'PLANNED' }),
        makeTask({ id: '2', title: 'Task Inbox', status: 'INBOX' }),
        makeTask({ id: '3', title: 'Task In Progress', status: 'IN_PROGRESS' }),
        makeTask({ id: '4', title: 'Task Completed', status: 'COMPLETED' }),
        makeTask({ id: '5', title: 'Task Cancelled', status: 'CANCELLED' }),
      ]

      // Set date segment to ALL so all dates are visible
      store.setDateSegment('ALL')

      const cols = store.boardColumns
      // PLANNED column includes PLANNED and INBOX
      expect(cols.PLANNED.map((t) => t.id)).toEqual(expect.arrayContaining(['1', '2']))
      // IN_PROGRESS column
      expect(cols.IN_PROGRESS.map((t) => t.id)).toEqual(['3'])
      // COMPLETED column
      expect(cols.COMPLETED.map((t) => t.id)).toEqual(['4'])
      // Cancelled task should not appear in active board
      const allBoardIds = [...cols.PLANNED, ...cols.IN_PROGRESS, ...cols.COMPLETED].map((t) => t.id)
      expect(allBoardIds).not.toContain('5')
    })

    it('renders TaskBoardColumn with title, count, and quick-add button', async () => {
      const app = createSSRApp({
        render: () =>
          h(TaskBoardColumn, {
            columnId: 'PLANNED',
            title: 'To Do',
            tasks: [makeTask({ id: '1', title: 'First Task' })],
          }),
      })
      app.use(createPinia())
      const html = await renderToString(app)

      expect(html).toContain('To Do')
      expect(html).toContain('count-badge')
      expect(html).toContain('1')
      expect(html).toContain('quick-add-btn')
    })

    it('partitions tasks into board columns ignoring active statusFilter', () => {
      const store = useTasksStore()
      store.tasks = [
        makeTask({ id: '1', title: 'Task Planned', status: 'PLANNED' }),
        makeTask({ id: '2', title: 'Task In Progress', status: 'IN_PROGRESS' }),
        makeTask({ id: '3', title: 'Task Completed', status: 'COMPLETED' }),
      ]
      store.setDateSegment('ALL')

      // In list view, filtering by COMPLETED would hide Planned & In Progress
      store.setFilter('COMPLETED')
      expect(store.statusFilter).toBe('COMPLETED')
      expect(store.visibleTasks.map((t) => t.id)).toEqual(['3'])

      // Board columns partition tasks properly ignoring status filter
      expect(store.boardColumns.PLANNED.map((t) => t.id)).toEqual(['1'])
      expect(store.boardColumns.IN_PROGRESS.map((t) => t.id)).toEqual(['2'])
      expect(store.boardColumns.COMPLETED.map((t) => t.id)).toEqual(['3'])
    })

    it('renders TasksPage in board view without status filter and resets statusFilter to ALL', async () => {
      const pinia = createPinia()
      setActivePinia(pinia)
      const store = useTasksStore()
      store.status = 'ready'
      store.setFilter('PLANNED')

      const router = createRouter({
        history: createMemoryHistory(),
        routes: [{ path: '/tasks', component: TasksPage }],
      })
      await router.push('/tasks?view=board')
      await router.isReady()

      const app = createSSRApp(TasksPage)
      app.use(pinia)
      app.use(router)

      const html = await renderToString(app)

      // TaskFilters should not be rendered in board layout
      expect(html).not.toContain('aria-label="Filter tasks by status"')
      // Kanban board is rendered
      expect(html).toContain('class="kanban-board"')
      // Status filter is reset to ALL
      expect(store.statusFilter).toBe('ALL')
    })

    it('renders TasksPage in list view with status filter', async () => {
      const pinia = createPinia()
      setActivePinia(pinia)
      const store = useTasksStore()
      store.status = 'ready'

      const router = createRouter({
        history: createMemoryHistory(),
        routes: [{ path: '/tasks', component: TasksPage }],
      })
      await router.push('/tasks?view=list')
      await router.isReady()

      const app = createSSRApp(TasksPage)
      app.use(pinia)
      app.use(router)

      const html = await renderToString(app)

      // TaskFilters should be rendered in list layout
      expect(html).toContain('aria-label="Filter tasks by status"')
      // Kanban board is not rendered
      expect(html).not.toContain('class="kanban-board"')
    })
  })

  describe('AC-UI-019: Drag-and-Drop Lifecycle State Transitions', () => {
    it('transitionTaskStatus transitions from PLANNED to IN_PROGRESS and updates optimistically', async () => {
      const store = useTasksStore()
      const task = makeTask({ id: 't1', status: 'PLANNED' })
      store.tasks = [task]

      await store.transitionTaskStatus('t1', 'IN_PROGRESS')

      expect(task.status).toBe('IN_PROGRESS')
      expect(store.lastUndoable).toBeDefined()
      expect(store.lastUndoable?.taskId).toBe('t1')
    })

    it('transitionTaskStatus transitions from IN_PROGRESS to COMPLETED with completedAt timestamp', async () => {
      const store = useTasksStore()
      const task = makeTask({ id: 't2', status: 'IN_PROGRESS' })
      store.tasks = [task]

      await store.transitionTaskStatus('t2', 'COMPLETED')

      expect(task.status).toBe('COMPLETED')
      expect(task.completedAt).not.toBeNull()
      expect(store.toast?.kind).toBe('complete')
    })

    it('transitionTaskStatus demotes from IN_PROGRESS to PLANNED', async () => {
      const store = useTasksStore()
      const task = makeTask({ id: 't3', status: 'IN_PROGRESS' })
      store.tasks = [task]

      await store.transitionTaskStatus('t3', 'PLANNED')

      expect(task.status).toBe('PLANNED')
      expect(store.toast?.message).toBe('Moved to To Do')
    })

    it('undoLast reverts a PLANNED to IN_PROGRESS transition back to PLANNED and does not delete task', async () => {
      const store = useTasksStore()
      const task = makeTask({ id: 'undo-trans-1', status: 'PLANNED' })
      store.tasks = [task]

      await store.transitionTaskStatus('undo-trans-1', 'IN_PROGRESS')
      expect(task.status).toBe('IN_PROGRESS')
      expect(store.lastUndoable?.kind).toBe('transition')
      expect(store.toast?.message).toBe('Moved to In Progress')

      const undone = store.undoLast()
      expect(undone).toBeDefined()
      expect(undone?.id).toBe('undo-trans-1')
      expect(undone?.status).toBe('PLANNED')
      // Ensure task remains in store and was NOT deleted
      expect(store.tasks.some((t) => t.id === 'undo-trans-1')).toBe(true)
    })

    it('undoLast reverts an IN_PROGRESS to PLANNED demotion back to IN_PROGRESS and does not delete task', async () => {
      const store = useTasksStore()
      const task = makeTask({ id: 'undo-trans-2', status: 'IN_PROGRESS' })
      store.tasks = [task]

      await store.transitionTaskStatus('undo-trans-2', 'PLANNED')
      expect(task.status).toBe('PLANNED')
      expect(store.lastUndoable?.kind).toBe('transition')
      expect(store.toast?.message).toBe('Moved to To Do')

      const undone = store.undoLast()
      expect(undone).toBeDefined()
      expect(undone?.id).toBe('undo-trans-2')
      expect(undone?.status).toBe('IN_PROGRESS')
      expect(store.tasks.some((t) => t.id === 'undo-trans-2')).toBe(true)
    })
  })

  describe('AC-UI-020: Disambiguating Click (Open Details) from Drag (4px threshold)', () => {
    it('opens task details when pointer distance <= 4px without initiating drag', () => {
      const listeners: Record<string, ((e: unknown) => void)[]> = {}
      const mockWindow = {
        addEventListener: (type: string, cb: (e: unknown) => void) => {
          listeners[type] = listeners[type] || []
          listeners[type].push(cb)
        },
        removeEventListener: (type: string, cb: (e: unknown) => void) => {
          if (listeners[type]) {
            listeners[type] = listeners[type].filter((fn) => fn !== cb)
          }
        },
      }
      vi.stubGlobal('window', mockWindow)

      const onSelect = vi.fn()
      const { startPointerDrag, isDragging } = useTaskDragAndDrop(onSelect)

      const task = makeTask({ id: 'task-click-test' })
      const pointerDownEvent = {
        button: 0,
        clientX: 100,
        clientY: 100,
        currentTarget: {
          getBoundingClientRect: () => ({ left: 80, top: 80, width: 300, height: 120 }),
        },
      } as unknown as PointerEvent

      startPointerDrag(pointerDownEvent, task)

      expect(isDragging.value).toBe(false)

      // Pointer moves by only 2px (within 4px threshold)
      listeners['pointermove']?.forEach((cb) => cb({ clientX: 102, clientY: 101 }))
      expect(isDragging.value).toBe(false)

      // Pointer released: treated as click
      listeners['pointerup']?.forEach((cb) => cb({}))

      expect(isDragging.value).toBe(false)
      expect(onSelect).toHaveBeenCalledWith('task-click-test')

      vi.unstubAllGlobals()
    })

    it('initiates drag mode when pointer distance exceeds 4px threshold', () => {
      const listeners: Record<string, ((e: unknown) => void)[]> = {}
      const mockWindow = {
        addEventListener: (type: string, cb: (e: unknown) => void) => {
          listeners[type] = listeners[type] || []
          listeners[type].push(cb)
        },
        removeEventListener: (type: string, cb: (e: unknown) => void) => {
          if (listeners[type]) {
            listeners[type] = listeners[type].filter((fn) => fn !== cb)
          }
        },
      }
      vi.stubGlobal('window', mockWindow)

      const onSelect = vi.fn()
      const { startPointerDrag, isDragging, draggedTask } = useTaskDragAndDrop(onSelect)

      const task = makeTask({ id: 'task-drag-test' })
      const pointerDownEvent = {
        button: 0,
        clientX: 100,
        clientY: 100,
        currentTarget: {
          getBoundingClientRect: () => ({ left: 80, top: 80, width: 300, height: 120 }),
        },
      } as unknown as PointerEvent

      startPointerDrag(pointerDownEvent, task)

      // Move pointer 15px (exceeds 4px threshold)
      listeners['pointermove']?.forEach((cb) => cb({ clientX: 115, clientY: 100 }))

      expect(isDragging.value).toBe(true)
      expect(draggedTask.value?.id).toBe('task-drag-test')

      // Pointer up suppresses onSelect
      listeners['pointerup']?.forEach((cb) => cb({}))

      expect(onSelect).not.toHaveBeenCalled()

      vi.unstubAllGlobals()
    })

    it('cancels drag and cleans up listeners when pointercancel event fires', () => {
      const listeners: Record<string, ((e: unknown) => void)[]> = {}
      const mockWindow = {
        addEventListener: (type: string, cb: (e: unknown) => void) => {
          listeners[type] = listeners[type] || []
          listeners[type].push(cb)
        },
        removeEventListener: (type: string, cb: (e: unknown) => void) => {
          if (listeners[type]) {
            listeners[type] = listeners[type].filter((fn) => fn !== cb)
          }
        },
      }
      vi.stubGlobal('window', mockWindow)

      const onSelect = vi.fn()
      const { startPointerDrag, isDragging } = useTaskDragAndDrop(onSelect)

      const task = makeTask({ id: 'task-cancel-test' })
      const pointerDownEvent = {
        button: 0,
        clientX: 100,
        clientY: 100,
        currentTarget: {
          getBoundingClientRect: () => ({ left: 80, top: 80, width: 300, height: 120 }),
        },
      } as unknown as PointerEvent

      startPointerDrag(pointerDownEvent, task)

      // Move beyond threshold
      listeners['pointermove']?.forEach((cb) => cb({ clientX: 120, clientY: 100 }))
      expect(isDragging.value).toBe(true)

      // Cancel pointer
      listeners['pointercancel']?.forEach((cb) => cb({}))
      expect(isDragging.value).toBe(false)
      expect(onSelect).not.toHaveBeenCalled()

      vi.unstubAllGlobals()
    })
  })

  describe('AC-UI-022: Accessible Keyboard Grab-Move-Drop', () => {
    it('toggles grabbed state on Space / Enter and moves columns on ArrowRight', async () => {
      const store = useTasksStore()
      const task = makeTask({ id: 'kb-task', status: 'PLANNED' })
      store.tasks = [task]

      const onSelect = vi.fn()
      const { handleKeydown, grabbedTaskId, announcement } = useTaskDragAndDrop(onSelect)

      // Press Space to grab
      const spaceEvent = { key: ' ', preventDefault: vi.fn() } as unknown as KeyboardEvent
      handleKeydown(spaceEvent, task)

      expect(grabbedTaskId.value).toBe('kb-task')
      expect(announcement.value).toContain('Grabbed')

      // Press ArrowRight to move to IN_PROGRESS
      const rightEvent = { key: 'ArrowRight', preventDefault: vi.fn() } as unknown as KeyboardEvent
      handleKeydown(rightEvent, task)

      expect(task.status).toBe('IN_PROGRESS')
      expect(announcement.value).toContain('Moved')

      // Press Enter to drop
      const enterEvent = { key: 'Enter', preventDefault: vi.fn() } as unknown as KeyboardEvent
      handleKeydown(enterEvent, task)

      expect(grabbedTaskId.value).toBeNull()
      expect(announcement.value).toContain('Dropped')
    })

    it('cancels grab and reverts status on Escape', () => {
      const store = useTasksStore()
      const task = makeTask({ id: 'kb-esc-task', status: 'PLANNED' })
      store.tasks = [task]

      const onSelect = vi.fn()
      const { handleKeydown, grabbedTaskId, announcement } = useTaskDragAndDrop(onSelect)

      // Grab task
      handleKeydown({ key: ' ', preventDefault: vi.fn() } as unknown as KeyboardEvent, task)
      expect(grabbedTaskId.value).toBe('kb-esc-task')

      // Move right to IN_PROGRESS
      handleKeydown({ key: 'ArrowRight', preventDefault: vi.fn() } as unknown as KeyboardEvent, task)
      expect(task.status).toBe('IN_PROGRESS')

      // Press Escape: reverts to original status
      handleKeydown({ key: 'Escape', preventDefault: vi.fn() } as unknown as KeyboardEvent, task)

      expect(task.status).toBe('PLANNED')
      expect(grabbedTaskId.value).toBeNull()
      expect(announcement.value).toBe('Move cancelled.')
    })
  })

  describe('AC-UI-023: Column-Specific Empty States & Quick Creation', () => {
    it('renders column-specific empty state copy for To Do column', async () => {
      const app = createSSRApp({
        render: () =>
          h(TaskBoardColumn, {
            columnId: 'PLANNED',
            title: 'To Do',
            tasks: [],
          }),
      })
      app.use(createPinia())
      const html = await renderToString(app)

      expect(html).toContain('Queue is clear.')
      expect(html).toContain('Capture or schedule work to plan ahead.')
      expect(html).toContain('Add to To Do')
    })

    it('renders column-specific empty state copy for In Progress column', async () => {
      const app = createSSRApp({
        render: () =>
          h(TaskBoardColumn, {
            columnId: 'IN_PROGRESS',
            title: 'In Progress',
            tasks: [],
          }),
      })
      app.use(createPinia())
      const html = await renderToString(app)

      expect(html).toContain('Nothing in progress.')
      expect(html).toContain('Drag tasks here when you start focusing.')
      expect(html).toContain('Start a Task')
    })

    it('renders column-specific empty state copy for Done column', async () => {
      const app = createSSRApp({
        render: () =>
          h(TaskBoardColumn, {
            columnId: 'COMPLETED',
            title: 'Done',
            tasks: [],
          }),
      })
      app.use(createPinia())
      const html = await renderToString(app)

      expect(html).toContain('No completed tasks yet.')
      expect(html).toContain('Finish a task to see your momentum here.')
    })

    it('renders TaskBoardCard with completion checkbox and metadata chips', async () => {
      const pinia = createPinia()
      setActivePinia(pinia)
      const store = useTasksStore()
      const task = makeTask({
        id: 'card-test-1',
        title: 'Review pull request',
        status: 'PLANNED',
        dueDate: store.todayISO,
        estimatedMinutes: 30,
      })

      const app = createSSRApp({
        render: () =>
          h(TaskBoardCard, {
            task,
          }),
      })
      app.use(pinia)
      const html = await renderToString(app)

      expect(html).toContain('Review pull request')
      expect(html).toContain('card-check')
      expect(html).toContain('Today')
    })
  })
})
