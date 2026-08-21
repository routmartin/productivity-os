<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Search, SearchX } from 'lucide-vue-next'

import UiSpinner from '@/components/ui/UiSpinner.vue'

import { useSearchStore, type SearchGroup, type SearchResult } from '../store'

const TRIGGER_ID = 'global-search-trigger'

const store = useSearchStore()
const router = useRouter()
const route = useRoute()

const inputEl = ref<HTMLInputElement | null>(null)
const panelEl = ref<HTMLElement | null>(null)

/** Groups that have results or are still loading. */
const visibleGroups = computed<SearchGroup[]>(() =>
  store.groups.filter(
    (group) =>
      group.results.length > 0 ||
      (group.type === 'task' && store.tasksLoading) ||
      (group.type === 'project' && store.projectsLoading) ||
      (group.type === 'goal' && store.goalsLoading),
  ),
)

function isGroupLoading(group: SearchGroup): boolean {
  if (group.type === 'task') return store.tasksLoading
  if (group.type === 'project') return store.projectsLoading
  return store.goalsLoading
}

/** Flat index of a result inside its group (keyboard navigation). */
function indexOf(group: SearchGroup, index: number): number {
  return store.groupOffsets[group.type] + index
}

/** ⌘K / Ctrl+K closes any other overlay and opens search (D6: takes over). */
function onGlobalKeydown(event: KeyboardEvent) {
  if (!(event.metaKey || event.ctrlKey) || event.key.toLowerCase() !== 'k') return
  event.preventDefault()
  if (!store.open) {
    window.dispatchEvent(new CustomEvent('app:close-overlays'))
  }
  store.toggle()
}

function onPanelKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') {
    event.preventDefault()
    store.closeSearch()
  }
}

function onInputKeydown(event: KeyboardEvent) {
  if (event.key === 'ArrowDown') {
    event.preventDefault()
    store.moveHighlight(1)
  } else if (event.key === 'ArrowUp') {
    event.preventDefault()
    store.moveHighlight(-1)
  } else if (event.key === 'Enter') {
    event.preventDefault()
    openHighlighted()
  } else if (event.key === 'Escape') {
    event.preventDefault()
    store.closeSearch()
  }
}

function openHighlighted() {
  const result = store.highlightedResult() ?? store.visibleResults[0]
  if (result) openResult(result)
}

function openResult(result: SearchResult) {
  store.closeSearch()
  const name =
    result.type === 'task' ? 'tasks' : result.type === 'project' ? 'projects' : 'goals'
  void router.push({ name, query: { open: result.id } })
}

function onHighlight(index: number) {
  store.highlightedIndex = index
}

// Focus moves into the input on open and back to the trigger on close
// (spec Rule 4).
watch(
  () => store.open,
  async (isOpen) => {
    await nextTick()
    if (isOpen) {
      inputEl.value?.focus()
    } else {
      document.getElementById(TRIGGER_ID)?.focus()
    }
  },
)

// The overlay never survives a route change (spec Edge Cases).
watch(
  () => route.fullPath,
  () => store.closeSearch(),
)

// Keep the highlighted row visible while navigating with the keyboard.
watch(
  () => store.highlightedIndex,
  (index) => {
    const row = panelEl.value?.querySelector(`[data-result-index="${index}"]`)
    ;(row as HTMLElement | null)?.scrollIntoView({ block: 'nearest' })
  },
)

onMounted(() => window.addEventListener('keydown', onGlobalKeydown))
onBeforeUnmount(() => window.removeEventListener('keydown', onGlobalKeydown))
</script>

