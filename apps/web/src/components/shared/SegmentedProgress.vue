<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    /** 0–100 */
    value: number
    color?: string
    segments?: number
    label?: string
  }>(),
  { color: 'var(--accent)', segments: 20, label: 'Progress' },
)

const filled = computed(() =>
  Math.round((Math.min(Math.max(props.value, 0), 100) / 100) * props.segments),
)

const items = computed(() =>
  Array.from({ length: props.segments }, (_, i) => i < filled.value),
)
</script>

<template>
  <div
    class="seg-progress"
    role="progressbar"
    :aria-valuenow="value"
    aria-valuemin="0"
    aria-valuemax="100"
    :aria-label="label"
  >
    <span
      v-for="(on, i) in items"
      :key="i"
      class="seg"
      :style="on ? { background: color } : undefined"
    />
  </div>
</template>

<style scoped>
.seg-progress {
  display: flex;
  gap: 4px;
  width: 100%;
}

.seg {
  flex: 1;
  height: 10px;
  border-radius: 3px;
  background: var(--surface-3);
  transition: background-color var(--duration-fast) var(--ease-out);
}
</style>
