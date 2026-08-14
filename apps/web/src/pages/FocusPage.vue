<script setup lang="ts">
import { computed, onMounted, ref, watch } from "vue";
import { useRoute } from "vue-router";
import {
  Check,
  CheckCircle2,
  Folder,
  ListChecks,
  Play,
  Search,
  Timer,
} from "lucide-vue-next";

import EmptyState from "@/components/shared/EmptyState.vue";
import ErrorState from "@/components/shared/ErrorState.vue";
import SkeletonBlock from "@/components/shared/SkeletonBlock.vue";
import SurfaceCard from "@/components/shared/SurfaceCard.vue";
import UiButton from "@/components/ui/UiButton.vue";
import UiPill from "@/components/ui/UiPill.vue";
import FocusSummary from "@/features/focus/components/FocusSummary.vue";
import { useFocusStore } from "@/features/focus/store";
import { useTasksStore } from "@/features/tasks/store";
import { findProjectById } from "@/features/tasks/mock";
import { PRIORITY_LABELS } from "@/features/tasks/types";
import type { Priority, Task } from "@/features/tasks/types";
import type { PreviewState } from "@/features/planning/types";

const route = useRoute();
const focusStore = useFocusStore();
const tasksStore = useTasksStore();

const search = ref("");

function previewFromQuery(): PreviewState {
  const value = route.query.preview;
  return value === "loading" || value === "error" || value === "empty" ? value : null;
}

