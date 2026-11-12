/**
 * Planning types — mirror the backend contracts:
 * DailyTopThree (position 1–3, calendar date) and DailyPlan (capacity).
 * Dates are ISO calendar dates interpreted in the user's timezone (ADR-006).
 */

export interface TopThreeEntry {
  taskId: string;
  /** 1, 2, or 3 — unique per user and date (Daily Top 3 spec). */
  position: 1 | 2 | 3;
}

export interface DailyPlanSummary {
  /** Total estimated minutes planned for the day (Top 3 included). */
  plannedMinutes: number;
  /** Available focus capacity for the day, in minutes. */
  focusCapacityMinutes: number;
  /** Focus minutes already logged today. */
  focusCompletedMinutes: number;
}

export type PreviewState = "loading" | "error" | "empty" | null;

/**
 * Today's Schedule — a visual timeline entry. UI-milestone mock shape; the
 * real schedule is derived from the daily plan in a later milestone.
 */
export type ScheduleTone =
  | "accent"
  | "blue"
  | "success"
  | "warning"
  | "neutral";

export interface ScheduleEntry {
  id: string;
  /** Wall-clock start time label, e.g. "09:00" — null when the backend
   *  has no time for the entry (real daily-plan rows). */
  time: string | null;
  title: string;
  /** Secondary line, e.g. "Productivity OS · High Priority". */
  meta: string;
  durationMinutes: number;
  tone: ScheduleTone;
  /** Linked task — clicking the row opens its detail panel (null for breaks). */
  taskId: string | null;
}

/** Event context shown under the week rail in the Calendar panel. */
export interface CalendarEventAttendee {
  initials: string;
  color: string;
}

export interface CalendarEvent {
  id: string
  /** e.g. "9:00 AM". */
  timeLabel: string
  title: string
  /** e.g. "Tomorrow 9:00 – 9:30 AM". */
  detail: string
  /** e.g. "Microsoft Teams". */
  provider: string
  attendees: CalendarEventAttendee[]
  extraAttendees: number
}

/** Layout projections for the Daily Schedule Link-Map (Spec AC-001). */
export type ScheduleLayoutMode = 'spine' | 'journey' | 'matrix'

export type ScheduleNodeType = 'anchor' | 'habit' | 'task' | 'recharge'

export type ScheduleEdgeType = 'sequential' | 'prerequisite' | 'phase'

export type SchedulePhaseId = 'morning' | 'deep-focus' | 'afternoon' | 'bedtime'

export interface SchedulePhase {
  id: SchedulePhaseId
  title: string
  subtitle: string
  timeRange: string
  colorTone?: 'accent' | 'blue' | 'success' | 'warning' | 'neutral'
}

export interface HabitStreakDay {
  date: string
  completed: boolean
}

export interface ScheduleNode {
  id: string
  type: ScheduleNodeType
  phase: SchedulePhaseId
  title: string
  subtitle?: string
  time?: string | null
  durationMinutes?: number
  // Habit-specific
  habitId?: string
  icon?: string
  streak?: number
  completed?: boolean
  frequency?: string
  history?: HabitStreakDay[]
  // Task-specific
  taskId?: string
  priority?: 'HIGH' | 'MEDIUM' | 'LOW'
  inFocus?: boolean
  completedMinutes?: number
  totalMinutes?: number
  projectName?: string
  // Anchor-specific
  anchorKind?: 'wake' | 'bedtime'
  targetTime?: string
  projectedTime?: string | null
  overflowMinutes?: number
  // Recharge-specific
  rechargeKind?: 'break' | 'nutrition' | 'walk' | 'winddown'
  // Common
  notes?: string
  order?: number
}

export interface ScheduleEdge {
  id: string
  fromNodeId: string
  toNodeId: string
  type?: ScheduleEdgeType
  active?: boolean
  label?: string
}

export interface ScheduleGraph {
  date: string
  wakeTime: string
  targetBedtime: string
  projectedBedtime: string
  overflowMinutes: number
  phases: SchedulePhase[]
  nodes: ScheduleNode[]
  edges: ScheduleEdge[]
}

export interface AddStepPayload {
  phaseId: SchedulePhaseId | string
  type: 'habit' | 'task' | 'recharge'
  title: string
  subtitle?: string
  totalMinutes?: number
  timeSlot?: string
  iconName?: string
}

export interface UpdateStepPayload {
  title: string
  subtitle?: string
  phase?: SchedulePhaseId | string
  timeSlot?: string
  durationMinutes?: number
  totalMinutes?: number
  notes?: string
  iconName?: string
  date?: string
}


