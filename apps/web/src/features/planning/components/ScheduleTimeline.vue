<script setup lang="ts">
import { ArrowRight, CalendarClock } from 'lucide-vue-next'

import EmptyState from '@/components/shared/EmptyState.vue'
import SectionHeader from '@/components/shared/SectionHeader.vue'

import type { ScheduleEntry } from '../types'

defineProps<{ entries: ScheduleEntry[] }>()

const emit = defineEmits<{ select: [taskId: string] }>()

function durationLabel(minutes: number): string {
  return `${minutes}m`
}

function onKeydown(event: KeyboardEvent, taskId: string | null) {
  if (!taskId) return
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    emit('select', taskId)
  }
}
</script>

<template>
  <section class="schedule panel">
    <SectionHeader title="Today's Schedule" />

    <ol v-if="entries.length > 0" class="timeline">
      <li v-for="entry in entries" :key="entry.id" class="slot">
        <span class="time tnum">{{ entry.time ?? '—' }}</span>
        <span class="rail" aria-hidden="true">
          <span class="dot" :class="`tone-${entry.tone}`" />
        </span>
        <div
          class="entry"
          :class="[`tone-${entry.tone}`, { clickable: entry.taskId }]"
          :role="entry.taskId ? 'button' : undefined"
          :tabindex="entry.taskId ? 0 : undefined"
          @click="entry.taskId && emit('select', entry.taskId)"
          @keydown="onKeydown($event, entry.taskId)"
        >
          <span class="entry-body">
            <span class="entry-title">{{ entry.title }}</span>
            <span class="entry-meta">{{ entry.meta }}</span>
          </span>
          <span class="duration tnum">{{ durationLabel(entry.durationMinutes) }}</span>
        </div>
      </li>
    </ol>

    <EmptyState
      v-else
      :icon="CalendarClock"
      title="Nothing scheduled"
      description="Plan tasks into time blocks and they will show up here."
      compact
    />

    <div v-if="entries.length > 0" class="footer">
      <RouterLink :to="{ name: 'timeline' }" class="footer-link">
        View full timeline
        <ArrowRight :size="14" :stroke-width="2" />
      </RouterLink>
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

.timeline {
  display: flex;
  flex-direction: column;
}

.slot {
  position: relative;
  display: flex;
  align-items: stretch;
  gap: var(--space-3);
  padding-bottom: var(--space-3);
}

.slot:last-child {
  padding-bottom: 0;
}

.time {
  width: 40px;
  flex-shrink: 0;
  padding-top: var(--space-4);
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--text-tertiary);
  text-align: right;
}

.rail {
  position: relative;
  width: 12px;
  flex-shrink: 0;
  display: flex;
  justify-content: center;
}

/* The continuous timeline spine. */
.rail::before {
  content: '';
  position: absolute;
  top: 0;
  bottom: 0;
  width: 2px;
  background: var(--border-strong);
}

.slot:first-child .rail::before {
  top: var(--space-5);
}

.slot:last-child .rail::before {
  bottom: auto;
  height: var(--space-5);
}

.dot {
  position: relative;
  z-index: 1;
  width: 10px;
  height: 10px;
  margin-top: var(--space-5);
  border-radius: var(--radius-full);
  background: var(--text-disabled);
  box-shadow: 0 0 0 3px var(--surface-1);
}

.dot.tone-accent {
  background: var(--accent);
}

.dot.tone-blue {
  background: var(--blue);
}

.dot.tone-success {
  background: var(--success);
}

.dot.tone-warning {
  background: var(--warning);
}

.entry {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  padding: var(--space-4);
  border: 1px solid transparent;
  border-radius: var(--radius-md);
  background: var(--surface-2);
  transition:
    border-color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.entry.clickable {
  cursor: pointer;
}

.entry.clickable:hover {
  transform: translateY(-1px);
  border-color: var(--border-strong);
}

.entry.tone-accent {
  background: linear-gradient(120deg, rgba(108, 92, 231, 0.16), rgba(108, 92, 231, 0.06));
  border-color: rgba(108, 92, 231, 0.22);
}

.entry.tone-blue {
  background: linear-gradient(120deg, rgba(59, 130, 246, 0.14), rgba(59, 130, 246, 0.05));
  border-color: rgba(59, 130, 246, 0.2);
}

.entry.tone-success {
  background: linear-gradient(120deg, rgba(57, 197, 138, 0.13), rgba(57, 197, 138, 0.05));
  border-color: rgba(57, 197, 138, 0.18);
}

.entry.tone-warning {
  background: linear-gradient(120deg, rgba(244, 183, 64, 0.13), rgba(232, 131, 73, 0.05));
  border-color: rgba(244, 183, 64, 0.18);
}

.entry-body {
  display: flex;
  flex-direction: column;
  gap: 3px;
  min-width: 0;
}

.entry-title {
  font-size: var(--text-lg);
  font-weight: 550;
  letter-spacing: -0.01em;
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.entry-meta {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.duration {
  flex-shrink: 0;
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--text-secondary);
}

.footer {
  margin-top: var(--space-4);
  padding-top: var(--space-4);
  border-top: 1px solid var(--border-subtle);
}

.footer-link {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--accent-strong);
  border-radius: var(--radius-sm);
}

.footer-link:hover {
  opacity: 0.82;
}
</style>
