import { defineStore } from "pinia";
import { computed, ref } from "vue";

import { errorMessage } from "@/lib/api/errorMessages";
import type { PreviewState } from "@/features/planning/types";
import { useTasksStore } from "@/features/tasks/store";
import type { Task } from "@/features/tasks/types";

import { useMock } from "@/lib/mock";
import { projectsApi } from "./api";
import { projectResponseToProject } from "./api-types";
import { mockProjects } from "./mock";
import type { NewProjectDraft, Project, ProjectStatus } from "./types";

export type LoadStatus = "idle" | "loading" | "ready" | "error";

/** Filters exposed in the UI — DRAFT exists in the lifecycle but has no
 * dedicated filter in this milestone's spec. */
export type ProjectFilter = "ACTIVE" | "COMPLETED" | "ARCHIVED";

export const PROJECT_FILTER_LABELS: Record<ProjectFilter, string> = {
  ACTIVE: "Active",
  COMPLETED: "Completed",
  ARCHIVED: "Archived",
};

export interface ProjectTaskStats {
  total: number;
  completed: number;
  remaining: number;
  /** 0–100, cancelled tasks excluded from the denominator. */
  progress: number;
}

const MOCK_LATENCY_MS = 550;

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function statsFor(projectId: string, tasks: Task[]): ProjectTaskStats {
  const own = tasks.filter((task) => task.projectId === projectId);
  const completed = own.filter((task) => task.status === "COMPLETED").length;
  const cancelled = own.filter((task) => task.status === "CANCELLED").length;
  const total = own.length;
  const remaining = total - completed - cancelled;
  const countable = total - cancelled;
  const progress =
    countable === 0 ? 0 : Math.round((completed / countable) * 100);
  return { total, completed, remaining, progress };
}

/**
 * Projects collection for the Projects workspace (and the sidebar list).
 *
 * Mock mode (`VITE_USE_MOCK_PROJECTS=true`) keeps the milestone behavior
 * for design review. Real mode (default) talks to the Project API: new
 * projects are created as DRAFT then immediately activated, matching the
 * UI's expectation that new projects are Active.
 */
const USE_MOCK = useMock("PROJECTS");

