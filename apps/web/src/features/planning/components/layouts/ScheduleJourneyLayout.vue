<script setup lang="ts">
import { computed } from 'vue'
import {
  BedDouble,
  Brain,
  Coffee,
  Plus,
  Sparkles,
  Sun,
  Zap,
} from 'lucide-vue-next'

import ScheduleAnchorNode from '../nodes/ScheduleAnchorNode.vue'
import ScheduleHabitNode from '../nodes/ScheduleHabitNode.vue'
import ScheduleTaskNode from '../nodes/ScheduleTaskNode.vue'
import { useScheduleStore } from '../../scheduleStore'
import type { SchedulePhaseId } from '../../types'

const scheduleStore = useScheduleStore()

const emit = defineEmits<{
  (e: 'add-step', phaseId: string): void
}>()

const phases = computed(() => scheduleStore.phases)

function getPhaseIcon(phaseId: SchedulePhaseId) {
  switch (phaseId) {
    case 'morning':
      return Sun
    case 'deep-focus':
      return Brain
    case 'afternoon':
      return Zap
    case 'bedtime':
      return BedDouble
  }
}

function getPhaseNodes(phaseId: SchedulePhaseId) {
  return scheduleStore.nodes.filter((n) => n.phase === phaseId)
}

function isPhaseCompleted(phaseId: SchedulePhaseId): boolean {
  const phaseHabits = scheduleStore.habitNodes.filter((h) => h.phase === phaseId)
  if (phaseHabits.length === 0) return false
  return phaseHabits.every((h) => h.completed)
}
</script>

<template>
  <div class="journey-layout" role="region" aria-label="Serpentine narrative daily journey">
    <div class="journey-track">
      <!-- 4 Serpentine Phases -->
      <section
        v-for="(phase, index) in phases"
        :key="phase.id"
        class="journey-phase-card"
        :class="[`phase-${phase.id}`, { 'phase-completed': isPhaseCompleted(phase.id) }]"
        :aria-label="phase.title"
      >
        <!-- Phase Header -->
        <header class="phase-header">
          <div class="phase-number-badge">
            <span class="step-num">0{{ index + 1 }}</span>
            <component :is="getPhaseIcon(phase.id)" :size="16" class="phase-icon" />
          </div>

          <div class="phase-heading">
            <div class="phase-title-row">
              <h3 class="phase-title">{{ phase.title }}</h3>
              <span class="phase-time">{{ phase.timeRange }}</span>
            </div>
            <p class="phase-subtitle">{{ phase.subtitle }}</p>
          </div>

          <button
            type="button"
            class="phase-add-step-btn"
            :aria-label="`Add step to ${phase.title}`"
            :title="`Add step to ${phase.title}`"
            @click="emit('add-step', phase.id)"
          >
            <Plus :size="13" />
            <span>Add Step</span>
          </button>
        </header>

        <!-- Phase Nodes Trajectory -->
        <div class="phase-nodes-list">
          <template v-for="(node, nodeIdx) in getPhaseNodes(phase.id)" :key="node.id">
            <!-- Node Rendering -->
            <div class="node-wrapper">
              <ScheduleAnchorNode
                v-if="node.type === 'anchor'"
                :node="node"
              />

              <ScheduleHabitNode
                v-else-if="node.type === 'habit'"
                :node="node"
              />

              <ScheduleTaskNode
                v-else-if="node.type === 'task'"
                :node="node"
              />

              <div
                v-else-if="node.type === 'recharge'"
                class="journey-recharge-chip"
                role="button"
                tabindex="0"
                @click="scheduleStore.selectNode(node.id)"
              >
                <Coffee :size="14" class="recharge-icon" />
                <div class="recharge-info">
                  <span class="recharge-title">{{ node.title }}</span>
                  <span class="recharge-meta">{{ node.time }} · {{ node.durationMinutes }}m rest</span>
                </div>
                <Sparkles :size="12" class="sparkle" />
              </div>
            </div>

            <!-- Inter-node glowing connector inside phase -->
            <div
              v-if="nodeIdx < getPhaseNodes(phase.id).length - 1"
              class="inter-node-connector"
              :class="{ lit: node.type === 'habit' && node.completed }"
              aria-hidden="true"
            >
              <div class="connector-line" />
              <div class="connector-arrow" />
            </div>
          </template>
        </div>

        <!-- Serpentine SVG Transition Curve between Phases -->
        <div
          v-if="index < phases.length - 1"
          class="phase-transition-bridge"
          aria-hidden="true"
        >
          <svg class="serpentine-svg" viewBox="0 0 200 64" fill="none" preserveAspectRatio="none">
            <path
              d="M 100 0 C 100 32, 100 32, 100 64"
              class="serpentine-path"
              :class="{ 'path-lit': isPhaseCompleted(phase.id) }"
            />
          </svg>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.journey-layout {
  width: 100%;
  max-width: 980px;
  margin: 0 auto;
  padding: var(--space-4) 0 var(--space-12);
}

