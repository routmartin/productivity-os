<script setup lang="ts">
import { Sparkles } from 'lucide-vue-next'

import SurfaceCard from '@/components/shared/SurfaceCard.vue'

import type { Insight } from '../mock'

defineProps<{ insights: Insight[] }>()
</script>

<template>
  <SurfaceCard>
    <div class="header">
      <span class="title-wrap">
        <Sparkles :size="14" :stroke-width="1.75" class="ai-icon" />
        <h2 class="title">AI Insights</h2>
      </span>
      <button class="view-all" type="button" title="The full insights view arrives in a later milestone">
        View all
      </button>
    </div>

    <ul class="items">
      <li v-for="insight in insights" :key="insight.id" class="item">
        <span class="tile" :class="`tone-${insight.tone}`" aria-hidden="true">
          <component :is="insight.icon" :size="15" :stroke-width="1.75" />
        </span>
        <span class="body">
          <span class="item-title">{{ insight.title }}</span>
          <span class="item-text">{{ insight.text }}</span>
        </span>
      </li>
    </ul>
  </SurfaceCard>
</template>

<style scoped>
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-4);
}

.title-wrap {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
}

.ai-icon {
  color: var(--ai-strong);
}

.title {
  font-size: var(--text-lg);
  font-weight: 600;
  letter-spacing: -0.01em;
}

.view-all {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ai-strong);
  padding: 2px var(--space-1);
  border-radius: var(--radius-sm);
  transition: opacity var(--duration-fast) var(--ease-out);
}

.view-all:hover {
  opacity: 0.8;
}

.items {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.item {
  display: flex;
  align-items: flex-start;
  gap: var(--space-3);
}

.tile {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  flex-shrink: 0;
  border-radius: var(--radius-md);
}

.tile.tone-ai {
  background: var(--ai-soft);
  color: var(--ai-strong);
}

.tile.tone-warning {
  background: var(--orange-soft);
  color: var(--orange);
}

.tile.tone-info {
  background: var(--blue-soft);
  color: var(--blue);
}

.body {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-width: 0;
}

.item-title {
  font-size: var(--text-md);
  font-weight: 550;
  color: var(--text-primary);
}

.item-text {
  font-size: var(--text-sm);
  line-height: 1.45;
  color: var(--text-tertiary);
}
</style>
