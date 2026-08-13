<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  CalendarCheck2,
  ChevronDown,
  Folder,
  Inbox,
  ListChecks,
  LogOut,
  Settings,
  Sparkles,
  Target,
  Timer,
} from 'lucide-vue-next'

import { useAuthStore } from '@/features/auth/store'
import { useProjectsStore } from '@/features/projects/store'
import { useTasksStore } from '@/features/tasks/store'
import { firstNameFromEmail } from '@/lib/utils/date'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const tasksStore = useTasksStore()
const projectsStore = useProjectsStore()

/** Favorites mirror the reference sidebar: the user's flagship projects with
 * their accent dots. Falls back to the first active projects. */
const FAVORITE_IDS = ['proj-pos', 'proj-mobile', 'proj-web', 'proj-personal']

const favorites = computed(() => {
  const active = projectsStore.activeProjects
  const pinned = FAVORITE_IDS.flatMap((id) => {
    const project = active.find((p) => p.id === id)
    return project ? [project] : []
  })
  return pinned.length > 0 ? pinned : active.slice(0, 4)
})

const mainNav = [
  { name: 'today', title: 'Today', icon: CalendarCheck2 },
  { name: 'inbox', title: 'Inbox', icon: Inbox, badge: true },
  { name: 'tasks', title: 'Tasks', icon: ListChecks },
  { name: 'projects', title: 'Projects', icon: Folder },
  { name: 'goals', title: 'Goals', icon: Target },
  { name: 'focus', title: 'Focus', icon: Timer },
  { name: 'ai', title: 'AI', icon: Sparkles },
] as const


/** Inbox badge tracks the live (mock) inbox count — quick captures and New
 * Task creations update it immediately. */
const inboxCount = computed(() => tasksStore.inboxCount)

const displayName = computed(() => firstNameFromEmail(auth.user?.email ?? ''))
const initials = computed(() => displayName.value.charAt(0).toUpperCase())

function isActive(name: string): boolean {
  return route.name === name
}

async function onLogout() {
  await auth.logout()
  router.push({ name: 'login' })
}
</script>

<template>
  <nav class="side-nav" aria-label="Primary">
    <div class="brand">
      <span class="brand-mark" aria-hidden="true">
        <Sparkles :size="16" :stroke-width="2" />
      </span>
      <span class="brand-name">Productivity OS</span>
    </div>

    <div class="scroll">
      <span class="section-label">Main</span>
      <ul class="nav-list">
        <li v-for="item in mainNav" :key="item.name">
          <RouterLink
            :to="{ name: item.name }"
            class="nav-item"
            :class="{ active: isActive(item.name) }"
            :aria-current="isActive(item.name) ? 'page' : undefined"
          >
            <component :is="item.icon" :size="18" :stroke-width="1.75" class="nav-icon" />
            <span class="nav-label">{{ item.title }}</span>
            <span v-if="'badge' in item && item.badge" class="badge tnum">{{ inboxCount }}</span>
          </RouterLink>
        </li>
      </ul>

      <span class="section-label">Favorites</span>
      <ul class="nav-list">
        <li v-for="project in favorites" :key="project.id">
          <RouterLink
            :to="{ name: 'projects' }"
            class="nav-item sub-item"
          >
            <span class="dot" :style="{ background: project.color }" aria-hidden="true" />
            <span class="nav-label">{{ project.name }}</span>
          </RouterLink>
        </li>
      </ul>

    </div>

    <div class="bottom">
      <ul class="nav-list">
        <li>
          <RouterLink
            :to="{ name: 'settings' }"
            class="nav-item"
            :class="{ active: isActive('settings') }"
          >
            <Settings :size="18" :stroke-width="1.75" class="nav-icon" />
            <span class="nav-label">Settings</span>
          </RouterLink>
        </li>
        <li>
          <button class="nav-item as-button" type="button" @click="onLogout">
            <LogOut :size="18" :stroke-width="1.75" class="nav-icon" />
            <span class="nav-label">Log out</span>
          </button>
        </li>
      </ul>

      <RouterLink :to="{ name: 'settings' }" class="user-card">
        <span class="avatar" aria-hidden="true">{{ initials }}</span>
        <span class="user-meta">
          <span class="user-name">{{ displayName }}</span>
          <span class="user-email">{{ auth.user?.email }}</span>
        </span>
        <ChevronDown :size="15" :stroke-width="1.75" class="user-chevron" />
      </RouterLink>
    </div>
  </nav>
