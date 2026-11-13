<script setup lang="ts">
import { computed } from 'vue'
import { ArrowRight, BatteryCharging, BedDouble } from 'lucide-vue-next'

import SectionHeader from '@/components/shared/SectionHeader.vue'
import { useTodayStore } from '@/features/planning/todayStore'
import { useScheduleStore } from '@/features/planning/scheduleStore'

const props = defineProps<{
  plannedMinutes?: number
  capacityMinutes?: number
  overflowMinutes?: number
  targetBedtime?: string
  projectedBedtime?: string
  completedHabitsCount?: number
  totalHabitsCount?: number
}>()

const todayStore = useTodayStore()
const scheduleStore = useScheduleStore()

const planned = computed(() => props.plannedMinutes ?? todayStore.plan?.plannedMinutes ?? 0)
const capacity = computed(
  () => props.capacityMinutes ?? todayStore.plan?.focusCapacityMinutes ?? 360,
)
const overflow = computed(() => props.overflowMinutes ?? scheduleStore.overflowMinutes ?? 0)
const target = computed(() => props.targetBedtime ?? scheduleStore.targetBedtime ?? '22:30')
const projected = computed(
  () => props.projectedBedtime ?? scheduleStore.projectedBedtime ?? '22:30',
)
const completedHabits = computed(
  () => props.completedHabitsCount ?? scheduleStore.completedHabitsCount ?? 0,
)
const totalHabits = computed(() => props.totalHabitsCount ?? scheduleStore.totalHabitsCount ?? 0)

const isOverCapacity = computed(() => planned.value > capacity.value)
const overMinutes = computed(() => Math.max(0, planned.value - capacity.value))
const bufferMinutes = computed(() => Math.max(0, capacity.value - planned.value))

const plannedHoursLabel = computed(() => (planned.value / 60).toFixed(1))
const capacityHoursLabel = computed(() => (capacity.value / 60).toFixed(1))
const bufferHoursLabel = computed(() => (bufferMinutes.value / 60).toFixed(1))

const fillPercent = computed(() => {
  if (capacity.value <= 0) return 0
  return Math.min(100, Math.round((planned.value / capacity.value) * 100))
})
</script>

<template>
  <section class="capacity-card panel" aria-label="Capacity & Energy Telemetry">
    <SectionHeader title="Capacity & Energy">
      <template #actions>
        <RouterLink :to="{ name: 'schedule' }" class="header-link">
          Review
          <ArrowRight :size="13" :stroke-width="2" />
        </RouterLink>
      </template>
    </SectionHeader>

    <!-- Planned vs Capacity Gauge (AC-010, AC-011) -->
    <div class="gauge-section">
      <div class="gauge-header">
        <span class="ratio-label tnum">{{ plannedHoursLabel }}h / {{ capacityHoursLabel }}h planned</span>
        <span
          v-if="isOverCapacity"
          class="status-badge tone-warning"
        >
          ⚠️ Over capacity by {{ overMinutes }}m
        </span>
        <span
          v-else
          class="status-badge tone-success"
        >
          +{{ bufferHoursLabel }}h buffer remaining
        </span>
      </div>

      <div
        class="progress-bar-track"
        role="progressbar"
        :aria-valuenow="fillPercent"
        aria-valuemin="0"
        aria-valuemax="100"
        :aria-label="`${plannedHoursLabel}h of ${capacityHoursLabel}h planned`"
      >
        <div
          class="progress-bar-fill"
          :class="isOverCapacity ? 'fill-warning' : 'fill-accent'"
          :style="{ width: `${fillPercent}%` }"
        />
      </div>
    </div>

    <!-- Bedtime Trajectory (AC-012) -->
    <div class="telemetry-item bedtime-item" :class="{ 'is-delayed': overflow > 0 }">
      <span class="item-icon tone-blue" aria-hidden="true">
        <BedDouble :size="15" :stroke-width="2" />
      </span>
      <div class="item-content">
        <div class="item-header">
          <span class="item-title">Bedtime Trajectory</span>
          <span
            v-if="overflow > 0"
            class="status-badge tone-warning"
          >
            Bedtime shifts by +{{ overflow }}m to {{ projected }}
          </span>
          <span
            v-else
            class="status-badge tone-success"
          >
            ✓ On track for {{ target }} bedtime
          </span>
        </div>
        <div class="item-meta tnum">
          Target {{ target }} · Projected {{ projected }}
          <span v-if="overflow > 0" class="overflow-delta">(+{{ overflow }}m)</span>
        </div>
      </div>
    </div>

    <!-- Habits Completion Ratio -->
    <div class="telemetry-item habits-item">
      <span class="item-icon tone-accent" aria-hidden="true">
        <BatteryCharging :size="15" :stroke-width="2" />
      </span>
      <div class="item-content">
        <span class="item-title">Habit Momentum</span>
        <span v-if="totalHabits === 0" class="item-meta">
          No daily habits scheduled
        </span>
        <span v-else class="item-meta">
          {{ completedHabits }} of {{ totalHabits }} habits completed
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
  gap: var(--space-4);
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

/* Gauge section */
.gauge-section {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.gauge-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.ratio-label {
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--text-primary);
  letter-spacing: -0.01em;
}

.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 7px;
  border-radius: var(--radius-full);
  white-space: nowrap;
  font-variant-numeric: tabular-nums;
}

.status-badge.tone-success {
  background: var(--success-soft);
  color: var(--success);
  border: 1px solid color-mix(in srgb, var(--success) 25%, transparent);
}

.status-badge.tone-warning {
  background: var(--warning-soft);
  color: var(--warning);
  border: 1px solid color-mix(in srgb, var(--warning) 30%, transparent);
}

.progress-bar-track {
  width: 100%;
  height: 8px;
  background: var(--surface-2);
  border-radius: var(--radius-full);
  overflow: hidden;
  border: 1px solid var(--border-subtle);
}

.progress-bar-fill {
  height: 100%;
  border-radius: var(--radius-full);
  transition: width 0.3s var(--ease-out);
}

.progress-bar-fill.fill-accent {
  background: linear-gradient(90deg, var(--accent), var(--accent-strong));
}

.progress-bar-fill.fill-warning {
  background: linear-gradient(90deg, var(--warning), var(--orange));
}

/* Telemetry items */
.telemetry-item {
  display: flex;
  align-items: flex-start;
  gap: var(--space-3);
  padding: var(--space-3);
  background: var(--surface-2);
  border-radius: var(--radius-md);
  border: 1px solid var(--border-subtle);
  transition: border-color var(--duration-fast);
}

.telemetry-item.is-delayed {
  border-color: color-mix(in srgb, var(--warning) 30%, transparent);
  background: color-mix(in srgb, var(--warning-soft) 18%, var(--surface-2));
}

.item-icon {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  border-radius: var(--radius-full);
  flex-shrink: 0;
  margin-top: 1px;
}

.item-icon.tone-blue {
  background: var(--blue-soft);
  color: var(--blue-strong);
}

.item-icon.tone-accent {
  background: var(--accent-soft);
  color: var(--accent-strong);
}

.item-content {
  display: flex;
  flex-direction: column;
  gap: 2px;
  flex: 1;
  min-width: 0;
}

.item-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.item-title {
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--text-primary);
}

.item-meta {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  font-variant-numeric: tabular-nums;
}

.overflow-delta {
  color: var(--warning);
  font-weight: 600;
}
</style>
