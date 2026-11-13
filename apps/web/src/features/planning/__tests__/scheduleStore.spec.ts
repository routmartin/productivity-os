import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { scheduleApi } from '../scheduleApi'
import { createMockScheduleGraph, useScheduleStore } from '../scheduleStore'
import type { ScheduleNode, SchedulePhaseId, UpdateStepPayload } from '../types'

describe('scheduleStore - updateStep', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.restoreAllMocks()
  })

  it('updates step fields and persists to backend via scheduleApi.updateStep (AC-010)', async () => {
    const store = useScheduleStore()
    store.graph = createMockScheduleGraph()

    const updatedNodeMock: ScheduleNode = {
      id: 'task-top1',
      type: 'task',
      phase: 'deep-focus',
      title: 'Architect Secure Auth Core',
      subtitle: 'Updated Subtitle',
      time: '09:45',
      durationMinutes: 120,
      totalMinutes: 120,
      notes: 'New protocol notes',
      order: 6,
    }

    const apiSpy = vi
      .spyOn(scheduleApi, 'updateStep')
      .mockResolvedValueOnce(updatedNodeMock)

    const payload: UpdateStepPayload = {
      title: 'Architect Secure Auth Core',
      subtitle: 'Updated Subtitle',
      timeSlot: '09:45',
      durationMinutes: 120,
      notes: 'New protocol notes',
    }

    const result = await store.updateStep('task-top1', payload)

    expect(apiSpy).toHaveBeenCalledTimes(1)
    expect(apiSpy).toHaveBeenCalledWith(
      'task-top1',
      expect.objectContaining({
        title: 'Architect Secure Auth Core',
        subtitle: 'Updated Subtitle',
        timeSlot: '09:45',
        durationMinutes: 120,
        notes: 'New protocol notes',
      }),
    )

    expect(result.title).toBe('Architect Secure Auth Core')
    expect(result.subtitle).toBe('Updated Subtitle')
    expect(result.time).toBe('09:45')
    expect(result.durationMinutes).toBe(120)
    expect(result.notes).toBe('New protocol notes')

    const nodeInStore = store.nodes.find((n) => n.id === 'task-top1')
    expect(nodeInStore?.title).toBe('Architect Secure Auth Core')
    expect(nodeInStore?.durationMinutes).toBe(120)
  })

  it('dynamically rewires edges when node phase is reassigned (AC-012)', async () => {
    const store = useScheduleStore()
    store.graph = createMockScheduleGraph()

    vi.spyOn(scheduleApi, 'updateStep').mockImplementation(async (_id, payload) => {
      const existing = store.nodes.find((n) => n.id === 'task-top1')!
      return {
        ...existing,
        title: payload.title,
        phase: (payload.phase as SchedulePhaseId) ?? existing.phase,
      }
    })

    const initialNode = store.nodes.find((n) => n.id === 'task-top1')!
    expect(initialNode.phase).toBe('deep-focus')

    // Reassign task-top1 to afternoon phase
    await store.updateStep('task-top1', {
      title: initialNode.title,
      phase: 'afternoon',
    })

    const movedNode = store.nodes.find((n) => n.id === 'task-top1')!
    expect(movedNode.phase).toBe('afternoon')

    // Verify topological sequence: all edges cleanly connect consecutive nodes without orphan edges
    for (let i = 0; i < store.nodes.length - 1; i++) {
      const fromNode = store.nodes[i]
      const toNode = store.nodes[i + 1]

      const edge = store.edges.find(
        (e) => e.fromNodeId === fromNode.id && e.toNodeId === toNode.id,
      )
      expect(edge).toBeDefined()

      if (fromNode.phase !== toNode.phase) {
        expect(edge?.type).toBe('phase')
      } else if (fromNode.type === 'habit' && toNode.type === 'habit') {
        expect(edge?.type).toBe('prerequisite')
      } else {
        expect(edge?.type).toBe('sequential')
      }
    }

    // Verify no orphan edges point to non-existent nodes
    const nodeIds = new Set(store.nodes.map((n) => n.id))
    for (const edge of store.edges) {
      expect(nodeIds.has(edge.fromNodeId)).toBe(true)
      expect(nodeIds.has(edge.toNodeId)).toBe(true)
    }
  })

  it('recalculates bedtime projection when activity duration increases (AC-004, AC-010)', async () => {
    const store = useScheduleStore()
    store.graph = createMockScheduleGraph()

    vi.spyOn(scheduleApi, 'updateStep').mockImplementation(async (_id, payload) => {
      const existing = store.nodes.find((n) => n.id === 'task-top1')!
      return {
        ...existing,
        title: payload.title,
        durationMinutes: payload.durationMinutes ?? existing.durationMinutes,
      }
    })

    const initialOverflow = store.overflowMinutes
    expect(initialOverflow).toBe(45)
    expect(store.projectedBedtime).toBe('23:15')

    // Increase duration from 90 to 150 (+60 minutes)
    await store.updateStep('task-top1', {
      title: 'Finish authentication architecture',
      durationMinutes: 150,
    })

    expect(store.overflowMinutes).toBe(initialOverflow + 60)
    expect(store.projectedBedtime).toBe('00:15')

    const bedtimeAnchor = store.bedtimeAnchor
    expect(bedtimeAnchor?.overflowMinutes).toBe(initialOverflow + 60)
    expect(bedtimeAnchor?.projectedTime).toBe('00:15')
  })

  it('protects anchor nodes from being updated and rejects edit actions (AC-011)', async () => {
    const store = useScheduleStore()
    store.graph = createMockScheduleGraph()

    const apiSpy = vi.spyOn(scheduleApi, 'updateStep')

    const originalWake = { ...store.wakeAnchor! }

    await expect(
      store.updateStep('anchor-wake', {
        title: 'Tampered Wake Title',
        timeSlot: '08:00',
      }),
    ).rejects.toThrow('Anchor node update is not allowed')

    expect(apiSpy).not.toHaveBeenCalled()
    expect(store.wakeAnchor?.title).toBe(originalWake.title)
    expect(store.wakeAnchor?.time).toBe(originalWake.time)

    const originalBedtime = { ...store.bedtimeAnchor! }

    await expect(
      store.updateStep('anchor-bedtime', {
        title: 'Tampered Bedtime',
      }),
    ).rejects.toThrow('Anchor node update is not allowed')

    expect(apiSpy).not.toHaveBeenCalled()
    expect(store.bedtimeAnchor?.title).toBe(originalBedtime.title)
  })

  it('rolls back optimistic modifications if backend updateStep fails (AC-C03)', async () => {
    const store = useScheduleStore()
    store.graph = createMockScheduleGraph()

    const initialNode = JSON.parse(
      JSON.stringify(store.nodes.find((n) => n.id === 'task-top1')),
    )
    const initialEdges = JSON.parse(JSON.stringify(store.edges))

    vi.spyOn(scheduleApi, 'updateStep').mockRejectedValueOnce(
      new Error('500 Internal Server Error'),
    )

    await expect(
      store.updateStep('task-top1', {
        title: 'New Failed Title',
        phase: 'afternoon',
        durationMinutes: 200,
      }),
    ).rejects.toThrow('500 Internal Server Error')

    // State must be completely restored to pre-mutation snapshot
    const rolledBackNode = store.nodes.find((n) => n.id === 'task-top1')!
    expect(rolledBackNode.title).toBe(initialNode.title)
    expect(rolledBackNode.phase).toBe(initialNode.phase)
    expect(rolledBackNode.durationMinutes).toBe(initialNode.durationMinutes)
    expect(store.edges).toEqual(initialEdges)
    expect(store.errorMessage).toBe('500 Internal Server Error')
  })

  it('throws an error if attempting to update a non-existent step id', async () => {
    const store = useScheduleStore()
    store.graph = createMockScheduleGraph()

    await expect(
      store.updateStep('non-existent-step-id', {
        title: 'Missing Node',
      }),
    ).rejects.toThrow('Schedule node not found: non-existent-step-id')
  })
})

