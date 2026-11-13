import { createPinia, setActivePinia } from 'pinia'
import { describe, expect, it } from 'vitest'
import { createSSRApp, defineComponent, h } from 'vue'
import { renderToString } from 'vue/server-renderer'

import ScheduleTimeline from '../components/ScheduleTimeline.vue'
import { createMockScheduleGraph, useScheduleStore } from '../scheduleStore'
import type { ScheduleEntry, ScheduleNode } from '../types'

const RouterLinkMock = defineComponent({
  name: 'RouterLink',
  props: ['to'],
  template: '<a><slot /></a>',
})

async function renderTimeline(props: Record<string, unknown> = {}) {
  const pinia = createPinia()
  setActivePinia(pinia)
  const app = createSSRApp({
    render: () => h(ScheduleTimeline, props),
  })
  app.use(pinia)
  app.component('RouterLink', RouterLinkMock)
  const html = await renderToString(app)
  return { html, pinia }
}

describe('ScheduleTimeline', () => {
  const mockHabits: ScheduleNode[] = [
    {
      id: 'habit-01',
      type: 'habit',
      phase: 'morning',
      habitId: 'habit-01',
      title: 'Morning Sunlight & Hydration',
      icon: 'Droplets',
      time: '07:00',
      durationMinutes: 15,
      streak: 12,
      completed: false,
    },
    {
      id: 'habit-02',
      type: 'habit',
      phase: 'bedtime',
      habitId: 'habit-02',
      title: 'Digital Screen Curfew',
      icon: 'Moon',
      time: '21:30',
      durationMinutes: 15,
      streak: 9,
      completed: true,
    },
  ]

  const mockTasks: ScheduleEntry[] = [
    {
      id: 'task-entry-01',
      time: '09:00',
      title: 'Deep Architecture Focus',
      meta: 'High Priority',
      durationMinutes: 90,
      tone: 'accent',
      taskId: 'task-101',
    },
  ]

  it('renders scheduled habits alongside tasks with icon, time, and streak badge (AC-001)', async () => {
    const { html } = await renderTimeline({
      entries: mockTasks,
      habits: mockHabits,
    })

    // Habit titles
    expect(html).toContain('Morning Sunlight')
    expect(html).toContain('Digital Screen Curfew')

    // Scheduled times
    expect(html).toContain('07:00')
    expect(html).toContain('21:30')
    expect(html).toContain('09:00')

    // Streak badges (AC-001)
    expect(html).toContain('🔥 12d')
    expect(html).toContain('🔥 9d')

    // Task title
    expect(html).toContain('Deep Architecture Focus')
  })

  it('renders 1-tap completion toggle button and completed styling (AC-001, AC-002, AC-003)', async () => {
    const { html } = await renderTimeline({
      entries: [],
      habits: mockHabits,
    })

    // Contains interactive habit toggle buttons
    expect(html).toContain('habit-toggle')
    expect(html).toContain('aria-label="Mark habit as complete"')
    expect(html).toContain('aria-label="Mark habit as incomplete"')

    // Completed habit gets strikethrough/completed class and checked state
    expect(html).toContain('checked')
    expect(html).toContain('entry-habit completed')
  })

  it('triggers scheduleStore.toggleHabit on habit toggle (AC-002, AC-003)', async () => {
    const pinia = createPinia()
    setActivePinia(pinia)
    const store = useScheduleStore()
    store.graph = createMockScheduleGraph()

    const habit = store.nodes.find((n) => n.id === 'habit-curfew')!
    expect(habit.completed).toBe(false)
    const initialStreak = habit.streak ?? 0

    // Toggle to completed
    await store.toggleHabit('habit-curfew')
    expect(habit.completed).toBe(true)
    expect(habit.streak).toBe(initialStreak + 1)

    // Toggle again (unchecking)
    await store.toggleHabit('habit-curfew')
    expect(habit.completed).toBe(false)
    expect(habit.streak).toBe(initialStreak)
  })

  it('renders EmptyState when neither tasks nor habits are scheduled', async () => {
    const { html } = await renderTimeline({
      entries: [],
      habits: [],
    })

    expect(html).toContain('Nothing scheduled')
    expect(html).toContain('Plan tasks and habits into time blocks')
  })

  it('sorts timeline items chronologically', async () => {
    const { html } = await renderTimeline({
      entries: mockTasks, // 09:00
      habits: mockHabits, // 07:00, 21:30
    })

    const idx0700 = html.indexOf('07:00')
    const idx0900 = html.indexOf('09:00')
    const idx2130 = html.indexOf('21:30')

    expect(idx0700).toBeLessThan(idx0900)
    expect(idx0900).toBeLessThan(idx2130)
  })
})
