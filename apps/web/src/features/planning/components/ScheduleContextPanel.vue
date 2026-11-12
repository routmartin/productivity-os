<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import {
  AlertTriangle,
  ArrowRight,
  BedDouble,
  BookOpen,
  Calendar,
  Check,
  Clock,
  Flame,
  Globe,
  Pencil,
  Play,
  Radio,
  Sparkles,
  Sun,
  Trash2,
  Zap,
} from 'lucide-vue-next'

import UiButton from '@/components/ui/UiButton.vue'
import UiDialog from '@/components/ui/UiDialog.vue'
import UiInput from '@/components/ui/UiInput.vue'
import UiSelect from '@/components/ui/UiSelect.vue'
import UiTextarea from '@/components/ui/UiTextarea.vue'
import { useScheduleStore } from '../scheduleStore'
import type { SchedulePhaseId } from '../types'

const scheduleStore = useScheduleStore()

const node = computed(() => scheduleStore.selectedNode)
const isOpen = computed(() => Boolean(node.value))

function close() {
  isEditing.value = false
  formError.value = null
  scheduleStore.selectNode(null)
}

function toggleHabit() {
  if (!node.value) return
  scheduleStore.toggleHabit(node.value.id)
}

function toggleActivity() {
  if (!node.value) return
  if (node.value.inFocus) {
    scheduleStore.stopFocus()
  } else {
    scheduleStore.startFocus(node.value.id)
  }
}

const isDeleting = ref(false)

async function handleDelete() {
  if (!node.value || node.value.type === 'anchor') return
  const idToDelete = node.value.id
  isDeleting.value = true
  try {
    close()
    await scheduleStore.deleteNode(idToDelete)
  } finally {
    isDeleting.value = false
  }
}

// In-Place Step Editing State & Methods (Spec AC-010, AC-011, AC-012)
const isEditing = ref(false)
const isSaving = ref(false)
const formError = ref<string | null>(null)

interface FormState {
  title: string
  subtitle: string
  phase: SchedulePhaseId
  timeSlot: string
  durationMinutes: string
  notes: string
  iconName: string
}

const form = ref<FormState>({
  title: '',
  subtitle: '',
  phase: 'morning',
  timeSlot: '',
  durationMinutes: '30',
  notes: '',
  iconName: 'Droplets',
})

const phaseOptions = [
  { value: 'morning', label: 'Morning Activation' },
  { value: 'deep-focus', label: 'Deep Focus Flow' },
  { value: 'afternoon', label: 'Afternoon Momentum' },
  { value: 'bedtime', label: 'Bedtime Sanctuary' },
]

const iconOptions = [
  { value: 'Droplets', label: 'Droplets (Hydration)' },
  { value: 'Dumbbell', label: 'Dumbbell (Workout / Movement)' },
  { value: 'Target', label: 'Target (Planning / Focus)' },
  { value: 'Footprints', label: 'Footprints (Walk / Stride)' },
  { value: 'Moon', label: 'Moon (Curfew / Evening)' },
  { value: 'BookOpen', label: 'BookOpen (Reading / Reflection)' },
  { value: 'Coffee', label: 'Coffee (Tea / Winddown)' },
  { value: 'Zap', label: 'Zap (Restoration / Energy)' },
  { value: 'Sparkles', label: 'Sparkles (Deep Flow)' },
]

function initForm() {
  if (!node.value) return
  form.value = {
    title: node.value.title ?? '',
    subtitle: node.value.subtitle ?? '',
    phase: node.value.phase ?? 'morning',
    timeSlot: node.value.time ?? '',
    durationMinutes: String(node.value.durationMinutes ?? node.value.totalMinutes ?? 30),
    notes: node.value.notes ?? '',
    iconName: node.value.icon ?? 'Droplets',
  }
  formError.value = null
}

function startEditing() {
  if (!node.value || node.value.type === 'anchor') return
  initForm()
  isEditing.value = true
}

function cancelEditing() {
  isEditing.value = false
  formError.value = null
}

