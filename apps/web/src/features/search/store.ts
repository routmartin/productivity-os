import { defineStore } from "pinia";
import { computed, ref, watch } from "vue";

import { useGoalsStore } from "@/features/goals/store";
import { useProjectsStore } from "@/features/projects/store";
import { useTasksStore } from "@/features/tasks/store";

export type SearchResultType = "task" | "project" | "goal";

export interface SearchResult {
  type: SearchResultType;
  id: string;
  title: string;
  /** Secondary line: project name (task), goal title (project), null (goal). */
  subtitle: string | null;
}

export interface SearchGroup {
  type: SearchResultType;
  label: string;
  results: SearchResult[];
}

/** Max results rendered per group (spec Rule 9). */
const GROUP_CAP = 6;

/**
 * Global search state (spec: docs/specs/ui/global-search.md).
 *
 * Read-only over the feature stores: results derive from the loaded tasks,
 * projects, and goals with a case-insensitive substring match, so mock and
 * real mode behave identically and no network request is ever issued
 * (spec Rule 1, AC-012/AC-013).
 */
export const useSearchStore = defineStore("search", () => {
  const open = ref(false);
  const query = ref("");
  const highlightedIndex = ref(0);

  const tasksStore = useTasksStore();
  const projectsStore = useProjectsStore();
  const goalsStore = useGoalsStore();

  // A new query always restarts navigation from the top (AC-014).
  watch(query, () => {
    highlightedIndex.value = 0;
  });

  const normalized = computed(() => query.value.trim().toLowerCase());

  function matches(value: string): boolean {
    const q = normalized.value;
    return q.length > 0 && value.toLowerCase().includes(q);
  }

  const taskResults = computed<SearchResult[]>(() => {
    if (tasksStore.status !== "ready") return [];
    return tasksStore.tasks
      .filter((task) => matches(task.title))
      .slice(0, GROUP_CAP)
      .map((task) => ({
        type: "task" as const,
        id: task.id,
        title: task.title,
        subtitle: task.projectId
          ? (projectsStore.projectById(task.projectId)?.name ?? null)
          : null,
      }));
  });

  const projectResults = computed<SearchResult[]>(() => {
    if (projectsStore.status !== "ready") return [];
    return projectsStore.projects
      .filter((project) => matches(project.name))
      .slice(0, GROUP_CAP)
      .map((project) => ({
        type: "project" as const,
        id: project.id,
        title: project.name,
        subtitle: project.goalId
          ? (goalsStore.goalById(project.goalId)?.title ?? null)
          : null,
      }));
  });

  const goalResults = computed<SearchResult[]>(() => {
    if (goalsStore.status !== "ready") return [];
    return goalsStore.goals
      .filter((goal) => matches(goal.title))
      .slice(0, GROUP_CAP)
      .map((goal) => ({
        type: "goal" as const,
        id: goal.id,
        title: goal.title,
        subtitle: null,
      }));
  });

  const groups = computed<SearchGroup[]>(() => [
    { type: "task", label: "Tasks", results: taskResults.value },
    { type: "project", label: "Projects", results: projectResults.value },
    { type: "goal", label: "Goals", results: goalResults.value },
  ]);

  const visibleResults = computed<SearchResult[]>(() =>
    groups.value.flatMap((group) => group.results),
  );

  /** Flat start index of each group's first result (for keyboard nav). */
  const groupOffsets = computed<Record<SearchResultType, number>>(() => {
    const offsets: Record<SearchResultType, number> = {
      task: 0,
      project: 0,
      goal: 0,
    };
    let cursor = 0;
    for (const group of groups.value) {
      offsets[group.type] = cursor;
      cursor += group.results.length;
    }
    return offsets;
  });

  const hasResults = computed(() => visibleResults.value.length > 0);
  const isEmptyQuery = computed(() => normalized.value.length === 0);

  const tasksLoading = computed(
    () => tasksStore.status === "loading" || tasksStore.status === "idle",
  );
  const projectsLoading = computed(
    () => projectsStore.status === "loading" || projectsStore.status === "idle",
  );
  const goalsLoading = computed(
    () => goalsStore.status === "loading" || goalsStore.status === "idle",
  );

  const anyLoading = computed(
    () => tasksLoading.value || projectsLoading.value || goalsLoading.value,
  );

  function openSearch(): void {
    query.value = "";
    highlightedIndex.value = 0;
    open.value = true;
  }

  function closeSearch(): void {
    open.value = false;
  }

  function toggle(): void {
    if (open.value) closeSearch();
    else openSearch();
  }

  function moveHighlight(delta: number): void {
    const total = visibleResults.value.length;
    if (total === 0) return;
    highlightedIndex.value = (highlightedIndex.value + delta + total) % total;
  }

  function highlightedResult(): SearchResult | null {
    return visibleResults.value[highlightedIndex.value] ?? null;
  }

  return {
    open,
    query,
    highlightedIndex,
    groups,
    groupOffsets,
    visibleResults,
    hasResults,
    isEmptyQuery,
    tasksLoading,
    projectsLoading,
    goalsLoading,
    anyLoading,
    openSearch,
    closeSearch,
    toggle,
    moveHighlight,
    highlightedResult,
  };
});
