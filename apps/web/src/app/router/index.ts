import {
  CalendarCheck2,
  Folder,
  Inbox,
  ListChecks,
  Settings,
  Target,
  Timer,
  type LucideIcon,
} from "lucide-vue-next";
import { createRouter, createWebHistory } from "vue-router";

import AppShell from "@/app/layouts/AppShell.vue";
import { useAuthStore } from "@/features/auth/store";
import ComingSoonPage from "@/pages/ComingSoonPage.vue";
import FocusPage from "@/pages/FocusPage.vue";
import GoalsPage from "@/pages/GoalsPage.vue";
import InboxPage from "@/pages/InboxPage.vue";
import LoginPage from "@/pages/LoginPage.vue";
import ProjectsPage from "@/pages/ProjectsPage.vue";
import TasksPage from "@/pages/TasksPage.vue";
import TodayPage from "@/pages/TodayPage.vue";

/** Metadata carried by section routes so the shell and placeholder pages
 * stay declarative. */
export interface SectionMeta {
  title: string;
  icon: LucideIcon;
  /** False until the section is implemented end-to-end. */
  implemented: boolean;
  blurb?: string;
  milestone?: string;
}

declare module "vue-router" {
  interface RouteMeta extends Partial<SectionMeta> {
    requiresAuth?: boolean;
  }
}

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: "/login",
      name: "login",
      component: LoginPage,
      meta: { title: "Sign in" },
    },
    {
      path: "/",
      component: AppShell,
      meta: { requiresAuth: true },
      children: [
        { path: "", redirect: { name: "today" } },
        {
          path: "today",
          name: "today",
          component: TodayPage,
          meta: { title: "Today", icon: CalendarCheck2, implemented: true },
        },
        {
          path: "inbox",
          name: "inbox",
          component: InboxPage,
          meta: { title: "Inbox", icon: Inbox, implemented: true },
        },
        {
          path: "tasks",
          name: "tasks",
          component: TasksPage,
          meta: { title: "Tasks", icon: ListChecks, implemented: true },
        },
        {
          path: "projects",
          name: "projects",
          component: ProjectsPage,
          meta: { title: "Projects", icon: Folder, implemented: true },
        },
        {
          path: "goals",
          name: "goals",
          component: GoalsPage,
          meta: { title: "Goals", icon: Target, implemented: true },
        },
        {
          path: "focus",
          name: "focus",
          component: FocusPage,
          meta: { title: "Focus", icon: Timer, implemented: true },
        },
        {
          path: "settings",
          name: "settings",
          component: ComingSoonPage,
          meta: {
            title: "Settings",
            icon: Settings,
            implemented: false,
            blurb:
              "Profile, timezone, and workspace preferences — including your daily focus capacity.",
            milestone: "Milestone 4",
          },
        },
      ],
    },
    { path: "/:pathMatch(.*)*", redirect: { name: "today" } },
  ],
});

router.beforeEach((to) => {
  const auth = useAuthStore();
  auth.restore();

  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: "login", query: { redirect: to.fullPath } };
  }
  if (to.name === "login" && auth.isAuthenticated) {
    return { name: "today" };
  }
  return true;
});

router.afterEach((to) => {
  const title = typeof to.meta.title === "string" ? to.meta.title : undefined;
  document.title = title ? `${title} · Productivity OS` : "Productivity OS";
});
