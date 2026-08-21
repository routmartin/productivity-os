<script setup lang="ts">
import { computed, ref } from "vue";
import {
  CheckCircle2,
  ChevronDown,
  ChevronUp,
  Folder,
  Pause,
  Play,
  Square,
} from "lucide-vue-next";

import UiPill from "@/components/ui/UiPill.vue";
import { useFocusStore } from "@/features/focus/store";
import { useProjectsStore } from "@/features/projects/store";
import { PRIORITY_LABELS } from "@/features/tasks/types";

/**
 * Floating focus dock — the standalone "focus clock".
 * Rendered once in AppShell so an active session follows the user
 * across every page. Collapsed pill by default; expands into the
 * full timer dialog.
 */
const focusStore = useFocusStore();
const projectsStore = useProjectsStore();
const expanded = ref(false);

const project = computed(() => {
  const task = focusStore.selectedTask;
  if (!task?.projectId) return null;
  return projectsStore.projectById(task.projectId) ?? null;
});

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

function onDone() {
  expanded.value = false;
  focusStore.doneFocus();
}
</script>

<template>
  <Teleport to="body">
    <div
      v-if="focusStore.state !== 'idle'"
      class="focus-dock"
      :class="{
        'is-expanded': expanded,
        'is-paused': focusStore.state === 'paused',
        'is-complete': focusStore.state === 'completed',
      }"
      role="status"
    >
      <!-- Collapsed pill -->
      <Transition name="dock" mode="out-in" appear>
        <button
          v-if="!expanded"
          key="pill"
          class="dock-pill"
          :aria-label="`Focus session ${focusStore.state}, ${focusStore.formattedTime}. Expand focus timer.`"
          @click="expanded = true"
        >
          <span class="dock-dot" aria-hidden="true"></span>
          <span class="dock-time tnum">{{ focusStore.formattedTime }}</span>
          <span class="dock-task">{{ focusStore.selectedTask?.title }}</span>
          <ChevronUp :size="14" :stroke-width="2" aria-hidden="true" />
        </button>

        <!-- Expanded dialog -->
        <div v-else key="panel" class="dock-panel">
        <span class="dock-halo" aria-hidden="true"></span>

        <div class="dock-head">
          <UiPill
            :tone="
              focusStore.state === 'completed'
                ? 'success'
                : focusStore.state === 'paused'
                  ? 'warning'
                  : 'accent'
            "
            class="dock-status"
          >
            <template v-if="focusStore.state === 'completed'">
              <CheckCircle2 :size="12" :stroke-width="2" aria-hidden="true" />
              Complete
            </template>
            <template v-else>
              <span class="dock-dot" aria-hidden="true"></span>
              {{ focusStore.state === "paused" ? "Paused" : "Focusing" }}
            </template>
          </UiPill>
          <button
            class="dock-collapse"
            aria-label="Collapse focus timer"
            @click="expanded = false"
          >
            <ChevronDown :size="16" :stroke-width="2" aria-hidden="true" />
          </button>
        </div>

        <h3 class="dock-title">{{ focusStore.selectedTask?.title }}</h3>
        <p v-if="project" class="dock-project">
          <Folder :size="13" :stroke-width="1.75" aria-hidden="true" />
          {{ project.name }}
          <template v-if="focusStore.selectedTask?.priority">
            · {{ PRIORITY_LABELS[focusStore.selectedTask.priority] }}
          </template>
        </p>

        <p v-if="focusStore.state !== 'completed'" class="dock-timer tnum" aria-live="polite">
          {{ focusStore.formattedTime }}
        </p>
        <p v-else class="dock-timer complete tnum">
          {{ formattedCompletionDuration() }}
        </p>

        <p v-if="focusStore.state === 'completed'" class="dock-message">
          Nice work. Take a breath before the next one.
        </p>

        <div class="dock-actions">
          <template v-if="focusStore.state === 'active'">
            <button class="dock-btn primary" @click="focusStore.pauseFocus()">
              <Pause :size="14" :stroke-width="2" aria-hidden="true" />
              Pause
            </button>
            <button class="dock-btn ghost" @click="focusStore.stopFocus()">
              <Square :size="13" :stroke-width="2" aria-hidden="true" />
              End
            </button>
          </template>
          <template v-else-if="focusStore.state === 'paused'">
            <button class="dock-btn primary" @click="focusStore.resumeFocus()">
              <Play :size="14" :stroke-width="2" aria-hidden="true" />
              Resume
            </button>
            <button class="dock-btn ghost" @click="focusStore.stopFocus()">
              <Square :size="13" :stroke-width="2" aria-hidden="true" />
              End
            </button>
          </template>
          <template v-else>
            <button class="dock-btn primary wide" @click="onDone">Done</button>
          </template>
        </div>
      </div>
      </Transition>
    </div>
  </Teleport>