async function handleSave() {
  if (!node.value) return
  if (!form.value.title.trim()) {
    formError.value = 'Title is required'
    return
  }
  isSaving.value = true
  formError.value = null
  try {
    const duration = Math.max(1, parseInt(form.value.durationMinutes, 10) || 15)
    await scheduleStore.updateStep(node.value.id, {
      title: form.value.title.trim(),
      subtitle: form.value.subtitle.trim() || undefined,
      phase: form.value.phase,
      timeSlot: form.value.timeSlot.trim() || undefined,
      durationMinutes: duration,
      totalMinutes: duration,
      notes: form.value.notes.trim() || undefined,
      iconName: form.value.iconName,
    })
    isEditing.value = false
  } catch (err) {
    formError.value = err instanceof Error ? err.message : 'Failed to save changes'
  } finally {
    isSaving.value = false
  }
}

function handleKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape' && isEditing.value) {
    event.stopPropagation()
    cancelEditing()
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeydown, true)
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', handleKeydown, true)
})

watch(node, () => {
  isEditing.value = false
  formError.value = null
})

const kindLabel = computed(() => {
  if (!node.value) return ''
  switch (node.value.type) {
    case 'habit':
      return 'Daily Habit Ritual'
    case 'task':
      return 'Scheduled Activity Block'
    case 'anchor':
      return node.value.anchorKind === 'wake' ? 'Morning Wake Anchor' : 'Bedtime Sanctuary Anchor'
    case 'recharge':
      return 'Recharge & Restoration Break'
    default:
      return 'Schedule Step'
  }
})

const phaseTitle = computed(() => {
  if (!node.value) return ''
  switch (node.value.phase) {
    case 'morning':
      return 'Morning Activation (06:30 – 09:00)'
    case 'deep-focus':
      return 'Deep Focus Flow (09:00 – 12:30)'
    case 'afternoon':
      return 'Afternoon Momentum (12:30 – 18:00)'
    case 'bedtime':
      return 'Evening Sanctuary (18:00 – 22:30)'
    default:
      return 'Daily Schedule'
  }
})

const consistencyPercent = computed(() => {
  if (!node.value?.history || node.value.history.length === 0) return 0
  const completed = node.value.history.filter((h) => h.completed).length
  return Math.round((completed / node.value.history.length) * 100)
})
</script>

