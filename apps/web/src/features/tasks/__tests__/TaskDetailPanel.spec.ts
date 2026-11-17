import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it } from 'vitest'
import { createSSRApp, h } from 'vue'
import { renderToString } from 'vue/server-renderer'

import TaskDetailPanel from '../components/TaskDetailPanel.vue'
import { useTasksStore } from '../store'
import { useTodayStore } from '@/features/planning/todayStore'
import type { Task } from '../types'

function makeTask(overrides: Partial<Task> = {}): Task {
  return {
    id: 'test-task-1',
    title: 'Test action buttons redesign',
    description: 'Detailed description',
    status: 'INBOX',
    priority: 'HIGH',
    energy: 'MEDIUM',
    estimatedMinutes: 30,
    dueDate: '2026-11-17',
    projectId: null,
    pinned: false,
    completedAt: null,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    ...overrides,
  }
}

describe('TaskDetailPanel Action Buttons Redesign', () => {
  let pinia: ReturnType<typeof createPinia>

  beforeEach(() => {
    pinia = createPinia()
    setActivePinia(pinia)
  })

  async function renderComponent(taskId: string) {
    const app = createSSRApp({
      render: () => h(TaskDetailPanel, { taskId }),
    })
    app.use(pinia)
    return renderToString(app)
  }

  it('renders Pinned and Top 3 indicator pills in header when active', async () => {
    const tasksStore = useTasksStore(pinia)
    const todayStore = useTodayStore(pinia)

    tasksStore.tasks = [
      makeTask({ id: 'task-1', pinned: true }),
    ]
    todayStore.topThree = [{ taskId: 'task-1', position: 1 }]

    const html = await renderComponent('task-1')

    expect(html).toContain('Pinned')
    expect(html).toContain('Top 3')
  })

  it('renders 2-column primary pair (Start task and Plan for today) for INBOX task', async () => {
    const tasksStore = useTasksStore(pinia)
    tasksStore.tasks = [makeTask({ id: 'task-inbox', status: 'INBOX' })]

    const html = await renderComponent('task-inbox')

    expect(html).toContain('primary-actions pair')
    expect(html).toContain('Start task')
    expect(html).toContain('Plan for today')
  })

  it('renders single primary Start task button for PLANNED task', async () => {
    const tasksStore = useTasksStore(pinia)
    tasksStore.tasks = [makeTask({ id: 'task-planned', status: 'PLANNED' })]

    const html = await renderComponent('task-planned')

    expect(html).toContain('primary-actions')
    expect(html).not.toContain('primary-actions pair')
    expect(html).toContain('Start task')
    expect(html).not.toContain('Plan for today')
  })

  it('renders Mark complete button for IN_PROGRESS task', async () => {
    const tasksStore = useTasksStore(pinia)
    tasksStore.tasks = [makeTask({ id: 'task-progress', status: 'IN_PROGRESS' })]

    const html = await renderComponent('task-progress')

    expect(html).toContain('Mark complete')
  })

  it('renders Reopen task button for CANCELLED task', async () => {
    const tasksStore = useTasksStore(pinia)
    tasksStore.tasks = [makeTask({ id: 'task-cancelled', status: 'CANCELLED' })]

    const html = await renderComponent('task-cancelled')

    expect(html).toContain('Reopen task')
  })

  it('renders secondary actions grid with Edit, Pin, and Top 3', async () => {
    const tasksStore = useTasksStore(pinia)
    tasksStore.tasks = [makeTask({ id: 'task-sec', pinned: true })]

    const html = await renderComponent('task-sec')

    expect(html).toContain('secondary-actions')
    expect(html).toContain('Edit task')
    expect(html).toContain('Unpin')
    expect(html).toContain('Add to Top 3')
    expect(html).toContain('is-active')
  })

  it('renders danger section with Cancel task and Delete task for active tasks', async () => {
    const tasksStore = useTasksStore(pinia)
    tasksStore.tasks = [makeTask({ id: 'task-active', status: 'INBOX' })]

    const html = await renderComponent('task-active')

    expect(html).toContain('danger-section')
    expect(html).toContain('danger-row')
    expect(html).toContain('Cancel task')
    expect(html).toContain('Delete task')
  })

  it('hides danger section for COMPLETED and CANCELLED tasks', async () => {
    const tasksStore = useTasksStore(pinia)
    tasksStore.tasks = [
      makeTask({ id: 'task-completed', status: 'COMPLETED' }),
      makeTask({ id: 'task-cancelled', status: 'CANCELLED' }),
    ]

    const htmlCompleted = await renderComponent('task-completed')
    expect(htmlCompleted).not.toContain('danger-section')

    const htmlCancelled = await renderComponent('task-cancelled')
    expect(htmlCancelled).not.toContain('danger-section')
  })
})
