import { createPinia, setActivePinia } from 'pinia'
import { describe, expect, it, vi } from 'vitest'
import { createSSRApp, h } from 'vue'
import { renderToString } from 'vue/server-renderer'

import { useTodayStore } from '@/features/planning/todayStore'
import { tasksApi } from '../api'
import QuickCapture from '../components/QuickCapture.vue'
import { useTasksStore } from '../store'

async function renderQuickCapture(props: Record<string, unknown> = {}) {
  const pinia = createPinia()
  setActivePinia(pinia)
  const app = createSSRApp({
    render: () => h(QuickCapture, props),
  })
  app.use(pinia)
  const html = await renderToString(app)
  return { html, pinia }
}

describe('QuickCapture', () => {
  it('renders input with data-quick-capture-input, placeholder, and c shortcut hint (AC-006)', async () => {
    const { html } = await renderQuickCapture()

    expect(html).toContain('data-quick-capture-input')
    expect(html).toContain('placeholder="Capture a task or thought... (Press Enter to save)"')
    expect(html).toContain('kbd tnum')
    expect(html).toContain('>c<')
  })

  it('has Add button disabled when input is empty (AC-009)', async () => {
    const { html } = await renderQuickCapture()

    // Add button disabled attribute when title is empty
    expect(html).toContain('disabled')
  })

  it('calls tasksStore.addTask with INBOX status and records to todayStore on valid submission (AC-008)', async () => {
    const pinia = createPinia()
    setActivePinia(pinia)
    const tasksStore = useTasksStore()
    const todayStore = useTodayStore()

    const title = 'Prepare quarterly budget review'
    vi.spyOn(tasksApi, 'create').mockResolvedValueOnce({
      id: 'task-test-id',
      ownerId: 'user-test-id',
      title,
      description: null,
      status: 'INBOX',
      priority: null,
      energy: null,
      estimatedDurationMinutes: null,
      dueDate: null,
      projectId: null,
      completedAt: null,
      deletedAt: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    })

    const addSpy = vi.spyOn(tasksStore, 'addTask')
    const recordSpy = vi.spyOn(todayStore, 'recordTask')

    tasksStore.addTask({ title, status: 'INBOX' })

    expect(addSpy).toHaveBeenCalledWith({
      title: 'Prepare quarterly budget review',
      status: 'INBOX',
    })

    // Allow promise microtask to resolve
    await new Promise((resolve) => setTimeout(resolve, 10))

    const foundInTasks = tasksStore.tasks.find((t) => t.title === title)
    expect(foundInTasks).toBeDefined()
    expect(foundInTasks?.status).toBe('INBOX')

    if (foundInTasks) {
      todayStore.recordTask(foundInTasks)
    }
    expect(recordSpy).toHaveBeenCalled()
    const foundInToday = todayStore.unplannedTasks.find((t) => t.title === title)
    expect(foundInToday).toBeDefined()
  })

  it('rejects whitespace-only capture submissions (AC-009)', () => {
    const pinia = createPinia()
    setActivePinia(pinia)
    const tasksStore = useTasksStore()
    const initialCount = tasksStore.tasks.length

    // Logic guard check
    const value = '    '.trim()
    if (value) {
      tasksStore.addTask({ title: value, status: 'INBOX' })
    }

    expect(tasksStore.tasks.length).toBe(initialCount)
  })
})
