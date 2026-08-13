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
import type { PreviewState } from '@/features/planning/types'
import NewProjectDialog from '@/features/projects/components/NewProjectDialog.vue'
import ProjectCard from '@/features/projects/components/ProjectCard.vue'
import {
  PROJECT_FILTER_LABELS,
  useProjectsStore,
  type ProjectFilter,
} from '@/features/projects/store'
import type { NewProjectDraft } from '@/features/projects/types'
import { showPreviewNote } from '@/lib/preview'

const route = useRoute()
const store = useProjectsStore()
const panel = useContextPanelStore()

/** `?preview=loading|error|empty` forces a UI state for design review. */
function previewFromQuery(): PreviewState {
  const value = route.query.preview
  return value === 'loading' || value === 'error' || value === 'empty' ? value : null
}

onMounted(() => store.load(previewFromQuery()))
watch(
  () => route.query.preview,
  () => store.load(previewFromQuery()),
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
  panel.toggleProject(projectId)
}

function onCreateProject(draft: NewProjectDraft) {
  store.addProject(draft)
  showPreviewNote('Project created locally — it will sync once the Project API is connected.')
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

    <!-- Loading -->
    <div v-if="isLoading" class="grid" aria-busy="true" aria-label="Loading projects">
      <SkeletonBlock v-for="i in 4" :key="i" height="220px" rounded="lg" />
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
        :active="project.id === panel.activeProjectId"
        @select="onSelectProject"
      />
    </div>

    <NewProjectDialog :open="dialogOpen" @close="dialogOpen = false" @create="onCreateProject" />
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

.empty-action {
  margin-top: var(--space-4);
}

@media (max-width: 900px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