onMounted(() => {
  const preview = previewFromQuery();
  tasksStore.load(preview);
  // Default-select the first eligible task so the start bar is ready to go.
  if (!preview && !focusStore.selectedTaskId) {
    focusStore.selectTask(focusStore.eligibleTasks[0]?.id ?? null);
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

const filteredTasks = computed<Task[]>(() => {
  const query = search.value.trim().toLowerCase();
  if (!query) return focusStore.eligibleTasks;
  return focusStore.eligibleTasks.filter((t) =>
    t.title.toLowerCase().includes(query),
  );
});

const hasNoTasks = computed(
  () => tasksStore.status === "ready" && focusStore.eligibleTasks.length === 0,
);

const selectedTask = computed(() => focusStore.selectedTask);

const selectedProject = computed(() => {
  const task = selectedTask.value;
  if (!task?.projectId) return null;
  return findProjectById(task.projectId) ?? null;
});

function projectName(task: Task): string | null {
  if (!task.projectId) return null;
  return findProjectById(task.projectId)?.name ?? null;
}

function priorityTone(priority: Priority): "danger" | "warning" | "neutral" {
  if (priority === "HIGH") return "danger";
  if (priority === "MEDIUM") return "warning";
  return "neutral";
}

function onSelect(taskId: string) {
  focusStore.selectTask(focusStore.selectedTaskId === taskId ? null : taskId);
}

function onRetry() {
  tasksStore.load(null);
}
</script>

<template>
  <div class="focus-page">
    <!-- Loading -->
    <div v-if="isLoading" class="loading" aria-busy="true" aria-label="Loading tasks">
      <div class="loading-header">
        <div class="loading-head">
          <SkeletonBlock height="34px" width="180px" rounded="md" />
          <SkeletonBlock height="20px" width="280px" rounded="md" />
        </div>
        <SkeletonBlock height="40px" width="200px" rounded="md" />
      </div>
      <div class="loading-toolbar">
        <SkeletonBlock height="44px" width="420px" rounded="md" />
        <SkeletonBlock height="20px" width="90px" rounded="md" />
      </div>
      <div class="card-grid">
        <SkeletonBlock v-for="n in 6" :key="n" height="148px" rounded="lg" />
      </div>
      <SkeletonBlock height="180px" rounded="lg" />
    </div>

    <!-- Error -->
    <ErrorState
      v-else-if="tasksStore.status === 'error'"
      title="Couldn't load tasks"
      description="Your tasks could not be reached. Try loading them again."
      @retry="onRetry"
    />

    <!-- IDLE -->
    <template v-else>
      <header class="page-header">
        <div class="page-heading">
          <h1 class="page-title">Focus</h1>
          <p class="page-subtitle">Pick one thing. Give it your full attention.</p>
        </div>
        <div v-if="!hasNoTasks" class="page-stats">
          <div class="page-stat">
            <span class="page-stat-value tnum">{{ focusStore.todaySummary.formatted }}</span>
            <span class="page-stat-label">focused today</span>
          </div>
          <span class="page-stat-divider" aria-hidden="true"></span>
          <div class="page-stat">
            <span class="page-stat-value tnum">{{ focusStore.todaySummary.sessions }}</span>
            <span class="page-stat-label">sessions</span>
          </div>
        </div>
      </header>

      <!-- Empty state -->
      <SurfaceCard v-if="hasNoTasks">
        <EmptyState
          :icon="ListChecks"
          title="Nothing to focus on yet."
          description="Create or plan a task first."
          compact
        >
          <RouterLink :to="{ name: 'tasks' }" class="empty-link">
            <UiButton variant="ghost" size="sm">Go to Tasks</UiButton>
          </RouterLink>
        </EmptyState>
      </SurfaceCard>

      <template v-else>
        <!-- Toolbar -->
        <div class="toolbar">
          <label class="search-box">
            <Search :size="15" :stroke-width="2" class="search-icon" aria-hidden="true" />
            <input
              v-model="search"
              type="search"
              class="search-input"
              placeholder="Filter tasks..."
              aria-label="Filter focus tasks"
            />
          </label>
          <span class="toolbar-meta tnum">{{ filteredTasks.length }} eligible</span>
        </div>

        <!-- Task card grid -->
        <div v-if="filteredTasks.length === 0" class="no-results">
          <p class="no-title">No matching tasks</p>
          <p class="no-desc">Try a different search.</p>
        </div>

        <div v-else class="card-grid" role="listbox" aria-label="Eligible tasks">
          <button
            v-for="task in filteredTasks"
            :key="task.id"
            class="task-card"
            :class="{ selected: focusStore.selectedTaskId === task.id }"
            role="option"
            :aria-selected="focusStore.selectedTaskId === task.id"
            @click="onSelect(task.id)"
          >
            <span class="card-check" aria-hidden="true">
              <Check
                v-if="focusStore.selectedTaskId === task.id"
                :size="13"
                :stroke-width="2.5"
              />
            </span>

            <span class="card-title">{{ task.title }}</span>

            <span class="card-meta">
              <UiPill v-if="projectName(task)" tone="accent">
                <Folder :size="11" :stroke-width="2" aria-hidden="true" />
                {{ projectName(task) }}
              </UiPill>
              <UiPill v-if="task.priority" :tone="priorityTone(task.priority)">
                {{ PRIORITY_LABELS[task.priority] }}
              </UiPill>
            </span>

            <span v-if="task.estimatedMinutes" class="card-estimate tnum">
              <Timer :size="13" :stroke-width="1.75" aria-hidden="true" />
              ~{{ task.estimatedMinutes }}m
            </span>
          </button>
        </div>

        <!-- Start bar -->
        <Transition name="rise">
          <div v-if="selectedTask" class="start-bar">
            <span class="start-bar-icon" aria-hidden="true">
              <CheckCircle2 :size="20" :stroke-width="2" />
            </span>
            <span class="start-bar-info">
              <span class="start-bar-title">{{ selectedTask.title }}</span>
              <span class="start-bar-meta">
                <UiPill v-if="selectedProject" tone="accent">{{ selectedProject.name }}</UiPill>
                <UiPill v-if="selectedTask.priority" tone="neutral">
                  {{ PRIORITY_LABELS[selectedTask.priority] }}
                </UiPill>
                <UiPill v-if="selectedTask.estimatedMinutes" tone="neutral">
                  ~{{ selectedTask.estimatedMinutes }}m
                </UiPill>
              </span>
            </span>
            <UiButton
              variant="primary"
              size="lg"
              class="start-btn"
              @click="focusStore.startFocus()"
            >
              <Play :size="15" :stroke-width="2" />
              Start Focus
            </UiButton>
          </div>
        </Transition>

        <!-- Today's focus summary -->
        <FocusSummary />
      </template>
    </template>
  </div>
</template>

<style scoped>
.focus-page {
  max-width: var(--content-max);
  margin: 0 auto;
  padding: var(--space-8) var(--space-10) var(--space-16);
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

/* Loading */
.loading {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.loading-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-6);
}

.loading-head {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.loading-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
}

/* Page header — same pattern as other pages */
.page-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-6);
  flex-wrap: wrap;
}

.page-title {
  font-size: var(--text-3xl);
  font-weight: 700;
  letter-spacing: -0.025em;
  color: var(--text-primary);
}

.page-subtitle {
  margin-top: var(--space-2);
  font-size: var(--text-lg);
  color: var(--text-tertiary);
}

.page-stats {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  padding-bottom: 2px;
}

.page-stat {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 1px;
}

.page-stat-value {
  font-size: var(--text-xl);
  font-weight: 650;
  letter-spacing: -0.02em;
  color: var(--text-primary);
}

.page-stat-label {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.page-stat-divider {
  width: 1px;
  height: 28px;
  background: var(--border-subtle);
}

.empty-link {
  margin-top: var(--space-2);
  display: inline-block;
}

/* Toolbar */
.toolbar {
  display: flex;
  align-items: center;
  gap: var(--space-4);
}

.search-box {
  position: relative;
  flex: 1;
  max-width: 420px;
  display: flex;
  align-items: center;
}

.search-icon {
  position: absolute;
  left: var(--space-4);
  color: var(--text-tertiary);
  pointer-events: none;
}

.search-input {
  width: 100%;
  height: 44px;
  padding: 0 var(--space-4) 0 var(--space-10);
  border-radius: var(--radius-md);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  color: var(--text-primary);
  font-size: var(--text-md);
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.search-input::placeholder {
  color: var(--text-tertiary);
}

.search-input:hover {
  background: var(--surface-2);
}

.search-input:focus {
  outline: none;
  border-color: var(--accent-border);
  background: var(--surface-1);
  box-shadow: 0 0 0 3px var(--accent-soft);
}

.toolbar-meta {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  white-space: nowrap;
}

/* Task card grid */
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: var(--space-4);
}

.task-card {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: var(--space-3);
  min-height: 148px;
  padding: var(--space-5);
  border-radius: var(--radius-lg);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  text-align: left;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out),
    box-shadow var(--duration-fast) var(--ease-out);
}

.task-card:hover {
  background: var(--surface-2);
  border-color: var(--border-strong);
  transform: translateY(-2px);
}

.task-card.selected {
  background: var(--accent-soft);
  border-color: var(--accent-border);
  box-shadow: 0 8px 28px var(--accent-glow);
}

.card-check {
  position: absolute;
  top: var(--space-4);
  right: var(--space-4);
  display: grid;
  place-items: center;
  width: 22px;
  height: 22px;
  border-radius: var(--radius-full);
  border: 1.5px solid var(--border-strong);
  color: transparent;
}

.task-card.selected .card-check {
  border-color: var(--accent);
  background: var(--accent);
  color: var(--on-accent);
}

.card-title {
  font-size: var(--text-lg);
  font-weight: 600;
  letter-spacing: -0.01em;
  line-height: 1.35;
  color: var(--text-primary);
  padding-right: var(--space-8);
}

.card-meta {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.card-estimate {
  margin-top: auto;
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.no-results {
  text-align: center;
  padding: var(--space-10) var(--space-4);
}

.no-title {
  font-size: var(--text-md);
  font-weight: 500;
  color: var(--text-secondary);
}

.no-desc {
  margin-top: var(--space-1);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

/* Start bar — sticky, spans full width */
.start-bar {
  position: sticky;
  bottom: var(--space-6);
  z-index: 10;
  display: flex;
  align-items: center;
  gap: var(--space-4);
  padding: var(--space-4) var(--space-5);
  border-radius: var(--radius-lg);
  background: var(--surface-1);
  border: 1px solid var(--accent-border);
  box-shadow:
    0 0 0 1px var(--accent-soft),
    0 16px 48px rgba(0, 0, 0, 0.45),
    0 8px 32px var(--accent-glow);
}

.start-bar-icon {
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  background: var(--accent-soft);
  color: var(--accent-strong);
}

.start-bar-info {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  min-width: 0;
  flex: 1;
}

.start-bar-title {
  font-size: var(--text-lg);
  font-weight: 600;
  letter-spacing: -0.01em;
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.start-bar-meta {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.start-btn {
  flex-shrink: 0;
}


/* Start bar entrance */
.rise-enter-active {
  transition:
    opacity var(--duration-normal) var(--ease-out),
    transform var(--duration-normal) var(--ease-out);
}

.rise-enter-from {
  opacity: 0;
  transform: translateY(8px);
}
</style>
