<script setup lang="ts">
import { ref } from 'vue'
import { Play } from 'lucide-vue-next'

import SurfaceCard from '@/components/shared/SurfaceCard.vue'
import UiButton from '@/components/ui/UiButton.vue'

/** Visual-only in Milestone 1 — pressing start says so honestly. */
const noteVisible = ref(false)
let noteTimer: ReturnType<typeof setTimeout> | undefined

function onStart() {
  noteVisible.value = true
  clearTimeout(noteTimer)
  noteTimer = setTimeout(() => (noteVisible.value = false), 3200)
}
</script>

<template>
  <SurfaceCard>
    <div class="focus-card">
      <div class="status-row">
        <span class="live-dot" aria-hidden="true" />
        <span class="label">Focus Session</span>
      </div>

      <h3 class="question">Ready to focus?</h3>
      <p class="timer tnum" aria-label="No focus session running">00:00</p>
      <p class="hint">Start focusing on your top priority</p>

      <UiButton variant="primary" size="lg" full-width class="start" @click="onStart">
        <Play :size="15" :stroke-width="2" />
        Start Focus
      </UiButton>

      <Transition name="fade">
        <p v-if="noteVisible" class="note" role="status">
          Focus sessions arrive in Milestone 2 — this button is visual for now.
        </p>
      </Transition>
    </div>
  </SurfaceCard>
</template>

<style scoped>
.focus-card {
  display: flex;
  flex-direction: column;
}

.status-row {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-bottom: var(--space-3);
}

.live-dot {
  width: 7px;
  height: 7px;
  border-radius: var(--radius-full);
  background: var(--success);
}

.label {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-secondary);
}

.question {
  font-size: var(--text-md);
  font-weight: 500;
  color: var(--text-secondary);
  margin-bottom: var(--space-3);
}

.timer {
  font-size: 40px;
  font-weight: 300;
  letter-spacing: 0.02em;
  line-height: 1.15;
  color: var(--text-primary);
}

.hint {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  margin: var(--space-1) 0 var(--space-5);
}

.note {
  margin-top: var(--space-3);
  font-size: var(--text-xs);
  line-height: 1.5;
  color: var(--text-tertiary);
}

/* The focus CTA uses the deeper indigo from the approved reference,
   distinct from the brighter primary action color. */
.start {
  background: var(--accent-deep);
}

.start:hover:not(:disabled) {
  background: var(--accent);
}
</style>
