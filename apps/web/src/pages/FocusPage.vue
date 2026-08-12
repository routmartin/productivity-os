<script setup lang="ts">
import { computed, onMounted, watch } from "vue";
import { useRoute } from "vue-router";
import {
  ListChecks,
  Pause,
  Play,
  Square,
} from "lucide-vue-next";

import EmptyState from "@/components/shared/EmptyState.vue";
import ErrorState from "@/components/shared/ErrorState.vue";
import SectionHeader from "@/components/shared/SectionHeader.vue";
import SkeletonBlock from "@/components/shared/SkeletonBlock.vue";
import SurfaceCard from "@/components/shared/SurfaceCard.vue";
import UiButton from "@/components/ui/UiButton.vue";
import FocusHistory from "@/features/focus/components/FocusHistory.vue";
import FocusSummary from "@/features/focus/components/FocusSummary.vue";
import TaskSelector from "@/features/focus/components/TaskSelector.vue";
import { useFocusStore } from "@/features/focus/store";
import { useTasksStore } from "@/features/tasks/store";
import { findProjectById } from "@/features/tasks/mock";
import { PRIORITY_LABELS } from "@/features/tasks/types";
import type { Priority } from "@/features/tasks/types";
import type { PreviewState } from "@/features/planning/types";

const route = useRoute();
const focusStore = useFocusStore();
const tasksStore = useTasksStore();

function previewFromQuery(): PreviewState {
  const value = route.query.preview;
  return value === "loading" || value === "error" || value === "empty" ? value : null;
}

onMounted(() => {
  const preview = previewFromQuery();
  tasksStore.load(preview);
  if (!preview) {
    focusStore.selectTask(null);
  }
});

watch(
  () => route.query.preview,
  () => {
    const preview = previewFromQuery();
    tasksStore.load(preview);
  },
);

const isLoading = computed(
  () => tasksStore.status === "loading" || tasksStore.status === "idle",
);

const hasNoTasks = computed(
  () =>
    tasksStore.status === "ready" &&
    focusStore.eligibleTasks.length === 0,
);

const project = computed(() => {
  const task = focusStore.selectedTask;
  if (!task?.projectId) return null;
  return findProjectById(task.projectId) ?? null;
});

function onRetry() {
  tasksStore.load(null);
}

function formattedCompletionDuration(): string {
  const mins = Math.floor(focusStore.elapsedSeconds / 60);
  const secs = focusStore.elapsedSeconds % 60;
  if (mins >= 60) {
    const hrs = Math.floor(mins / 60);
    const rem = mins % 60;
    return `${hrs}h ${rem}m ${secs}s`;
  }
  return `${mins}m ${secs}s`;
}
</script>

<template>
  <div
    class="focus-page"
    :class="{
      'is-immersive': focusStore.state === 'active' || focusStore.state === 'paused',
    }"
  >
    <!-- Loading -->
    <div v-if="isLoading" class="loading" aria-busy="true" aria-label="Loading tasks">
      <SkeletonBlock height="120px" rounded="lg" />
      <SkeletonBlock height="48px" rounded="md" />
      <SkeletonBlock height="200px" rounded="lg" />
    </div>

    <!-- Error -->
    <ErrorState
      v-else-if="tasksStore.status === 'error'"
      title="Couldn't load tasks"
      description="Your tasks could not be reached. Try loading them again."
      @retry="onRetry"
    />

    <!-- IDLE STATE -->
    <template v-else-if="focusStore.state === 'idle'">
      <header class="idle-header">
        <h1 class="title">Focus</h1>
        <p class="subtitle">What do you want to work on?</p>
      </header>

      <div class="idle-grid">
        <div class="idle-main">
          <!-- Empty state: no eligible tasks -->
          <template v-if="hasNoTasks">
            <SurfaceCard>
              <EmptyState
                :icon="ListChecks"
                title="Nothing to focus on yet."
                description="Create or plan a task first."
                compact
              >
                <RouterLink :to="{ name: 'tasks' }" class="empty-link">
                  <UiButton variant="ghost" size="sm">
                    Go to Tasks
                  </UiButton>
                </RouterLink>
              </EmptyState>
            </SurfaceCard>
          </template>

          <!-- Task Selector -->
          <template v-else>
            <SurfaceCard>
              <SectionHeader title="Select a task" />
              <TaskSelector />
            </SurfaceCard>

            <!-- Selected task context -->
            <Transition name="fade">
              <SurfaceCard
                v-if="focusStore.selectedTask"
                class="task-context"
              >
                <SectionHeader title="Selected" />
                <div class="context-body">
                  <p class="context-title">{{ focusStore.selectedTask.title }}</p>
                  <div class="context-meta">
                    <span v-if="project" class="context-tag project">
                      {{ project.name }}
                    </span>
                    <span
                      v-if="focusStore.selectedTask.priority"
                      class="context-tag priority"
                    >
                      {{ PRIORITY_LABELS[focusStore.selectedTask.priority as Priority] }}
                    </span>
                    <span
                      v-if="focusStore.selectedTask.estimatedMinutes"
                      class="context-tag duration"
                    >
                      {{ focusStore.selectedTask.estimatedMinutes }}m
                    </span>
                  </div>
                </div>
              </SurfaceCard>
            </Transition>

            <!-- Start Focus -->
            <UiButton
              variant="primary"
              size="lg"
              full-width
              :disabled="!focusStore.selectedTaskId"
              class="start-btn"
              @click="focusStore.startFocus()"
            >
              <Play :size="15" :stroke-width="2" />
              Start Focus
            </UiButton>
          </template>
        </div>

        <div v-if="!hasNoTasks" class="idle-rail">
          <SurfaceCard>
            <FocusSummary />
          </SurfaceCard>
          <SurfaceCard>
            <FocusHistory />
          </SurfaceCard>
        </div>
      </div>
    </template>

    <!-- ACTIVE STATE -->
    <div
      v-else-if="focusStore.state === 'active'"
      class="focus-active"
    >
      <span class="focus-label">FOCUS</span>
      <h2 class="focus-task-title">{{ focusStore.selectedTask?.title }}</h2>
      <p v-if="project" class="focus-project">{{ project.name }}</p>
      <p class="focus-timer tnum" aria-live="polite" aria-label="Focus time">
        {{ focusStore.formattedTime }}
      </p>
      <div class="focus-actions">
        <UiButton variant="subtle" size="lg" @click="focusStore.pauseFocus()">
          <Pause :size="15" :stroke-width="2" />
          Pause
        </UiButton>
        <UiButton variant="ghost" size="lg" @click="focusStore.stopFocus()">
          <Square :size="14" :stroke-width="2" />
          Stop
        </UiButton>
      </div>
    </div>

    <!-- PAUSED STATE -->
    <div
      v-else-if="focusStore.state === 'paused'"
      class="focus-active is-paused"
    >
      <span class="focus-label paused-label">PAUSED</span>
      <h2 class="focus-task-title">{{ focusStore.selectedTask?.title }}</h2>
      <p v-if="project" class="focus-project">{{ project.name }}</p>
      <p class="focus-timer tnum" aria-live="polite" aria-label="Paused time">
        {{ focusStore.formattedTime }}
      </p>
      <div class="focus-actions">
        <UiButton variant="primary" size="lg" @click="focusStore.resumeFocus()">
          <Play :size="15" :stroke-width="2" />
          Resume
        </UiButton>
        <UiButton variant="ghost" size="lg" @click="focusStore.stopFocus()">
          <Square :size="14" :stroke-width="2" />
          Stop
        </UiButton>
      </div>
    </div>

    <!-- COMPLETED STATE -->
    <div
      v-else-if="focusStore.state === 'completed'"
      class="focus-complete"
    >
      <span class="complete-label">Focus complete</span>
      <h2 class="complete-title">{{ focusStore.selectedTask?.title }}</h2>
      <p class="complete-duration tnum">{{ formattedCompletionDuration() }}</p>
      <p class="complete-message">Nice work.</p>
      <UiButton variant="primary" size="lg" @click="focusStore.doneFocus()">
        Done
      </UiButton>
    </div>
  </div>
