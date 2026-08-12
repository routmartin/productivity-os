<script setup lang="ts">
import { ref } from 'vue'
import { Check, RotateCcw, Sparkles } from 'lucide-vue-next'

import UiButton from '@/components/ui/UiButton.vue'
import UiPill from '@/components/ui/UiPill.vue'

import type { Briefing } from '../mock'

defineProps<{ briefing: Briefing }>()

type BriefingState = 'visible' | 'applied' | 'dismissed'

const state = ref<BriefingState>('visible')
const detailsOpen = ref(false)
</script>

<template>
  <Transition name="fade" mode="out-in">
    <section v-if="state !== 'dismissed'" key="briefing" class="briefing" aria-label="AI briefing">
      <div class="main">
        <span class="ai-tile" aria-hidden="true">
          <Sparkles :size="16" :stroke-width="1.75" />
        </span>

        <div class="content">
          <div class="heading">
            <h2 class="title">{{ briefing.assistantName }}</h2>
            <UiPill v-if="briefing.isNew" tone="ai">New</UiPill>
          </div>
          <p class="recommendation">{{ briefing.recommendation }}</p>
          <Transition name="fade">
            <p v-if="detailsOpen" class="rationale">{{ briefing.rationale }}</p>
          </Transition>
          <Transition name="fade">
            <p v-if="state === 'applied'" class="applied" role="status">
              <Check :size="13" :stroke-width="2" />
              “{{ briefing.suggestionTaskTitle }}” would move to tomorrow. Preview only — no changes
              were made.
            </p>
          </Transition>
        </div>
      </div>

      <div v-if="state === 'visible'" class="actions">
        <UiButton variant="ghost" @click="detailsOpen = !detailsOpen">
          {{ detailsOpen ? 'Hide details' : 'View details' }}
        </UiButton>
        <UiButton variant="primary" @click="state = 'applied'">Apply suggestion</UiButton>
        <button class="ignore" type="button" @click="state = 'dismissed'">Ignore</button>
      </div>
    </section>

    <button v-else key="restore" class="restore" type="button" @click="state = 'visible'">
      <Sparkles :size="13" :stroke-width="1.75" />
      Briefing dismissed
      <span class="undo">
        <RotateCcw :size="12" :stroke-width="1.75" />
        Show again
      </span>
    </button>
  </Transition>
</template>

<style scoped>
.briefing {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-6);
  padding: var(--space-5);
  border: 1px solid var(--ai-border);
  border-radius: var(--radius-lg);
  background:
    radial-gradient(520px 160px at 0% 0%, rgba(139, 92, 246, 0.09), transparent 70%),
    var(--surface-1);
}

.main {
  display: flex;
  align-items: flex-start;
  gap: var(--space-4);
  min-width: 0;
}

.ai-tile {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  flex-shrink: 0;
  border-radius: var(--radius-md);
  background: var(--ai-soft);
  color: var(--ai-strong);
}

.content {
  min-width: 0;
}

.heading {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-bottom: var(--space-1);
}

.title {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--text-primary);
}

.recommendation {
  font-size: var(--text-md);
  line-height: 1.55;
  color: var(--text-secondary);
  max-width: 62ch;
}

.rationale {
  margin-top: var(--space-2);
  font-size: var(--text-sm);
  line-height: 1.5;
  color: var(--text-tertiary);
  max-width: 62ch;
}

.applied {
  display: flex;
  align-items: flex-start;
  gap: var(--space-2);
  margin-top: var(--space-2);
  font-size: var(--text-sm);
  color: var(--ai-strong);
}

.applied svg {
  flex-shrink: 0;
  margin-top: 2px;
}

.actions {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-shrink: 0;
}

.ignore {
  padding: 4px var(--space-2);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  transition: color var(--duration-fast) var(--ease-out);
}

.ignore:hover {
  color: var(--text-secondary);
}

.restore {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  width: 100%;
  padding: var(--space-3) var(--space-4);
  border: 1px dashed var(--border-strong);
  border-radius: var(--radius-lg);
  color: var(--text-tertiary);
  font-size: var(--text-sm);
  transition:
    border-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.restore:hover {
  border-color: var(--ai-border);
  color: var(--text-secondary);
}

.restore svg {
  color: var(--ai);
}

.undo {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  margin-left: auto;
  font-size: var(--text-xs);
  color: var(--ai-strong);
}

@media (max-width: 900px) {
  .briefing {
    flex-direction: column;
    align-items: stretch;
  }

  .actions {
    justify-content: flex-end;
  }
}
</style>
