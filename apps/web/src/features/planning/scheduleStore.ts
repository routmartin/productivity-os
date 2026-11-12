import { defineStore } from 'pinia'
import { computed, ref } from 'vue'

import { todayISODate } from './api'
import { scheduleApi } from './scheduleApi'
import type {
  AddStepPayload,
  HabitStreakDay,
  PreviewState,
  ScheduleEdge,
  ScheduleEdgeType,
  ScheduleGraph,
  ScheduleLayoutMode,
  ScheduleNode,
  SchedulePhase,
  SchedulePhaseId,
  UpdateStepPayload,
} from './types'

const STORAGE_KEY = 'productivity-os:schedule-layout'

function isUuid(id: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)
}

function getSavedLayout(): ScheduleLayoutMode {
  if (typeof window === 'undefined') return 'spine'
  const saved = localStorage.getItem(STORAGE_KEY)
  if (saved === 'spine' || saved === 'journey' || saved === 'matrix') {
    return saved
  }
  return 'spine'
}

function generateHistory(streakDays: number): HabitStreakDay[] {
  const days: HabitStreakDay[] = []
  const today = new Date()
  for (let i = 13; i >= 0; i--) {
    const d = new Date(today)
    d.setDate(today.getDate() - i)
    const dateStr = d.toISOString().slice(0, 10)
    // Mark completed if within the streak count (relative to past days)
    const completed = i < streakDays
    days.push({ date: dateStr, completed })
  }
  return days
}

