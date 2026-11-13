<script setup lang="ts">
import { computed } from 'vue'
import {
  ArrowRight,
  BookOpen,
  CalendarClock,
  Check,
  Coffee,
  Droplets,
  Dumbbell,
  Flame,
  Footprints,
  Moon,
  Smile,
  Sparkles,
  Target,
  Zap,
} from 'lucide-vue-next'

import EmptyState from '@/components/shared/EmptyState.vue'
import SectionHeader from '@/components/shared/SectionHeader.vue'

import { useScheduleStore } from '../scheduleStore'
import type { ScheduleEntry, ScheduleNode } from '../types'

const props = defineProps<{
  entries?: ScheduleEntry[]
  habits?: ScheduleNode[]
}>()

const emit = defineEmits<{
  select: [taskId: string]
  toggleHabit: [habitId: string]
}>()

const scheduleStore = useScheduleStore()

function durationLabel(minutes: number): string {
  return `${minutes}m`
}

function onKeydown(event: KeyboardEvent, taskId: string | null) {
  if (!taskId) return
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    emit('select', taskId)
  }
}

function getHabitIcon(iconName?: string) {
  switch (iconName) {
    case 'Droplets':
    case 'water':
      return Droplets
    case 'Dumbbell':
    case 'dumbbell':
      return Dumbbell
    case 'Target':
      return Target
    case 'Footprints':
      return Footprints
    case 'Moon':
    case 'moon':
      return Moon
    case 'BookOpen':
    case 'book':
      return BookOpen
    case 'Coffee':
    case 'coffee':
      return Coffee
    case 'Zap':
    case 'zap':
      return Zap
    case 'Smile':
    case 'smile':
      return Smile
    case 'Sparkles':
      return Sparkles
    default:
      return Flame
  }
}

function parseTimeToMinutes(time: string | null | undefined): number {
  if (!time) return 9999
  const parts = time.split(':')
  if (parts.length < 2) return 9999
  const h = parseInt(parts[0], 10)
  const m = parseInt(parts[1], 10)
  if (isNaN(h) || isNaN(m)) return 9999
  return h * 60 + m
}

export interface UnifiedTimelineItem {
  id: string
  itemType: 'task' | 'habit'
  time: string | null
  title: string
  meta: string
  durationMinutes: number
  tone: string
  taskId?: string | null
  habitId?: string
  icon?: string
  streak?: number
  completed?: boolean
}

const timelineItems = computed<UnifiedTimelineItem[]>(() => {
  const taskEntries: UnifiedTimelineItem[] = (props.entries ?? []).map((entry) => ({
    id: entry.id,
    itemType: 'task',
    time: entry.time,
    title: entry.title,
    meta: entry.meta,
    durationMinutes: entry.durationMinutes,
    tone: entry.tone,
    taskId: entry.taskId,
  }))

  const habitSource = props.habits !== undefined ? props.habits : scheduleStore.habitNodes
  const habitEntries: UnifiedTimelineItem[] = habitSource.map((habit) => ({
    id: habit.id,
    itemType: 'habit',
    time: habit.time ?? null,
    title: habit.title,
    meta: habit.subtitle ?? (habit.frequency ? `Habit · ${habit.frequency}` : 'Daily Habit'),
    durationMinutes: habit.durationMinutes ?? 15,
    tone: habit.completed ? 'success' : 'accent',
    habitId: habit.habitId ?? habit.id,
    icon: habit.icon,
    streak: habit.streak ?? 0,
    completed: Boolean(habit.completed),
  }))

  return [...taskEntries, ...habitEntries].sort((a, b) => {
    const timeA = parseTimeToMinutes(a.time)
    const timeB = parseTimeToMinutes(b.time)
    if (timeA !== timeB) return timeA - timeB
    return a.title.localeCompare(b.title)
  })
})

async function onToggleHabit(habitId: string) {
  emit('toggleHabit', habitId)
  await scheduleStore.toggleHabit(habitId)
}
</script>

