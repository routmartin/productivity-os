<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { Bell, Moon, Search, Settings, Sun } from 'lucide-vue-next'

import { useAuthStore } from '@/features/auth/store'
import { useSearchStore } from '@/features/search/store'
import { theme, toggleTheme } from '@/lib/theme'
import { firstNameFromEmail, greetingFor } from '@/lib/utils/date'

const route = useRoute()
const auth = useAuthStore()
const search = useSearchStore()

/** Today leads with the personal greeting (see the approved reference);
 *  other sections show their page title. */
const isToday = computed(() => route.name === 'today')
const contextLabel = computed(() => {
  if (isToday.value) {
    const name = firstNameFromEmail(auth.user?.email ?? '')
    return `${greetingFor(new Date(), auth.user?.timezone)}, ${name}`
  }
  return String(route.meta.title ?? '')
})
</script>

<template>
  <header class="top-bar">
    <div class="page-id">
      <h1 class="page-title">
        {{ contextLabel }}
        <span v-if="isToday" aria-hidden="true">👋</span>
      </h1>
    </div>

    <div class="chrome">
      <button
        id="global-search-trigger"
        class="search"
        type="button"
        aria-label="Open search"
        title="Search tasks, projects, goals"
        @click="search.openSearch()"
      >
        <Search :size="15" :stroke-width="1.75" />
        <span class="search-label">Search tasks, projects, goals…</span>
        <kbd class="kbd tnum">⌘K</kbd>
      </button>

      <button class="icon-button" type="button" aria-label="Notifications" title="Notifications arrive in a later milestone">
        <Bell :size="17" :stroke-width="1.75" />
        <span class="notify-badge tnum">2</span>
      </button>

      <button
        class="icon-button"
        type="button"
        :aria-label="theme === 'dark' ? 'Switch to light theme' : 'Switch to dark theme'"
        :title="theme === 'dark' ? 'Switch to light theme' : 'Switch to dark theme'"
        @click="toggleTheme"
      >
        <Sun v-if="theme === 'dark'" :size="17" :stroke-width="1.75" />
        <Moon v-else :size="17" :stroke-width="1.75" />
      </button>

      <RouterLink
        class="icon-button"
        :to="{ name: 'settings' }"
        aria-label="Settings"
        title="Settings"
      >
        <Settings :size="17" :stroke-width="1.75" />
      </RouterLink>
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
  gap: var(--space-6);
  height: var(--header-height);
  padding: 0 var(--space-10);
  background: color-mix(in srgb, var(--surface-0) 84%, transparent);
  backdrop-filter: blur(12px);
  flex-shrink: 0;
}

.page-id {
  display: flex;
  align-items: baseline;
  gap: var(--space-3);
  min-width: 0;
}

.page-title {
  font-size: var(--text-xl);
  font-weight: 650;
  letter-spacing: -0.015em;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.chrome {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.search {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  width: 340px;
  height: 42px;
  padding: 0 var(--space-4);
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
  padding: 2px 6px;
  border: 1px solid var(--border-subtle);
  border-radius: 6px;
  background: var(--surface-2);
  font-family: inherit;
  font-size: 11px;
  color: var(--text-disabled);
}

.icon-button {
  position: relative;
  display: grid;
  place-items: center;
  width: 42px;
  height: 42px;
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  background: var(--surface-1);
  color: var(--text-tertiary);
  transition:
    background-color var(--duration-fast) var(--ease-out),
    border-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.icon-button:hover {
  background: var(--surface-2);
  border-color: var(--border-strong);
  color: var(--text-primary);
}

.notify-badge {
  position: absolute;
  top: -5px;
  right: -5px;
  display: grid;
  place-items: center;
  min-width: 17px;
  height: 17px;
  padding: 0 4px;
  border-radius: var(--radius-full);
  background: var(--accent);
  color: #fff;
  font-size: 10px;
  font-weight: 700;
  box-shadow: 0 0 0 2px var(--surface-0);
}

@media (max-width: 1100px) {
  .search {
    width: 220px;
  }
}

@media (max-width: 900px) {
  .search {
    width: 42px;
    padding: 0;
    justify-content: center;
  }

  .search-label,
  .kbd {
    display: none;
  }
}
</style>