</template>

<style scoped>
.side-nav {
  display: flex;
  flex-direction: column;
  width: var(--sidebar-width);
  height: 100%;
  background: var(--surface-1);
  border-right: 1px solid var(--border-subtle);
  padding: var(--space-5) var(--space-3) var(--space-4);
  overflow: hidden;
  flex-shrink: 0;
}

.scroll {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  min-height: 0;
}

.brand {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-1) var(--space-3) var(--space-5);
  white-space: nowrap;
}

.brand-mark {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  flex-shrink: 0;
  border-radius: 10px;
  background: linear-gradient(135deg, var(--ai) 0%, var(--accent-deep) 100%);
  color: #fff;
  box-shadow: 0 4px 18px var(--accent-glow);
}

.brand-name {
  font-size: var(--text-lg);
  font-weight: 650;
  letter-spacing: -0.015em;
}

.section-label {
  display: block;
  padding: var(--space-5) var(--space-3) var(--space-2);
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.09em;
  text-transform: uppercase;
  color: var(--text-disabled);
  white-space: nowrap;
}

.nav-list {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  width: 100%;
  height: 42px;
  padding: 0 var(--space-3);
  border-radius: var(--radius-md);
  color: var(--text-secondary);
  font-size: var(--text-md);
  white-space: nowrap;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.nav-item:hover {
  background: var(--surface-2);
  color: var(--text-primary);
}

.nav-item.active {
  background: var(--surface-2);
  color: var(--text-primary);
  font-weight: 550;
  box-shadow: inset 0 0 0 1px var(--border-subtle);
}

.nav-item.active .nav-icon {
  color: var(--accent-strong);
}

.as-button {
  text-align: left;
}

.nav-icon {
  flex-shrink: 0;
  color: var(--text-tertiary);
}

.nav-item:hover .nav-icon {
  color: var(--text-secondary);
}

.nav-label {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
}

.badge {
  display: inline-grid;
  place-items: center;
  min-width: 22px;
  height: 20px;
  padding: 0 7px;
  border-radius: var(--radius-full);
  background: var(--surface-3);
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--text-secondary);
}

.nav-item.active .badge {
  background: var(--accent-soft);
  color: var(--accent-strong);
}

.sub-item {
  height: 38px;
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.sub-item:hover {
  color: var(--text-primary);
}

.dot {
  width: 8px;
  height: 8px;
  margin: 0 5px;
  border-radius: var(--radius-full);
  flex-shrink: 0;
}

.bottom {
  padding-top: var(--space-3);
  border-top: 1px solid var(--border-subtle);
}

.user-card {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-top: var(--space-3);
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-md);
  transition: background-color var(--duration-fast) var(--ease-out);
}

.user-card:hover {
  background: var(--surface-2);
}

.avatar {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  background: linear-gradient(135deg, var(--ai) 0%, var(--accent-deep) 100%);
  color: #fff;
  font-size: var(--text-sm);
  font-weight: 600;
}

.user-meta {
  display: flex;
  flex-direction: column;
  min-width: 0;
  flex: 1;
  line-height: 1.35;
}

.user-name {
  font-size: var(--text-sm);
  font-weight: 550;
  color: var(--text-primary);
}

.user-email {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.user-chevron {
  color: var(--text-disabled);
  flex-shrink: 0;
}
</style>