<template>
  <section class="schedule panel">
    <SectionHeader title="Today's Schedule" />

    <ol v-if="timelineItems.length > 0" class="timeline">
      <li
        v-for="item in timelineItems"
        :key="item.id"
        class="slot"
        :class="`slot-${item.itemType}`"
      >
        <span class="time tnum">{{ item.time ?? '—' }}</span>
        <span class="rail" aria-hidden="true">
          <span
            class="dot"
            :class="[
              `tone-${item.tone}`,
              { 'is-completed': item.itemType === 'habit' && item.completed },
            ]"
          />
        </span>
        <div
          class="entry"
          :class="[
            `tone-${item.tone}`,
            `entry-${item.itemType}`,
            {
              clickable: item.itemType === 'task' && item.taskId,
              completed: item.itemType === 'habit' && item.completed,
            },
          ]"
          :role="item.itemType === 'task' && item.taskId ? 'button' : undefined"
          :tabindex="item.itemType === 'task' && item.taskId ? 0 : undefined"
          @click="item.itemType === 'task' && item.taskId && emit('select', item.taskId)"
          @keydown="item.itemType === 'task' && onKeydown($event, item.taskId ?? null)"
        >
          <!-- 1-tap habit toggle checkbox (AC-002, AC-003) -->
          <button
            v-if="item.itemType === 'habit'"
            type="button"
            class="habit-toggle"
            :class="{ checked: item.completed }"
            :aria-label="item.completed ? 'Mark habit as incomplete' : 'Mark habit as complete'"
            @click.stop="onToggleHabit(item.habitId ?? item.id)"
          >
            <Check v-if="item.completed" :size="12" :stroke-width="3" class="check-icon" />
          </button>

          <!-- Habit icon wrap -->
          <span
            v-if="item.itemType === 'habit'"
            class="habit-icon-wrap"
            :class="{ completed: item.completed }"
            aria-hidden="true"
          >
            <component :is="getHabitIcon(item.icon)" :size="14" />
          </span>

          <span class="entry-body">
            <span class="entry-title">{{ item.title }}</span>
            <span class="entry-meta">{{ item.meta }}</span>
          </span>

          <!-- Habit streak badge (AC-001) -->
          <span
            v-if="item.itemType === 'habit'"
            class="habit-streak-badge"
            :class="{ 'streak-lit': item.completed }"
            title="Daily streak"
          >
            🔥 {{ item.streak }}d
          </span>

          <span class="duration tnum">{{ durationLabel(item.durationMinutes) }}</span>
        </div>
      </li>
    </ol>

    <EmptyState
      v-else
      :icon="CalendarClock"
      title="Nothing scheduled"
      description="Plan tasks and habits into time blocks and they will show up here."
      compact
    />

    <div v-if="timelineItems.length > 0" class="footer">
      <RouterLink :to="{ name: 'schedule' }" class="footer-link">
        View schedule
        <ArrowRight :size="14" :stroke-width="2" />
      </RouterLink>
    </div>
  </section>
</template>

<style scoped>
.panel {
  display: flex;
  flex-direction: column;
  padding: var(--space-6);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  background: var(--surface-1);
  min-width: 0;
}

.timeline {
  display: flex;
  flex-direction: column;
}

.slot {
  position: relative;
  display: flex;
  align-items: stretch;
  gap: var(--space-3);
  padding-bottom: var(--space-3);
}

.slot:last-child {
  padding-bottom: 0;
}

.time {
  width: 40px;
  flex-shrink: 0;
  padding-top: var(--space-4);
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--text-tertiary);
  text-align: right;
}

.rail {
  position: relative;
  width: 12px;
  flex-shrink: 0;
  display: flex;
  justify-content: center;
}

/* The continuous timeline spine. */
.rail::before {
  content: '';
  position: absolute;
  top: 0;
  bottom: 0;
  width: 2px;
  background: var(--border-strong);
}

.slot:first-child .rail::before {
  top: var(--space-5);
}

.slot:last-child .rail::before {
  bottom: auto;
  height: var(--space-5);
}

