<script setup lang="ts">
import { computed } from 'vue'
import {
  Anchor,
  CheckCircle,
  Coffee,
  Plus,
  Target,
} from 'lucide-vue-next'

import ScheduleAnchorNode from '../nodes/ScheduleAnchorNode.vue'
import ScheduleHabitNode from '../nodes/ScheduleHabitNode.vue'
import ScheduleTaskNode from '../nodes/ScheduleTaskNode.vue'
import { useScheduleStore } from '../../scheduleStore'
import type { ScheduleNode, SchedulePhaseId } from '../../types'

const scheduleStore = useScheduleStore()

const emit = defineEmits<{
  (e: 'add-step', phaseId: string): void
}>()

const phases = computed(() => scheduleStore.phases)

interface Swimlane {
  id: 'habits' | 'tasks' | 'anchors'
  title: string
  subtitle: string
  icon: typeof CheckCircle
}

const swimlanes: Swimlane[] = [
  {
    id: 'habits',
    title: 'Habits & Rituals',
    subtitle: 'Recurring stacks & daily consistency',
    icon: CheckCircle,
  },
  {
    id: 'tasks',
    title: 'Focus Work',
    subtitle: 'Daily Top 3 priorities & shallow work',
    icon: Target,
  },
  {
    id: 'anchors',
    title: 'Anchors & Recovery',
    subtitle: 'Circadian targets, rest & bedtime',
    icon: Anchor,
  },
]

function getNodesForCell(phaseId: SchedulePhaseId, swimlaneId: Swimlane['id']): ScheduleNode[] {
  return scheduleStore.nodes.filter((node) => {
    if (node.phase !== phaseId) return false
    if (swimlaneId === 'habits') return node.type === 'habit'
    if (swimlaneId === 'tasks') return node.type === 'task'
    if (swimlaneId === 'anchors') return node.type === 'anchor' || node.type === 'recharge'
    return false
  })
}
</script>

<template>
  <div class="matrix-layout" role="region" aria-label="Swimlane matrix daily schedule">
    <div class="matrix-table-wrap">
      <div class="matrix-grid">
        <!-- Top-Left Corner: Matrix Label -->
        <div class="grid-header-cell corner-cell">
          <span class="corner-title">Swimlanes</span>
          <span class="corner-subtitle">4 Phases · 3 Categories</span>
        </div>

        <!-- Column Headers (The 4 Phases) -->
        <div
          v-for="phase in phases"
          :key="phase.id"
          class="grid-header-cell phase-column-header"
        >
          <div class="phase-col-title-wrap">
            <span class="phase-col-title">{{ phase.title }}</span>
            <span class="phase-col-time">{{ phase.timeRange }}</span>
          </div>
          <button
            type="button"
            class="matrix-add-phase-btn"
            :aria-label="`Add step to ${phase.title}`"
            :title="`Add step to ${phase.title}`"
            @click="emit('add-step', phase.id)"
          >
            <Plus :size="13" />
          </button>
        </div>

        <!-- Swimlane Rows -->
        <template v-for="lane in swimlanes" :key="lane.id">
          <!-- Row Header -->
          <div class="grid-row-header">
            <div class="lane-icon-wrap" :class="`lane-${lane.id}`">
              <component :is="lane.icon" :size="16" />
            </div>
            <div class="lane-titles">
              <span class="lane-name">{{ lane.title }}</span>
              <span class="lane-sub">{{ lane.subtitle }}</span>
            </div>
          </div>

          <!-- Cells for each phase in this swimlane -->
          <div
            v-for="phase in phases"
            :key="`${lane.id}-${phase.id}`"
            class="matrix-cell"
          >
            <div
              v-if="getNodesForCell(phase.id, lane.id).length > 0"
              class="cell-items"
            >
              <template
                v-for="node in getNodesForCell(phase.id, lane.id)"
                :key="node.id"
              >
                <ScheduleHabitNode
                  v-if="node.type === 'habit'"
                  :node="node"
                  compact
                />

                <ScheduleTaskNode
                  v-else-if="node.type === 'task'"
                  :node="node"
                  compact
                />

                <ScheduleAnchorNode
                  v-else-if="node.type === 'anchor'"
                  :node="node"
                  compact
                />

                <div
                  v-else-if="node.type === 'recharge'"
                  class="matrix-recharge-chip"
                  role="button"
                  tabindex="0"
                  @click="scheduleStore.selectNode(node.id)"
                >
                  <Coffee :size="13" class="recharge-icon" />
                  <span class="recharge-text">{{ node.title }}</span>
                  <span class="recharge-duration">{{ node.durationMinutes }}m</span>
                </div>
              </template>
            </div>

            <!-- Empty cell state -->
            <div v-else class="empty-cell-placeholder" aria-hidden="true">
              <span class="empty-dash">—</span>
            </div>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>