<template>
  <UiDialog
    :open="isOpen"
    :title="isEditing ? `Edit: ${node?.title ?? 'Step'}` : (node ? node.title : 'Step Details')"
    size="full"
    @close="close"
  >
    <div v-if="node" class="detail-container">
      <!-- Top Badges Row -->
      <div class="badges-row">
        <span class="kind-tag" :class="`kind-${node.type}`">
          {{ kindLabel }}
        </span>
        <span v-if="node.time" class="meta-pill">
          <Clock :size="13" />
          <span>{{ node.time }}</span>
        </span>
        <span v-if="node.durationMinutes" class="meta-pill">
          <Sparkles :size="13" />
          <span>{{ node.durationMinutes }}m Duration</span>
        </span>
        <span class="meta-pill phase-pill">
          <span>{{ phaseTitle }}</span>
        </span>

        <!-- Edit Step toggle button (hidden for anchors) -->
        <button
          v-if="node.type !== 'anchor' && !isEditing"
          type="button"
          class="edit-step-btn"
          @click="startEditing"
        >
          <Pencil :size="14" />
          <span>Edit Step</span>
        </button>
      </div>

      <!-- Edit Form (when isEditing is true) -->
      <form v-if="isEditing" class="edit-form-container" @submit.prevent="handleSave">
        <div v-if="formError" class="form-error-banner" role="alert">
          <AlertTriangle :size="16" />
          <span>{{ formError }}</span>
        </div>

        <div class="edit-grid">
          <div class="edit-col">
            <UiInput
              v-model="form.title"
              label="Step Title"
              placeholder="e.g. Deep Focus Flow or Morning Workout"
              required
            />

            <UiInput
              v-model="form.subtitle"
              label="Subtitle (Optional)"
              placeholder="e.g. High cognitive load · Core schema"
            />

            <UiSelect
              v-model="form.phase"
              label="Schedule Phase"
              :options="phaseOptions"
            />

            <UiSelect
              v-model="form.iconName"
              label="Icon / Symbol"
              :options="iconOptions"
            />
          </div>

          <div class="edit-col">
            <UiInput
              v-model="form.timeSlot"
              label="Scheduled Time"
              type="time"
              placeholder="e.g. 09:30"
            />

            <UiInput
              v-model="form.durationMinutes"
              label="Duration (minutes)"
              type="number"
              placeholder="30"
            />

            <UiTextarea
              v-model="form.notes"
              label="Protocol & Execution Guidance"
              placeholder="Enter notes, execution cues, or protocol instructions..."
              :rows="4"
            />
          </div>
        </div>
      </form>

      <!-- Main 2-Column Desktop Grid -->
      <div v-else class="detail-grid">
        <!-- Left Column: Primary Content & Actions -->
        <div class="main-column">
          <section class="intro-card">
            <h3 class="hero-title">{{ node.title }}</h3>
            <p v-if="node.subtitle" class="hero-subtitle">{{ node.subtitle }}</p>
          </section>

          <!-- Habit Interactive Hero -->
          <section v-if="node.type === 'habit'" class="hero-action-section">
            <div class="habit-action-box" :class="{ 'is-completed': node.completed }">
              <div class="habit-left">
                <button
                  type="button"
                  class="big-check-btn"
                  :class="{ checked: node.completed }"
                  :aria-label="node.completed ? 'Mark habit as incomplete' : 'Mark habit as completed'"
                  @click="toggleHabit"
                >
                  <Check v-if="node.completed" :size="20" :stroke-width="3" />
                </button>
                <div class="habit-texts">
                  <h4 class="action-heading">
                    {{ node.completed ? 'Completed for Today!' : 'Mark Completed Today' }}
                  </h4>
                  <p class="action-caption">
                    {{
                      node.completed
                        ? 'Great momentum. Neural pathways reinforced.'
                        : 'Click to check off and illuminate your daily progress path.'
                    }}
                  </p>
                </div>
              </div>

              <div class="streak-badge-card">
                <Flame :size="22" class="flame-icon" />
                <div class="streak-info">
                  <span class="streak-number">{{ node.streak ?? 0 }}</span>
                  <span class="streak-label">Day Streak</span>
                </div>
              </div>
            </div>
          </section>

          <!-- Activity Block Interactive Hero -->
          <section v-else-if="node.type === 'task'" class="hero-action-section">
            <div class="activity-action-box" :class="{ 'is-active': node.inFocus }">
              <div class="activity-left">
                <div class="beacon-ring" :class="{ pulsing: node.inFocus }">
                  <component :is="node.inFocus ? Radio : Play" :size="20" />
                </div>
                <div class="activity-texts">
                  <h4 class="action-heading">
                    {{ node.inFocus ? 'Activity In Progress' : 'Ready to Start' }}
                  </h4>
                  <p class="action-caption">
                    {{
                      node.inFocus
                        ? 'Timer is running actively. Keep your attention focused on this block.'
                        : `Scheduled for ${node.durationMinutes ?? 60} minutes of uninterrupted execution.`
                    }}
                  </p>
                </div>
              </div>

              <UiButton
                :variant="node.inFocus ? 'subtle' : 'primary'"
                size="lg"
                @click="toggleActivity"
              >
                {{ node.inFocus ? 'Pause / Stop Activity' : 'Start Activity Now' }}
              </UiButton>
            </div>
          </section>

          <!-- Anchor Circadian Rhythm Hero -->
          <section v-else-if="node.type === 'anchor'" class="hero-action-section">
            <div
              class="anchor-circadian-box"
              :class="{
                'warning-tone': node.overflowMinutes && node.overflowMinutes > 0,
                'wake-tone': node.anchorKind === 'wake',
              }"
            >
              <div class="circadian-header">
                <component
                  :is="node.anchorKind === 'wake' ? Sun : BedDouble"
                  :size="26"
                  class="circadian-icon"
                />
                <div class="circadian-title-wrap">
                  <h4 class="circadian-heading">
                    {{
                      node.anchorKind === 'wake'
                        ? 'Target Wake: 06:30'
                        : `Target Bedtime: ${node.targetTime ?? '22:30'}`
                    }}
                  </h4>
                  <span
                    v-if="node.projectedTime && node.overflowMinutes && node.overflowMinutes > 0"
                    class="circadian-delay-badge"
                  >
                    Projected: {{ node.projectedTime }} (+{{ node.overflowMinutes }}m shift)
                  </span>
                  <span v-else class="circadian-ontrack-badge">
                    Circadian Target Locked · On Track
                  </span>
                </div>
              </div>

              <p
                v-if="node.anchorKind === 'bedtime' && node.overflowMinutes && node.overflowMinutes > 0"
                class="circadian-alert"
              >
                <AlertTriangle :size="16" class="alert-icon" />
                <span>
                  Your planned afternoon activities and habits shift bedtime past 22:30. Consider trimming
                  secondary tasks to protect deep REM recovery sleep.
                </span>
              </p>
              <p v-else class="circadian-ok">
                <Check :size="16" class="ok-icon" />
                <span>
                  Full 8-hour sleep opportunity preserved. Consistent bedtimes regulate your natural melatonin release.
                </span>
              </p>
            </div>
          </section>

          <!-- Recharge Hero -->
          <section v-else-if="node.type === 'recharge'" class="hero-action-section">
            <div class="recharge-banner">
              <Zap :size="24" class="recharge-icon" />
              <div class="recharge-texts">
                <h4 class="action-heading">Cognitive Reset & Restoration</h4>
                <p class="action-caption">
                  Deliberate downtime resets dopamine levels and sustains high cognitive output for upcoming blocks.
                </p>
              </div>
            </div>
          </section>

          <!-- Protocol & Notes Section -->
          <section v-if="node.notes" class="content-block">
            <div class="block-header">
              <BookOpen :size="16" class="header-icon" />
              <h4 class="block-title">Protocol & Execution Guidance</h4>
            </div>
            <div class="notes-body">
              <p>{{ node.notes }}</p>
            </div>
          </section>

          <!-- Flow Connectivity Path -->
          <section class="content-block">
            <div class="block-header">
              <ArrowRight :size="16" class="header-icon" />
              <h4 class="block-title">Position in Daily Trajectory</h4>
            </div>
            <div class="trajectory-card">
              <div class="phase-badge-large">
                <span class="phase-dot" />
                <span>Phase: {{ phaseTitle }}</span>
              </div>
              <p class="trajectory-hint">
                This step is chained in your morning-to-bedtime flow. Completing it unlocks the next milestone in your schedule.
              </p>
            </div>
          </section>
        </div>

        <!-- Right Column: Stats, Consistency & Attributes -->
        <div class="side-column">
          <!-- 14-Day Consistency Matrix (For Habits) -->
          <section v-if="node.type === 'habit'" class="side-card">
            <div class="card-title-row">
              <Calendar :size="16" />
              <h4 class="card-title">14-Day Consistency</h4>
              <span class="consistency-rate">{{ consistencyPercent }}%</span>
            </div>

            <div class="matrix-grid">
              <div
                v-for="(day, idx) in node.history ?? []"
                :key="idx"
                class="matrix-cell"
                :class="{ completed: day.completed }"
                :title="`${day.date}: ${day.completed ? 'Completed' : 'Missed'}`"
              >
                <div class="cell-inner" />
              </div>
            </div>

            <div class="matrix-legend">
              <span class="legend-item">
                <span class="legend-dot completed" /> Completed
              </span>
              <span class="legend-item">
                <span class="legend-dot" /> Missed / Pending
              </span>
            </div>
          </section>

          <!-- Schedule Attributes Card -->
          <section class="side-card">
            <h4 class="card-title">Schedule Attributes</h4>
            <dl class="attr-list">
              <div class="attr-row">
                <dt class="attr-term">Step Type</dt>
                <dd class="attr-def">{{ kindLabel }}</dd>
              </div>
              <div v-if="node.time" class="attr-row">
                <dt class="attr-term">Time Target</dt>
                <dd class="attr-def">{{ node.time }}</dd>
              </div>
              <div v-if="node.durationMinutes" class="attr-row">
                <dt class="attr-term">Duration</dt>
                <dd class="attr-def">{{ node.durationMinutes }} minutes</dd>
              </div>
              <div class="attr-row">
                <dt class="attr-term">Recurrence</dt>
                <dd class="attr-def">{{ node.frequency ?? 'Daily Blueprint' }}</dd>
              </div>
              <div v-if="node.priority" class="attr-row">
                <dt class="attr-term">Priority</dt>
                <dd class="attr-def" :class="`prio-${node.priority.toLowerCase()}`">
                  {{ node.priority }}
                </dd>
              </div>
            </dl>
          </section>

          <!-- Timezone & Sleep Alignment Info -->
          <section class="side-card info-subcard">
            <div class="info-title-row">
              <Globe :size="14" />
              <span>Circadian Alignment</span>
            </div>
            <p class="info-subtext">
              Times are evaluated against your local IANA timezone per ADR-006 to maintain natural biological rhythms.
            </p>
          </section>
        </div>
      </div>
    </div>

    <!-- Dialog Footer -->
    <template #footer>
      <div v-if="isEditing" class="dialog-footer-actions">
        <UiButton
          variant="subtle"
          size="lg"
          type="button"
          :disabled="isSaving"
          @click="cancelEditing"
        >
          Cancel
        </UiButton>
        <UiButton
          variant="primary"
          size="lg"
          type="button"
          :loading="isSaving"
          @click="handleSave"
        >
          Save Changes
        </UiButton>
      </div>
      <div v-else class="dialog-footer-actions">
        <button
          v-if="node?.type !== 'anchor'"
          type="button"
          class="delete-step-btn"
          title="Delete from Today"
          :disabled="isDeleting"
          @click="handleDelete"
        >
          <Trash2 :size="15" />
          <span>{{ isDeleting ? 'Deleting...' : 'Delete from Today' }}</span>
        </button>
        <div v-else />

        <UiButton variant="primary" size="lg" @click="close">
          Done
        </UiButton>
      </div>
    </template>
  </UiDialog>
