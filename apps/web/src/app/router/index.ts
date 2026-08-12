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
import InboxPage from "@/pages/InboxPage.vue";
import LoginPage from "@/pages/LoginPage.vue";
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
          component: ComingSoonPage,
          meta: {
            title: "Projects",
            icon: Folder,
            implemented: false,
            blurb:
              "Bodies of work that group tasks toward an outcome, from draft to archived.",
            milestone: "Milestone 3",
          },
        },
        {
          path: "goals",
          name: "goals",
          component: ComingSoonPage,
          meta: {
            title: "Goals",
            icon: Target,
            implemented: false,
            blurb:
              "Meaningful outcomes that give projects and daily priorities a direction.",
            milestone: "Milestone 3",
          },
        },
        {
          path: "focus",
          name: "focus",
          component: ComingSoonPage,
          meta: {
            title: "Focus",
            icon: Timer,
            implemented: false,
            blurb:
              "Distraction-free focus sessions tied to the task at hand, with a calm session timeline.",
            milestone: "Milestone 2",
          },
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
