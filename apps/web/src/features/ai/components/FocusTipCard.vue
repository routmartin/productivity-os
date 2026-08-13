<script setup lang="ts">
import { Quote } from 'lucide-vue-next'

import { mockFocusTip } from '../mock'

/** Small ambient tip closing the Today right rail — purple, restrained. */
</script>

<template>
  <section class="focus-tip panel" aria-label="Focus tip">
    <div class="content">
      <span class="eyebrow">
        <Quote :size="13" :stroke-width="2" aria-hidden="true" />
        {{ mockFocusTip.title }}
      </span>
      <p class="body">{{ mockFocusTip.body }}</p>
    </div>

    <!-- Restrained ambient illustration (pure CSS): a glowing horizon orb
         above quiet hills, echoing the reference artwork. -->
    <div class="art" aria-hidden="true">
      <div class="horizon-glow" />
      <div class="sun" />
      <div class="hill hill-back" />
      <div class="hill hill-front" />
    </div>
  </section>
</template>

<style scoped>
.panel {
  position: relative;
  display: flex;
  flex-direction: column;
  min-height: 168px;
  padding: var(--space-6);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  background:
    radial-gradient(360px 200px at 92% 100%, rgba(139, 108, 255, 0.12), transparent 70%),
    var(--surface-1);
  overflow: hidden;
}

.content {
  position: relative;
  z-index: 1;
  max-width: 70%;
}

.eyebrow {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--text-primary);
}

.eyebrow svg {
  color: var(--ai-strong);
}

.body {
  margin-top: var(--space-3);
  font-size: var(--text-md);
  line-height: 1.55;
  color: var(--text-secondary);
}

.art {
  position: absolute;
  right: 0;
  bottom: 0;
  width: 55%;
  height: 70%;
  pointer-events: none;
}

.horizon-glow {
  position: absolute;
  right: -10%;
  bottom: -30%;
  width: 240px;
  height: 240px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(139, 108, 255, 0.32), transparent 65%);
  filter: blur(20px);
}

.sun {
  position: absolute;
  right: 34px;
  bottom: 46px;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: radial-gradient(circle at 34% 30%, #c4aeff, #8b6cff 55%, #3c2a96 100%);
  box-shadow: 0 8px 30px rgba(139, 108, 255, 0.5);
}

.hill {
  position: absolute;
  bottom: -18px;
  border-radius: 50% 50% 0 0;
}

.hill-back {
  right: -30px;
  width: 220px;
  height: 74px;
  background: linear-gradient(180deg, rgba(76, 52, 184, 0.55), rgba(23, 18, 46, 0.9));
}

.hill-front {
  right: 30px;
  width: 170px;
  height: 52px;
  background: linear-gradient(180deg, rgba(46, 34, 104, 0.85), rgba(13, 10, 26, 0.95));
}
</style>