</template>

<style scoped>
.detail-container {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
  color: var(--text-primary);
}

/* Badges Row */
.badges-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-2);
}

.kind-tag {
  font-size: var(--text-sm);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 5px 12px;
  border-radius: var(--radius-sm);
}

.kind-habit {
  background: var(--success-soft);
  color: var(--success);
  border: 1px solid color-mix(in srgb, var(--success) 30%, transparent);
}

.kind-task {
  background: var(--accent-soft);
  color: var(--accent-strong);
  border: 1px solid var(--accent-border);
}

.kind-anchor {
  background: rgba(244, 183, 64, 0.14);
  color: var(--warning);
  border: 1px solid rgba(244, 183, 64, 0.3);
}

.kind-recharge {
  background: var(--blue-soft);
  color: var(--blue-strong);
  border: 1px solid rgba(59, 130, 246, 0.3);
}

.meta-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: var(--text-sm);
  color: var(--text-secondary);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  padding: 5px 12px;
  border-radius: var(--radius-full);
}

.phase-pill {
  color: var(--text-tertiary);
}

/* 2-Column Grid Layout */
.detail-grid {
  display: grid;
  grid-template-columns: 1fr 340px;
  gap: var(--space-8);
  align-items: start;
}

@media (max-width: 900px) {
  .detail-grid {
    grid-template-columns: 1fr;
  }
}