export function createMockScheduleGraph(): ScheduleGraph {
  const phases: SchedulePhase[] = [
    {
      id: 'morning',
      title: 'Morning Activation',
      subtitle: 'Rise, hydrate, move & set daily direction',
      timeRange: '06:30 – 09:00',
      colorTone: 'warning',
    },
    {
      id: 'deep-focus',
      title: 'Deep Focus Work',
      subtitle: 'Uninterrupted creative flow on Daily Top 1 & Top 2',
      timeRange: '09:00 – 12:30',
      colorTone: 'accent',
    },
    {
      id: 'afternoon',
      title: 'Afternoon Momentum',
      subtitle: 'Top 3, collaboration, shallow work & reset',
      timeRange: '12:30 – 18:00',
      colorTone: 'blue',
    },
    {
      id: 'bedtime',
      title: 'Bedtime Sanctuary',
      subtitle: 'Digital curfew, reflection, reading & sleep recovery',
      timeRange: '21:00 – 22:30',
      colorTone: 'success',
    },
  ]

  const nodes: ScheduleNode[] = [
    // Morning Phase
    {
      id: 'anchor-wake',
      type: 'anchor',
      phase: 'morning',
      anchorKind: 'wake',
      title: 'Wake Up & Natural Sunlight',
      subtitle: 'Anchor routine to reset circadian clock',
      time: '06:30',
      targetTime: '06:30',
      durationMinutes: 15,
      order: 1,
      notes: 'Get 10 minutes of direct sunlight outdoors within 30 minutes of waking.',
    },
    {
      id: 'habit-hydration',
      type: 'habit',
      phase: 'morning',
      habitId: 'habit-hydration',
      title: '500ml Mineral Water & Salts',
      subtitle: 'Rehydrate brain and kickstart metabolism',
      icon: 'Droplets',
      time: '06:45',
      durationMinutes: 15,
      streak: 12,
      completed: true,
      frequency: 'Daily · Morning Stack',
      history: generateHistory(12),
      order: 2,
      notes: 'Filtered water with a pinch of Himalayan pink salt and lemon.',
    },
    {
      id: 'habit-workout',
      type: 'habit',
      phase: 'morning',
      habitId: 'habit-workout',
      title: 'Zone 2 Cardio & Mobility',
      subtitle: 'Light jog or bodyweight mobility flow',
      icon: 'Dumbbell',
      time: '07:00',
      durationMinutes: 45,
      streak: 8,
      completed: true,
      frequency: 'Daily · Morning Stack',
      history: generateHistory(8),
      order: 3,
      notes: 'Elevate heart rate to 125-135 bpm for mitochondrial health.',
    },
    {
      id: 'habit-cold-shower',
      type: 'habit',
      phase: 'morning',
      habitId: 'habit-cold-shower',
      title: 'Cold Rinse & Grooming',
      subtitle: 'Dopamine surge and alertness spike',
      icon: 'Droplets',
      time: '07:45',
      durationMinutes: 15,
      streak: 5,
      completed: true,
      frequency: 'Daily · Morning Stack',
      history: generateHistory(5),
      order: 4,
      notes: '2 minutes cold finish to boost norepinephrine.',
    },
    {
      id: 'habit-planning',
      type: 'habit',
      phase: 'morning',
      habitId: 'habit-planning',
      title: 'Daily Top 3 Planning & Intent',
      subtitle: 'Review priorities and calibrate focus blocks',
      icon: 'Target',
      time: '08:15',
      durationMinutes: 30,
      streak: 14,
      completed: true,
      frequency: 'Daily · Morning Stack',
      history: generateHistory(14),
      order: 5,
      notes: 'Lock in Daily Top 3 and silence notification channels.',
    },

    // Deep Focus Phase
    {
      id: 'task-top1',
      type: 'task',
      phase: 'deep-focus',
      taskId: 'task-01',
      title: 'Finish authentication architecture',
      subtitle: 'Top 1 Priority · Core Security & JWT flow',
      time: '09:00',
      durationMinutes: 90,
      priority: 'HIGH',
      inFocus: false,
      completedMinutes: 0,
      totalMinutes: 90,
      projectName: 'Productivity OS',
      order: 6,
      notes: 'Implement refresh tokens, user isolation tests, and session revocation.',
    },
    {
      id: 'recharge-pause',
      type: 'recharge',
      phase: 'deep-focus',
      rechargeKind: 'walk',
      title: 'Eye Rest & Hydration Walk',
      subtitle: 'Disengage focus network and look at distance',
      time: '10:30',
      durationMinutes: 15,
      order: 7,
      notes: 'Step away from screen. Look at horizon to relax ciliary eye muscles.',
    },
    {
      id: 'task-top2',
      type: 'task',
      phase: 'deep-focus',
      taskId: 'task-02',
      title: 'Build task dashboard layout',
      subtitle: 'Top 2 Priority · Kanban & List hybrid',
      time: '10:45',
      durationMinutes: 75,
      priority: 'HIGH',
      inFocus: false,
      completedMinutes: 0,
      totalMinutes: 75,
      projectName: 'Productivity OS',
      order: 8,
      notes: 'Desktop 1600px responsive grid with priority column drag-drop.',
    },

    // Afternoon Phase
    {
      id: 'recharge-lunch',
      type: 'recharge',
      phase: 'afternoon',
      rechargeKind: 'nutrition',
      title: 'Nutritious Lunch & Outdoor Walk',
      subtitle: 'Balanced protein + low glycemic index carbs',
      time: '12:00',
      durationMinutes: 60,
      order: 9,
      notes: 'Avoid heavy sugars to prevent post-lunch sluggishness.',
    },
    {
      id: 'task-top3',
      type: 'task',
      phase: 'afternoon',
      taskId: 'task-03',
      title: 'Review API implementation',
      subtitle: 'Top 3 Priority · Verification & OpenAPI docs',
      time: '13:00',
      durationMinutes: 60,
      priority: 'MEDIUM',
      inFocus: false,
      completedMinutes: 0,
      totalMinutes: 60,
      projectName: 'Productivity OS',
      order: 10,
      notes: 'Review error schemas, DTOs, and test coverage on PR #42.',
    },
    {
      id: 'task-shallow',
      type: 'task',
      phase: 'afternoon',
      taskId: 'task-05',
      title: 'Write documentation & Team Sync',
      subtitle: 'Low cognitive load · Clean inbox & sync updates',
      time: '14:00',
      durationMinutes: 60,
      priority: 'LOW',
      inFocus: false,
      completedMinutes: 0,
      totalMinutes: 60,
      projectName: 'Productivity OS',
      order: 11,
      notes: 'Update README architecture diagrams and respond to team RFC comments.',
    },
    {
      id: 'habit-afternoon-walk',
      type: 'habit',
      phase: 'afternoon',
      habitId: 'habit-afternoon-walk',
      title: 'Afternoon Sunset Stride',
      subtitle: 'Evening light cues to initiate melatonin onset',
      icon: 'Footprints',
      time: '16:00',
      durationMinutes: 30,
      streak: 4,
      completed: false,
      frequency: 'Daily · Afternoon Stack',
      history: generateHistory(4),
      order: 12,
      notes: '20-30 min brisk walk outdoors during golden hour.',
    },

    // Bedtime Sanctuary Phase
    {
      id: 'habit-curfew',
      type: 'habit',
      phase: 'bedtime',
      habitId: 'habit-curfew',
      title: 'Digital Screen Curfew',
      subtitle: 'Turn off blue light displays and dock phone away from bed',
      icon: 'Moon',
      time: '21:00',
      durationMinutes: 15,
      streak: 9,
      completed: false,
      frequency: 'Daily · Bedtime Stack',
      history: generateHistory(9),
      order: 13,
      notes: 'All screens off. Night lighting turned to warm amber dim mode.',
    },
    {
      id: 'habit-journal',
      type: 'habit',
      phase: 'bedtime',
      habitId: 'habit-journal',
      title: 'Evening Reflection & Fiction Reading',
      subtitle: '3 wins of the day, brain dump & analog paper book',
      icon: 'BookOpen',
      time: '21:30',
      durationMinutes: 30,
      streak: 21,
      completed: false,
      frequency: 'Daily · Bedtime Stack',
      history: generateHistory(21),
      order: 14,
      notes: 'Write 3 wins in physical notebook, read 15-20 pages fiction.',
    },
    {
      id: 'habit-winddown',
      type: 'habit',
      phase: 'bedtime',
      habitId: 'habit-winddown',
      title: 'Chamomile Tea & 4-7-8 Breathing',
      subtitle: 'Down-regulate central nervous system',
      icon: 'Coffee',
      time: '22:00',
      durationMinutes: 15,
      streak: 11,
      completed: false,
      frequency: 'Daily · Bedtime Stack',
      history: generateHistory(11),
      order: 15,
      notes: 'Warm herbal tea, 5 minutes 4-7-8 parasympathetic breathing.',
    },
    {
      id: 'anchor-bedtime',
      type: 'anchor',
      phase: 'bedtime',
      anchorKind: 'bedtime',
      title: 'Sleep Target & Bedtime Terminus',
      subtitle: 'Target 22:30 · 8h Recovery Sleep Target',
      time: '22:30',
      targetTime: '22:30',
      projectedTime: '23:15',
      overflowMinutes: 45,
      durationMinutes: 480,
      order: 16,
      notes: 'Room temperature 18°C, total blackout, earplugs ready.',
    },
  ]

  const edges: ScheduleEdge[] = [
    // Morning Stack
    { id: 'e-wake-hydro', fromNodeId: 'anchor-wake', toNodeId: 'habit-hydration', type: 'sequential', active: true },
    { id: 'e-hydro-workout', fromNodeId: 'habit-hydration', toNodeId: 'habit-workout', type: 'prerequisite', active: true },
    { id: 'e-workout-shower', fromNodeId: 'habit-workout', toNodeId: 'habit-cold-shower', type: 'prerequisite', active: true },
    { id: 'e-shower-plan', fromNodeId: 'habit-cold-shower', toNodeId: 'habit-planning', type: 'prerequisite', active: true },
    { id: 'e-plan-top1', fromNodeId: 'habit-planning', toNodeId: 'task-top1', type: 'phase', active: true },

    // Deep Focus
    { id: 'e-top1-pause', fromNodeId: 'task-top1', toNodeId: 'recharge-pause', type: 'sequential', active: false },
    { id: 'e-pause-top2', fromNodeId: 'recharge-pause', toNodeId: 'task-top2', type: 'sequential', active: false },
    { id: 'e-top2-lunch', fromNodeId: 'task-top2', toNodeId: 'recharge-lunch', type: 'phase', active: false },

    // Afternoon Momentum
    { id: 'e-lunch-top3', fromNodeId: 'recharge-lunch', toNodeId: 'task-top3', type: 'sequential', active: false },
    { id: 'e-top3-shallow', fromNodeId: 'task-top3', toNodeId: 'task-shallow', type: 'sequential', active: false },
    { id: 'e-shallow-walk', fromNodeId: 'task-shallow', toNodeId: 'habit-afternoon-walk', type: 'prerequisite', active: false },
    { id: 'e-walk-curfew', fromNodeId: 'habit-afternoon-walk', toNodeId: 'habit-curfew', type: 'phase', active: false },

    // Bedtime Sanctuary
    { id: 'e-curfew-journal', fromNodeId: 'habit-curfew', toNodeId: 'habit-journal', type: 'prerequisite', active: false },
    { id: 'e-journal-tea', fromNodeId: 'habit-journal', toNodeId: 'habit-winddown', type: 'prerequisite', active: false },
    { id: 'e-tea-bed', fromNodeId: 'habit-winddown', toNodeId: 'anchor-bedtime', type: 'sequential', active: false },
  ]

  return {
    date: new Date().toISOString().slice(0, 10),
    wakeTime: '06:30',
    targetBedtime: '22:30',
    projectedBedtime: '23:15',
    overflowMinutes: 45,
    phases,
    nodes,
    edges,
  }
}