</template>

<style scoped>
.focus-dock {
  position: fixed;
  right: var(--space-6);
  bottom: var(--space-6);
  z-index: 90;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

/* Collapsed pill */
.dock-pill {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  max-width: 360px;
  height: 44px;
  padding: 0 var(--space-4);
  border-radius: var(--radius-full);
  background: var(--surface-1);
  border: 1px solid var(--accent-border);
  color: var(--text-primary);
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.4),
    0 4px 20px var(--accent-glow);
  transition:
    border-color var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.dock-pill:hover {
  border-color: var(--accent);
  transform: translateY(-1px);
}

.is-paused .dock-pill {
  border-color: var(--warning);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
}

.dock-dot {
  width: 8px;
  height: 8px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  background: var(--accent-strong);
}

.focus-dock:not(.is-paused):not(.is-complete) .dock-dot {
  animation: dock-pulse 2.4s var(--ease-out) infinite;
}

.is-paused .dock-dot {
  background: var(--warning);
}

@keyframes dock-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}

.dock-time {
  font-size: var(--text-md);
  font-weight: 650;
  letter-spacing: 0.02em;
}

.dock-task {
  max-width: 140px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

/* Expanded dialog */
.dock-panel {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-4);
  width: 340px;
  padding: var(--space-6);
  border-radius: var(--radius-xl);
  background: var(--surface-1);
  border: 1px solid var(--border-strong);
  box-shadow: var(--shadow-panel);
  overflow: hidden;
  text-align: center;
}

.dock-halo {
  position: absolute;
  inset: 0;
  pointer-events: none;
  background:
    radial-gradient(360px 240px at 50% 30%, var(--accent-soft), transparent 70%);
}

.is-paused .dock-halo {
  background:
    radial-gradient(360px 240px at 50% 30%, var(--warning-soft), transparent 70%);
}

.is-complete .dock-halo {
  background:
    radial-gradient(360px 240px at 50% 30%, var(--success-soft), transparent 70%);
}

.dock-panel > *:not(.dock-halo) {
  position: relative;
}

.dock-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}

.dock-status {
  letter-spacing: 0.08em;
  text-transform: uppercase;
  font-weight: 600;
}

.dock-collapse {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  border-radius: var(--radius-full);
  color: var(--text-tertiary);
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.dock-collapse:hover {
  background: var(--surface-2);
  color: var(--text-primary);
}

.dock-title {
  font-size: var(--text-xl);
  font-weight: 650;
  letter-spacing: -0.015em;
  color: var(--text-primary);
  max-width: 100%;
}

.dock-project {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.dock-timer {
  font-size: 64px;
  font-weight: 200;
  letter-spacing: 0.02em;
  line-height: 1.1;
  color: var(--text-primary);
  font-variant-numeric: tabular-nums;
}

.is-paused .dock-timer {
  color: var(--text-secondary);
}

.dock-timer.complete {
  font-size: 48px;
}

.dock-message {
  font-size: var(--text-md);
  color: var(--text-secondary);
}

.dock-actions {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  width: 100%;
  margin-top: var(--space-2);
}

.dock-btn {
  flex: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  height: 42px;
  border-radius: var(--radius-md);
  font-size: var(--text-md);
  font-weight: 550;
  letter-spacing: -0.005em;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.dock-btn.primary {
  background: var(--accent);
  color: var(--on-accent);
  font-weight: 600;
}

.dock-btn.primary:hover {
  background: color-mix(in srgb, var(--accent) 88%, white);
}

.dock-btn.ghost {
  background: transparent;
  color: var(--text-secondary);
  border: 1px solid var(--border-strong);
}

.dock-btn.ghost:hover {
  background: var(--surface-2);
  color: var(--text-primary);
}

.dock-btn.wide {
  width: 100%;
}

/* Expand/collapse transition — the dock grows out of the pill and
   shrinks back into it (motion spec §22). */
.dock-enter-active {
  transition:
    opacity var(--motion-standard) var(--ease-out),
    transform var(--motion-standard) var(--ease-out);
}

.dock-leave-active {
  transition:
    opacity var(--motion-fast) var(--ease-in),
    transform var(--motion-fast) var(--ease-in);
}

.dock-enter-from,
.dock-leave-to {
  opacity: 0;
  transform: translateY(8px) scale(0.98);
}
</style>