.main-column {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
  min-width: 0;
}

.side-column {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
  min-width: 0;
}

/* Intro Card */
.intro-card {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.hero-title {
  font-size: var(--text-3xl);
  font-weight: 700;
  letter-spacing: -0.02em;
  color: var(--text-primary);
  margin: 0;
}

.hero-subtitle {
  font-size: var(--text-lg);
  color: var(--text-secondary);
  line-height: 1.5;
  margin: 0;
}

/* Habit Interactive Hero */
.habit-action-box {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-6);
  padding: var(--space-6);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  transition: all 0.2s ease;
}

.habit-action-box.is-completed {
  border-color: color-mix(in srgb, var(--success) 40%, transparent);
  background: var(--success-soft);
}

.habit-left {
  display: flex;
  align-items: center;
  gap: var(--space-4);
}

.big-check-btn {
  width: 48px;
  height: 48px;
  border-radius: var(--radius-full);
  border: 2px solid var(--border-strong);
  background: var(--surface-1);
  color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
}

.big-check-btn:hover {
  border-color: var(--success);
  transform: scale(1.05);
}

.big-check-btn.checked {
  background: var(--success);
  border-color: var(--success);
  box-shadow: 0 0 16px color-mix(in srgb, var(--success) 40%, transparent);
}

.habit-texts {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.action-heading {
  font-size: var(--text-xl);
  font-weight: 600;
  margin: 0;
}

.action-caption {
  font-size: var(--text-md);
  color: var(--text-secondary);
  margin: 0;
}

.streak-badge-card {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  background: rgba(244, 183, 64, 0.1);
  border: 1px solid rgba(244, 183, 64, 0.25);
  border-radius: var(--radius-md);
  flex-shrink: 0;
}

.flame-icon {
  color: var(--warning);
}

.streak-info {
  display: flex;
  flex-direction: column;
}

.streak-number {
  font-size: var(--text-2xl);
  font-weight: 700;
  line-height: 1;
  color: var(--warning);
}

.streak-label {
  font-size: var(--text-xs);
  text-transform: uppercase;
  color: var(--text-secondary);
  letter-spacing: 0.04em;
}

/* Activity Block Hero */
.activity-action-box {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-6);
  padding: var(--space-6);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
}