describe('scheduleStore - toggleHabit', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.restoreAllMocks()
  })

  it('optimistically marks pending habit as completed and increments streak (AC-002)', async () => {
    const store = useScheduleStore()
    store.graph = createMockScheduleGraph()

    const habit = store.nodes.find((n) => n.id === 'habit-curfew')!
    expect(habit.completed).toBe(false)
    const prevStreak = habit.streak ?? 0

    await store.toggleHabit('habit-curfew')

    expect(habit.completed).toBe(true)
    expect(habit.streak).toBe(prevStreak + 1)
  })

  it('optimistically unchecks completed habit and decrements streak (AC-003)', async () => {
    const store = useScheduleStore()
    store.graph = createMockScheduleGraph()

    const habit = store.nodes.find((n) => n.id === 'habit-hydration')!
    expect(habit.completed).toBe(true)
    const prevStreak = habit.streak ?? 12

    await store.toggleHabit('habit-hydration')

    expect(habit.completed).toBe(false)
    expect(habit.streak).toBe(prevStreak - 1)
  })

  it('recalculates bedtime projection and overflow on habit toggle (AC-004)', async () => {
    const store = useScheduleStore()
    store.graph = createMockScheduleGraph()

    // Completing pending habits shrinks overflow
    const prevOverflow = store.overflowMinutes
    await store.toggleHabit('habit-curfew')
    await store.toggleHabit('habit-journal')
    await store.toggleHabit('habit-winddown')

    expect(store.overflowMinutes).toBeLessThanOrEqual(prevOverflow)
  })

  it('rolls back optimistic state on backend toggle failure (AC-005)', async () => {
    const store = useScheduleStore()
    store.graph = createMockScheduleGraph()

    // Assign a valid UUID so real mode triggers server call
    const habit = store.nodes.find((n) => n.id === 'habit-hydration')!
    habit.habitId = '11111111-1111-1111-1111-111111111111'

    const prevCompleted = habit.completed
    const prevStreak = habit.streak
    const prevBedtime = store.projectedBedtime

    vi.spyOn(scheduleApi, 'toggleHabit').mockRejectedValueOnce(
      new Error('500 Internal Server Error'),
    )

    await store.toggleHabit('habit-hydration')

    // Expect rollback to snapshot
    expect(habit.completed).toBe(prevCompleted)
    expect(habit.streak).toBe(prevStreak)
    expect(store.projectedBedtime).toBe(prevBedtime)
    expect(store.errorMessage).toContain('500 Internal Server Error')
  })
})