export const useScheduleStore = defineStore('schedule', () => {
  const status = ref<'idle' | 'loading' | 'ready' | 'error' | 'empty'>('idle')
  const graph = ref<ScheduleGraph | null>(null)
  const activeLayout = ref<ScheduleLayoutMode>(getSavedLayout())
  const selectedNodeId = ref<string | null>(null)
  const activeTaskId = ref<string | null>(null)
  const errorMessage = ref<string | null>(null)
  const previewMode = ref<PreviewState>(null)

  // Getters
  const nodes = computed(() => graph.value?.nodes ?? [])
  const edges = computed(() => graph.value?.edges ?? [])
  const phases = computed(() => graph.value?.phases ?? [])

  const selectedNode = computed<ScheduleNode | null>(() => {
    if (!selectedNodeId.value || !graph.value) return null
    return graph.value.nodes.find((n) => n.id === selectedNodeId.value) ?? null
  })

  const habitNodes = computed(() => nodes.value.filter((n) => n.type === 'habit'))
  const taskNodes = computed(() => nodes.value.filter((n) => n.type === 'task'))

  const completedHabitsCount = computed(() => habitNodes.value.filter((h) => h.completed).length)
  const totalHabitsCount = computed(() => habitNodes.value.length)

  const habitProgressPercent = computed(() => {
    if (totalHabitsCount.value === 0) return 0
    return Math.round((completedHabitsCount.value / totalHabitsCount.value) * 100)
  })

  const wakeAnchor = computed(() =>
    nodes.value.find((n) => n.type === 'anchor' && n.anchorKind === 'wake'),
  )

  const bedtimeAnchor = computed(() =>
    nodes.value.find((n) => n.type === 'anchor' && n.anchorKind === 'bedtime'),
  )

  const overflowMinutes = computed(() => graph.value?.overflowMinutes ?? 0)
  const isOverflowing = computed(() => overflowMinutes.value > 0)
  const projectedBedtime = computed(() => graph.value?.projectedBedtime ?? '22:30')
  const targetBedtime = computed(() => graph.value?.targetBedtime ?? '22:30')

  const bedtimeStatusMessage = computed(() => {
    if (isOverflowing.value) {
      return `Schedule overflow: Bedtime shifts by ${overflowMinutes.value}m`
    }
    return `On track for ${targetBedtime.value} bedtime`
  })

  // Dynamic Bedtime Projection Engine (Spec AC-004)
  function recalculateBedtime(): void {
    if (!graph.value) return

    // Count pending habits and incomplete tasks
    const pendingHabits = habitNodes.value.filter((h) => !h.completed).length
    const incompleteTasks = taskNodes.value.filter((t) => (t.completedMinutes ?? 0) < (t.totalMinutes ?? 60)).length

    // In the sample day, base overflow is 45m if afternoon/evening pending
    // As items complete, overflow shrinks proportionally
    let baseOverflow = 0
    if (pendingHabits > 0 || incompleteTasks > 0) {
      // 15m per pending habit/task up to max 45m
      baseOverflow = Math.min(45, (pendingHabits + incompleteTasks) * 15)
    }

    // Additional duration overflow beyond standard 285m total planned task time (if any)
    const totalTaskMinutes = taskNodes.value.reduce(
      (sum, t) => sum + (t.durationMinutes ?? t.totalMinutes ?? 60),
      0,
    )
    const durationDelta = Math.max(0, totalTaskMinutes - 285)

    const newOverflow = baseOverflow + durationDelta

    graph.value.overflowMinutes = newOverflow

    // Calculate projected time from 22:30 target
    const [targetHour, targetMinute] = targetBedtime.value.split(':').map(Number)
    const totalMinutes = targetHour * 60 + targetMinute + newOverflow
    const projectedHour = Math.floor(totalMinutes / 60) % 24
    const projectedMinute = totalMinutes % 60
    const pad = (n: number) => String(n).padStart(2, '0')
    const calculatedProjected = `${pad(projectedHour)}:${pad(projectedMinute)}`

    graph.value.projectedBedtime = calculatedProjected

    // Update bedtime anchor node
    const bedtime = nodes.value.find((n) => n.type === 'anchor' && n.anchorKind === 'bedtime')
    if (bedtime) {
      bedtime.overflowMinutes = newOverflow
      bedtime.projectedTime = calculatedProjected
    }
  }

  // Actions
  function setLayout(mode: ScheduleLayoutMode): void {
    activeLayout.value = mode
    if (typeof window !== 'undefined') {
      try {
        localStorage.setItem(STORAGE_KEY, mode)
      } catch {
        // Ignore storage write issues
      }
    }
  }

  function selectNode(nodeId: string | null): void {
    selectedNodeId.value = nodeId
  }

  // Habit Stacking and Edge Illumination (Spec AC-002, AC-005, Plan AC-C02, AC-C03)
  async function toggleHabit(nodeIdOrHabitId: string): Promise<void> {
    if (!graph.value) return
    const habit = graph.value.nodes.find(
      (n) => n.id === nodeIdOrHabitId || n.habitId === nodeIdOrHabitId,
    )
    if (!habit || habit.type !== 'habit') return

    errorMessage.value = null

    // 1. Snapshot previous state for optimistic rollback
    const prevCompleted = habit.completed
    const prevStreak = habit.streak
    const prevHistory = habit.history ? JSON.parse(JSON.stringify(habit.history)) : undefined
    const prevEdges = JSON.parse(JSON.stringify(graph.value.edges))
    const prevOverflow = graph.value.overflowMinutes
    const prevProjectedBedtime = graph.value.projectedBedtime

    // 2. Optimistic local mutation
    const nextCompleted = !habit.completed
    habit.completed = nextCompleted

    // Adjust streak
    const currentStreak = habit.streak ?? 0
    habit.streak = nextCompleted ? currentStreak + 1 : Math.max(0, currentStreak - 1)

    // Update today's entry in history
    if (habit.history && habit.history.length > 0) {
      const todayEntry = habit.history[habit.history.length - 1]
      if (todayEntry) {
        todayEntry.completed = nextCompleted
      }
    }

    // Light up outgoing edges (Spec AC-005)
    graph.value.edges.forEach((edge) => {
      if (edge.fromNodeId === habit.id) {
        edge.active = nextCompleted
      }
    })

    recalculateBedtime()

    // In preview mode or if habit has no valid UUID (legacy mock data), keep local simulation
    const targetHabitId = habit.habitId ?? habit.id
    if (previewMode.value !== null || !isUuid(targetHabitId)) {
      return
    }

    // 3. Authoritative server sync
    try {
      const response = await scheduleApi.toggleHabit(targetHabitId, {
        date: graph.value.date,
      })

      habit.completed = response.completed
      habit.streak = response.streak
      habit.history = response.history
      graph.value.overflowMinutes = response.overflowMinutes
      graph.value.projectedBedtime = response.projectedBedtime

      if (response.updatedEdges && response.updatedEdges.length > 0) {
        response.updatedEdges.forEach((updatedEdge) => {
          const edgeIndex = graph.value!.edges.findIndex(
            (e) =>
              e.id === updatedEdge.id ||
              (e.fromNodeId === updatedEdge.fromNodeId && e.toNodeId === updatedEdge.toNodeId),
          )
          if (edgeIndex !== -1) {
            graph.value!.edges[edgeIndex] = {
              ...graph.value!.edges[edgeIndex],
              ...updatedEdge,
            }
          }
        })
      }

      const bedtime = graph.value.nodes.find(
        (n) => n.type === 'anchor' && n.anchorKind === 'bedtime',
      )
      if (bedtime) {
        bedtime.overflowMinutes = response.overflowMinutes
        bedtime.projectedTime = response.projectedBedtime
      }
    } catch (err) {
      // 4. Rollback to snapshot on network / server failure (AC-C03)
      habit.completed = prevCompleted
      habit.streak = prevStreak
      habit.history = prevHistory
      graph.value.edges = prevEdges
      graph.value.overflowMinutes = prevOverflow
      graph.value.projectedBedtime = prevProjectedBedtime

      recalculateBedtime()

      errorMessage.value =
        err instanceof Error ? err.message : 'Network failure toggling habit. Changes rolled back.'
      console.error('Failed to sync habit toggle with server:', err)
    }
  }

  // Native Activity Execution State (Autonomous to Schedule)
  function startFocus(nodeIdOrTaskId: string): void {
    if (!graph.value) return

    // Mark active in graph natively without external store coupling
    graph.value.nodes.forEach((node) => {
      if (node.type === 'task') {
        node.inFocus = node.id === nodeIdOrTaskId || node.taskId === nodeIdOrTaskId
      }
    })
    activeTaskId.value = nodeIdOrTaskId
  }

  function stopFocus(): void {
    if (!graph.value) return
    graph.value.nodes.forEach((node) => {
      if (node.type === 'task') {
        node.inFocus = false
      }
    })
    activeTaskId.value = null
  }

  // Schedule Creation & Blueprint Engine (Spec AC-007, Plan AC-C04)
  async function addStep(payload: AddStepPayload): Promise<ScheduleNode> {
    if (!graph.value) {
      graph.value = createMockScheduleGraph()
    }

    const rawPhase = payload.phaseId.toLowerCase()
    const targetPhase: SchedulePhaseId =
      rawPhase === 'evening' ? 'bedtime' : (rawPhase as SchedulePhaseId)

    const duration =
      payload.totalMinutes ??
      (payload.type === 'habit' ? 15 : payload.type === 'recharge' ? 15 : 60)

    let newNode: ScheduleNode

    if (previewMode.value !== null) {
      const id = `node-${Date.now()}`
      newNode = {
        id,
        type: payload.type,
        phase: targetPhase,
        title: payload.title.trim(),
        subtitle: payload.subtitle?.trim() || undefined,
        time: payload.timeSlot?.trim() || null,
        durationMinutes: duration,
        order: graph.value.nodes.length + 1,
      }

      if (payload.type === 'habit') {
        newNode.habitId = id
        newNode.icon = payload.iconName ?? 'Droplets'
        newNode.streak = 1
        newNode.completed = false
        newNode.frequency = 'Daily'
        newNode.history = generateHistory(1)
      } else if (payload.type === 'task') {
        newNode.taskId = `task-${Date.now()}`
        newNode.priority = 'MEDIUM'
        newNode.inFocus = false
        newNode.completedMinutes = 0
        newNode.totalMinutes = duration
        newNode.projectName = 'Personal OS'
      } else if (payload.type === 'recharge') {
        newNode.rechargeKind = 'break'
      }
    } else {
      // Async dispatch to backend to obtain canonical UUID (AC-C04 / D3)
      newNode = await scheduleApi.addStep({
        date: graph.value.date,
        phase: targetPhase,
        type: payload.type,
        title: payload.title.trim(),
        subtitle: payload.subtitle?.trim() || undefined,
        timeSlot: payload.timeSlot?.trim() || undefined,
        durationMinutes: duration,
        iconName: payload.iconName,
      })
    }

    // Determine insertion index in graph.nodes
    let insertIndex = graph.value.nodes.length
    if (targetPhase === 'bedtime') {
      const bedtimeAnchorIdx = graph.value.nodes.findIndex(
        (n) => n.type === 'anchor' && n.anchorKind === 'bedtime',
      )
      if (bedtimeAnchorIdx !== -1) {
        insertIndex = bedtimeAnchorIdx
      }
    } else {
      let lastPhaseIdx = -1
      for (let i = 0; i < graph.value.nodes.length; i++) {
        if (graph.value.nodes[i].phase === targetPhase) {
          lastPhaseIdx = i
        }
      }
      if (lastPhaseIdx !== -1) {
        insertIndex = lastPhaseIdx + 1
      } else {
        const phaseOrder: SchedulePhaseId[] = ['morning', 'deep-focus', 'afternoon', 'bedtime']
        const currentTargetOrder = phaseOrder.indexOf(targetPhase)
        const nextPhaseNodeIdx = graph.value.nodes.findIndex(
          (n) => phaseOrder.indexOf(n.phase) > currentTargetOrder,
        )
        if (nextPhaseNodeIdx !== -1) {
          insertIndex = nextPhaseNodeIdx
        }
      }
    }

    const prevNode = insertIndex > 0 ? graph.value.nodes[insertIndex - 1] : null
    const nextNode =
      insertIndex < graph.value.nodes.length ? graph.value.nodes[insertIndex] : null

    graph.value.nodes.splice(insertIndex, 0, newNode)

    // Re-wire edges cleanly
    if (prevNode && nextNode) {
      const existingEdgeIndex = graph.value.edges.findIndex(
        (e) => e.fromNodeId === prevNode.id && e.toNodeId === nextNode.id,
      )
      if (existingEdgeIndex !== -1) {
        const oldEdge = graph.value.edges[existingEdgeIndex]
        graph.value.edges.splice(existingEdgeIndex, 1)
        graph.value.edges.push({
          id: `e-${prevNode.id}-${newNode.id}`,
          fromNodeId: prevNode.id,
          toNodeId: newNode.id,
          type: prevNode.phase !== newNode.phase ? 'phase' : (prevNode.type === 'habit' && newNode.type === 'habit' ? 'prerequisite' : (oldEdge.type ?? 'sequential')),
          active: Boolean(prevNode.completed),
        })
        graph.value.edges.push({
          id: `e-${newNode.id}-${nextNode.id}`,
          fromNodeId: newNode.id,
          toNodeId: nextNode.id,
          type: newNode.phase !== nextNode.phase ? 'phase' : (newNode.type === 'habit' && nextNode.type === 'habit' ? 'prerequisite' : (oldEdge.type ?? 'sequential')),
          active: false,
        })
      } else {
        graph.value.edges.push({
          id: `e-${prevNode.id}-${newNode.id}`,
          fromNodeId: prevNode.id,
          toNodeId: newNode.id,
          type: prevNode.phase !== newNode.phase ? 'phase' : (prevNode.type === 'habit' && newNode.type === 'habit' ? 'prerequisite' : 'sequential'),
          active: Boolean(prevNode.completed),
        })
        if (nextNode.type === 'anchor' && nextNode.anchorKind === 'bedtime') {
          graph.value.edges.push({
            id: `e-${newNode.id}-${nextNode.id}`,
            fromNodeId: newNode.id,
            toNodeId: nextNode.id,
            type: newNode.phase !== nextNode.phase ? 'phase' : 'sequential',
            active: false,
          })
        }
      }
    } else if (prevNode) {
      graph.value.edges.push({
        id: `e-${prevNode.id}-${newNode.id}`,
        fromNodeId: prevNode.id,
        toNodeId: newNode.id,
        type: prevNode.phase !== newNode.phase ? 'phase' : 'sequential',
        active: Boolean(prevNode.completed),
      })
    }

    recalculateBedtime()
    return newNode
  }

  function rewireEdges(): void {
    if (!graph.value || graph.value.nodes.length < 2) return

    const newEdges: ScheduleEdge[] = []
    for (let i = 0; i < graph.value.nodes.length - 1; i++) {
      const from = graph.value.nodes[i]
      const to = graph.value.nodes[i + 1]
      const edgeType: ScheduleEdgeType =
        from.phase !== to.phase
          ? 'phase'
          : from.type === 'habit' && to.type === 'habit'
            ? 'prerequisite'
            : 'sequential'
      const existing = graph.value.edges.find(
        (e) => e.fromNodeId === from.id && e.toNodeId === to.id,
      )
      newEdges.push({
        id: `e-${from.id}-${to.id}`,
        fromNodeId: from.id,
        toNodeId: to.id,
        type: edgeType,
        active: existing ? existing.active : Boolean(from.completed),
      })
    }
    graph.value.edges = newEdges
  }

  async function addNode(phaseId: string, stepData: Omit<AddStepPayload, 'phaseId'>): Promise<ScheduleNode> {
    return addStep({ phaseId, ...stepData })
  }

  // Schedule Step Update & In-Place Editing (Spec AC-010, AC-011, AC-012)
  async function updateStep(
    stepId: string,
    payload: UpdateStepPayload,
  ): Promise<ScheduleNode> {
    if (!graph.value) {
      throw new Error('Schedule graph is not loaded')
    }

    const nodeIndex = graph.value.nodes.findIndex((n) => n.id === stepId)
    if (nodeIndex === -1) {
      throw new Error(`Schedule node not found: ${stepId}`)
    }

    const targetNode = graph.value.nodes[nodeIndex]

    // 1. Guard against anchor node updates (Spec AC-011)
    if (
      targetNode.type === 'anchor' ||
      targetNode.anchorKind != null ||
      stepId.startsWith('anchor-')
    ) {
      throw new Error('Anchor node update is not allowed')
    }

    errorMessage.value = null

    // 2. Snapshot previous state for optimistic rollback
    const prevNodes = JSON.parse(JSON.stringify(graph.value.nodes))
    const prevEdges = JSON.parse(JSON.stringify(graph.value.edges))
    const prevOverflow = graph.value.overflowMinutes
    const prevProjectedBedtime = graph.value.projectedBedtime

    // 3. Mutate node in nodes
    targetNode.title = payload.title.trim()
    if (payload.subtitle !== undefined) {
      targetNode.subtitle = payload.subtitle.trim() || undefined
    }
    if (payload.timeSlot !== undefined) {
      targetNode.time = payload.timeSlot.trim() || null
    }
    const duration = payload.durationMinutes ?? payload.totalMinutes
    if (duration !== undefined) {
      targetNode.durationMinutes = duration
      if (targetNode.type === 'task') {
        targetNode.totalMinutes = duration
      }
    }
    if (payload.notes !== undefined) {
      targetNode.notes = payload.notes.trim() || undefined
    }
    if (payload.iconName !== undefined) {
      targetNode.icon = payload.iconName
    }

    // 4. If phase changed, repartition and rewire edges dynamically (Spec AC-012)
    const phaseChanged = Boolean(payload.phase && payload.phase !== targetNode.phase)
    if (phaseChanged) {
      const rawPhase = payload.phase!.toLowerCase()
      const newPhase: SchedulePhaseId =
        rawPhase === 'evening' ? 'bedtime' : (rawPhase as SchedulePhaseId)
      targetNode.phase = newPhase

      // Remove from current position
      graph.value.nodes.splice(nodeIndex, 1)

      // Repartition: find insertion index for newPhase
      let insertIndex = graph.value.nodes.length
      if (newPhase === 'bedtime') {
        const bedtimeAnchorIdx = graph.value.nodes.findIndex(
          (n) => n.type === 'anchor' && n.anchorKind === 'bedtime',
        )
        if (bedtimeAnchorIdx !== -1) {
          insertIndex = bedtimeAnchorIdx
        }
      } else {
        let lastPhaseIdx = -1
        for (let i = 0; i < graph.value.nodes.length; i++) {
          if (graph.value.nodes[i].phase === newPhase) {
            lastPhaseIdx = i
          }
        }
        if (lastPhaseIdx !== -1) {
          insertIndex = lastPhaseIdx + 1
        } else {
          const phaseOrder: SchedulePhaseId[] = ['morning', 'deep-focus', 'afternoon', 'bedtime']
          const currentTargetOrder = phaseOrder.indexOf(newPhase)
          const nextPhaseNodeIdx = graph.value.nodes.findIndex(
            (n) => phaseOrder.indexOf(n.phase) > currentTargetOrder,
          )
          if (nextPhaseNodeIdx !== -1) {
            insertIndex = nextPhaseNodeIdx
          }
        }
      }

      graph.value.nodes.splice(insertIndex, 0, targetNode)

      // Re-assign order numbers
      graph.value.nodes.forEach((n, idx) => {
        n.order = idx + 1
      })

      // Rewire edges dynamically
      rewireEdges()
    }

    // 5. Trigger bedtime recalculation
    recalculateBedtime()

    // In preview mode, keep local simulation
    if (previewMode.value !== null) {
      return targetNode
    }

    // 6. Call scheduleApi.updateStep. Roll back on error.
    try {
      const serverUpdated = await scheduleApi.updateStep(stepId, {
        ...payload,
        date: payload.date ?? graph.value.date,
      })
      if (serverUpdated) {
        Object.assign(targetNode, serverUpdated)
      }
      return targetNode
    } catch (err) {
      // Rollback to snapshot on error
      graph.value.nodes = prevNodes
      graph.value.edges = prevEdges
      graph.value.overflowMinutes = prevOverflow
      graph.value.projectedBedtime = prevProjectedBedtime
      recalculateBedtime()

      errorMessage.value =
        err instanceof Error ? err.message : 'Failed to update step on server'
      throw err
    }
  }

  // Node Deletion from Schedule (Spec AC-008, Plan AC-C05)
  async function deleteNode(nodeId: string): Promise<void> {
    if (!graph.value) return
    const nodeIndex = graph.value.nodes.findIndex((n) => n.id === nodeId)
    if (nodeIndex === -1) return

    const nodeToDelete = graph.value.nodes[nodeIndex]
    // Invariant: anchors are permanent circadian milestones
    if (nodeToDelete.type === 'anchor' || nodeToDelete.anchorKind != null || nodeId.startsWith('anchor-')) {
      return
    }

    errorMessage.value = null

    // 1. Snapshot previous state for rollback (AC-C05)
    const prevNodes = [...graph.value.nodes]
    const prevEdges = [...graph.value.edges]
    const prevSelectedNodeId = selectedNodeId.value
    const prevOverflow = graph.value.overflowMinutes
    const prevProjectedBedtime = graph.value.projectedBedtime

    const incomingEdges = graph.value.edges.filter((e) => e.toNodeId === nodeId)
    const outgoingEdges = graph.value.edges.filter((e) => e.fromNodeId === nodeId)

    // 2. Optimistic removal & edge bridging
    graph.value.edges = graph.value.edges.filter(
      (e) => e.fromNodeId !== nodeId && e.toNodeId !== nodeId,
    )

    if (incomingEdges.length > 0 && outgoingEdges.length > 0) {
      const fromNodeId = incomingEdges[0].fromNodeId
      const toNodeId = outgoingEdges[0].toNodeId
      const alreadyConnected = graph.value.edges.some(
        (e) => e.fromNodeId === fromNodeId && e.toNodeId === toNodeId,
      )
      if (fromNodeId !== toNodeId && !alreadyConnected) {
        const fromNode = graph.value.nodes.find((n) => n.id === fromNodeId)
        const toNode = graph.value.nodes.find((n) => n.id === toNodeId)
        const edgeType = fromNode && toNode && fromNode.phase !== toNode.phase
          ? 'phase'
          : (fromNode && toNode && fromNode.type === 'habit' && toNode.type === 'habit'
            ? 'prerequisite'
            : (incomingEdges[0].type ?? 'sequential'))
        graph.value.edges.push({
          id: `e-${fromNodeId}-${toNodeId}`,
          fromNodeId,
          toNodeId,
          type: edgeType,
          active: Boolean(fromNode?.completed),
        })
      }
    }

    graph.value.nodes.splice(nodeIndex, 1)

    if (selectedNodeId.value === nodeId) {
      selectedNodeId.value = null
    }

    recalculateBedtime()

    // In preview mode or non-UUID legacy mock node, skip server call
    if (previewMode.value !== null || !isUuid(nodeId)) {
      return
    }

    // 3. Asynchronously call backend DELETE
    try {
      await scheduleApi.deleteStep(nodeId)
    } catch (err) {
      // 4. Rollback on failure
      graph.value.nodes = prevNodes
      graph.value.edges = prevEdges
      selectedNodeId.value = prevSelectedNodeId
      graph.value.overflowMinutes = prevOverflow
      graph.value.projectedBedtime = prevProjectedBedtime
      recalculateBedtime()

      errorMessage.value = err instanceof Error ? err.message : 'Failed to delete step from server'
      console.error('Failed to delete step on server:', err)
    }
  }

  async function load(preview: PreviewState = null, date?: string): Promise<void> {
    previewMode.value = preview
    errorMessage.value = null

    if (preview === 'loading') {
      status.value = 'loading'
      return
    }
    if (preview === 'error') {
      status.value = 'error'
      errorMessage.value = 'Simulated error in preview mode'
      return
    }
    if (preview === 'empty') {
      status.value = 'empty'
      graph.value = {
        date: date ?? todayISODate(),
        wakeTime: '06:30',
        targetBedtime: '22:30',
        projectedBedtime: '22:30',
        overflowMinutes: 0,
        phases: [],
        nodes: [],
        edges: [],
      }
      return
    }

    status.value = 'loading'
    const targetDate = date ?? todayISODate()
    try {
      const response = await scheduleApi.getSchedule(targetDate)
      graph.value = response
      recalculateBedtime()
      status.value = 'ready'
    } catch (err) {
      console.error('Failed to load schedule from server:', err)
      status.value = 'error'
      errorMessage.value = err instanceof Error ? err.message : 'Could not reach server. Check your connection.'
      if (!graph.value) {
        graph.value = createMockScheduleGraph()
        graph.value.date = targetDate
      }
    }
  }

  return {
    status,
    graph,
    activeLayout,
    selectedNodeId,
    activeTaskId,
    errorMessage,
    previewMode,
    // Getters
    nodes,
    edges,
    phases,
    selectedNode,
    habitNodes,
    taskNodes,
    completedHabitsCount,
    totalHabitsCount,
    habitProgressPercent,
    wakeAnchor,
    bedtimeAnchor,
    overflowMinutes,
    isOverflowing,
    projectedBedtime,
    targetBedtime,
    bedtimeStatusMessage,
    // Actions
    setLayout,
    selectNode,
    toggleHabit,
    startFocus,
    stopFocus,
    addStep,
    addNode,
    updateStep,
    deleteNode,
    recalculateBedtime,
    rewireEdges,
    load,
  }
})
