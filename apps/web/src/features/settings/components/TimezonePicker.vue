<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { Check, ChevronDown, Search } from 'lucide-vue-next'

import {
  buildTimezoneGroups,
  describeTimezone,
  type TimezoneGroup,
} from '../timezones'

const props = withDefaults(
  defineProps<{
    modelValue: string
    disabled?: boolean
    error?: string | null
  }>(),
  {
    disabled: false,
    error: null,
  },
)

const emit = defineEmits<{ 'update:modelValue': [value: string] }>()

const groups = buildTimezoneGroups()

const root = ref<HTMLElement | null>(null)
const searchInput = ref<HTMLInputElement | null>(null)
const open = ref(false)
const query = ref('')
const highlighted = ref<string | null>(null)

const selected = computed(() => describeTimezone(props.modelValue))

const filteredGroups = computed<TimezoneGroup[]>(() => {
  const q = query.value.trim().toLowerCase()
  if (!q) return groups
  return groups
    .map((group) => ({
      ...group,
      zones: group.zones.filter(
        (zone) =>
          zone.id.toLowerCase().includes(q) ||
          zone.city.toLowerCase().includes(q) ||
          zone.region.toLowerCase().includes(q),
      ),
    }))
    .filter((group) => group.zones.length > 0)
})

const visibleZones = computed(() => filteredGroups.value.flatMap((g) => g.zones))

function toggle() {
  if (props.disabled) return
  open.value = !open.value
  if (open.value) {
    query.value = ''
    highlighted.value = props.modelValue || visibleZones.value[0]?.id || null
    nextTick(() => searchInput.value?.focus())
  }
}

function close() {
  open.value = false
  query.value = ''
}

function select(id: string) {
  emit('update:modelValue', id)
  close()
}

function onKeydown(event: KeyboardEvent) {
  if (!open.value) return
  if (event.key === 'Escape') {
    close()
    return
  }
  if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
    event.preventDefault()
    const zones = visibleZones.value
    if (zones.length === 0) return
    const current = zones.findIndex((z) => z.id === highlighted.value)
    const delta = event.key === 'ArrowDown' ? 1 : -1
    const next = (current + delta + zones.length) % zones.length
    highlighted.value = zones[next].id
  } else if (event.key === 'Enter') {
    event.preventDefault()
    const target =
      visibleZones.value.find((z) => z.id === highlighted.value) ??
      visibleZones.value[0]
    if (target) select(target.id)
  }
}

watch(highlighted, (id) => {
  if (!id) return
  const element = root.value?.querySelector(`[data-zone-id="${CSS.escape(id)}"]`)
  ;(element as HTMLElement | null)?.scrollIntoView({ block: 'nearest' })
})

function onDocPointerDown(event: MouseEvent) {
  if (root.value && !root.value.contains(event.target as Node)) close()
}

/** Global search takes over any open popover (spec: global-search, Edge
 *  Cases — ⌘K closes other overlays). */
function onCloseOverlays() {
  close()
}

onMounted(() => {
  document.addEventListener('mousedown', onDocPointerDown)
  window.addEventListener('app:close-overlays', onCloseOverlays)
})
onBeforeUnmount(() => {
  document.removeEventListener('mousedown', onDocPointerDown)
  window.removeEventListener('app:close-overlays', onCloseOverlays)
})
</script>

