<script setup lang="ts">
import { computed } from 'vue'
import { ChevronLeft, ChevronRight } from 'lucide-vue-next'

import SurfaceCard from '@/components/shared/SurfaceCard.vue'
import { formatMonthYear } from '@/lib/utils/date'

interface CalendarDay {
  key: string
  dayOfMonth: number
  inCurrentMonth: boolean
  isToday: boolean
}

/** Lightweight date context — a mini month view. Intentionally not a
 * calendar application; navigation arrows are visual-only this milestone. */

const today = new Date()

const monthLabel = computed(() => formatMonthYear(today))

const weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S']

const days = computed<CalendarDay[]>(() => {
  const year = today.getFullYear()
  const month = today.getMonth()
  const firstOfMonth = new Date(year, month, 1)
  // Monday-first offset: JS getDay() is Sunday-first.
  const leadingBlanks = (firstOfMonth.getDay() + 6) % 7
  const start = new Date(year, month, 1 - leadingBlanks)

  const result: CalendarDay[] = []
  for (let i = 0; i < 42; i += 1) {
    const date = new Date(start)
    date.setDate(start.getDate() + i)
    result.push({
      key: date.toISOString(),
      dayOfMonth: date.getDate(),
      inCurrentMonth: date.getMonth() === month,
      isToday: date.toDateString() === today.toDateString(),
    })
  }
  return result
})
</script>

<template>
  <SurfaceCard>
    <div class="header">
      <h2 class="title">Calendar</h2>
      <button class="view-full" type="button" title="The full calendar arrives in a later milestone">
        View full
      </button>
    </div>

    <div class="month-nav">
      <span class="month">{{ monthLabel }}</span>
      <span class="arrows">
        <button class="arrow" type="button" aria-label="Previous month" title="Month navigation arrives later">
          <ChevronLeft :size="14" :stroke-width="1.75" />
        </button>
        <button class="arrow" type="button" aria-label="Next month" title="Month navigation arrives later">
          <ChevronRight :size="14" :stroke-width="1.75" />
        </button>
      </span>
    </div>

    <div class="grid" role="grid" aria-label="Month view">
      <span v-for="(letter, i) in weekdayLetters" :key="i" class="weekday">{{ letter }}</span>
      <span
        v-for="day in days"
        :key="day.key"
        class="day tnum"
        :class="{ outside: !day.inCurrentMonth, today: day.isToday }"
        :aria-current="day.isToday ? 'date' : undefined"
      >
        {{ day.dayOfMonth }}
      </span>
    </div>
  </SurfaceCard>
</template>

<style scoped>
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-4);
}

.title {
  font-size: var(--text-lg);
  font-weight: 600;
  letter-spacing: -0.01em;
}

.view-full {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--accent-strong);
  padding: 2px var(--space-1);
  border-radius: var(--radius-sm);
}

.view-full:hover {
  opacity: 0.8;
}

.month-nav {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-3);
}

.month {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-secondary);
}

.arrows {
  display: inline-flex;
  gap: var(--space-1);
}

.arrow {
  display: grid;
  place-items: center;
  width: 24px;
  height: 24px;
  border-radius: var(--radius-sm);
  color: var(--text-tertiary);
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.arrow:hover {
  background: var(--surface-2);
  color: var(--text-primary);
}

.grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
}

.weekday {
  padding: var(--space-1) 0;
  font-size: 10px;
  font-weight: 600;
  color: var(--text-disabled);
  text-align: center;
}

.day {
  display: grid;
  place-items: center;
  aspect-ratio: 1;
  font-size: var(--text-xs);
  color: var(--text-secondary);
  border-radius: var(--radius-full);
}

.day.outside {
  color: var(--text-disabled);
  opacity: 0.6;
}

.day.today {
  background: var(--accent);
  color: #fff;
  font-weight: 600;
}
</style>
