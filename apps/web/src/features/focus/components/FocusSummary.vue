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
  padding: var(--space-4) var(--space-2);
  border-radius: var(--radius-md);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
}

.stat-value {
  font-size: var(--text-xl);
  font-weight: 650;
  letter-spacing: -0.02em;
  color: var(--text-primary);
}

.stat-label {
  margin-top: 3px;
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}
</style>
