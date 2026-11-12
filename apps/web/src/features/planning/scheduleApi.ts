import { apiClient } from '@/lib/api/client'
import { todayISODate } from './api'
import type {
  AddStepPayload,
  HabitStreakDay,
  ScheduleEdge,
  ScheduleNode,
  SchedulePhase,
  UpdateStepPayload,
} from './types'

export interface ScheduleGraphResponse {
  date: string
  wakeTime: string
  targetBedtime: string
  projectedBedtime: string
  overflowMinutes: number
  phases: SchedulePhase[]
  nodes: ScheduleNode[]
  edges: ScheduleEdge[]
}

export interface ToggleHabitRequest {
  date?: string
}

export interface ToggleHabitResponse {
  habitId: string
  completed: boolean
  streak: number
  history: HabitStreakDay[]
  updatedEdges: ScheduleEdge[]
  projectedBedtime: string
  overflowMinutes: number
}

export interface AddScheduleStepRequest {
  date?: string
  phase: string
  type: string
  title: string
  subtitle?: string
  timeSlot?: string
  durationMinutes?: number
  iconName?: string
}

export interface UpdateScheduleStepRequest {
  title: string
  subtitle?: string
  phase?: string
  timeSlot?: string
  durationMinutes?: number
  notes?: string
  iconName?: string
  date?: string
}

const BASE = '/schedule'

async function getSchedule(date?: string): Promise<ScheduleGraphResponse> {
  const targetDate = date ?? todayISODate()
  return apiClient.get<ScheduleGraphResponse>(`${BASE}/${targetDate}`)
}

async function toggleHabit(
  habitId: string,
  request?: ToggleHabitRequest,
): Promise<ToggleHabitResponse> {
  return apiClient.post<ToggleHabitResponse>(
    `${BASE}/habits/${habitId}/toggle`,
    request,
  )
}

async function addStep(
  request: AddScheduleStepRequest | AddStepPayload,
): Promise<ScheduleNode> {
  const targetDate =
    'date' in request && request.date ? request.date : todayISODate()
  const phase = 'phase' in request ? request.phase : request.phaseId
  const durationMinutes =
    'durationMinutes' in request
      ? request.durationMinutes
      : 'totalMinutes' in request
        ? request.totalMinutes
        : undefined

  const payload: AddScheduleStepRequest = {
    date: targetDate,
    phase,
    type: request.type,
    title: request.title,
    subtitle: request.subtitle,
    timeSlot: request.timeSlot,
    durationMinutes,
    iconName: request.iconName,
  }
  return apiClient.post<ScheduleNode>(`${BASE}/steps`, payload)
}

async function deleteStep(stepId: string): Promise<void> {
  return apiClient.delete<void>(`${BASE}/steps/${stepId}`)
}

async function updateStep(
  stepId: string,
  payload: UpdateStepPayload,
): Promise<ScheduleNode> {
  const durationMinutes =
    payload.durationMinutes !== undefined
      ? payload.durationMinutes
      : payload.totalMinutes

  const body: UpdateScheduleStepRequest = {
    title: payload.title,
    subtitle: payload.subtitle,
    phase: payload.phase,
    timeSlot: payload.timeSlot,
    durationMinutes,
    notes: payload.notes,
    iconName: payload.iconName,
    date: payload.date,
  }
  return apiClient.put<ScheduleNode>(`${BASE}/steps/${stepId}`, body)
}

export const scheduleApi = {
  getSchedule,
  toggleHabit,
  addStep,
  deleteStep,
  updateStep,
}
