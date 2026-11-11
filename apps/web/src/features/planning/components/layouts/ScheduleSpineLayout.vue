<script setup lang="ts">
import { computed } from 'vue'
import { Plus, Sparkles } from 'lucide-vue-next'

import ScheduleAnchorNode from '../nodes/ScheduleAnchorNode.vue'
import ScheduleHabitNode from '../nodes/ScheduleHabitNode.vue'
import ScheduleTaskNode from '../nodes/ScheduleTaskNode.vue'
import { useScheduleStore } from '../../scheduleStore'

const scheduleStore = useScheduleStore()

const emit = defineEmits<{
  (e: 'add-step', phaseId: string): void
}>()

const wakeAnchor = computed(() => scheduleStore.wakeAnchor)
const bedtimeAnchor = computed(() => scheduleStore.bedtimeAnchor)

// Group bilateral items chronologically
const morningHabits = computed(() =>
  scheduleStore.habitNodes.filter((h) => h.phase === 'morning'),
)
const eveningHabits = computed(() =>
  scheduleStore.habitNodes.filter((h) => h.phase === 'afternoon' || h.phase === 'bedtime'),
)

const focusTasks = computed(() => scheduleStore.taskNodes)
const rechargeNodes = computed(() =>
  scheduleStore.nodes.filter((n) => n.type === 'recharge'),
)
</script>

<template>
  <div class="spine-layout" role="region" aria-label="Central spine chronological schedule">
    <!-- Top Terminal: Wake Anchor -->
    <div v-if="wakeAnchor" class="spine-terminus-top">
      <ScheduleAnchorNode :node="wakeAnchor" />
      <div class="spine-lead-line" aria-hidden="true" />
    </div>

    <!-- Main Bilateral Track -->
    <div class="bilateral-track">
      <!-- Left Rail: Habits & Rituals -->
      <section class="rail left-rail" aria-label="Habits and Daily Rituals">
        <header class="rail-header">
          <span class="rail-badge">Habits & Rituals</span>
          <span class="rail-meta">
            {{ scheduleStore.completedHabitsCount }}/{{ scheduleStore.totalHabitsCount }} Completed
          </span>
        </header>

        <div class="rail-cards">
          <!-- Morning Stack -->
          <div class="habit-stack-group">
            <div class="stack-header-row">
              <span class="stack-tag">Morning Stack</span>
              <button
                type="button"
                class="stack-add-btn"
                aria-label="Add habit to Morning Stack"
                title="Add step to Morning Stack"
                @click="emit('add-step', 'morning')"
              >
                <Plus :size="12" />
                <span>Add</span>
              </button>
            </div>
            <div
              v-for="habit in morningHabits"
              :key="habit.id"
              class="node-with-connector"
            >
              <ScheduleHabitNode :node="habit" />
              <div class="connector-to-spine right-connector" aria-hidden="true" />
            </div>
          </div>

          <!-- Evening Stack -->
          <div class="habit-stack-group">
            <div class="stack-header-row">
              <span class="stack-tag">Evening Sanctuary Stack</span>
              <button
                type="button"
                class="stack-add-btn"
                aria-label="Add habit to Evening Stack"
                title="Add step to Bedtime Stack"
                @click="emit('add-step', 'bedtime')"
              >
                <Plus :size="12" />
                <span>Add</span>
              </button>
            </div>
            <div
              v-for="habit in eveningHabits"
              :key="habit.id"
              class="node-with-connector"
            >
              <ScheduleHabitNode :node="habit" />
              <div class="connector-to-spine right-connector" aria-hidden="true" />
            </div>
          </div>
        </div>
      </section>

      <!-- Central Chronological Spine Axis -->
      <div class="central-spine-axis" aria-hidden="true">
        <div class="spine-rail-line" />
        <div class="spine-live-beacon" title="Current Day Trajectory">
          <div class="beacon-pulse" />
          <div class="beacon-core" />
        </div>

        <div class="spine-ticks">
          <span class="time-tick">07:00</span>
          <span class="time-tick">09:00</span>
          <span class="time-tick">12:00</span>
          <span class="time-tick">15:00</span>
          <span class="time-tick">18:00</span>
          <span class="time-tick">21:00</span>
        </div>
      </div>

      <!-- Right Rail: Focus Work & Recharge Blocks -->
      <section class="rail right-rail" aria-label="Focus Tasks and Recharge Blocks">
        <header class="rail-header">
          <div class="rail-title-group">
            <span class="rail-badge badge-focus">Focus & Deep Work</span>
            <span class="rail-meta">Daily Top 3 Priorities</span>
          </div>
          <button
            type="button"
            class="stack-add-btn"
            aria-label="Add activity to Focus Work"
            title="Add activity to Deep Focus"
            @click="emit('add-step', 'deep-focus')"
          >
            <Plus :size="12" />
            <span>Add Focus</span>
          </button>
        </header>

        <div class="rail-cards">
          <!-- Tasks and Recharges interleaved by order -->
          <div
            v-for="task in focusTasks"
            :key="task.id"
            class="node-with-connector"
          >
            <div class="connector-to-spine left-connector" aria-hidden="true" />
            <ScheduleTaskNode :node="task" />
          </div>

          <!-- Recharge Blocks -->
          <div
            v-for="recharge in rechargeNodes"
            :key="recharge.id"
            class="recharge-spine-card"
            role="button"
            tabindex="0"
            @click="scheduleStore.selectNode(recharge.id)"
          >
            <div class="connector-to-spine left-connector" aria-hidden="true" />
            <div class="recharge-badge">
              <Sparkles :size="13" class="recharge-sparkle" />
              <span class="recharge-title">{{ recharge.title }}</span>
              <span class="recharge-time">{{ recharge.time }} ({{ recharge.durationMinutes }}m)</span>
            </div>
          </div>
        </div>
      </section>
    </div>

    <!-- Bottom Terminal: Bedtime Anchor -->
    <div v-if="bedtimeAnchor" class="spine-terminus-bottom">
      <div class="spine-lead-line" aria-hidden="true" />
      <ScheduleAnchorNode :node="bedtimeAnchor" />
    </div>
  </div>