<template>
  <div ref="root" class="tz-picker" :class="{ 'has-error': Boolean(error) }">
    <button
      type="button"
      class="trigger"
      :disabled="disabled"
      :aria-expanded="open"
      aria-haspopup="listbox"
      @click="toggle"
    >
      <span class="value">
        <span class="city">{{ selected.label }}</span>
        <span class="offset tnum">{{ selected.offset }}</span>
      </span>
      <ChevronDown :size="15" :stroke-width="1.75" class="chevron" aria-hidden="true" />
    </button>
    <p v-if="error" class="error" role="alert">{{ error }}</p>

    <Transition name="drop">
      <div v-if="open" class="menu">
        <div class="search">
          <Search :size="14" :stroke-width="1.75" class="search-icon" aria-hidden="true" />
          <input
            ref="searchInput"
            v-model="query"
            type="search"
            class="search-input"
            placeholder="Search timezones…"
            aria-label="Search timezones"
            @keydown="onKeydown"
          />
        </div>

        <div class="list" role="listbox" aria-label="Timezones">
          <template v-for="group in filteredGroups" :key="group.label">
            <p class="group-label">{{ group.label }}</p>
            <button
              v-for="zone in group.zones"
              :key="zone.id"
              type="button"
              class="option"
              :class="{
                selected: zone.id === modelValue,
                highlighted: zone.id === highlighted,
              }"
              :data-zone-id="zone.id"
              role="option"
              :aria-selected="zone.id === modelValue"
              @mouseenter="highlighted = zone.id"
              @click="select(zone.id)"
            >
              <span class="opt-city">{{ zone.city }}</span>
              <span class="opt-offset tnum">{{ zone.offset }}</span>
              <Check
                v-if="zone.id === modelValue"
                :size="14"
                :stroke-width="2"
                class="check"
                aria-hidden="true"
              />
            </button>
          </template>
          <p v-if="filteredGroups.length === 0" class="empty">No matching timezone.</p>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.tz-picker {
  position: relative;
  width: 100%;
}

.trigger {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  width: 100%;
  height: 46px;
  padding: 0 var(--space-4);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  color: var(--text-primary);
  font-size: var(--text-md);
  text-align: left;
  transition:
    border-color var(--duration-fast) var(--ease-out),
    background-color var(--duration-fast) var(--ease-out);
}

.trigger:hover:not(:disabled) {
  border-color: var(--border-strong);
}

.trigger:focus-visible {
  outline: none;
  border-color: var(--accent-border);
  background: var(--surface-1);
}

.trigger:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

.has-error .trigger {
  border-color: var(--danger);
}

.value {
  display: flex;
  align-items: baseline;
  gap: var(--space-2);
  min-width: 0;
}

.city {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.offset {
  flex-shrink: 0;
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.chevron {
  flex-shrink: 0;
  color: var(--text-tertiary);
  transition: transform var(--duration-fast) var(--ease-out);
}

.tz-picker:has(.menu) .chevron {
  transform: rotate(180deg);
}

.error {
  margin-top: var(--space-2);
  font-size: var(--text-sm);
  color: var(--danger);
}

.menu {
  position: absolute;
  top: calc(100% + var(--space-2));
  left: 0;
  right: 0;
  z-index: 40;
  display: flex;
  flex-direction: column;
  background: var(--surface-1);
  border: 1px solid var(--border-strong);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-panel);
  overflow: hidden;
}

.search {
  position: relative;
  display: flex;
  align-items: center;
  padding: var(--space-3);
  border-bottom: 1px solid var(--border-subtle);
}

.search-icon {
  position: absolute;
  left: var(--space-6);
  color: var(--text-tertiary);
  pointer-events: none;
}

.search-input {
  width: 100%;
  height: 40px;
  padding: 0 var(--space-4) 0 var(--space-8);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  color: var(--text-primary);
  font-size: var(--text-md);
}

.search-input::placeholder {
  color: var(--text-tertiary);
}

.search-input:focus {
  outline: none;
  border-color: var(--accent-border);
}

.list {
  max-height: 320px;
  overflow-y: auto;
  padding: var(--space-2);
}

.group-label {
  padding: var(--space-3) var(--space-3) var(--space-1);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-disabled);
}

.option {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  width: 100%;
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-sm);
  color: var(--text-secondary);
  font-size: var(--text-sm);
  text-align: left;
  transition:
    background-color var(--duration-fast) var(--ease-out),
    color var(--duration-fast) var(--ease-out);
}

.option:hover,
.option.highlighted {
  background: var(--surface-2);
  color: var(--text-primary);
}

.option.selected {
  color: var(--text-primary);
}

.opt-city {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.opt-offset {
  flex-shrink: 0;
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

.option.selected .opt-offset {
  color: var(--text-secondary);
}

.check {
  flex-shrink: 0;
  color: var(--accent-strong);
}

.empty {
  padding: var(--space-4) var(--space-3);
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.drop-enter-active,
.drop-leave-active {
  transition:
    opacity var(--duration-fast) var(--ease-out),
    transform var(--duration-fast) var(--ease-out);
}

.drop-enter-from,
.drop-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}
</style>
