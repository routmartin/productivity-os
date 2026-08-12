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
  Plus,
  Settings,
  Target,
  Timer,
} from 'lucide-vue-next'

import { useAuthStore } from '@/features/auth/store'
import { useGoalsStore } from '@/features/goals/store'
import { useProjectsStore } from '@/features/projects/store'
import { useTasksStore } from '@/features/tasks/store'
import { firstNameFromEmail } from '@/lib/utils/date'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const tasksStore = useTasksStore()
const projectsStore = useProjectsStore()
const goalsStore = useGoalsStore()

/** Sidebar lists active projects only — completed/archived stay out of the
 * way (Projects UI spec §14). */
const activeProjects = computed(() => projectsStore.activeProjects)

/** Sidebar lists pursued goals; drafts stay out until activated. */
const activeGoals = computed(() => goalsStore.activeGoals)

const mainNav = [
  { name: 'today', title: 'Today', icon: CalendarCheck2 },
  { name: 'inbox', title: 'Inbox', icon: Inbox, badge: true },
  { name: 'tasks', title: 'Tasks', icon: ListChecks },
  { name: 'projects', title: 'Projects', icon: Folder },
  { name: 'goals', title: 'Goals', icon: Target },
  { name: 'focus', title: 'Focus', icon: Timer },
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
        <svg width="16" height="16" viewBox="0 0 18 18" fill="none">
          <path d="M5 11.5h8" stroke="#fff" stroke-width="1.6" stroke-linecap="round" />
          <circle cx="9" cy="7" r="1.7" fill="#fff" />
        </svg>
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
            <component :is="item.icon" :size="17" :stroke-width="1.75" class="nav-icon" />
            <span class="nav-label">{{ item.title }}</span>
            <span v-if="'badge' in item && item.badge" class="badge tnum">{{ inboxCount }}</span>
          </RouterLink>
        </li>
      </ul>

      <span class="section-label">Projects</span>
      <ul class="nav-list">
        <li v-for="project in activeProjects" :key="project.id">
          <RouterLink :to="{ name: 'projects' }" class="nav-item sub-item">
            <span class="dot" :style="{ background: project.color }" />
            <span class="nav-label">{{ project.name }}</span>
          </RouterLink>
        </li>
        <li>
          <RouterLink :to="{ name: 'projects' }" class="nav-item sub-item ghost-item">
            <Plus :size="15" :stroke-width="1.75" class="nav-icon" />
            <span class="nav-label">New Project</span>
          </RouterLink>
        </li>
      </ul>

      <span class="section-label">Goals</span>
      <ul class="nav-list">
        <li v-for="goal in activeGoals" :key="goal.id">
          <RouterLink :to="{ name: 'goals' }" class="nav-item sub-item">
            <Target :size="15" :stroke-width="1.75" class="nav-icon goal-icon" />
            <span class="nav-label">{{ goal.title }}</span>
          </RouterLink>
        </li>
        <li>
          <RouterLink :to="{ name: 'goals' }" class="nav-item sub-item ghost-item">
            <Plus :size="15" :stroke-width="1.75" class="nav-icon" />
            <span class="nav-label">New Goal</span>
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
            <Settings :size="17" :stroke-width="1.75" class="nav-icon" />
            <span class="nav-label">Settings</span>
          </RouterLink>
        </li>
        <li>
          <button class="nav-item as-button" type="button" @click="onLogout">
            <LogOut :size="17" :stroke-width="1.75" class="nav-icon" />
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
        <ChevronDown :size="14" :stroke-width="1.75" class="user-chevron" />
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
  padding: var(--space-4) var(--space-3) var(--space-3);
  overflow: hidden;
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
  padding: var(--space-2) var(--space-3) var(--space-4);
  white-space: nowrap;
}

.brand-mark {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  flex-shrink: 0;
  border-radius: 9px;
  background: linear-gradient(135deg, var(--ai) 0%, var(--accent) 100%);
}

.brand-name {
  font-size: var(--text-md);
  font-weight: 650;
  letter-spacing: -0.01em;
}

.section-label {
  display: block;
  padding: var(--space-4) var(--space-3) var(--space-2);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--text-disabled);
  white-space: nowrap;
}

.nav-list {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  width: 100%;
  height: 36px;
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
  font-weight: 500;
}

.as-button {
  text-align: left;
}

.nav-icon {
  flex-shrink: 0;
  color: var(--text-tertiary);
}

.nav-item:hover .nav-icon,
.nav-item.active .nav-icon {
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
  min-width: 20px;
  height: 19px;
  padding: 0 6px;
  border-radius: var(--radius-full);
  background: var(--surface-3);
  font-size: 12px;
  font-weight: 600;
  color: var(--text-secondary);
}

.sub-item {
  height: 32px;
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.dot {
  width: 7px;
  height: 7px;
  margin: 0 5px;
  border-radius: var(--radius-full);
  flex-shrink: 0;
}

.goal-icon {
  color: var(--text-tertiary);
}

.ghost-item {
  color: var(--text-disabled);
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
  width: 30px;
  height: 30px;
  flex-shrink: 0;
  border-radius: var(--radius-full);
  background: linear-gradient(135deg, var(--ai) 0%, var(--accent) 100%);
  color: #fff;
  font-size: var(--text-sm);
  font-weight: 600;
}

.user-meta {
  display: flex;
  flex-direction: column;
  min-width: 0;
  flex: 1;
  line-height: 1.3;
}

.user-name {
  font-size: var(--text-sm);
  font-weight: 500;
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

/* Collapsed rail on narrower desktops */
@media (max-width: 1200px) {
  .side-nav {
    width: var(--sidebar-collapsed-width);
    padding: var(--space-4) var(--space-2) var(--space-2);
  }

  .brand {
    justify-content: center;
    padding: 0 0 var(--space-4);
  }

  .brand-name,
  .nav-label,
  .badge,
  .section-label,
  .user-meta,
  .user-chevron {
    display: none;
  }

  .nav-item {
    justify-content: center;
    padding: 0;
  }

  .user-card {
    justify-content: center;
  }
}
</style>
