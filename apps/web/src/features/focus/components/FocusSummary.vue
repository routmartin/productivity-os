<script setup lang="ts">
import SectionHeader from "@/components/shared/SectionHeader.vue";
import { useFocusStore } from "@/features/focus/store";

const store = useFocusStore();
</script>

<template>
  <div class="focus-summary">
    <SectionHeader title="Today" />
    <div class="stats">
      <div class="stat">
        <span class="stat-value tnum">{{ store.todaySummary.formatted }}</span>
        <span class="stat-label">focused</span>
      </div>
      <div class="stat">
        <span class="stat-value tnum">{{ store.todaySummary.sessions }}</span>
        <span class="stat-label">sessions</span>
      </div>
      <div class="stat">
        <span class="stat-value tnum">{{ store.todaySummary.avgMinutes }}m</span>
        <span class="stat-label">average</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.focus-summary {
  display: flex;
  flex-direction: column;
}

.stats {
  display: flex;
  gap: var(--space-2);
}

.stat {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: var(--space-3) var(--space-2);
  border-radius: var(--radius-md);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
}

.stat-value {
  font-size: var(--text-lg);
  font-weight: 650;
  color: var(--text-primary);
}

.stat-label {
  margin-top: 2px;
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}
</style>
