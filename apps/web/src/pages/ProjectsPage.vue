<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Folder, Plus } from 'lucide-vue-next'

import { useContextPanelStore } from '@/app/layouts/contextPanelStore'
import EmptyState from '@/components/shared/EmptyState.vue'
import ErrorState from '@/components/shared/ErrorState.vue'
import FilterChips from '@/components/shared/FilterChips.vue'
import SkeletonBlock from '@/components/shared/SkeletonBlock.vue'
import UiButton from '@/components/ui/UiButton.vue'
import UiDialog from '@/components/ui/UiDialog.vue'
import type { PreviewState } from '@/features/planning/types'
import { useGoalsStore } from '@/features/goals/store'
import NewProjectDialog from '@/features/projects/components/NewProjectDialog.vue'
import ProjectCard from '@/features/projects/components/ProjectCard.vue'
import ProjectDetailPanel from '@/features/projects/components/ProjectDetailPanel.vue'
import TaskDetailPanel from '@/features/tasks/components/TaskDetailPanel.vue'
import {
  PROJECT_FILTER_LABELS,
  useProjectsStore,
  type ProjectFilter,
} from '@/features/projects/store'
import type { NewProjectDraft } from '@/features/projects/types'
import { useMock } from '@/lib/mock'
import { showPreviewNote } from '@/lib/preview'

const route = useRoute()
const store = useProjectsStore()
const goalsStore = useGoalsStore()
const panel = useContextPanelStore()

/** `?preview=loading|error|empty` forces a UI state for design review. */
function previewFromQuery(): PreviewState {
  const value = route.query.preview
  return value === 'loading' || value === 'error' || value === 'empty' ? value : null
}

/** `?open=<id>` lands here from global search (spec: global-search AC-010). */
const openProjectId = computed(() => {
  const value = route.query.open
  return typeof value === 'string' && value ? value : null
})

/** Project whose detail dialog is open. Clicking a card opens it; clicking
 *  the same card again toggles it closed. */
const detailProjectId = ref<string | null>(null)

/** Task detail dialog stacked above the project dialog. A task picked in
 *  the project detail opens here instead of the side panel, which the
 *  dialog overlay would otherwise hide. */
const taskDialogId = ref<string | null>(null)

watch(
  () => panel.activeTaskId,
  (taskId) => {
    if (taskId && detailProjectId.value) taskDialogId.value = taskId
  },
)

// Deleting a task closes its panel — mirror that by closing the overlay.
watch(
  () => panel.isOpen,
  (open) => {
    if (!open) taskDialogId.value = null
  },
)

function closeTaskDialog() {
  taskDialogId.value = null
  panel.close()
}

function loadAndSelect(preview: PreviewState) {
  void store.load(preview)
  // Goal titles on cards/detail come from the goals store — load it once.
  if (goalsStore.status === 'idle') void goalsStore.load()

  // A search result lands with its project detail open (no default selection).
  if (openProjectId.value && store.projectById(openProjectId.value)) {
    detailProjectId.value = openProjectId.value
  }
}

onMounted(() => loadAndSelect(previewFromQuery()))
watch(
  () => route.query.preview,
  () => loadAndSelect(previewFromQuery()),
)

// A search result picked while already on this page opens the dialog live.
watch(
  () => route.query.open,
  (value) => {
    const id = typeof value === 'string' && value ? value : null
    if (id && store.status === 'ready' && store.projectById(id))
      detailProjectId.value = id
  },
)

const dialogOpen = ref(false)

const isLoading = computed(() => store.status === 'loading' || store.status === 'idle')

const filterOptions = computed(() =>
  (Object.keys(PROJECT_FILTER_LABELS) as ProjectFilter[]).map((key) => ({
    key,
    label: PROJECT_FILTER_LABELS[key],
    count: store.filterCounts[key],
  })),
)

const emptyCopy = computed(() => {
  switch (store.statusFilter) {
    case 'ACTIVE':
      return {
        title: "You're clear.",
        description: 'There are no active projects right now.',
      }
    case 'COMPLETED':
      return {
        title: 'No completed projects yet.',
        description: 'Finished projects land here for the record.',
      }
    case 'ARCHIVED':
      return {
        title: 'No archived projects.',
        description: 'Archived projects are kept out of the way here.',
      }
    default:
      return {
        title: 'No projects yet.',
        description: "Group related tasks into a project when you're ready to work toward something bigger.",
      }
  }
})