.journey-track {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
  position: relative;
}

/* Phase Card */
.journey-phase-card {
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-xl);
  padding: var(--space-6);
  position: relative;
  transition: all 0.25s var(--ease-out);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.25);
}

.journey-phase-card:hover {
  border-color: var(--border-strong);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.35);
}

.phase-completed {
  border-color: rgba(57, 197, 138, 0.3);
}

/* Phase Header */
.phase-header {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  padding-bottom: var(--space-5);
  border-bottom: 1px solid var(--border-subtle);
  margin-bottom: var(--space-5);
}

.phase-add-step-btn {
  margin-left: auto;
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  padding: 4px 10px;
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  color: var(--text-secondary);
  font-size: var(--text-xs);
  font-weight: 500;
  cursor: pointer;
  white-space: nowrap;
  transition: all var(--duration-fast) var(--ease-out);
}

.phase-add-step-btn:hover {
  background: var(--surface-3);
  border-color: var(--accent);
  color: var(--text-primary);
}

.phase-number-badge {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: 6px 12px;
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-full);
}

.step-num {
  font-size: 11px;
  font-weight: 700;
  color: var(--text-tertiary);
  letter-spacing: 0.05em;
}

.phase-icon {
  color: var(--accent-strong);
}

.phase-morning .phase-icon {
  color: var(--warning);
}

.phase-deep-focus .phase-icon {
  color: var(--accent-strong);
}

.phase-afternoon .phase-icon {
  color: var(--blue-strong);
}

.phase-bedtime .phase-icon {
  color: var(--success);
}

.phase-heading {
  flex: 1;
  min-width: 0;
}

.phase-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
}

.phase-title {
  font-size: var(--text-xl);
  font-weight: 700;
  color: var(--text-primary);
  margin: 0;
  letter-spacing: -0.01em;
}

.phase-time {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  font-variant-numeric: tabular-nums;
  padding: 2px 8px;
  background: var(--surface-2);
  border-radius: var(--radius-sm);
}

.phase-subtitle {
  font-size: var(--text-xs);
  color: var(--text-secondary);
  margin-top: 3px;
  margin-bottom: 0;
}

/* Nodes List */
.phase-nodes-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.node-wrapper {
  position: relative;
}

/* Inter-node connector */
.inter-node-connector {
  display: flex;
  flex-direction: column;
  align-items: center;
  height: 20px;
  position: relative;
  margin: -4px 0;
}

.connector-line {
  width: 2px;
  height: 100%;
  background: var(--border-subtle);
  transition: all 0.25s var(--ease-out);
}

.inter-node-connector.lit .connector-line {
  background: var(--accent);
  box-shadow: 0 0 8px var(--accent-glow);
}

/* Recharge Chip in Journey */
.journey-recharge-chip {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  background: rgba(59, 130, 246, 0.08);
  border: 1px dashed rgba(59, 130, 246, 0.3);
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: all 0.2s;
}

.journey-recharge-chip:hover {
  background: rgba(59, 130, 246, 0.14);
  border-color: rgba(59, 130, 246, 0.5);
  transform: translateY(-1px);
}

.recharge-icon {
  color: var(--blue-strong);
  flex-shrink: 0;
}

.recharge-info {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.recharge-title {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--text-primary);
}

.recharge-meta {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.sparkle {
  color: var(--blue-strong);
  opacity: 0.6;
}

/* Phase Transition Bridge */
.phase-transition-bridge {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 48px;
  margin-top: var(--space-4);
  margin-bottom: -16px;
}

.serpentine-svg {
  width: 100%;
  height: 48px;
}

.serpentine-path {
  stroke: var(--border-strong);
  stroke-width: 2.5;
  stroke-dasharray: 6 4;
  transition: all 0.3s var(--ease-out);
}

.serpentine-path.path-lit {
  stroke: var(--accent-strong);
  stroke-dasharray: none;
  filter: drop-shadow(0 0 6px var(--accent));
}
</style>