.dot {
  position: relative;
  z-index: 1;
  width: 10px;
  height: 10px;
  margin-top: var(--space-5);
  border-radius: var(--radius-full);
  background: var(--text-disabled);
  box-shadow: 0 0 0 3px var(--surface-1);
}

.dot.tone-accent {
  background: var(--accent);
}

.dot.tone-blue {
  background: var(--blue);
}

.dot.tone-success,
.dot.is-completed {
  background: var(--success);
}

.dot.tone-warning {
  background: var(--warning);
}

.entry {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  padding: var(--space-4);
  border: 1px solid transparent;
  border-radius: var(--radius-md);
  background: var(--surface-2);
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.entry.clickable {
  cursor: pointer;
}

.entry.clickable:hover {
  transform: translateY(-1px);
  border-color: var(--border-strong);
}

.entry.tone-accent {
  background: linear-gradient(120deg, var(--accent-soft), transparent);
  border-color: var(--accent-border);
}

.entry.tone-blue {
  background: linear-gradient(120deg, var(--blue-soft), transparent);
  border-color: color-mix(in srgb, var(--blue) 25%, transparent);
}

.entry.tone-success {
  background: linear-gradient(120deg, var(--success-soft), transparent);
  border-color: color-mix(in srgb, var(--success) 25%, transparent);
}

.entry.tone-warning {
  background: linear-gradient(120deg, var(--warning-soft), transparent);
  border-color: color-mix(in srgb, var(--warning) 25%, transparent);
}

/* Habit specific styles */
.entry-habit {
  border-left: 3px solid var(--accent);
}

.entry-habit.completed {
  border-left-color: var(--success);
  background: color-mix(in srgb, var(--success-soft) 20%, var(--surface-2));
}

.entry.completed .entry-title {
  text-decoration: line-through;
  color: var(--text-tertiary);
}

.habit-toggle {
  width: 20px;
  height: 20px;
  border-radius: var(--radius-full);
  border: 1.5px solid var(--border-strong);
  background: transparent;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
  transition: all 0.18s var(--ease-out);
  padding: 0;
}

.habit-toggle:hover {
  border-color: var(--success);
  background: var(--success-soft);
}

.habit-toggle.checked {
  background: var(--success);
  border-color: var(--success);
  color: #ffffff;
  box-shadow: 0 0 8px color-mix(in srgb, var(--success) 35%, transparent);
}

.check-icon {
  animation: checkPop 0.18s var(--ease-out);
}

@keyframes checkPop {
  0% {
    transform: scale(0.6);
  }
  100% {
    transform: scale(1);
  }
}

.habit-icon-wrap {
  width: 26px;
  height: 26px;
  border-radius: var(--radius-sm);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--accent-strong);
  flex-shrink: 0;
}

.habit-icon-wrap.completed {
  color: var(--success);
  background: var(--success-soft);
  border-color: color-mix(in srgb, var(--success) 25%, transparent);
}

.habit-streak-badge {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 2px 7px;
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-full);
  font-size: 11px;
  font-weight: 600;
  color: var(--text-tertiary);
  flex-shrink: 0;
  font-variant-numeric: tabular-nums;
  transition: all 0.2s;
}

.habit-streak-badge.streak-lit {
  background: var(--orange-soft);
  border-color: color-mix(in srgb, var(--orange) 30%, transparent);
  color: var(--orange);
}

.entry-body {
  display: flex;
  flex-direction: column;
  gap: 3px;
  min-width: 0;
}

.entry-title {
  font-size: var(--text-base);
  font-weight: 550;
  letter-spacing: -0.01em;
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.entry-meta {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.duration {
  flex-shrink: 0;
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--text-secondary);
}

.footer {
  margin-top: var(--space-4);
  padding-top: var(--space-4);
  border-top: 1px solid var(--border-subtle);
}

.footer-link {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--accent-strong);
  border-radius: var(--radius-sm);
}

.footer-link:hover {
  opacity: 0.82;
}
</style>
