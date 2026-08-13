<script setup lang="ts">
import { ArrowRight, Clock, Crosshair, TrendingUp } from 'lucide-vue-next'

import SectionHeader from '@/components/shared/SectionHeader.vue'

import { useFocusStore } from '../store'

/** "Daily Summary" — three quiet secondary metrics from the reference. */
const store = useFocusStore()
</script>

<template>
  <section class="daily-summary panel">
    <SectionHeader title="Daily Summary">
      <template #actions>
        <RouterLink :to="{ name: 'focus' }" class="header-link">
          View full report
          <ArrowRight :size="14" :stroke-width="2" />
        </RouterLink>
      </template>
    </SectionHeader>

    <div class="stats">
      <div class="stat">
        <span class="icon tone-accent" aria-hidden="true">
          <Clock :size="16" :stroke-width="2" />
        </span>
        <span class="value tnum">{{ store.todaySummary.formatted }}</span>
        <span class="label">Focused Time</span>
      </div>
      <div class="stat">
        <span class="icon tone-blue" aria-hidden="true">
          <Crosshair :size="16" :stroke-width="2" />
        </span>
        <span class="value tnum">{{ store.todaySummary.sessions }}</span>
        <span class="label">Sessions</span>
      </div>
      <div class="stat">
        <span class="icon tone-success" aria-hidden="true">
          <TrendingUp :size="16" :stroke-width="2" />
        </span>
        <span class="value tnum">{{ store.todaySummary.avgMinutes }}m</span>
        <span class="label">Average</span>
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
  white-space: nowrap;
}

.header-link:hover {
  opacity: 0.82;
}

.stats {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--space-3);
}

.stat {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: var(--space-1);
  min-width: 0;
}

.icon {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  margin-bottom: var(--space-1);
  border-radius: var(--radius-full);
}

.icon.tone-accent {
  background: var(--accent-soft);
  color: var(--accent-strong);
}

.icon.tone-blue {
  background: var(--blue-soft);
  color: var(--blue-strong);
}

.icon.tone-success {
  background: var(--success-soft);
  color: var(--success);
}

.value {
  font-size: var(--text-xl);
  font-weight: 650;
  letter-spacing: -0.02em;
  color: var(--text-primary);
  white-space: nowrap;
}

.label {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  white-space: nowrap;
}
</style>
