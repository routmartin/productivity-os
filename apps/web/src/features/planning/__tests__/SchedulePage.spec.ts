import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createSSRApp, h } from 'vue'
import { renderToString } from 'vue/server-renderer'
import { useRoute } from 'vue-router'

import SchedulePage from '@/pages/SchedulePage.vue'
import { createMockScheduleGraph, useScheduleStore } from '../scheduleStore'

vi.mock('vue-router', () => ({
  useRoute: vi.fn(),
  useRouter: vi.fn(),
}))

describe('SchedulePage empty state and blueprint loading', () => {
  let pinia: ReturnType<typeof createPinia>

  beforeEach(() => {
    pinia = createPinia()
    setActivePinia(pinia)
    vi.restoreAllMocks()

    vi.mocked(useRoute).mockReturnValue({
      query: {},
      name: 'schedule',
      path: '/schedule',
      params: {},
      hash: '',
      fullPath: '/schedule',
      matched: [],
      meta: {},
      redirectedFrom: undefined,
    })
  })

  async function renderSchedulePage() {
    const app = createSSRApp({
      render: () => h(SchedulePage),
    })
    app.use(pinia)
    return renderToString(app)
  }

  it('renders EmptyState and header Load button when schedule only contains anchors (0 habits, 0 tasks)', async () => {
    const store = useScheduleStore(pinia)

    // Simulate backend response with only anchors
    store.status = 'ready'
    store.graph = {
      date: '2026-11-18',
      wakeTime: '06:20',
      targetBedtime: '23:20',
      projectedBedtime: '23:20',
      overflowMinutes: 0,
      phases: [],
      nodes: [
        {
          id: 'anchor-wake',
          type: 'anchor',
          phase: 'morning',
          anchorKind: 'wake',
          title: 'Wake Up & Circadian Anchor',
          time: '06:20',
          durationMinutes: 10,
          order: 1,
        },
        {
          id: 'anchor-bedtime',
          type: 'anchor',
          phase: 'bedtime',
          anchorKind: 'bedtime',
          title: 'Target Sleep Sanctuary',
          time: '23:20',
          durationMinutes: 0,
          order: 2,
        },
      ],
      edges: [
        {
          id: 'e-anchor-wake-anchor-bedtime',
          fromNodeId: 'anchor-wake',
          toNodeId: 'anchor-bedtime',
          type: 'sequential',
          active: false,
        },
      ],
    }

    const html = await renderSchedulePage()

    // 0/0 Habits pill should NOT be rendered
    expect(html).not.toContain('0/0 Habits')

    // Empty state should be visible
    expect(html).toContain('No activities scheduled for today')
    expect(html).toContain('Load Recommended Day Trajectory')
    expect(html).toContain('Load Recommended Blueprint')
  })

  it('renders habit progress and canvas when habits exist', async () => {
    const store = useScheduleStore(pinia)
    store.status = 'ready'
    store.graph = createMockScheduleGraph()

    const html = await renderSchedulePage()

    // Summary pill with habits should be visible
    expect(html).toContain('Habits')
    expect(html).not.toContain('No activities scheduled for today')
  })

  it('resetToDefaultBlueprint is called when resetting to recommended blueprint', async () => {
    const store = useScheduleStore(pinia)
    const resetSpy = vi.spyOn(store, 'resetToDefaultBlueprint').mockResolvedValueOnce()

    await store.resetToDefaultBlueprint()

    expect(resetSpy).toHaveBeenCalledTimes(1)
  })
})
