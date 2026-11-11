<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  CalendarCheck2,
  ChevronDown,
  Folder,
  History,
  Inbox,
  ListChecks,
  LogOut,
  PanelLeftClose,
  PanelLeftOpen,
  Settings,
  Sparkles,
  Target,
} from 'lucide-vue-next'

import { useAuthStore } from '@/features/auth/store'
import { useTasksStore } from '@/features/tasks/store'
import { firstNameFromEmail } from '@/lib/utils/date'
import { useNavStore } from './navStore'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const tasksStore = useTasksStore()
const nav = useNavStore()

const mainNav = [
  { name: 'today', title: 'Today', icon: CalendarCheck2 },
  { name: 'tasks', title: 'Tasks', icon: ListChecks },
  { name: 'inbox', title: 'Inbox', icon: Inbox, badge: true },
  { name: 'projects', title: 'Projects', icon: Folder },
  { name: 'goals', title: 'Goals', icon: Target },
  { name: 'schedule', title: 'Schedule', icon: History },
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

/** Keyboard shortcut: ⌘\ or Ctrl+\ to toggle sidebar collapse */
function onKeydown(e: KeyboardEvent) {
  if ((e.metaKey || e.ctrlKey) && e.key === '\\') {
    e.preventDefault()
    nav.toggleCollapse()
  }
}

onMounted(() => window.addEventListener('keydown', onKeydown))
onBeforeUnmount(() => window.removeEventListener('keydown', onKeydown))
</script>

<template>
  <nav
    class="side-nav"
    :class="{ collapsed: nav.isCollapsed }"
    aria-label="Primary"
  >
    <!-- Brand & Toggle Header -->
    <div class="brand">
      <div class="brand-left">
        <span class="brand-mark" aria-hidden="true">
          <Sparkles :size="16" :stroke-width="2" />
        </span>
        <span v-if="!nav.isCollapsed" class="brand-name">Productivity OS</span>
      </div>

      <button
        type="button"
        class="toggle-btn"
        :aria-label="nav.isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'"
        :title="nav.isCollapsed ? 'Expand sidebar (⌘\\)' : 'Collapse sidebar (⌘\\)'"
        @click="nav.toggleCollapse"
      >
        <component
          :is="nav.isCollapsed ? PanelLeftOpen : PanelLeftClose"
          :size="16"
          :stroke-width="1.75"
        />
      </button>
    </div>

    <!-- Nav List -->
    <div class="scroll">
      <span v-if="!nav.isCollapsed" class="section-label">Main</span>
      <div v-else class="section-divider" aria-hidden="true" />

      <ul class="nav-list">
        <li v-for="item in mainNav" :key="item.name">
          <RouterLink
            :to="{ name: item.name }"
            class="nav-item"
            :class="{ active: isActive(item.name), 'icon-only': nav.isCollapsed }"
            :aria-current="isActive(item.name) ? 'page' : undefined"
            :title="nav.isCollapsed ? item.title : undefined"
          >
            <component :is="item.icon" :size="18" :stroke-width="1.75" class="nav-icon" />
            <span v-if="!nav.isCollapsed" class="nav-label">{{ item.title }}</span>
            <span
              v-if="'badge' in item && item.badge && !nav.isCollapsed"
              class="badge tnum"
            >
              {{ inboxCount }}
            </span>
            <span
              v-else-if="'badge' in item && item.badge && nav.isCollapsed && inboxCount > 0"
              class="badge-dot"
              :title="`${inboxCount} unread inbox items`"
            />
          </RouterLink>
        </li>
      </ul>
    </div>

    <!-- Bottom Controls -->
    <div class="bottom">
      <ul class="nav-list">
        <li>
          <RouterLink
            :to="{ name: 'settings' }"
            class="nav-item"
            :class="{ active: isActive('settings'), 'icon-only': nav.isCollapsed }"
            :title="nav.isCollapsed ? 'Settings' : undefined"
          >
            <Settings :size="18" :stroke-width="1.75" class="nav-icon" />
            <span v-if="!nav.isCollapsed" class="nav-label">Settings</span>
          </RouterLink>
        </li>
        <li>
          <button
            class="nav-item as-button"
            :class="{ 'icon-only': nav.isCollapsed }"
            type="button"
            :title="nav.isCollapsed ? 'Log out' : undefined"
            @click="onLogout"
          >
            <LogOut :size="18" :stroke-width="1.75" class="nav-icon" />
            <span v-if="!nav.isCollapsed" class="nav-label">Log out</span>
          </button>
        </li>
      </ul>

      <!-- User Profile Card -->
      <RouterLink
        :to="{ name: 'settings' }"
        class="user-card"
        :class="{ 'icon-only': nav.isCollapsed }"
        :title="nav.isCollapsed ? displayName : undefined"
      >
        <span class="avatar" aria-hidden="true">{{ initials }}</span>
        <span v-if="!nav.isCollapsed" class="user-meta">
          <span class="user-name">{{ displayName }}</span>
          <span class="user-email">{{ auth.user?.email }}</span>
        </span>
        <ChevronDown
          v-if="!nav.isCollapsed"
          :size="15"
          :stroke-width="1.75"
          class="user-chevron"
        />
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
  transition: width 0.22s cubic-bezier(0.16, 1, 0.3, 1), padding 0.22s ease;
}

.side-nav.collapsed {
  width: 68px;
  padding: var(--space-5) var(--space-2) var(--space-4);
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
  justify-content: space-between;
  padding: var(--space-1) var(--space-3) var(--space-5);
  white-space: nowrap;
}

.side-nav.collapsed .brand {
  flex-direction: column;
  gap: var(--space-3);
  padding: var(--space-1) var(--space-1) var(--space-4);
  align-items: center;
}

.brand-left {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  min-width: 0;
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
  color: var(--text-primary);
}

.toggle-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: var(--radius-sm);
  background: transparent;
  border: 1px solid transparent;
  color: var(--text-tertiary);
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

.toggle-btn:hover {
  background: var(--surface-2);
  color: var(--text-primary);
  border-color: var(--border-subtle);
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

.section-divider {
  height: 1px;
  background: var(--border-subtle);
  margin: var(--space-3) var(--space-2);
}

.nav-list {
  display: flex;
  flex-direction: column;
  gap: 2px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.nav-item {
  position: relative;
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

.nav-item.icon-only {
  justify-content: center;
  padding: 0;
  width: 44px;
  margin: 0 auto;
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
  border: none;
  background: transparent;
  cursor: pointer;
}

.nav-icon {
  flex-shrink: 0;
  color: var(--text-tertiary);
  transition: color var(--duration-fast) var(--ease-out);
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

.badge-dot {
  position: absolute;
  top: 8px;
  right: 8px;
  width: 7px;
  height: 7px;
  border-radius: var(--radius-full);
  background: var(--accent);
  box-shadow: 0 0 6px var(--accent-glow);
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
  text-decoration: none;
}

.user-card.icon-only {
  justify-content: center;
  padding: var(--space-2) 0;
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
