<script setup lang="ts">
import { computed } from 'vue'
import { AlertTriangle, BedDouble, CheckCircle2, Sun } from 'lucide-vue-next'

import type { ScheduleNode } from '../../types'
import { useScheduleStore } from '../../scheduleStore'

const props = withDefaults(
  defineProps<{
    node: ScheduleNode
    selected?: boolean
    compact?: boolean
  }>(),
  {
    selected: false,
    compact: false,
  },
)

const emit = defineEmits<{
  (e: 'select', nodeId: string): void
}>()

const scheduleStore = useScheduleStore()

const isSelected = computed(() => props.selected || scheduleStore.selectedNodeId === props.node.id)
const isWake = computed(() => props.node.anchorKind === 'wake')
const isBedtime = computed(() => props.node.anchorKind === 'bedtime')

const overflow = computed(() => props.node.overflowMinutes ?? scheduleStore.overflowMinutes)
const hasOverflow = computed(() => isBedtime.value && overflow.value > 0)
const projectedTime = computed(
  () => props.node.projectedTime ?? scheduleStore.projectedBedtime ?? '22:30',
)
const targetTime = computed(
  () => props.node.targetTime ?? (isWake.value ? '06:30' : '22:30'),
)

function handleSelect() {
  scheduleStore.selectNode(props.node.id)
  emit('select', props.node.id)
}
</script>

<template>
  <div
    class="anchor-node"
    :class="{
      selected: isSelected,
      'anchor-wake': isWake,
      'anchor-bedtime': isBedtime,
      'has-overflow': hasOverflow,
      compact: compact,
    }"
    role="button"
    tabindex="0"
    :aria-pressed="isSelected"
    :aria-label="`Anchor: ${node.title}, time ${isBedtime && hasOverflow ? projectedTime : targetTime}`"
    @click="handleSelect"
    @keydown.enter.prevent="handleSelect"
  >
    <div class="anchor-glow" aria-hidden="true" />

    <div class="anchor-icon-wrap">
      <Sun v-if="isWake" :size="compact ? 16 : 20" class="sun-icon" />
      <BedDouble v-else :size="compact ? 16 : 20" class="bed-icon" />
    </div>

    <div class="anchor-content">
      <div class="anchor-header">
        <span class="anchor-type-label">
          {{ isWake ? 'Circadian Wake Anchor' : 'Sleep Target Anchor' }}
        </span>
        <div v-if="isBedtime" class="bedtime-badge-wrap">
          <span v-if="hasOverflow" class="overflow-badge">
            <AlertTriangle :size="12" />
            <span>{{ projectedTime }} (+{{ overflow }}m)</span>
          </span>
          <span v-else class="on-track-badge">
            <CheckCircle2 :size="12" />
            <span>{{ targetTime }} (On track)</span>
          </span>
        </div>
        <span v-else class="wake-time-badge">{{ targetTime }}</span>
      </div>

      <h4 class="anchor-title">{{ node.title }}</h4>

      <p v-if="node.subtitle && !compact" class="anchor-subtitle">
        {{ node.subtitle }}
      </p>

      <p v-if="hasOverflow && !compact" class="overflow-warning-text">
        Schedule overflow: Planned work extends past target bedtime by {{ overflow }}m.
      </p>
    </div>
  </div>
</template>

<style scoped>
.anchor-node {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  padding: var(--space-4) var(--space-5);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  cursor: pointer;
  user-select: none;
  transition: all 0.2s var(--ease-out);
  position: relative;
  overflow: hidden;
  text-align: left;
}

.anchor-node:hover {
  background: var(--surface-2);
  border-color: var(--border-strong);
  transform: translateY(-1px);
}

.anchor-node.selected {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px var(--accent-border), 0 8px 24px rgba(108, 92, 231, 0.2);
  background: var(--surface-2);
}

/* Compact matrix mode */
.anchor-node.compact {
  padding: var(--space-3) var(--space-3);
  gap: var(--space-3);
  border-radius: var(--radius-md);
}

.anchor-node.compact .anchor-title {
  font-size: var(--text-xs);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 150px;
}

/* Specific glows */
.anchor-wake .anchor-icon-wrap {
  background: var(--warning-soft);
  color: var(--warning);
  border: 1px solid color-mix(in srgb, var(--warning) 30%, transparent);
}

.anchor-bedtime .anchor-icon-wrap {
  background: var(--accent-soft);
  color: var(--accent-strong);
  border: 1px solid var(--accent-border);
}

.anchor-bedtime.has-overflow .anchor-icon-wrap {
  background: var(--warning-soft);
  color: var(--warning);
  border-color: color-mix(in srgb, var(--warning) 45%, transparent);
}

.anchor-node.has-overflow {
  border-color: var(--warning);
  background: linear-gradient(135deg, var(--warning-soft), var(--surface-1));
}

.anchor-icon-wrap {
  width: 44px;
  height: 44px;
  border-radius: var(--radius-md);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: all 0.2s;
}

.compact .anchor-icon-wrap {
  width: 32px;
  height: 32px;
}

/* Content */
.anchor-content {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.anchor-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
}

.anchor-type-label {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--text-tertiary);
}

.wake-time-badge {
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--warning);
  padding: 2px 8px;
  background: rgba(244, 183, 64, 0.12);
  border-radius: var(--radius-full);
  font-variant-numeric: tabular-nums;
}

.bedtime-badge-wrap {
  display: flex;
  align-items: center;
}

.overflow-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: var(--text-xs);
  font-weight: 700;
  color: var(--warning);
  background: var(--warning-soft);
  border: 1px solid rgba(244, 183, 64, 0.3);
  padding: 3px 8px;
  border-radius: var(--radius-full);
  font-variant-numeric: tabular-nums;
}

.on-track-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--success);
  background: var(--success-soft);
  border: 1px solid color-mix(in srgb, var(--success) 25%, transparent);
  padding: 3px 8px;
  border-radius: var(--radius-full);
}

.anchor-title {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--text-primary);
  margin: 0;
  line-height: 1.3;
}

.anchor-subtitle {
  font-size: var(--text-xs);
  color: var(--text-secondary);
  margin: 0;
}

.overflow-warning-text {
  font-size: var(--text-xs);
  color: var(--warning);
  margin-top: 4px;
  font-weight: 500;
}
</style>