<template>
  <Teleport to="body">
    <Transition name="search">
      <div
        v-if="store.open"
        class="search-overlay"
        role="presentation"
        @mousedown.self="store.closeSearch()"
      >
        <div
          ref="panelEl"
          class="search-panel"
          role="dialog"
          aria-modal="true"
          aria-label="Global search"
          @keydown="onPanelKeydown"
        >
          <div class="search-head">
            <Search :size="16" :stroke-width="1.75" class="search-icon" aria-hidden="true" />
            <input
              ref="inputEl"
              v-model="store.query"
              type="text"
              class="search-input"
              placeholder="Search tasks, projects, goals…"
              aria-label="Search tasks, projects, goals"
              autocomplete="off"
              spellcheck="false"
              @keydown="onInputKeydown"
            />
            <kbd class="kbd tnum">esc</kbd>
          </div>

          <div class="results">
            <p v-if="store.isEmptyQuery" class="hint">
              Start typing to search your tasks, projects, and goals.
            </p>

            <template v-else>
              <section
                v-for="group in visibleGroups"
                :key="group.type"
                class="group"
                :aria-label="group.label"
              >
                <h3 class="group-label">{{ group.label }}</h3>

                <div v-if="isGroupLoading(group)" class="loading-row">
                  <UiSpinner :size="14" />
                  <span>Searching…</span>
                </div>

                <template v-else>
                  <button
                    v-for="(result, index) in group.results"
                    :key="`${result.type}-${result.id}`"
                    type="button"
                    class="result"
                    :class="{ highlighted: indexOf(group, index) === store.highlightedIndex }"
                    :data-result-index="indexOf(group, index)"
                    @mouseenter="onHighlight(indexOf(group, index))"
                    @click="openResult(result)"
                  >
                    <span class="result-main">
                      <span class="result-title">{{ result.title }}</span>
                      <span v-if="result.subtitle" class="result-subtitle">
                        {{ result.subtitle }}
                      </span>
                    </span>
                    <span class="result-type">{{ group.label }}</span>
                  </button>
                </template>
              </section>

              <div v-if="!store.hasResults && !store.anyLoading" class="empty-state">
                <SearchX :size="20" :stroke-width="1.5" aria-hidden="true" />
                <p class="empty-title">No results</p>
                <p class="empty-desc">Nothing matches “{{ store.query }}”.</p>
              </div>
            </template>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.search-overlay {
  position: fixed;
  inset: 0;
  z-index: 80;
  display: flex;
  justify-content: center;
  padding: var(--space-16) var(--space-6) var(--space-6);
  background: var(--surface-overlay);
  backdrop-filter: blur(4px);
}

.search-panel {
  width: 100%;
  max-width: 600px;
  height: fit-content;
  max-height: calc(100vh - var(--space-16) - var(--space-6));
  display: flex;
  flex-direction: column;
  background: var(--surface-1);
  border: 1px solid var(--border-strong);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-panel);
  overflow: hidden;
}

.search-head {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-4) var(--space-5);
  border-bottom: 1px solid var(--border-subtle);
}

.search-icon {
  flex-shrink: 0;
  color: var(--text-tertiary);
}

.search-input {
  flex: 1;
  min-width: 0;
  background: transparent;
  border: none;
  outline: none;
  color: var(--text-primary);
  font-size: var(--text-lg);
}

.search-input::placeholder {
  color: var(--text-disabled);
}

.kbd {
  flex-shrink: 0;
  padding: 2px 6px;
  border: 1px solid var(--border-subtle);
  border-radius: 6px;
  background: var(--surface-2);
  font-family: inherit;
  font-size: 11px;
  color: var(--text-disabled);
}

.results {
  overflow-y: auto;
  padding: var(--space-3);
}

.hint {
  padding: var(--space-8) var(--space-4);
  text-align: center;
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.group {
  margin-bottom: var(--space-2);
}

.group-label {
  padding: var(--space-2) var(--space-3);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-disabled);
}

.loading-row {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-3) var(--space-2);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.result {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  width: 100%;
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-sm);
  text-align: left;
  transition: background-color var(--duration-fast) var(--ease-out);
}

.result:hover,
.result.highlighted {
  background: var(--surface-2);
}

.result-main {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-width: 0;
}

.result-title {
  font-size: var(--text-md);
  font-weight: 550;
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.result-subtitle {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.result-type {
  flex-shrink: 0;
  font-size: var(--text-xs);
  color: var(--text-disabled);
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-1);
  padding: var(--space-10) var(--space-4);
  text-align: center;
  color: var(--text-tertiary);
}

.empty-title {
  margin-top: var(--space-2);
  font-size: var(--text-md);
  font-weight: 550;
  color: var(--text-secondary);
}

.empty-desc {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.search-enter-active {
  transition: opacity var(--motion-standard) var(--ease-out);
}

.search-leave-active {
  transition: opacity var(--motion-fast) var(--ease-in);
}

.search-enter-active .search-panel {
  transition:
    transform var(--motion-standard) var(--ease-out),
    opacity var(--motion-standard) var(--ease-out);
}

.search-leave-active .search-panel {
  transition:
    transform var(--motion-fast) var(--ease-in),
    opacity var(--motion-fast) var(--ease-in);
}

.search-enter-from,
.search-leave-to {
  opacity: 0;
}

.search-enter-from .search-panel,
.search-leave-to .search-panel {
  transform: translateY(-8px);
  opacity: 0;
}
</style>