</template>

<style scoped>
.spine-layout {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
  width: 100%;
  max-width: 1240px;
  margin: 0 auto;
  padding: var(--space-4) 0 var(--space-12);
}

/* Terminus Nodes */
.spine-terminus-top,
.spine-terminus-bottom {
  width: 100%;
  max-width: 720px;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.spine-lead-line {
  width: 2px;
  height: 48px;
  background: linear-gradient(to bottom, var(--accent), rgba(108, 92, 231, 0.2));
  position: relative;
}

.spine-terminus-bottom .spine-lead-line {
  background: linear-gradient(to bottom, rgba(108, 92, 231, 0.2), var(--accent));
}

/* Bilateral Layout */
.bilateral-track {
  display: grid;
  grid-template-columns: 1fr 64px 1fr;
  gap: var(--space-4);
  width: 100%;
  position: relative;
}

/* Rails */
.rail {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.rail-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 var(--space-2);
}

.rail-title-group {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.rail-badge {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  padding: 3px 10px;
  border-radius: var(--radius-full);
  background: var(--success-soft);
  color: var(--success);
  border: 1px solid color-mix(in srgb, var(--success) 30%, transparent);
}

.badge-focus {
  background: var(--accent-soft);
  color: var(--accent-strong);
  border-color: var(--accent-border);
}

.rail-meta {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.rail-cards {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.habit-stack-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  padding: var(--space-4);
  background: var(--surface-2);
  border: 1px dashed var(--border-strong);
  border-radius: var(--radius-lg);
}

.stack-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 var(--space-1);
}

.stack-tag {
  font-size: 11px;
  font-weight: 700;
  color: var(--text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.stack-add-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 10px;
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  color: var(--text-secondary);
  font-size: 11px;
  font-weight: 500;
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

.stack-add-btn:hover {
  background: var(--surface-3);
  border-color: var(--accent);
  color: var(--text-primary);
}

/* Central Axis */
.central-spine-axis {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
}

.spine-rail-line {
  position: absolute;
  top: 0;
  bottom: 0;
  width: 3px;
  background: linear-gradient(
    to bottom,
    rgba(108, 92, 231, 0.4) 0%,
    var(--accent) 30%,
    var(--accent-strong) 70%,
    rgba(108, 92, 231, 0.4) 100%
  );
  box-shadow: 0 0 12px var(--accent-glow);
  border-radius: var(--radius-full);
}

.spine-live-beacon {
  position: sticky;
  top: 140px;
  z-index: 2;
  margin-top: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.beacon-core {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: var(--accent-strong);
  border: 2px solid #ffffff;
  box-shadow: 0 0 16px var(--accent);
}

.beacon-pulse {
  position: absolute;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: var(--accent-glow);
  animation: beaconWave 2.4s infinite var(--ease-out);
}

@keyframes beaconWave {
  0% {
    transform: scale(0.6);
    opacity: 0.9;
  }
  100% {
    transform: scale(2);
    opacity: 0;
  }
}

.spine-ticks {
  position: absolute;
  top: 40px;
  bottom: 40px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: center;
  pointer-events: none;
}

.time-tick {
  font-size: 10px;
  font-weight: 600;
  color: var(--text-tertiary);
  background: var(--surface-0);
  padding: 1px 4px;
  border-radius: 3px;
  border: 1px solid var(--border-subtle);
  font-variant-numeric: tabular-nums;
}

/* Connectors */
.node-with-connector {
  position: relative;
  display: flex;
  align-items: center;
}

.connector-to-spine {
  position: absolute;
  height: 2px;
  background: linear-gradient(to right, var(--border-strong), var(--accent-border));
  width: 24px;
  z-index: 1;
}

.right-connector {
  right: -24px;
  background: linear-gradient(to right, var(--border-subtle), var(--accent-border));
}

.left-connector {
  left: -24px;
  background: linear-gradient(to left, var(--border-subtle), var(--accent-border));
}

/* Recharge Card */
.recharge-spine-card {
  position: relative;
  display: flex;
  align-items: center;
  cursor: pointer;
  user-select: none;
}

.recharge-badge {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-4);
  background: rgba(59, 130, 246, 0.08);
  border: 1px dashed rgba(59, 130, 246, 0.3);
  border-radius: var(--radius-md);
  width: 100%;
  transition: all 0.2s;
}

.recharge-badge:hover {
  background: rgba(59, 130, 246, 0.14);
  border-color: rgba(59, 130, 246, 0.5);
}

.recharge-sparkle {
  color: var(--blue-strong);
  flex-shrink: 0;
}

.recharge-title {
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--text-primary);
  flex: 1;
}

.recharge-time {
  font-size: 11px;
  color: var(--text-tertiary);
  font-variant-numeric: tabular-nums;
}

@media (max-width: 900px) {
  .bilateral-track {
    grid-template-columns: 1fr;
    gap: var(--space-8);
  }
  .central-spine-axis {
    display: none;
  }
  .connector-to-spine {
    display: none;
  }
}
</style>
