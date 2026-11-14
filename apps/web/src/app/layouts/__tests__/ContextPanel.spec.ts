import { createPinia, setActivePinia } from 'pinia'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createSSRApp, h, reactive } from 'vue'
import { renderToString } from 'vue/server-renderer'
import { useRoute } from 'vue-router'

import ContextPanel from '../ContextPanel.vue'
import { useContextPanelStore } from '../contextPanelStore'

vi.mock('vue-router', () => ({
  useRoute: vi.fn(),
}))

describe('ContextPanel Popup Dialog', () => {
  let mockRoute: { name: string; path: string; fullPath: string; query: Record<string, string> }

  beforeEach(() => {
    setActivePinia(createPinia())
    mockRoute = reactive({
      name: 'tasks',
      path: '/tasks',
      fullPath: '/tasks',
      query: {},
    })
    vi.mocked(useRoute).mockReturnValue(mockRoute as unknown as ReturnType<typeof useRoute>)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  async function renderPanel(pinia = createPinia()) {
    setActivePinia(pinia)
    const app = createSSRApp({
      render: () => h(ContextPanel),
    })
    app.use(pinia)
    const html = await renderToString(app)
    return { html, pinia }
  }

  it('renders nothing when contextPanelStore is closed', async () => {
    const pinia = createPinia()
    const { html } = await renderPanel(pinia)

    expect(html).not.toContain('role="dialog"')
  })

  it('renders UiDialog with "Task details" when task content is opened (AC-002)', async () => {
    const pinia = createPinia()
    const panel = useContextPanelStore(pinia)
    panel.openTask('task-123')

    const { html } = await renderPanel(pinia)

    expect(html).toContain('role="dialog"')
    expect(html).toContain('Task details')
    expect(html).toContain('lg dialog')
  })

  it('renders UiDialog with "Project details" when project content is opened (AC-003)', async () => {
    const pinia = createPinia()
    const panel = useContextPanelStore(pinia)
    panel.openProject('proj-456')

    const { html } = await renderPanel(pinia)

    expect(html).toContain('role="dialog"')
    expect(html).toContain('Project details')
    expect(html).toContain('lg dialog')
  })

  it('renders UiDialog with "Goal details" when goal content is opened (AC-004)', async () => {
    const pinia = createPinia()
    const panel = useContextPanelStore(pinia)
    panel.openGoal('goal-789')

    const { html } = await renderPanel(pinia)

    expect(html).toContain('role="dialog"')
    expect(html).toContain('Goal details')
    expect(html).toContain('lg dialog')
  })

  it('renders UiDialog with "Details" and skeleton blocks when skeleton content is opened', async () => {
    const pinia = createPinia()
    const panel = useContextPanelStore(pinia)
    panel.openSkeleton()

    const { html } = await renderPanel(pinia)

    expect(html).toContain('role="dialog"')
    expect(html).toContain('Details')
    expect(html).toContain('panel-skeleton')
  })

  it('closes dialog and resets store state when panel.close() is called on @close (AC-005)', async () => {
    const pinia = createPinia()
    const panel = useContextPanelStore(pinia)
    panel.openTask('task-123')

    expect(panel.isOpen).toBe(true)
    expect(panel.activeTaskId).toBe('task-123')

    // Simulate @close trigger by calling panel.close()
    panel.close()

    expect(panel.isOpen).toBe(false)
    expect(panel.content).toBeNull()
    expect(panel.activeTaskId).toBeNull()
  })

  it('supports toggling entities via contextPanelStore (AC-002, AC-003, AC-004)', () => {
    const pinia = createPinia()
    setActivePinia(pinia)
    const panel = useContextPanelStore(pinia)

    panel.toggleTask('task-1')
    expect(panel.isOpen).toBe(true)
    expect(panel.activeTaskId).toBe('task-1')

    panel.toggleTask('task-1')
    expect(panel.isOpen).toBe(false)
    expect(panel.activeTaskId).toBeNull()

    panel.toggleProject('proj-1')
    expect(panel.isOpen).toBe(true)
    expect(panel.activeProjectId).toBe('proj-1')

    panel.toggleProject('proj-1')
    expect(panel.isOpen).toBe(false)
    expect(panel.activeProjectId).toBeNull()

    panel.toggleGoal('goal-1')
    expect(panel.isOpen).toBe(true)
    expect(panel.activeGoalId).toBe('goal-1')

    panel.toggleGoal('goal-1')
    expect(panel.isOpen).toBe(false)
    expect(panel.activeGoalId).toBeNull()
  })
})
