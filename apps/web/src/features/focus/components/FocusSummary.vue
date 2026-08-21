<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { AudioLines, Clock, Layers, Timer, TrendingUp } from "lucide-vue-next";

import { mockFocusTrend } from "@/features/focus/mock";
import { useFocusStore } from "@/features/focus/store";

const store = useFocusStore();

/** Entrance gate — triggers ring fill + staggered stat reveals on mount. */
const visible = ref(false);
onMounted(() => {
  requestAnimationFrame(() => {
    visible.value = true;
  });
});

/* Progress ring — share of a mock 4h daily focus capacity. */
const DAILY_CAPACITY_MINUTES = 4 * 60;
const R = 56;
const CIRCUMFERENCE = 2 * Math.PI * R;

const totalMinutes = computed(() => {
  const now = new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return Math.floor(
    store.sessionHistory
      .filter((s) => new Date(s.startedAt) >= todayStart)
      .reduce((sum, s) => sum + s.durationSeconds, 0) / 60,
  );
});

const progress = computed(() =>
  Math.min(totalMinutes.value / DAILY_CAPACITY_MINUTES, 1),
);

const dashOffset = computed(() => CIRCUMFERENCE * (1 - progress.value));

const trend = mockFocusTrend.deltaPercent;
</script>

<template>
  <section class="focus-summary" :class="{ visible }" aria-label="Today's focus summary">
    <span class="summary-halo" aria-hidden="true"></span>

    <!-- Left: hero ring + total -->
    <div class="hero">
      <div class="ring-wrap" role="img" :aria-label="`${Math.round(progress * 100)}% of daily focus capacity`">
        <svg class="ring" viewBox="0 0 128 128">
          <circle
            cx="64" cy="64" :r="R"
            fill="none"
            stroke="var(--surface-3)"
            stroke-width="9"
          />
          <circle
            class="ring-progress"
            cx="64" cy="64" :r="R"
            fill="none"
            stroke="var(--accent)"
            stroke-width="9"
            stroke-linecap="round"
            :stroke-dasharray="CIRCUMFERENCE"
            :stroke-dashoffset="visible ? dashOffset : CIRCUMFERENCE"
            transform="rotate(-90 64 64)"
          />
        </svg>
        <span class="ring-icon" aria-hidden="true">
          <AudioLines :size="24" :stroke-width="2" />
        </span>
      </div>

      <div class="hero-stats">
        <span class="hero-label">Today's Focus</span>
        <span class="hero-value tnum">{{ store.todaySummary.formatted }}</span>
        <span class="hero-trend">
          <TrendingUp :size="14" :stroke-width="2" aria-hidden="true" />
          {{ trend }}% vs yesterday
        </span>
      </div>
    </div>

    <!-- Right: supporting stats -->
    <div class="stats">
      <div class="stat" style="--i: 0">
        <span class="stat-icon" aria-hidden="true">
          <Layers :size="15" :stroke-width="1.75" />
        </span>
        <span class="stat-value tnum">{{ store.todaySummary.sessions }}</span>
        <span class="stat-label">sessions</span>
      </div>
      <div class="stat" style="--i: 1">
        <span class="stat-icon" aria-hidden="true">
          <Timer :size="15" :stroke-width="1.75" />
        </span>
        <span class="stat-value tnum">{{ store.todaySummary.avgMinutes }}m</span>
        <span class="stat-label">avg session</span>
      </div>
      <div class="stat" style="--i: 2">
        <span class="stat-icon" aria-hidden="true">
          <Clock :size="15" :stroke-width="1.75" />
        </span>
        <span class="stat-value tnum">{{ totalMinutes }}m</span>
        <span class="stat-label">total minutes</span>
      </div>
    </div>
  </section>
</template>

<style scoped>
.focus-summary {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-8);
  padding: var(--space-6) var(--space-8);
  border-radius: var(--radius-lg);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  overflow: hidden;
}

.summary-halo {
  position: absolute;
  inset: 0;
  pointer-events: none;
  background:
    radial-gradient(520px 280px at 18% 50%, var(--accent-soft), transparent 70%);
  opacity: 0;
  transition: opacity 600ms var(--ease-out);
}

.visible .summary-halo {
  opacity: 1;
}

.focus-summary > *:not(.summary-halo) {
  position: relative;
}

/* Hero — ring + total */
.hero {
  display: flex;
  align-items: center;
  gap: var(--space-6);
  min-width: 0;
}

.ring-wrap {
  position: relative;
  width: 128px;
  height: 128px;
  flex-shrink: 0;
}

.ring {
  width: 100%;
  height: 100%;
  filter: drop-shadow(0 4px 16px var(--accent-glow));
}

.ring-progress {
  transition: stroke-dashoffset 1.2s var(--ease-out);
}

.ring-icon {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  color: var(--accent-strong);
}

.hero-stats {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.hero-label {
  font-size: var(--text-xs);
  font-weight: 700;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--text-tertiary);
}

.hero-value {
  font-size: 2.5rem;
  font-weight: 650;
  letter-spacing: -0.03em;
  line-height: 1.1;
  color: var(--text-primary);
}

.hero-trend {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  margin-top: var(--space-1);
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--success);
}

/* Supporting stats — staggered fade-up on mount */
.stats {
  display: flex;
  gap: var(--space-3);
}

.stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-1);
  min-width: 108px;
  padding: var(--space-4) var(--space-3);
  border-radius: var(--radius-md);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  opacity: 0;
  transform: translateY(10px);
  transition:
    opacity 420ms var(--ease-out),
    transform 420ms var(--ease-out);
  transition-delay: calc(var(--i) * 120ms + 200ms);
}

.visible .stat {
  opacity: 1;
  transform: translateY(0);
}

.stat-icon {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  border-radius: var(--radius-sm);
  background: var(--accent-soft);
  color: var(--accent-strong);
  margin-bottom: var(--space-1);
}

.stat-value {
  font-size: var(--text-xl);
  font-weight: 650;
  letter-spacing: -0.02em;
  color: var(--text-primary);
}

.stat-label {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

@container workspace (max-width: 760px) {
  .focus-summary {
    flex-direction: column;
    align-items: stretch;
    gap: var(--space-6);
  }

  .stats {
    justify-content: space-between;
  }

  .stat {
    flex: 1;
    min-width: 0;
  }
}

/* Reduced motion: reveal stats immediately — the stagger delay must not
   keep content hidden (motion spec §28). */
@media (prefers-reduced-motion: reduce) {
  .stat {
    opacity: 1;
    transform: none;
    transition-delay: 0ms;
  }

  .summary-halo {
    opacity: 1;
  }
}
</style>