</template>

<style scoped>
.focus-page {
  max-width: 720px;
  margin: 0 auto;
  padding: var(--space-8) var(--space-8) var(--space-12);
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

/* Loading */
.loading {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

/* Idle */
.idle-header {
  margin-bottom: var(--space-1);
}

.title {
  font-size: var(--text-2xl);
  font-weight: 650;
  letter-spacing: -0.02em;
}

.subtitle {
  margin-top: var(--space-1);
  font-size: var(--text-md);
  color: var(--text-tertiary);
}

.idle-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 280px;
  gap: var(--space-5);
  align-items: start;
}

@media (max-width: 900px) {
  .idle-grid {
    grid-template-columns: 1fr;
  }

  .idle-rail {
    display: none;
  }
}

.idle-main {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.idle-rail {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.empty-link {
  margin-top: var(--space-2);
  display: inline-block;
}

/* Task context */
.task-context .context-body {
  padding: var(--space-3);
}

.context-title {
  font-size: var(--text-md);
  font-weight: 500;
  color: var(--text-primary);
}

.context-meta {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-top: var(--space-2);
  flex-wrap: wrap;
}

.context-tag {
  font-size: var(--text-xs);
  font-weight: 500;
  padding: 2px var(--space-2);
  border-radius: var(--radius-full);
  background: var(--surface-2);
  color: var(--text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.context-tag.project {
  background: var(--accent-soft);
  color: var(--accent-strong);
}

/* Start button uses deeper indigo */
.start-btn {
  background: var(--accent-deep);
}

.start-btn:hover:not(:disabled) {
  background: var(--accent);
}

/* Active / Paused — immersive, minimal */
.focus-active {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: calc(100vh - 200px);
  text-align: center;
  gap: var(--space-4);
}

.focus-label {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--accent-strong);
  background: var(--accent-soft);
  padding: 4px var(--space-3);
  border-radius: var(--radius-full);
}

.paused-label {
  color: var(--warning);
  background: var(--warning-soft);
}

.focus-task-title {
  font-size: var(--text-2xl);
  font-weight: 650;
  letter-spacing: -0.02em;
  max-width: 480px;
}

.focus-project {
  font-size: var(--text-md);
  color: var(--text-tertiary);
}

.focus-timer {
  font-size: 96px;
  font-weight: 200;
  letter-spacing: 0.02em;
  line-height: 1.1;
  color: var(--text-primary);
}

.is-paused .focus-timer {
  color: var(--text-secondary);
}

@media (max-width: 600px) {
  .focus-timer {
    font-size: 64px;
  }
}

.focus-actions {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  margin-top: var(--space-6);
}

/* Completed */
.focus-complete {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: calc(100vh - 200px);
  text-align: center;
  gap: var(--space-4);
}

.complete-label {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--success);
  background: var(--success-soft);
  padding: 4px var(--space-3);
  border-radius: var(--radius-full);
}

.complete-title {
  font-size: var(--text-2xl);
  font-weight: 650;
  letter-spacing: -0.02em;
  max-width: 480px;
}

.complete-duration {
  font-size: 64px;
  font-weight: 200;
  letter-spacing: 0.02em;
  line-height: 1.15;
  color: var(--text-primary);
}

.complete-message {
  font-size: var(--text-lg);
  color: var(--text-secondary);
}
</style>