.activity-action-box.is-active {
  border-color: var(--accent-border);
  background: var(--accent-soft);
}

.activity-left {
  display: flex;
  align-items: center;
  gap: var(--space-4);
}

.beacon-ring {
  width: 48px;
  height: 48px;
  border-radius: var(--radius-full);
  background: var(--surface-3);
  border: 1px solid var(--border-subtle);
  color: var(--accent-strong);
  display: flex;
  align-items: center;
  justify-content: center;
}

.beacon-ring.pulsing {
  background: var(--accent);
  color: #ffffff;
  animation: pulse-ring 2s infinite;
}

@keyframes pulse-ring {
  0% {
    box-shadow: 0 0 0 0 rgba(108, 92, 231, 0.6);
  }
  70% {
    box-shadow: 0 0 0 12px rgba(108, 92, 231, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(108, 92, 231, 0);
  }
}

.activity-texts {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

/* Anchor Circadian Box */
.anchor-circadian-box {
  padding: var(--space-6);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.anchor-circadian-box.warning-tone {
  border-color: rgba(244, 183, 64, 0.4);
  background: rgba(244, 183, 64, 0.08);
}

.circadian-header {
  display: flex;
  align-items: center;
  gap: var(--space-4);
}

.circadian-icon {
  color: var(--warning);
}

.circadian-title-wrap {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.circadian-heading {
  font-size: var(--text-xl);
  font-weight: 600;
  margin: 0;
}

.circadian-delay-badge {
  font-size: var(--text-sm);
  color: var(--warning);
  font-weight: 600;
}

.circadian-ontrack-badge {
  font-size: var(--text-sm);
  color: var(--success);
  font-weight: 500;
}

.circadian-alert {
  display: flex;
  align-items: flex-start;
  gap: var(--space-2);
  font-size: var(--text-md);
  color: var(--warning);
  line-height: 1.5;
  margin: 0;
  padding: var(--space-3) var(--space-4);
  background: rgba(244, 183, 64, 0.1);
  border-radius: var(--radius-md);
}

.circadian-ok {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-md);
  color: var(--success);
  margin: 0;
}

/* Recharge Banner */
.recharge-banner {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  padding: var(--space-6);
  background: var(--blue-soft);
  border: 1px solid rgba(59, 130, 246, 0.3);
  border-radius: var(--radius-lg);
}

.recharge-icon {
  color: var(--blue);
}

.recharge-texts {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

/* Content Blocks */
.content-block {
  padding: var(--space-6);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.block-header {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.header-icon {
  color: var(--accent-strong);
}

.block-title {
  font-size: var(--text-lg);
  font-weight: 600;
  margin: 0;
}

.notes-body p {
  font-size: var(--text-md);
  line-height: 1.6;
  color: var(--text-secondary);
  margin: 0;
}

.trajectory-card {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.phase-badge-large {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-md);
  font-weight: 500;
  color: var(--text-primary);
}

.phase-dot {
  width: 8px;
  height: 8px;
  border-radius: var(--radius-full);
  background: var(--accent);
}

.trajectory-hint {
  font-size: var(--text-sm);
  color: var(--text-tertiary);
  margin: 0;
}

/* Right Side Column Cards */
.side-card {
  padding: var(--space-5);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.card-title-row {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.card-title {
  font-size: var(--text-lg);
  font-weight: 600;
  margin: 0;
  flex-grow: 1;
}

.consistency-rate {
  font-size: var(--text-sm);
  font-weight: 700;
  color: var(--success);
  background: var(--success-soft);
  padding: 2px 8px;
  border-radius: var(--radius-full);
}

.matrix-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 6px;
}

.matrix-cell {
  aspect-ratio: 1;
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.matrix-cell.completed {
  background: var(--success-soft);
  border-color: var(--success);
}

.matrix-cell.completed .cell-inner {
  width: 8px;
  height: 8px;
  border-radius: var(--radius-full);
  background: var(--success);
}

.matrix-legend {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
}

.legend-dot {
  width: 8px;
  height: 8px;
  border-radius: 2px;
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
}

.legend-dot.completed {
  background: var(--success);
  border-color: var(--success);
}

/* Attributes List */
.attr-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  margin: 0;
}

.attr-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: var(--text-md);
}

.attr-term {
  color: var(--text-tertiary);
}

.attr-def {
  font-weight: 500;
  color: var(--text-primary);
  margin: 0;
}

.attr-def.prio-high {
  color: var(--danger);
}

.info-subcard {
  background: var(--surface-2);
}

.info-title-row {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--text-secondary);
}

.info-subtext {
  font-size: var(--text-sm);
  line-height: 1.5;
  color: var(--text-tertiary);
  margin: 0;
}

/* Footer Actions */
.dialog-footer-actions {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}

.delete-step-btn {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-md);
  color: var(--text-tertiary);
  background: transparent;
  border: 1px solid transparent;
  border-radius: var(--radius-md);
  padding: var(--space-2) var(--space-3);
  cursor: pointer;
  transition: all 0.15s ease;
}

.delete-step-btn:hover {
  color: var(--danger);
  background: var(--danger-soft);
  border-color: rgba(240, 90, 90, 0.2);
}

/* Edit Mode Styles */
.edit-step-btn {
  margin-left: auto;
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  padding: 5px 12px;
  border-radius: var(--radius-sm);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  color: var(--text-primary);
  font-size: var(--text-sm);
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
}

.edit-step-btn:hover {
  background: var(--surface-2);
  border-color: var(--border-default);
}

.edit-form-container {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
  padding: var(--space-6);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
}

.form-error-banner {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-4);
  border-radius: var(--radius-md);
  background: var(--danger-soft);
  color: var(--danger);
  border: 1px solid rgba(240, 90, 90, 0.2);
  font-size: var(--text-sm);
  font-weight: 500;
}

.edit-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-6);
}

@media (max-width: 768px) {
  .edit-grid {
    grid-template-columns: 1fr;
  }
}

.edit-col {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}
</style>
