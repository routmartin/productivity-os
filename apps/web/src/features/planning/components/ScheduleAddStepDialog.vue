<script setup lang="ts">
import { computed, nextTick, ref, watch } from 'vue'
import {
  BedDouble,
  BookOpen,
  Brain,
  Check,
  Clock,
  Coffee,
  Droplets,
  Dumbbell,
  Moon,
  Plus,
  Smile,
  Sparkles,
  Sun,
  Target,
  Zap,
} from 'lucide-vue-next'

import UiButton from '@/components/ui/UiButton.vue'
import UiDialog from '@/components/ui/UiDialog.vue'
import { useScheduleStore } from '../scheduleStore'
import type { SchedulePhaseId } from '../types'

const props = withDefaults(
  defineProps<{
    open: boolean
    initialPhase?: string | null
  }>(),
  {
    initialPhase: 'morning',
  },
)

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'created', nodeId: string): void
}>()

const scheduleStore = useScheduleStore()

type StepType = 'habit' | 'task' | 'recharge'

const selectedPhase = ref<SchedulePhaseId>('morning')
const selectedType = ref<StepType>('habit')
const title = ref('')
const subtitle = ref('')
const timeSlot = ref('')
const durationMinutes = ref(30)
const selectedIcon = ref('water')
const titleError = ref<string | null>(null)
const titleInputRef = ref<HTMLInputElement | null>(null)
const isSubmitting = ref(false)
const submitError = ref<string | null>(null)

// Phase definitions
interface PhaseOption {
  id: SchedulePhaseId
  label: string
  timeRange: string
  icon: typeof Sun
}

const phases: PhaseOption[] = [
  { id: 'morning', label: 'Morning Activation', timeRange: '06:30 – 09:00', icon: Sun },
  { id: 'deep-focus', label: 'Deep Focus', timeRange: '09:00 – 12:30', icon: Brain },
  { id: 'afternoon', label: 'Afternoon Momentum', timeRange: '12:30 – 18:00', icon: Zap },
  { id: 'bedtime', label: 'Bedtime Sanctuary', timeRange: '21:00 – 22:30', icon: BedDouble },
]

// Step Types
interface TypeOption {
  id: StepType
  label: string
  description: string
  icon: typeof Target
}

const stepTypes: TypeOption[] = [
  {
    id: 'habit',
    label: 'Daily Habit',
    description: 'Circadian ritual or stacking habit',
    icon: Sparkles,
  },
  {
    id: 'task',
    label: 'Activity Block',
    description: 'Deep focus priority or work sprint',
    icon: Target,
  },
  {
    id: 'recharge',
    label: 'Recharge Break',
    description: 'Rest, nutrition or recovery pause',
    icon: Coffee,
  },
]

// Habit Icons
interface IconOption {
  id: string
  label: string
  component: typeof Droplets
  canonicalName: string
}

const habitIcons: IconOption[] = [
  { id: 'water', label: 'Water', component: Droplets, canonicalName: 'Droplets' },
  { id: 'dumbbell', label: 'Workout', component: Dumbbell, canonicalName: 'Dumbbell' },
  { id: 'book', label: 'Reading', component: BookOpen, canonicalName: 'BookOpen' },
  { id: 'coffee', label: 'Coffee/Tea', component: Coffee, canonicalName: 'Coffee' },
  { id: 'zap', label: 'Energy', component: Zap, canonicalName: 'Zap' },
  { id: 'moon', label: 'Sleep/Curfew', component: Moon, canonicalName: 'Moon' },
  { id: 'smile', label: 'Mindset', component: Smile, canonicalName: 'Smile' },
  { id: 'check', label: 'Ritual', component: Check, canonicalName: 'Check' },
]

const durationPresets = [15, 30, 45, 60, 90]

const titlePlaceholder = computed(() => {
  switch (selectedType.value) {
    case 'habit':
      return 'e.g. 500ml Mineral Water & Salts'
    case 'task':
      return 'e.g. Finish authentication architecture'
    case 'recharge':
    default:
      return 'e.g. Eye Rest & Outdoor Walk'
  }
})