export const useProjectsStore = defineStore("projects", () => {
  const projects = ref<Project[]>(USE_MOCK ? [...mockProjects] : []);
  const status = ref<LoadStatus>("idle");
  const statusFilter = ref<ProjectFilter>("ACTIVE");
  const previewEmpty = ref(false);
  /** Last failed mutation message (null when none). */
  const lastError = ref<string | null>(null);

  function clearError(): void {
    lastError.value = null;
  }

  const tasksStore = useTasksStore();

  function projectById(id: string): Project | undefined {
    return projects.value.find((project) => project.id === id);
  }

  function statsForProject(projectId: string): ProjectTaskStats {
    return statsFor(projectId, tasksStore.tasks);
  }

  const activeProjects = computed(() =>
    projects.value.filter((project) => project.status === "ACTIVE"),
  );

  const filterCounts = computed<Record<ProjectFilter, number>>(() => ({
    ACTIVE: activeProjects.value.length,
    COMPLETED: projects.value.filter((p) => p.status === "COMPLETED").length,
    ARCHIVED: projects.value.filter((p) => p.status === "ARCHIVED").length,
  }));

  const visibleProjects = computed(() => {
    if (previewEmpty.value) return [];
    return projects.value.filter(
      (project) => project.status === statusFilter.value,
    );
  });

  /** Active + recently completed tasks for a project detail panel. */
  function tasksForProject(projectId: string): {
    active: Task[];
    completed: Task[];
  } {
    const own = tasksStore.tasks.filter((task) => task.projectId === projectId);
    return {
      active: own.filter(
        (task) => task.status !== "COMPLETED" && task.status !== "CANCELLED",
      ),
      completed: own
        .filter((task) => task.status === "COMPLETED")
        .slice()
        .sort((a, b) =>
          (b.completedAt ?? "").localeCompare(a.completedAt ?? ""),
        )
        .slice(0, 3),
    };
  }

  /** Persist edits (amendment AC-014). Mock mode mutates locally (color
   *  stays UI-only); real mode sends PUT /api/v1/projects/{id}. */
  function updateProject(projectId: string, draft: NewProjectDraft): void {
    const project = projectById(projectId);
    if (!project) return;
    lastError.value = null;

    if (USE_MOCK) {
      project.name = draft.name;
      project.description = draft.description;
      project.goalId = draft.goalId;
      project.color = draft.color;
      return;
    }

    projectsApi
      .update(projectId, {
        title: draft.name,
        description: draft.description,
        goalId: draft.goalId,
        deadline: draft.deadline ?? null,
      })
      .then((updated) => {
        const live = projectById(projectId);
        if (live) {
          const mapped = projectResponseToProject(updated);
          mapped.color = live.color;
          Object.assign(live, mapped);
        }
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
  }

  /** Delete a project (amendment AC-015). The backend detaches the
   *  project's tasks (project_id = NULL); the stores mirror that so the
   *  tasks keep their data and surface as unassigned. */
  function deleteProject(projectId: string): void {
    const project = projectById(projectId);
    if (!project) return;
    lastError.value = null;

    const detach = () => {
      projects.value = projects.value.filter((p) => p.id !== projectId);
      for (const task of tasksStore.tasks) {
        if (task.projectId === projectId) task.projectId = null;
      }
    };

    if (USE_MOCK) {
      detach();
      return;
    }

    projectsApi
      .delete(projectId)
      .then(detach)
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
  }

  /**
   * @param preview forces a UI state for design verification
   * (`?preview=loading|error|empty`) — mock mode only.
   */
  async function load(preview: PreviewState = null): Promise<void> {
    status.value = "loading";
    lastError.value = null;

    if (preview === "loading") return;

    if (USE_MOCK) {
      await delay(MOCK_LATENCY_MS);

      if (preview === "error") {
        status.value = "error";
        return;
      }

      previewEmpty.value = preview === "empty";
      status.value = "ready";
      return;
    }

    try {
      const list = await projectsApi.list();
      projects.value = list.map(projectResponseToProject);
      status.value = "ready";
    } catch (error) {
      status.value = "error";
      lastError.value = errorMessage(error);
    }
  }

  function setFilter(filter: ProjectFilter): void {
    statusFilter.value = filter;
  }

  /** Create a project. Mock mode creates it Active immediately; real mode
   *  creates as DRAFT then activates it, so the UI sees an Active project. */
  function addProject(draft: NewProjectDraft): Project | null {
    lastError.value = null;

    if (USE_MOCK) {
      const project: Project = {
        id: `proj-local-${Date.now()}`,
        name: draft.name,
        description: draft.description || null,
        goalId: draft.goalId,
        color: draft.color,
        status: "ACTIVE",
        createdAt: new Date().toISOString(),
        completedAt: null,
      };
      projects.value.unshift(project);
      return project;
    }

    projectsApi
      .create({
        title: draft.name,
        description: draft.description || null,
        goalId: draft.goalId,
        deadline: draft.deadline ?? null,
      })
      .then((created) => projectsApi.activate(created.id))
      .then((activated) => {
        const project = projectResponseToProject(activated);
        project.color = draft.color;
        projects.value.unshift(project);
      })
      .catch((error: unknown) => {
        lastError.value = errorMessage(error);
      });
    return null;
  }

  return {
    projects,
    status,
    statusFilter,
    visibleProjects,
    activeProjects,
    filterCounts,
    lastError,
    projectById,
    statsForProject,
    tasksForProject,
    load,
    setFilter,
    addProject,
    updateProject,
    deleteProject,
    clearError,
  };
});

export type { ProjectStatus };