<style scoped>
.matrix-layout {
  width: 100%;
  max-width: 1360px;
  margin: 0 auto;
  padding: var(--space-4) 0 var(--space-12);
}

.matrix-table-wrap {
  width: 100%;
  overflow-x: auto;
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-panel);
}

.matrix-grid {
  display: grid;
  grid-template-columns: 220px repeat(4, minmax(240px, 1fr));
  min-width: 1100px;
}

/* Header Cells */
.grid-header-cell {
  padding: var(--space-4) var(--space-5);
  background: var(--surface-2);
  border-bottom: 1px solid var(--border-strong);
  border-right: 1px solid var(--border-subtle);
  display: flex;
  align-items: center;
}

.corner-cell {
  flex-direction: column;
  align-items: flex-start;
  justify-content: center;
  gap: 2px;
}

.corner-title {
  font-size: var(--text-xs);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--text-primary);
}

.corner-subtitle {
  font-size: 11px;
  color: var(--text-tertiary);
}

.phase-column-header {
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
}

.matrix-add-phase-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  color: var(--text-secondary);
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
  flex-shrink: 0;
}

.matrix-add-phase-btn:hover {
  background: var(--surface-3);
  border-color: var(--accent);
  color: var(--text-primary);
}

.phase-col-title-wrap {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.phase-col-title {
  font-size: var(--text-sm);
  font-weight: 700;
  color: var(--text-primary);
}

.phase-col-time {
  font-size: 11px;
  color: var(--text-tertiary);
  font-variant-numeric: tabular-nums;
}

/* Row Headers */
.grid-row-header {
  padding: var(--space-5) var(--space-4);
  background: var(--surface-1);
  border-bottom: 1px solid var(--border-subtle);
  border-right: 1px solid var(--border-strong);
  display: flex;
  align-items: flex-start;
  gap: var(--space-3);
}

.lane-icon-wrap {
  width: 32px;
  height: 32px;
  border-radius: var(--radius-md);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.lane-habits {
  background: var(--success-soft);
  color: var(--success);
  border: 1px solid color-mix(in srgb, var(--success) 30%, transparent);
}

.lane-tasks {
  background: var(--accent-soft);
  color: var(--accent-strong);
  border: 1px solid var(--accent-border);
}

.lane-anchors {
  background: var(--warning-soft);
  color: var(--warning);
  border: 1px solid color-mix(in srgb, var(--warning) 30%, transparent);
}

.lane-titles {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.lane-name {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--text-primary);
}

.lane-sub {
  font-size: 11px;
  color: var(--text-tertiary);
  line-height: 1.35;
}

/* Matrix Cells */
.matrix-cell {
  padding: var(--space-4);
  border-bottom: 1px solid var(--border-subtle);
  border-right: 1px solid var(--border-subtle);
  background: var(--surface-1);
  min-height: 140px;
  display: flex;
  flex-direction: column;
}

.cell-items {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  width: 100%;
}

.empty-cell-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  flex: 1;
  color: var(--text-disabled);
}

.empty-dash {
  font-size: var(--text-sm);
  opacity: 0.4;
}

/* Matrix Recharge Chip */
.matrix-recharge-chip {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-3);
  background: rgba(59, 130, 246, 0.08);
  border: 1px dashed rgba(59, 130, 246, 0.3);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: all 0.2s;
}

.matrix-recharge-chip:hover {
  background: rgba(59, 130, 246, 0.15);
  border-color: rgba(59, 130, 246, 0.5);
}

.recharge-icon {
  color: var(--blue-strong);
  flex-shrink: 0;
}

.recharge-text {
  font-size: var(--text-xs);
  color: var(--text-primary);
  flex: 1;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.recharge-duration {
  font-size: 11px;
  color: var(--text-tertiary);
  font-variant-numeric: tabular-nums;
}
</style>
