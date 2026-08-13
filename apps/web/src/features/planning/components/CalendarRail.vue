<script setup lang="ts">
import { computed } from 'vue'
import { ArrowRight, Users } from 'lucide-vue-next'

import SectionHeader from '@/components/shared/SectionHeader.vue'
import { WEEKDAY_LABELS } from '@/lib/utils/date'

import { mockCalendarEvent } from '../mock'

interface RailDay {
  key: string
  weekday: string
  dayOfMonth: number
  isToday: boolean
}

/** Horizontal week rail with the selected (today) date in the purple accent,
 *  plus the day's event context — per the approved visual reference. */
const today = new Date()

const week = computed<RailDay[]>(() => {
  // Monday-first week containing today (JS getDay() is Sunday-first).
  const monday = new Date(today)
  monday.setDate(today.getDate() - ((today.getDay() + 6) % 7))
  return WEEKDAY_LABELS.map((weekday, i) => {
    const date = new Date(monday)
    date.setDate(monday.getDate() + i)
    return {
      key: date.toDateString(),
      weekday,
      dayOfMonth: date.getDate(),
      isToday: date.toDateString() === today.toDateString(),
    }
  })
})

const event = mockCalendarEvent
</script>

<template>
  <section class="calendar panel">
    <SectionHeader title="Calendar">
      <template #actions>
        <RouterLink :to="{ name: 'calendar' }" class="header-link">
          View full calendar
          <ArrowRight :size="14" :stroke-width="2" />
        </RouterLink>
      </template>
    </SectionHeader>

    <div class="rail" role="grid" aria-label="This week">
      <div v-for="day in week" :key="day.key" class="rail-day">
        <span class="weekday">{{ day.weekday }}</span>
        <span
          class="date tnum"
          :class="{ today: day.isToday }"
          :aria-current="day.isToday ? 'date' : undefined"
        >
          {{ day.dayOfMonth }}
        </span>
      </div>
    </div>

    <article class="event">
      <span class="event-time tnum">{{ event.timeLabel }}</span>
      <h3 class="event-title">{{ event.title }}</h3>
      <p class="event-detail">{{ event.detail }}</p>
      <div class="event-footer">
        <span class="provider">
          <Users :size="13" :stroke-width="2" />
          {{ event.provider }}
        </span>
        <span class="attendees">
          <span
            v-for="person in event.attendees"
            :key="person.initials"
            class="avatar"
            :style="{ background: person.color }"
          >
            {{ person.initials }}
          </span>
          <span v-if="event.extraAttendees > 0" class="avatar more tnum">
            +{{ event.extraAttendees }}
          </span>
        </span>
      </div>
    </article>
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

.header-link {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--accent-strong);
  border-radius: var(--radius-sm);
  white-space: nowrap;
}

.header-link:hover {
  opacity: 0.82;
}

.rail {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
  margin-bottom: var(--space-4);
}

.rail-day {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-1);
  min-width: 0;
}

.weekday {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--text-disabled);
}

.date {
  display: grid;
  place-items: center;
  width: 36px;
  height: 42px;
  border-radius: var(--radius-sm);
  font-size: var(--text-md);
  font-weight: 550;
  color: var(--text-secondary);
}

.date.today {
  background: var(--accent);
  color: var(--on-accent);
  font-weight: 650;
  box-shadow: 0 4px 16px var(--accent-glow);
}

.event {
  padding: var(--space-4) var(--space-5);
  border-radius: var(--radius-md);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
}

.event-time {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--accent-strong);
}

.event-title {
  margin-top: var(--space-1);
  font-size: var(--text-lg);
  font-weight: 600;
  letter-spacing: -0.01em;
  color: var(--text-primary);
}

.event-detail {
  margin-top: 2px;
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.event-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  margin-top: var(--space-4);
}

.provider {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  height: 26px;
  padding: 0 var(--space-3);
  border-radius: var(--radius-full);
  background: var(--blue-soft);
  color: var(--blue-strong);
  font-size: var(--text-xs);
  font-weight: 550;
  white-space: nowrap;
}

.attendees {
  display: flex;
  align-items: center;
}

.avatar {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  margin-left: -7px;
  border-radius: var(--radius-full);
  border: 2px solid var(--surface-2);
  color: #fff;
  font-size: 10px;
  font-weight: 650;
}

.avatar:first-child {
  margin-left: 0;
}

.avatar.more {
  background: var(--surface-3);
  color: var(--text-secondary);
  font-size: 10px;
}
</style>