function onSelectProject(projectId: string) {
  detailProjectId.value = detailProjectId.value === projectId ? null : projectId
}

function onCreateProject(draft: NewProjectDraft) {
  store.addProject(draft)
  if (useMock('PROJECTS')) {
    showPreviewNote('Project created locally — preview only.')
  }
}

function onRetry() {
  store.load(null)
}
</script>

<template>
  <div class="projects-page">
    <header class="page-header">
      <div class="heading">
        <h1 class="title">Projects</h1>
        <p class="subtitle">Everything you're building.</p>
      </div>
      <UiButton variant="primary" @click="dialogOpen = true">
        <Plus :size="15" :stroke-width="2" />
        New Project
      </UiButton>
    </header>

    <FilterChips
      :options="filterOptions"
      :active="store.statusFilter"
      label="Filter projects by status"
      @change="store.setFilter($event)"
    />

    <!-- Loading — mirrors the header and card grid -->
    <div v-if="isLoading" class="skeleton-page" aria-busy="true" aria-label="Loading projects">
      <div class="skeleton-header">
        <div class="skeleton-heading">
          <SkeletonBlock height="30px" width="180px" rounded="md" />
          <SkeletonBlock height="18px" width="260px" rounded="md" />
        </div>
        <SkeletonBlock height="44px" width="150px" rounded="md" />
      </div>
      <div class="grid">
        <SkeletonBlock v-for="i in 4" :key="i" height="220px" rounded="lg" />
      </div>
    </div>

    <!-- Error -->
    <ErrorState
      v-else-if="store.status === 'error'"
      title="Projects didn't load"
      description="Your projects could not be reached. Your data is safe — try loading them again."
      @retry="onRetry"
    />

    <!-- Empty -->
    <EmptyState
      v-else-if="store.visibleProjects.length === 0"
      :icon="Folder"
      :title="emptyCopy.title"
      :description="emptyCopy.description"
    >
      <UiButton
        v-if="store.statusFilter === 'ACTIVE'"
        variant="primary"
        size="sm"
        class="empty-action"
        @click="dialogOpen = true"
      >
        <Plus :size="14" :stroke-width="2" />
        New Project
      </UiButton>
    </EmptyState>

    <!-- Grid -->
    <div v-else class="grid">
      <ProjectCard
        v-for="project in store.visibleProjects"
        :key="project.id"
        :project="project"
        :stats="store.statsForProject(project.id)"
        :active="project.id === detailProjectId"
        @select="onSelectProject"
      />
    </div>

    <NewProjectDialog :open="dialogOpen" @close="dialogOpen = false" @create="onCreateProject" />

    <UiDialog
      :open="detailProjectId !== null"
      title="Project details"
      size="lg"
      @close="detailProjectId = null"
    >
      <ProjectDetailPanel
        v-if="detailProjectId"
        :project-id="detailProjectId"
        @delete="detailProjectId = null"
      />
    </UiDialog>

    <UiDialog
      :open="taskDialogId !== null"
      title="Task details"
      @close="closeTaskDialog"
    >
      <TaskDetailPanel v-if="taskDialogId" :task-id="taskDialogId" />
    </UiDialog>
  </div>
</template>

<style scoped>
.projects-page {
  max-width: 1180px;
  margin: 0 auto;
  padding: var(--space-8) var(--space-10) var(--space-16);
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.page-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-6);
  margin-bottom: var(--space-1);
}

.title {
  font-size: var(--text-3xl);
  font-weight: 700;
  letter-spacing: -0.025em;
}

.subtitle {
  margin-top: var(--space-2);
  font-size: var(--text-lg);
  color: var(--text-tertiary);
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
  gap: var(--space-6);
}

/* Grid transitions — cards fade/rise in, retreat on removal, and glide when
   the grid reorders (motion spec §11–12, §26). */
.grid-move,
.grid-enter-active,
.grid-leave-active {
  transition:
    opacity var(--motion-standard) var(--ease-out),
    transform var(--motion-standard) var(--ease-out);
}

.grid-enter-from {
  opacity: 0;
  transform: translateY(8px);
}

.grid-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}

.empty-action {
  margin-top: var(--space-4);
}

.skeleton-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.skeleton-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-6);
}

.skeleton-heading {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

@media (max-width: 900px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
