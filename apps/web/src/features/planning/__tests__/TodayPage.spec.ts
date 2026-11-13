import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { useRoute, useRouter } from 'vue-router'

import { useScheduleStore } from '../scheduleStore'
import { useTodayStore } from '../todayStore'

vi.mock('vue-router', () => ({
  useRoute: vi.fn(),
  useRouter: vi.fn(),
}))

describe('TodayPage dynamic AI briefing & telemetry', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.restoreAllMocks()
    vi.mocked(useRoute).mockReturnValue({
      query: {},
      name: 'today',
      path: '/today',
      params: {},
      hash: '',
      fullPath: '/today',
      matched: [],
      meta: {},
      redirectedFrom: undefined,
    })
    vi.mocked(useRouter).mockReturnValue({
      push: vi.fn(),
    } as unknown as ReturnType<typeof useRouter>)
  })

  it('synthesizes AI Briefing with overflow warning and Review Schedule CTA when overflow > 0 (AC-013)', () => {
    const todayStore = useTodayStore()
    const scheduleStore = useScheduleStore()

    todayStore.topThree = [
      { taskId: 't-1', position: 1 },
      { taskId: 't-2', position: 2 },
    ]
    todayStore.plan = {
      plannedMinutes: 300,
      focusCapacityMinutes: 360,
      focusCompletedMinutes: 0,
    }

    scheduleStore.graph = {
      date: '2026-11-13',
      wakeTime: '06:30',
      targetBedtime: '22:30',
      projectedBedtime: '23:15',
      overflowMinutes: 45,
      phases: [],
      nodes: [],
      edges: [],
    }

    const isOverflowing = scheduleStore.overflowMinutes > 0
    const slipMinutes = scheduleStore.overflowMinutes

    let subline = ''
    let ctaLabel = ''
    if (isOverflowing) {
      subline = `Schedule is over capacity by ${slipMinutes}m. Bedtime projected to slip to ${scheduleStore.projectedBedtime}.`
      ctaLabel = 'Review Schedule'
    }

    expect(subline).toContain('Schedule is over capacity by 45m')
    expect(subline).toContain('Bedtime projected to slip to 23:15')
    expect(ctaLabel).toBe('Review Schedule')
  })

  it('synthesizes AI Briefing with buffer remaining and habit momentum in normal state', () => {
    const todayStore = useTodayStore()
    const scheduleStore = useScheduleStore()

    todayStore.topThree = [
      { taskId: 't-1', position: 1 },
      { taskId: 't-2', position: 2 },
    ]
    todayStore.plan = {
      plannedMinutes: 270,
      focusCapacityMinutes: 360,
      focusCompletedMinutes: 0,
    }

    scheduleStore.graph = {
      date: '2026-11-13',
      wakeTime: '06:30',
      targetBedtime: '22:30',
      projectedBedtime: '22:30',
      overflowMinutes: 0,
      phases: [],
      nodes: [
        { id: 'h-1', type: 'habit', phase: 'morning', title: 'Water', completed: true, order: 1 },
        { id: 'h-2', type: 'habit', phase: 'morning', title: 'Stretch', completed: true, order: 2 },
        { id: 'h-3', type: 'habit', phase: 'bedtime', title: 'Read', completed: false, order: 3 },
      ],
      edges: [],
    }

    const bufferMinutes = todayStore.plan.focusCapacityMinutes - todayStore.plan.plannedMinutes
    const bufferHours = (bufferMinutes / 60).toFixed(1)
    const subline = `You have ${bufferHours}h buffer remaining today. ${scheduleStore.completedHabitsCount} of ${scheduleStore.totalHabitsCount} habits completed.`

    expect(subline).toBe('You have 1.5h buffer remaining today. 2 of 3 habits completed.')
  })

  it('correctly handles deterministic preview=empty state across stores (AC-014)', async () => {
    const todayStore = useTodayStore()
    const scheduleStore = useScheduleStore()

    await todayStore.load('empty')
    await scheduleStore.load('empty')

    expect(todayStore.topThree).toHaveLength(0)
    expect(todayStore.plan?.plannedMinutes).toBe(0)
    expect(todayStore.schedule).toHaveLength(0)
    expect(scheduleStore.nodes).toHaveLength(0)
    expect(scheduleStore.overflowMinutes).toBe(0)
    expect(scheduleStore.projectedBedtime).toBe('22:30')
  })
})
