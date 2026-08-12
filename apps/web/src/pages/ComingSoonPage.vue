<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

import UiButton from '@/components/ui/UiButton.vue'
import UiPill from '@/components/ui/UiPill.vue'

const route = useRoute()

const title = computed(() => String(route.meta.title ?? 'Section'))
const blurb = computed(() =>
  route.meta.blurb ? String(route.meta.blurb) : 'This section is on the roadmap.',
)
const milestone = computed(() =>
  route.meta.milestone ? String(route.meta.milestone) : null,
)
const icon = computed(() => route.meta.icon)
</script>

<template>
  <div class="coming-soon">
    <div class="content">
      <span class="icon-tile">
        <component :is="icon" :size="22" :stroke-width="1.5" />
      </span>
      <UiPill tone="neutral">Coming soon</UiPill>
      <h1 class="title">{{ title }}</h1>
      <p class="blurb">{{ blurb }}</p>
      <p v-if="milestone" class="milestone tnum">Planned for {{ milestone }}</p>
      <RouterLink :to="{ name: 'today' }" class="back">
        <UiButton variant="ghost" size="sm">Back to Today</UiButton>
      </RouterLink>
    </div>
  </div>
</template>

<style scoped>
.coming-soon {
  display: grid;
  place-items: center;
  min-height: 100%;
  padding: var(--space-10) var(--space-6);
}

.content {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  max-width: 420px;
  gap: var(--space-4);
}

.icon-tile {
  display: grid;
  place-items: center;
  width: 56px;
  height: 56px;
  border-radius: var(--radius-lg);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  color: var(--text-tertiary);
  margin-bottom: var(--space-2);
}

.title {
  font-size: var(--text-2xl);
  letter-spacing: -0.02em;
}

.blurb {
  font-size: var(--text-md);
  line-height: 1.6;
  color: var(--text-secondary);
}

.milestone {
  font-size: var(--text-xs);
  font-weight: 500;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--text-disabled);
}

.back {
  margin-top: var(--space-2);
}
</style>
