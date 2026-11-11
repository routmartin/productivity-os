<script setup lang="ts">
import { computed } from 'vue'
import {
  BookOpen,
  Check,
  Coffee,
  Droplets,
  Dumbbell,
  Flame,
  Footprints,
  Moon,
  Smile,
  Sparkles,
  Target,
  Zap,
} from 'lucide-vue-next'

import type { ScheduleNode } from '../../types'
import { useScheduleStore } from '../../scheduleStore'

const props = withDefaults(
  defineProps<{
    node: ScheduleNode
    compact?: boolean
    selected?: boolean
  }>(),
  {
    compact: false,
    selected: false,
  },
)

const emit = defineEmits<{
  (e: 'toggle', nodeId: string): void
  (e: 'select', nodeId: string): void
}>()

const scheduleStore = useScheduleStore()

const isSelected = computed(() => props.selected || scheduleStore.selectedNodeId === props.node.id)
const isCompleted = computed(() => Boolean(props.node.completed))
const streak = computed(() => props.node.streak ?? 0)

const iconComponent = computed(() => {
  switch (props.node.icon) {
    case 'Droplets':
    case 'water':
      return Droplets
    case 'Dumbbell':
    case 'dumbbell':
      return Dumbbell
    case 'Target':
      return Target
    case 'Footprints':
      return Footprints
    case 'Moon':
    case 'moon':
      return Moon
    case 'BookOpen':
    case 'book':
      return BookOpen
    case 'Coffee':
    case 'coffee':
      return Coffee
    case 'Zap':
    case 'zap':
      return Zap
    case 'Smile':
    case 'smile':
      return Smile
    case 'Check':
    case 'check':
      return Check
    case 'Sparkles':
      return Sparkles
    default:
      return Flame
  }
})

function handleToggle(event: Event) {
  event.stopPropagation()
  scheduleStore.toggleHabit(props.node.id)
  emit('toggle', props.node.id)
}

function handleSelect() {
  scheduleStore.selectNode(props.node.id)
  emit('select', props.node.id)
}
</script>

<template>
  <div
    class="habit-node"
    :class="{
      completed: isCompleted,
      selected: isSelected,
      compact: compact,
    }"
    role="button"
    tabindex="0"
    :aria-pressed="isSelected"
    :aria-label="`Habit: ${node.title}, ${isCompleted ? 'completed' : 'incomplete'}, streak ${streak} days`"
    @click="handleSelect"
    @keydown.enter.prevent="handleSelect"
    @keydown.space.prevent="handleToggle"
  >
    <button
      type="button"
      class="check-toggle"
      :class="{ checked: isCompleted }"
      :aria-label="isCompleted ? 'Mark habit as incomplete' : 'Mark habit as complete'"
      @click="handleToggle"
    >
      <Check v-if="isCompleted" :size="13" :stroke-width="3" class="check-icon" />
    </button>

    <div class="habit-icon-wrap" :class="{ completed: isCompleted }">
      <component :is="iconComponent" :size="compact ? 14 : 16" />
    </div>

    <div class="habit-content">
      <div class="habit-header">
        <span class="habit-title">{{ node.title }}</span>
        <span v-if="node.time && !compact" class="habit-time">{{ node.time }}</span>
      </div>
      <p v-if="node.subtitle && !compact" class="habit-subtitle">
        {{ node.subtitle }}
      </p>
    </div>

    <div class="habit-streak" :class="{ 'streak-lit': streak > 0 && isCompleted }" title="Daily Habit Streak">
      <Flame :size="12" class="flame-icon" />
      <span class="streak-count">{{ streak }}d</span>
    </div>
  </div>
</template>

<style scoped>
.habit-node {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  cursor: pointer;
  user-select: none;
  transition: all 0.2s var(--ease-out);
  position: relative;
  text-align: left;
}

.habit-node:hover {
  background: var(--surface-2);
  border-color: var(--border-strong);
  transform: translateY(-1px);
}

.habit-node.selected {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px var(--accent-border), 0 4px 16px rgba(108, 92, 231, 0.16);
  background: var(--surface-2);
}

.habit-node.completed {
  border-color: rgba(57, 197, 138, 0.28);
  background: rgba(17, 20, 27, 0.95);
}

.habit-node.completed:hover {
  border-color: rgba(57, 197, 138, 0.45);
}

/* Compact matrix mode */
.habit-node.compact {
  padding: var(--space-2) var(--space-3);
  gap: var(--space-2);
  border-radius: var(--radius-sm);
}

.habit-node.compact .habit-title {
  font-size: var(--text-xs);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 140px;
}

/* Checkbox button */
.check-toggle {
  width: 22px;
  height: 22px;
  border-radius: var(--radius-full);
  border: 1.5px solid var(--border-strong);
  background: transparent;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
  transition: all 0.18s var(--ease-out);
  padding: 0;
}

.check-toggle:hover {
  border-color: var(--success);
  background: var(--success-soft);
}

.check-toggle.checked {
  background: var(--success);
  border-color: var(--success);
  color: #0b0d12;
  box-shadow: 0 0 10px rgba(57, 197, 138, 0.4);
}

.check-icon {
  animation: checkPop 0.2s var(--ease-out);
}

@keyframes checkPop {
  0% {
    transform: scale(0.6);
  }
  100% {
    transform: scale(1);
  }
}

/* Icon Wrap */
.habit-icon-wrap {
  width: 30px;
  height: 30px;
  border-radius: var(--radius-md);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--accent-strong);
  flex-shrink: 0;
  transition: all 0.2s;
}

.compact .habit-icon-wrap {
  width: 24px;
  height: 24px;
  border-radius: var(--radius-sm);
}

.habit-icon-wrap.completed {
  color: var(--success);
  background: var(--success-soft);
  border-color: rgba(57, 197, 138, 0.2);
}

/* Text Content */
.habit-content {
  flex: 1;
  min-width: 0;
}

.habit-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
}

.habit-title {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-primary);
  line-height: 1.3;
  transition: color 0.18s;
}

.completed .habit-title {
  color: var(--text-secondary);
}

.habit-time {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  font-variant-numeric: tabular-nums;
  flex-shrink: 0;
}

.habit-subtitle {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  margin-top: 2px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Streak Badge */
.habit-streak {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 3px 7px;
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-full);
  font-size: 11px;
  font-weight: 600;
  color: var(--text-tertiary);
  flex-shrink: 0;
  transition: all 0.2s;
}

.flame-icon {
  color: var(--orange);
}

.streak-lit {
  background: var(--orange-soft);
  border-color: rgba(232, 131, 73, 0.3);
  color: var(--orange);
  box-shadow: 0 0 8px rgba(232, 131, 73, 0.2);
}
</style>