function resetForm() {
  if (props.initialPhase) {
    const raw = props.initialPhase.toLowerCase()
    selectedPhase.value = raw === 'evening' ? 'bedtime' : (raw as SchedulePhaseId)
  } else {
    selectedPhase.value = 'morning'
  }
  selectedType.value = 'habit'
  title.value = ''
  subtitle.value = ''
  timeSlot.value = ''
  durationMinutes.value = 30
  selectedIcon.value = 'water'
  titleError.value = null
  submitError.value = null
  isSubmitting.value = false
}

watch(
  () => props.open,
  (isOpen) => {
    if (isOpen) {
      resetForm()
      nextTick(() => {
        titleInputRef.value?.focus()
      })
    }
  },
  { immediate: true },
)

watch(
  () => props.initialPhase,
  (newPhase) => {
    if (newPhase) {
      const raw = newPhase.toLowerCase()
      selectedPhase.value = raw === 'evening' ? 'bedtime' : (raw as SchedulePhaseId)
    }
  },
)

function onSelectType(type: StepType) {
  selectedType.value = type
  if (type === 'recharge' && durationMinutes.value > 60) {
    durationMinutes.value = 15
  } else if (type === 'task' && durationMinutes.value < 30) {
    durationMinutes.value = 60
  }
}

function handleClose() {
  emit('close')
}

