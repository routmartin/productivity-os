<script setup lang="ts">
withDefaults(
  defineProps<{
    width?: string
    height?: string
    rounded?: 'sm' | 'md' | 'lg' | 'full'
  }>(),
  { width: '100%', height: '14px', rounded: 'sm' },
)
</script>

<template>
  <div
    class="skeleton"
    :class="`rounded-${rounded}`"
    :style="{ width, height }"
    aria-hidden="true"
  />
</template>

<style scoped>
.skeleton {
  background: linear-gradient(
    100deg,
    var(--surface-2) 40%,
    var(--surface-3) 50%,
    var(--surface-2) 60%
  );
  background-size: 200% 100%;
  animation: shimmer 1.6s var(--ease-out) infinite;
}

.rounded-sm {
  border-radius: var(--radius-sm);
}

.rounded-md {
  border-radius: var(--radius-md);
}

.rounded-lg {
  border-radius: var(--radius-lg);
}

.rounded-full {
  border-radius: var(--radius-full);
}

@keyframes shimmer {
  from {
    background-position: 120% 0;
  }
  to {
    background-position: -80% 0;
  }
}

@media (prefers-reduced-motion: reduce) {
  .skeleton {
    animation: none;
  }
}
</style>
