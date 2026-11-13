<script setup lang="ts">
import { computed } from 'vue'
import { ArrowRight, AudioLines, Pause, Play, Square, TrendingUp } from 'lucide-vue-next'

import SectionHeader from '@/components/shared/SectionHeader.vue'

import { useFocusStore } from '../store'

/** "Focus Today" — the right-rail focus surface from the approved reference:
 *  big focused time, restrained ring, and the day-over-day trend.
 *  When a focus session is active or paused, transforms into an interactive command widget. */
const store = useFocusStore()

/* Ring geometry — a restrained visualization, not the hero of the panel. */
const R = 54
const CIRCUMFERENCE = 2 * Math.PI * R
/** Daily focus capacity used for the ring (4h, same as FocusSummary). */
const DAILY_CAPACITY_MINUTES = 4 * 60

const totalMinutes = computed(() => {
  const now = new Date()
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  return Math.floor(
    store.sessionHistory
      .filter((s) => new Date(s.startedAt) >= todayStart)
      .reduce((sum, s) => sum + s.durationSeconds, 0) / 60,
  )
})

const progress = computed(() =>
  Math.min(totalMinutes.value / DAILY_CAPACITY_MINUTES, 1),
)

const dashOffset = computed(() => CIRCUMFERENCE * (1 - progress.value))

const trend = store.trendDeltaPercent

const isActive = computed(() => store.state === 'active' || store.state === 'paused')
const activeTaskTitle = computed(() => store.selectedTask?.title ?? 'Deep Focus Session')
</script>

<template>
  <section class="focus-today panel" :class="{ 'panel-active': isActive }">
    <SectionHeader title="Focus Today">
      <template #actions>
        <RouterLink :to="{ name: 'schedule' }" class="header-link">
          View schedule
          <ArrowRight :size="14" :stroke-width="2" />
        </RouterLink>
      </template>
    </SectionHeader>

    <!-- Active focus session live command center -->
    <div v-if="isActive" class="active-session">
      <div class="active-header">
        <span class="active-badge" :class="{ paused: store.state === 'paused' }">
          <span class="pulse-dot" />
          {{ store.state === 'paused' ? 'Paused' : 'In Progress' }}
        </span>
        <span class="active-task-title" :title="activeTaskTitle">{{ activeTaskTitle }}</span>
      </div>

      <div class="active-timer tnum">{{ store.formattedTime }}</div>

      <div class="active-controls">
        <button
          v-if="store.state === 'active'"
          class="control-btn"
          type="button"
          aria-label="Pause focus"
          title="Pause focus"
          @click="store.pauseFocus()"
        >
          <Pause :size="14" :stroke-width="2.5" />
          Pause
        </button>
        <button
          v-else
          class="control-btn resume-btn"
          type="button"
          aria-label="Resume focus"
          title="Resume focus"
          @click="store.resumeFocus()"
        >
          <Play :size="14" :stroke-width="2.5" />
          Resume
        </button>
        <button
          class="control-btn stop-btn"
          type="button"
          aria-label="End focus session"
          title="End focus session"
          @click="store.stopFocus()"
        >
          <Square :size="13" :stroke-width="2.5" />
          End Session
        </button>
      </div>
    </div>

    <!-- Idle / summary state -->
    <div v-else class="body">
      <div class="stats">
        <span class="value tnum">{{ store.todaySummary.formatted }}</span>
        <span class="label">Total focused time</span>
        <span v-if="trend !== null" class="trend">
          <TrendingUp :size="14" :stroke-width="2" />
          {{ trend > 0 ? "+" : "" }}{{ trend }}% vs yesterday
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
  transition:
    border-color var(--motion-standard) var(--ease-out),
    background var(--motion-standard) var(--ease-out);
}

.panel-active {
  border-color: var(--accent-border);
  background:
    radial-gradient(320px 180px at 90% 0%, rgba(139, 108, 255, 0.14), transparent 70%),
    var(--surface-1);
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

/* Active session live widget styles */
.active-session {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  padding-top: var(--space-1);
}

.active-header {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  min-width: 0;
}

.active-badge {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  padding: 2px 8px;
  border-radius: var(--radius-full);
  background: rgba(139, 108, 255, 0.18);
  color: var(--accent-strong);
  font-size: var(--text-xs);
  font-weight: 600;
  flex-shrink: 0;
}

.active-badge.paused {
  background: rgba(234, 179, 8, 0.18);
  color: var(--warning);
}

.pulse-dot {
  width: 6px;
  height: 6px;
  border-radius: var(--radius-full);
  background: currentColor;
  animation: pulse-dot 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse-dot {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.4; transform: scale(0.85); }
}

.active-task-title {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.active-timer {
  font-size: 2.5rem;
  font-weight: 700;
  letter-spacing: -0.02em;
  line-height: 1;
  color: var(--text-primary);
}

.active-controls {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.control-btn {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-md);
  border: 1px solid var(--border-subtle);
  background: var(--surface-2);
  color: var(--text-primary);
  font-size: var(--text-sm);
  font-weight: 550;
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    border-color var(--duration-fast) var(--ease-out);
}

.control-btn:hover {
  background: var(--surface-hover);
  border-color: var(--border-default);
}

.resume-btn {
  background: var(--accent);
  border-color: var(--accent);
  color: #fff;
}

.resume-btn:hover {
  filter: brightness(1.1);
}

.stop-btn {
  color: var(--text-secondary);
}

.stop-btn:hover {
  color: var(--danger);
  border-color: rgba(239, 68, 68, 0.3);
}

/* Idle state */
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
