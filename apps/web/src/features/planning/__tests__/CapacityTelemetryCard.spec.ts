import { createPinia, setActivePinia } from 'pinia'
import { describe, expect, it } from 'vitest'
import { createSSRApp, defineComponent, h } from 'vue'
import { renderToString } from 'vue/server-renderer'

import CapacityTelemetryCard from '../components/CapacityTelemetryCard.vue'

const RouterLinkMock = defineComponent({
  name: 'RouterLink',
  props: ['to'],
  template: '<a><slot /></a>',
})

async function renderCard(props: Record<string, unknown> = {}) {
  const pinia = createPinia()
  setActivePinia(pinia)
  const app = createSSRApp({
    render: () => h(CapacityTelemetryCard, props),
  })
  app.use(pinia)
  app.component('RouterLink', RouterLinkMock)
  const html = await renderToString(app)
  return { html, pinia }
}

describe('CapacityTelemetryCard', () => {
  it('renders capacity ratio and remaining buffer correctly (AC-010)', async () => {
    // Given plannedMinutes = 270 (4.5h) and focusCapacityMinutes = 360 (6.0h)
    const { html } = await renderCard({
      plannedMinutes: 270,
      capacityMinutes: 360,
      overflowMinutes: 0,
      targetBedtime: '22:30',
      projectedBedtime: '22:30',
      completedHabitsCount: 3,
      totalHabitsCount: 5,
    })

    // Ratio display
    expect(html).toContain('4.5h / 6.0h planned')
    // Buffer badge
    expect(html).toContain('+1.5h buffer remaining')
    expect(html).toContain('tone-success')
    // 75% fill
    expect(html).toContain('width:75%')
    expect(html).toContain('aria-valuenow="75"')
  })

  it('renders over-capacity warning state when planned exceeds capacity (AC-011)', async () => {
    // Given plannedMinutes = 420 (7.0h) exceeds focusCapacityMinutes = 360 (6.0h) -> 60m over
    const { html } = await renderCard({
      plannedMinutes: 420,
      capacityMinutes: 360,
      overflowMinutes: 0,
    })

    expect(html).toContain('7.0h / 6.0h planned')
    expect(html).toContain('Over capacity by 60m')
    expect(html).toContain('tone-warning')
    expect(html).toContain('fill-warning')
  })

  it('renders bedtime trajectory with overflow warning delay (AC-012)', async () => {
    // Given targetBedtime = 22:30 and overflowMinutes = 45 -> 23:15 projected
    const { html } = await renderCard({
      plannedMinutes: 300,
      capacityMinutes: 360,
      targetBedtime: '22:30',
      projectedBedtime: '23:15',
      overflowMinutes: 45,
    })

    expect(html).toContain('Bedtime shifts by +45m to 23:15')
    expect(html).toContain('tone-warning')
    expect(html).toContain('Target 22:30 · Projected 23:15')
    expect(html).toContain('(+45m)')
  })

  it('renders on-track bedtime message when there is no overflow (AC-012)', async () => {
    const { html } = await renderCard({
      plannedMinutes: 300,
      capacityMinutes: 360,
      targetBedtime: '22:30',
      projectedBedtime: '22:30',
      overflowMinutes: 0,
    })

    expect(html).toContain('✓ On track for 22:30 bedtime')
    expect(html).toContain('tone-success')
  })

  it('renders habit completion ratio cleanly', async () => {
    const { html } = await renderCard({
      completedHabitsCount: 3,
      totalHabitsCount: 5,
    })

    expect(html).toContain('3 of 5 habits completed')
  })

  it('renders fallback when no habits are scheduled', async () => {
    const { html } = await renderCard({
      totalHabitsCount: 0,
    })

    expect(html).toContain('No daily habits scheduled')
  })
})
