<script setup lang="ts">
import { Clock } from "lucide-vue-next";

import SectionHeader from "@/components/shared/SectionHeader.vue";
import { useFocusStore } from "@/features/focus/store";
import { PRIORITY_LABELS } from "@/features/tasks/types";
import type { Priority } from "@/features/tasks/types";

const store = useFocusStore();
</script>

<template>
  <div class="focus-history">
    <SectionHeader title="Recent Focus" />
    <ul v-if="store.sessionHistory.length > 0" class="session-list">
      <li v-for="session in store.sessionHistory.slice(0, 8)" :key="session.id" class="session-row">
        <span class="session-icon">
          <Clock :size="14" :stroke-width="1.75" />
        </span>
        <span class="session-info">
          <span class="session-title">{{ session.taskTitle }}</span>
          <span class="session-meta">
            <span v-if="session.projectName" class="session-project">
              {{ session.projectName }}
            </span>
            <span v-if="session.priority" class="session-priority">
              {{ PRIORITY_LABELS[session.priority as Priority] }}
            </span>
          </span>
        </span>
        <span class="session-duration tnum">{{ store.formattedDuration(session.durationSeconds) }}</span>
      </li>
    </ul>
    <p v-else class="empty">No focus sessions yet.</p>
  </div>
</template>

<style scoped>
.focus-history {
  display: flex;
  flex-direction: column;
}

.session-list {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.session-row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3);
  border-radius: var(--radius-md);
}

.session-icon {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  flex-shrink: 0;
  border-radius: var(--radius-sm);
  background: var(--surface-2);
  color: var(--text-tertiary);
}

.session-info {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-width: 0;
  flex: 1;
}

.session-title {
  font-size: var(--text-md);
  font-weight: 550;
  color: var(--text-primary);
}

.session-meta {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.session-duration {
  font-size: var(--text-md);
  font-weight: 550;
  color: var(--text-secondary);
  flex-shrink: 0;
}

.empty {
  padding: var(--space-4) var(--space-3);
  font-size: var(--text-md);
  color: var(--text-tertiary);
}
</style>
