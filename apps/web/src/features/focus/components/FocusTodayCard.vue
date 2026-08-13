<script setup lang="ts">
import { ArrowRight, AudioLines, TrendingUp } from 'lucide-vue-next'

import SectionHeader from '@/components/shared/SectionHeader.vue'

import { mockFocusTrend } from '../mock'
import { useFocusStore } from '../store'

/** "Focus Today" — the right-rail focus surface from the approved reference:
 *  big focused time, restrained ring, and the day-over-day trend. */
const store = useFocusStore()

/* Ring geometry — a restrained visualization, not the hero of the panel. */
const R = 54
const CIRCUMFERENCE = 2 * Math.PI * R
/** Share of the daily focus capacity already logged (mock trend baseline). */
const RING_PROGRESS = 0.68
const dashOffset = CIRCUMFERENCE * (1 - RING_PROGRESS)
</script>

<template>
  <section class="focus-today panel">
    <SectionHeader title="Focus Today">
      <template #actions>
        <RouterLink :to="{ name: 'focus' }" class="header-link">
          View history
          <ArrowRight :size="14" :stroke-width="2" />
        </RouterLink>
      </template>
    </SectionHeader>

    <div class="body">
      <div class="stats">
        <span class="value tnum">{{ store.todaySummary.formatted }}</span>
        <span class="label">Total focused time</span>
        <span class="trend">
          <TrendingUp :size="14" :stroke-width="2" />
          {{ mockFocusTrend.deltaPercent }}% vs yesterday
        </span>
      </div>

      <div class="ring-wrap" role="img" aria-label="Focus progress ring">
        <svg class="ring" viewBox="0 0 128 128">
          <circle
            cx="64" cy="64" :r="R"
            fill="none"
            stroke="var(--surface-3)"
            stroke-width="9"
          />
          <circle
            cx="64" cy="64" :r="R"
            fill="none"
            stroke="var(--accent)"
            stroke-width="9"
            stroke-linecap="round"
            :stroke-dasharray="CIRCUMFERENCE"
            :stroke-dashoffset="dashOffset"
            transform="rotate(-90 64 64)"
          />
        </svg>
        <span class="ring-icon" aria-hidden="true">
          <AudioLines :size="22" :stroke-width="2" />
        </span>
      </div>
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

.header-link {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--accent-strong);
  border-radius: var(--radius-sm);
}

.header-link:hover {
  opacity: 0.82;
}

.body {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
}

.stats {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.value {
  font-size: 2.5rem;
  font-weight: 650;
  letter-spacing: -0.03em;
  line-height: 1.1;
  color: var(--text-primary);
}

.label {
  margin-top: var(--space-1);
  font-size: var(--text-md);
  color: var(--text-tertiary);
}

.trend {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  margin-top: var(--space-3);
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--success);
}

.ring-wrap {
  position: relative;
  width: 112px;
  height: 112px;
  flex-shrink: 0;
}

.ring {
  width: 100%;
  height: 100%;
  filter: drop-shadow(0 4px 14px var(--accent-glow));
}

.ring-icon {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  color: var(--accent-strong);
}
</style>