async function handleSubmit() {
  const trimmed = title.value.trim()
  if (!trimmed) {
    titleError.value = 'Please enter a title for this step'
    titleInputRef.value?.focus()
    return
  }

  const iconItem = habitIcons.find((i) => i.id === selectedIcon.value)
  const canonicalIcon = iconItem ? iconItem.canonicalName : 'Droplets'

  isSubmitting.value = true
  submitError.value = null

  try {
    const createdNode = await scheduleStore.addStep({
      phaseId: selectedPhase.value,
      type: selectedType.value,
      title: trimmed,
      subtitle: subtitle.value.trim() || undefined,
      totalMinutes: selectedType.value === 'habit' ? 15 : durationMinutes.value,
      timeSlot: timeSlot.value.trim() || undefined,
      iconName: selectedType.value === 'habit' ? canonicalIcon : undefined,
    })

    emit('created', createdNode.id)
    emit('close')
  } catch (err) {
    submitError.value = err instanceof Error ? err.message : 'Failed to add step to schedule. Please try again.'
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <UiDialog
    :open="open"
    title="Add Step to Schedule"
    size="lg"
    @close="handleClose"
  >
    <form class="add-step-form" @submit.prevent="handleSubmit">
      <div v-if="submitError" class="submit-error-banner" role="alert">
        {{ submitError }}
      </div>
      <!-- 1. Phase Selector -->
      <div class="form-section">
        <label class="section-label">Schedule Phase</label>
        <div class="phase-selector-grid" role="radiogroup" aria-label="Select Schedule Phase">
          <button
            v-for="phase in phases"
            :key="phase.id"
            type="button"
            class="phase-option-card"
            :class="{ active: selectedPhase === phase.id }"
            role="radio"
            :aria-checked="selectedPhase === phase.id"
            @click="selectedPhase = phase.id"
          >
            <component :is="phase.icon" :size="16" class="phase-card-icon" />
            <div class="phase-card-text">
              <span class="phase-card-title">{{ phase.label }}</span>
              <span class="phase-card-time">{{ phase.timeRange }}</span>
            </div>
          </button>
        </div>
      </div>

      <!-- 2. Type Selector -->
      <div class="form-section">
        <label class="section-label">Step Type</label>
        <div class="type-selector-row" role="radiogroup" aria-label="Select Step Type">
          <button
            v-for="type in stepTypes"
            :key="type.id"
            type="button"
            class="type-option-btn"
            :class="{ active: selectedType === type.id }"
            role="radio"
            :aria-checked="selectedType === type.id"
            @click="onSelectType(type.id)"
          >
            <component :is="type.icon" :size="15" />
            <span>{{ type.label }}</span>
          </button>
        </div>
      </div>

      <!-- 3. Title Input -->
      <div class="form-section">
        <label class="section-label" for="step-title-input">
          Step Title <span class="required-star">*</span>
        </label>
        <input
          id="step-title-input"
          ref="titleInputRef"
          v-model="title"
          type="text"
          class="custom-input"
          :class="{ 'has-error': Boolean(titleError) }"
          :placeholder="titlePlaceholder"
          required
          aria-required="true"
          :aria-invalid="Boolean(titleError)"
          @input="titleError = null"
        />
        <span v-if="titleError" class="field-error-msg">{{ titleError }}</span>
      </div>

      <!-- 4. Habit Icon Selector (only for habits) -->
      <div v-if="selectedType === 'habit'" class="form-section">
        <label class="section-label">Ritual Icon</label>
        <div class="icon-selector-grid" role="radiogroup" aria-label="Select Ritual Icon">
          <button
            v-for="icon in habitIcons"
            :key="icon.id"
            type="button"
            class="icon-pick-btn"
            :class="{ active: selectedIcon === icon.id }"
            role="radio"
            :aria-checked="selectedIcon === icon.id"
            :title="icon.label"
            :aria-label="icon.label"
            @click="selectedIcon = icon.id"
          >
            <component :is="icon.component" :size="18" />
            <span class="icon-pick-label">{{ icon.label }}</span>
          </button>
        </div>
      </div>

      <!-- 5. Duration Selector (for Activity Block and Recharge Break) -->
      <div v-if="selectedType !== 'habit'" class="form-section">
        <label class="section-label">Duration</label>
        <div class="duration-chips-wrap">
          <button
            v-for="m in durationPresets"
            :key="m"
            type="button"
            class="duration-chip"
            :class="{ active: durationMinutes === m }"
            @click="durationMinutes = m"
          >
            {{ m }}m
          </button>
          <div class="custom-duration-input-wrap">
            <input
              v-model.number="durationMinutes"
              type="number"
              min="5"
              max="240"
              step="5"
              class="custom-number-input"
              aria-label="Custom duration in minutes"
            />
            <span class="unit-label">min</span>
          </div>
        </div>
      </div>

      <!-- 6. Optional Time Slot & Subtitle -->
      <div class="form-row-two-col">
        <div class="form-section col">
          <label class="section-label" for="step-time-input">
            Target Time Slot <span class="optional-hint">(optional)</span>
          </label>
          <div class="time-input-wrap">
            <Clock :size="14" class="time-field-icon" />
            <input
              id="step-time-input"
              v-model="timeSlot"
              type="text"
              class="custom-input with-icon"
              placeholder="e.g. 09:30"
            />
          </div>
        </div>

        <div class="form-section col">
          <label class="section-label" for="step-subtitle-input">
            Secondary Note <span class="optional-hint">(optional)</span>
          </label>
          <input
            id="step-subtitle-input"
            v-model="subtitle"
            type="text"
            class="custom-input"
            placeholder="e.g. Top 1 Priority or Protocol rule"
          />
        </div>
      </div>
    </form>

    <template #footer>
      <div class="dialog-action-bar">
        <UiButton
          variant="ghost"
          type="button"
          :disabled="isSubmitting"
          @click="handleClose"
        >
          Cancel
        </UiButton>
        <UiButton
          variant="primary"
          type="button"
          :loading="isSubmitting"
          :disabled="isSubmitting"
          @click="handleSubmit"
        >
          <Plus :size="15" />
          <span>{{ isSubmitting ? 'Adding...' : 'Add to Schedule' }}</span>
        </UiButton>
      </div>
    </template>
  </UiDialog>
</template>

<style scoped>
.add-step-form {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
  padding: var(--space-2) 0;
}

.submit-error-banner {
  padding: var(--space-3) var(--space-4);
  background: var(--danger-soft);
  border: 1px solid color-mix(in srgb, var(--danger) 30%, transparent);
  border-radius: var(--radius-md);
  color: var(--danger);
  font-size: var(--text-sm);
  font-weight: 500;
}

.form-section {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.section-label {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--text-secondary);
  display: flex;
  align-items: center;
  gap: var(--space-1);
}

.required-star {
  color: var(--danger);
}

.optional-hint {
  font-size: var(--text-xs);
  font-weight: 400;
  color: var(--text-tertiary);
}

/* Phase Selector */
.phase-selector-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: var(--space-2);
}

.phase-option-card {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  cursor: pointer;
  text-align: left;
  transition: all var(--duration-fast) var(--ease-out);
}

.phase-option-card:hover {
  border-color: var(--border-strong);
  background: var(--surface-3);
}

.phase-option-card.active {
  background: var(--accent-soft);
  border-color: var(--accent);
  box-shadow: 0 0 12px var(--accent-glow);
}

.phase-card-icon {
  color: var(--text-secondary);
  flex-shrink: 0;
}

.phase-option-card.active .phase-card-icon {
  color: var(--accent-strong);
}

.phase-card-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.phase-card-title {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.phase-card-time {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

/* Type Selector */
.type-selector-row {
  display: flex;
  gap: var(--space-2);
}

.type-option-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-3);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-secondary);
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

.type-option-btn:hover {
  background: var(--surface-3);
  color: var(--text-primary);
}

.type-option-btn.active {
  background: var(--accent);
  border-color: var(--accent-strong);
  color: var(--on-accent);
  font-weight: 600;
}

/* Custom Text Input */
.custom-input {
  width: 100%;
  padding: var(--space-3) var(--space-4);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  color: var(--text-primary);
  font-size: var(--text-md);
  font-family: inherit;
  outline: none;
  transition: border-color var(--duration-fast) var(--ease-out);
}

.custom-input:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px var(--accent-soft);
}

