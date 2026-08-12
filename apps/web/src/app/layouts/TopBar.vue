<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { Bell, Search, Sun } from 'lucide-vue-next'

import { formatLongDate } from '@/lib/utils/date'

const route = useRoute()

const title = computed(() => String(route.meta.title ?? ''))
/** The date sits next to the page title on the Today screen (see the
 * approved visual reference). */
const showDate = computed(() => route.name === 'today')
const dateLabel = formatLongDate(new Date())
</script>

<template>
  <header class="top-bar">
    <div class="page-id">
      <h1 class="page-title">{{ title }}</h1>
      <span v-if="showDate" class="page-date">{{ dateLabel }}</span>
    </div>

    <div class="chrome">
      <button class="search" type="button" title="Search arrives in Milestone 2">
        <Search :size="14" :stroke-width="1.75" />
        <span class="search-label">Search tasks…</span>
        <kbd class="kbd tnum">⌘K</kbd>
      </button>

      <button class="icon-button" type="button" aria-label="Notifications" title="Notifications arrive in a later milestone">
        <Bell :size="16" :stroke-width="1.75" />
        <span class="notify-badge tnum">2</span>
      </button>

      <button class="icon-button" type="button" aria-label="Theme" title="Light theme arrives later — dark-first by design">
        <Sun :size="16" :stroke-width="1.75" />
      </button>
    </div>
  </header>
</template>

<style scoped>
.top-bar {
  position: sticky;
  top: 0;
  z-index: 20;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  padding: var(--space-4) var(--space-8);
  background: color-mix(in srgb, var(--surface-0) 82%, transparent);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--border-subtle);
}

.page-id {
  display: flex;
  align-items: baseline;
  gap: var(--space-3);
  min-width: 0;
}

.page-title {
  font-size: var(--text-lg);
  font-weight: 650;
  letter-spacing: -0.01em;
}

.page-date {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  white-space: nowrap;
}

.chrome {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.search {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  width: 230px;
  height: 32px;
  padding: 0 var(--space-3);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  background: var(--surface-1);
  color: var(--text-tertiary);
  font-size: var(--text-sm);
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.search:hover {
  border-color: var(--border-strong);
  background: var(--surface-2);
}

.search-label {
  flex: 1;
  text-align: left;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.kbd {
  padding: 1px 5px;
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  background: var(--surface-2);
  font-family: inherit;
  font-size: 10px;
  color: var(--text-disabled);
}

.icon-button {
  position: relative;
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  border-radius: var(--radius-md);
  color: var(--text-tertiary);
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.icon-button:hover {
  background: var(--surface-2);
  color: var(--text-primary);
}

.notify-badge {
  position: absolute;
  top: 2px;
  right: 2px;
  display: grid;
  place-items: center;
  min-width: 14px;
  height: 14px;
  padding: 0 3px;
  border-radius: var(--radius-full);
  background: var(--accent);
  color: #fff;
  font-size: 9px;
  font-weight: 700;
}

@media (max-width: 900px) {
  .search {
    width: 40px;
  }

  .search-label,
  .kbd {
    display: none;
  }
}
</style>
