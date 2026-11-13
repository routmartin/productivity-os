<script setup lang="ts">
import { computed } from 'vue'
import { Plus } from 'lucide-vue-next'

import type { BoardColumnId, Task, TaskStatus } from '../types'
import TaskBoardCard from './TaskBoardCard.vue'

const props = withDefaults(
  defineProps<{
    columnId: BoardColumnId
    title: string
    tasks: Task[]
    activeTaskId?: string | null
    draggingTaskId?: string | null
    grabbedTaskId?: string | null
    isOver?: boolean
  }>(),
  {
    activeTaskId: null,
    draggingTaskId: null,
    grabbedTaskId: null,
    isOver: false,
  },
)

const emit = defineEmits<{
  selectTask: [taskId: string]
  pointerdownTask: [event: PointerEvent, task: Task]
  keydownTask: [event: KeyboardEvent, task: Task]
  createTask: [status: TaskStatus]
}>()

const emptyConfig = computed(() => {
  switch (props.columnId) {
    case 'PLANNED':
      return {
        title: 'Queue is clear.',
        subtitle: 'Capture or schedule work to plan ahead.',
        buttonLabel: 'Add to To Do',
      }
    case 'IN_PROGRESS':
      return {
        title: 'Nothing in progress.',
        subtitle: 'Drag tasks here when you start focusing.',
        buttonLabel: 'Start a Task',
      }
    case 'COMPLETED':
      return {
        title: 'No completed tasks yet.',
        subtitle: 'Finish a task to see your momentum here.',
        buttonLabel: null,
      }
    default:
      return {
        title: '',
        subtitle: '',
        buttonLabel: null,
      }
  }
})

function onQuickAdd() {
  emit('createTask', props.columnId)
}
</script>

<template>
  <section
    class="board-column"
    :class="[
      `column-${columnId.toLowerCase()}`,
      { 'is-over': isOver },
    ]"
    :data-column-id="columnId"
  >
    <!-- Column Header -->
    <header class="column-header">
      <div class="header-left">
        <span class="status-dot" />
        <h2 class="column-title">{{ title }}</h2>
        <span class="count-badge tnum">{{ tasks.length }}</span>
      </div>

      <button
        type="button"
        class="quick-add-btn"
        :aria-label="`Add task to ${title}`"
        title="Add task"
        @click="onQuickAdd"
      >
        <Plus :size="15" :stroke-width="2" />
      </button>
    </header>

    <!-- Cards Scroll Container -->
    <div class="cards-list" :data-drop-zone="columnId">
      <div v-if="isOver && tasks.length > 0" class="drop-indicator-line" aria-hidden="true" />
      <TransitionGroup name="board-card">
        <TaskBoardCard
          v-for="task in tasks"
          :key="task.id"
          :task="task"
          :active="task.id === activeTaskId"
          :is-dragging="task.id === draggingTaskId"
          :is-grabbed="task.id === grabbedTaskId"
          @select="emit('selectTask', task.id)"
          @pointerdown="emit('pointerdownTask', $event, task)"
          @keydown="emit('keydownTask', $event, task)"
        />
      </TransitionGroup>

      <!-- Empty Column Drop Zone -->
      <div
        v-if="tasks.length === 0"
        class="empty-column-zone"
        :class="{ 'drop-active': isOver }"
      >
        <p class="empty-title">{{ emptyConfig.title }}</p>
        <p class="empty-subtitle">{{ emptyConfig.subtitle }}</p>
        <button
          v-if="emptyConfig.buttonLabel"
          type="button"
          class="empty-add-btn"
          @click="onQuickAdd"
        >
          <Plus :size="13" :stroke-width="2" />
          <span>{{ emptyConfig.buttonLabel }}</span>
        </button>
      </div>
    </div>
  </section>
</template>

<style scoped>
.board-column {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  padding: var(--space-4);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  min-height: 480px;
  min-width: 0;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.board-column.is-over {
  border-color: var(--accent-border);
  background: linear-gradient(180deg, var(--accent-soft) 0%, var(--surface-1) 120px);
}

/* Header */
.column-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-2);
  padding: var(--space-1) var(--space-2) var(--space-2);
}

.header-left {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  min-width: 0;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: var(--radius-full);
  flex-shrink: 0;
}

.column-planned .status-dot {
  background: var(--text-tertiary);
}

.column-in_progress .status-dot {
  background: var(--accent-strong);
  box-shadow: 0 0 8px var(--accent-glow);
}

.column-completed .status-dot {
  background: var(--success);
}

.column-title {
  font-size: var(--text-md);
  font-weight: 650;
  color: var(--text-primary);
  letter-spacing: -0.01em;
  line-height: 1.2;
}

.count-badge {
  display: inline-grid;
  place-items: center;
  min-width: 22px;
  height: 20px;
  padding: 0 6px;
  border-radius: var(--radius-full);
  font-size: 11px;
  font-weight: 600;
  flex-shrink: 0;
}

.column-planned .count-badge {
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  color: var(--text-tertiary);
}

.column-in_progress .count-badge {
  background: var(--accent-soft);
  border: 1px solid var(--accent-border);
  color: var(--accent-strong);
}

.column-completed .count-badge {
  background: var(--success-soft);
  border: 1px solid rgba(57, 197, 138, 0.28);
  color: var(--success);
}

.quick-add-btn {
  display: grid;
  place-items: center;
  width: 26px;
  height: 26px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--text-tertiary);
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.quick-add-btn:hover {
  background: var(--surface-2);
  color: var(--text-primary);
}

/* Cards List */
.cards-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  min-height: 160px;
  flex: 1;
}

.drop-indicator-line {
  height: 2px;
  width: 100%;
  background: var(--accent-strong);
  border-radius: var(--radius-full);
  box-shadow: 0 0 8px var(--accent-glow);
  margin: var(--space-1) 0;
  animation: pulse-line 1.5s ease-in-out infinite;
}

@keyframes pulse-line {
  0%, 100% {
    opacity: 0.8;
  }
  50% {
    opacity: 1;
  }
}

/* Empty Column State */
.empty-column-zone {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  padding: var(--space-6) var(--space-4);
  border: 1.5px dashed var(--border-subtle);
  border-radius: var(--radius-md);
  min-height: 180px;
  text-align: center;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.empty-column-zone.drop-active {
  border-color: var(--accent-border);
  background: var(--accent-soft);
}

.empty-title {
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--text-secondary);
  line-height: 1.3;
}

.empty-subtitle {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  line-height: 1.3;
}

.empty-add-btn {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  margin-top: var(--space-2);
  padding: 5px 12px;
  border-radius: var(--radius-full);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  color: var(--text-secondary);
  font-size: var(--text-xs);
  font-weight: 550;
  cursor: pointer;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    border-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.empty-add-btn:hover {
  background: var(--surface-3);
  border-color: var(--border-strong);
  color: var(--text-primary);
}

/* Board card transitions */
.board-card-move {
  transition: transform var(--duration-normal) var(--ease-out);
}

.board-card-enter-active,
.board-card-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.board-card-enter-from,
.board-card-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

@media (prefers-reduced-motion: reduce) {
  .board-card-move,
  .board-card-enter-active,
  .board-card-leave-active {
    transition: none;
  }
}
</style>
