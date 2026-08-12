<script setup lang="ts">
import LoginForm from '@/features/auth/components/LoginForm.vue'
</script>

<template>
  <div class="login-page">
    <div class="backdrop-glow" aria-hidden="true" />

    <main class="center">
      <header class="brand">
        <span class="brand-mark" aria-hidden="true">
          <svg width="22" height="22" viewBox="0 0 18 18" fill="none">
            <rect x="1" y="1" width="16" height="16" rx="4.5" stroke="currentColor" stroke-width="1.5" />
            <path d="M5 11.5h8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
            <circle cx="9" cy="7" r="1.6" fill="currentColor" />
          </svg>
        </span>
        <span class="brand-name">Productivity OS</span>
      </header>

      <div class="panel">
        <div class="panel-header">
          <h1 class="title">Welcome back</h1>
          <p class="subtitle">Sign in to your calm command center.</p>
        </div>
        <LoginForm />
      </div>

      <footer class="footer">
        <span>Preview build · mock authentication</span>
      </footer>
    </main>
  </div>
</template>

<style scoped>
.login-page {
  position: relative;
  display: grid;
  place-items: center;
  min-height: 100vh;
  padding: var(--space-6);
  overflow: hidden;
}

/* One restrained blue wash — the only gradient on the screen. */
.backdrop-glow {
  position: absolute;
  inset: 0;
  background: radial-gradient(
    640px 320px at 50% -10%,
    rgba(91, 141, 239, 0.08),
    transparent 70%
  );
  pointer-events: none;
}

.center {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 100%;
  max-width: 400px;
}

.brand {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-bottom: var(--space-8);
}

.brand-mark {
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  border-radius: var(--radius-lg);
  background: var(--accent-soft);
  color: var(--accent-strong);
}

.brand-name {
  font-size: var(--text-lg);
  font-weight: 600;
  letter-spacing: -0.01em;
}

.panel {
  width: 100%;
  padding: var(--space-8);
  background: var(--surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
}

.panel-header {
  margin-bottom: var(--space-6);
}

.title {
  font-size: var(--text-2xl);
  letter-spacing: -0.02em;
}

.subtitle {
  margin-top: var(--space-1);
  font-size: var(--text-md);
  color: var(--text-tertiary);
}

.footer {
  margin-top: var(--space-6);
  font-size: var(--text-xs);
  color: var(--text-disabled);
}
</style>