.custom-input.has-error {
  border-color: var(--danger);
}

.field-error-msg {
  font-size: var(--text-xs);
  color: var(--danger);
  margin-top: 2px;
}

/* Habit Icon Picker */
.icon-selector-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: var(--space-2);
}

.icon-pick-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: var(--space-1);
  padding: var(--space-2) var(--space-1);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  color: var(--text-secondary);
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

.icon-pick-btn:hover {
  background: var(--surface-3);
  color: var(--text-primary);
}

.icon-pick-btn.active {
  background: var(--accent-soft);
  border-color: var(--accent);
  color: var(--accent-strong);
}

.icon-pick-label {
  font-size: 11px;
  font-weight: 500;
}

/* Duration Presets */
.duration-chips-wrap {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.duration-chip {
  padding: var(--space-1) var(--space-3);
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-full);
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--text-secondary);
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

.duration-chip:hover {
  background: var(--surface-3);
  color: var(--text-primary);
}

.duration-chip.active {
  background: var(--accent-soft);
  border-color: var(--accent);
  color: var(--accent-strong);
}

.custom-duration-input-wrap {
  display: flex;
  align-items: center;
  gap: 4px;
  background: var(--surface-2);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  padding: 2px 8px;
}

.custom-number-input {
  width: 48px;
  background: transparent;
  border: none;
  color: var(--text-primary);
  font-size: var(--text-xs);
  font-weight: 600;
  outline: none;
  text-align: right;
}

.unit-label {
  font-size: var(--text-xs);
  color: var(--text-tertiary);
}

/* Two Column Row */
.form-row-two-col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-4);
}

.time-input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.time-field-icon {
  position: absolute;
  left: var(--space-3);
  color: var(--text-tertiary);
  pointer-events: none;
}

.custom-input.with-icon {
  padding-left: calc(var(--space-3) + 20px);
}

/* Action Bar in Footer */
.dialog-action-bar {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: var(--space-3);
  width: 100%;
}
</style>
