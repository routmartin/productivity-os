<script setup lang="ts">
import { Sparkles } from 'lucide-vue-next'

import UiButton from '@/components/ui/UiButton.vue'

import type { Briefing } from '../mock'

defineProps<{ briefing: Briefing }>()

const emit = defineEmits<{ plan: [] }>()
</script>

<template>
  <section class="briefing" aria-label="AI briefing">
    <div class="content">
      <span class="eyebrow">
        <Sparkles :size="14" :stroke-width="2" aria-hidden="true" />
        AI Briefing
      </span>

      <h2 class="headline">
        You have
        <span class="highlight">{{ briefing.focusCount }} important things</span>
        to focus on today.
      </h2>
      <p class="subline">{{ briefing.subline }}</p>

      <UiButton variant="primary" size="md" class="cta" @click="emit('plan')">
        <Sparkles :size="15" :stroke-width="2" />
        {{ briefing.ctaLabel }}
      </UiButton>
    </div>

    <!-- Ambient AI orb — the reference's signature visual. Pure CSS. -->
    <div class="orb-stage" aria-hidden="true">
      <div class="orb-glow" />
      <div class="orb-ring" />
      <div class="orb" />
      <span class="star star-a" />
      <span class="star star-b" />
      <span class="star star-c" />
    </div>
  </section>
</template>

<style scoped>
.briefing {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-8);
  min-height: 218px;
  padding: var(--space-7) var(--space-8);
  border: 1px solid var(--ai-border);
  border-radius: var(--radius-xl);
  background:
    radial-gradient(720px 320px at 88% 40%, rgba(139, 108, 255, 0.14), transparent 65%),
    linear-gradient(120deg, rgba(108, 92, 231, 0.1), rgba(17, 20, 27, 0) 55%),
    var(--surface-1);
  overflow: hidden;
}

.content {
  position: relative;
  z-index: 1;
  min-width: 0;
}

.eyebrow {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--ai-strong);
}

.headline {
  margin-top: var(--space-3);
  font-size: var(--text-3xl);
  font-weight: 650;
  letter-spacing: -0.02em;
  line-height: 1.25;
  color: var(--text-primary);
  max-width: 24ch;
}

.highlight {
  color: var(--ai-strong);
}

.subline {
  margin-top: var(--space-2);
  font-size: var(--text-lg);
  color: var(--text-secondary);
}

.cta {
  margin-top: var(--space-5);
}

/* ——— Orb ——— */
.orb-stage {
  position: relative;
  width: 260px;
  height: 100%;
  min-height: 170px;
  flex-shrink: 0;
}

.orb-glow {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 260px;
  height: 260px;
  transform: translate(-50%, -50%);
  border-radius: 50%;
  background: radial-gradient(circle, rgba(139, 108, 255, 0.4), transparent 65%);
  filter: blur(28px);
}

.orb {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 132px;
  height: 132px;
  transform: translate(-50%, -50%);
  border-radius: 50%;
  background: radial-gradient(
    circle at 32% 26%,
    #c4aeff 0%,
    #8b6cff 34%,
    #4c34b8 68%,
    #17122e 100%
  );
  box-shadow:
    inset -12px -18px 36px rgba(6, 4, 18, 0.65),
    0 18px 48px rgba(108, 92, 231, 0.45);
}

.orb-ring {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 240px;
  height: 84px;
  transform: translate(-50%, -50%) rotate(-16deg);
  border: 1.5px solid rgba(167, 139, 250, 0.4);
  border-radius: 50%;
  box-shadow: 0 0 22px rgba(139, 108, 255, 0.18);
}

.star {
  position: absolute;
  width: 3px;
  height: 3px;
  border-radius: 50%;
  background: var(--ai-strong);
  box-shadow: 0 0 8px var(--ai-strong);
}

.star-a {
  top: 22%;
  left: 18%;
}

.star-b {
  top: 30%;
  right: 14%;
  width: 2px;
  height: 2px;
}

.star-c {
  bottom: 18%;
  left: 30%;
  width: 2px;
  height: 2px;
}

/* The orb folds away before the text is ever squeezed. */
@media (max-width: 900px) {
  .orb-stage {
    display: none;
  }
}
</style>
