<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { AlertCircle } from 'lucide-vue-next'

import UiButton from '@/components/ui/UiButton.vue'
import UiInput from '@/components/ui/UiInput.vue'

import { useAuthStore } from '../store'

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

const auth = useAuthStore()
const router = useRouter()
const route = useRoute()

const form = reactive({
  email: '',
  password: '',
})

const touched = reactive({
  email: false,
  password: false,
})

const emailError = computed(() => {
  if (!touched.email) return null
  if (!form.email.trim()) return 'Email is required.'
  if (!EMAIL_PATTERN.test(form.email.trim())) return 'Enter a valid email address.'
  return null
})

const passwordError = computed(() => {
  if (!touched.password) return null
  if (!form.password) return 'Password is required.'
  if (form.password.length < 8) return 'Passwords are at least 8 characters.'
  return null
})

const isValid = computed(
  () =>
    EMAIL_PATTERN.test(form.email.trim()) && form.password.length >= 8,
)

/** Registration link — the screen ships later; for the preview we explain
 * the mock sign-in instead of pretending a register flow exists. */
const registerNoteVisible = ref(false)

async function onSubmit() {
  touched.email = true
  touched.password = true
  if (!isValid.value || auth.isSubmitting) return

  const ok = await auth.login(form.email.trim(), form.password)
  if (ok) {
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/today'
    router.push(redirect)
  }
}
</script>

<template>
  <form class="login-form" novalidate @submit.prevent="onSubmit">
    <Transition name="fade">
      <div v-if="auth.loginError" class="form-error" role="alert">
        <AlertCircle :size="15" :stroke-width="1.75" />
        <span>{{ auth.loginError }}</span>
      </div>
    </Transition>

    <UiInput
      v-model="form.email"
      label="Email"
      type="email"
      placeholder="you@example.com"
      autocomplete="email"
      :error="emailError"
      :disabled="auth.isSubmitting"
      @blur="touched.email = true"
    />

    <UiInput
      v-model="form.password"
      label="Password"
      type="password"
      placeholder="Your password"
      autocomplete="current-password"
      :error="passwordError"
      :disabled="auth.isSubmitting"
      @blur="touched.password = true"
    />

    <UiButton
      type="submit"
      variant="primary"
      size="lg"
      full-width
      :loading="auth.isSubmitting"
      :disabled="!isValid"
      class="submit"
    >
      Sign in
    </UiButton>

    <p class="register">
      New to Productivity OS?
      <button class="register-link" type="button" @click="registerNoteVisible = !registerNoteVisible">
        Create an account
      </button>
    </p>

    <Transition name="fade">
      <p v-if="registerNoteVisible" class="register-note" role="status">
        Self-serve registration ships with a later milestone. For this preview, sign in with any
        email and a password of 8+ characters.
      </p>
    </Transition>
  </form>
</template>

<style scoped>
.login-form {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.form-error {
  display: flex;
  align-items: flex-start;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-4);
  border: 1px solid rgba(242, 112, 122, 0.3);
  border-radius: var(--radius-md);
  background: var(--danger-soft);
  color: var(--danger);
  font-size: var(--text-sm);
}

.form-error svg {
  flex-shrink: 0;
  margin-top: 2px;
}

.submit {
  margin-top: var(--space-2);
}

.register {
  text-align: center;
  font-size: var(--text-sm);
  color: var(--text-tertiary);
}

.register-link {
  color: var(--accent);
  font-size: inherit;
  font-weight: 500;
  margin-left: var(--space-1);
  transition: color var(--duration-fast) var(--ease-out);
}

.register-link:hover {
  color: var(--accent-strong);
}

.register-note {
  font-size: var(--text-xs);
  line-height: 1.5;
  color: var(--text-tertiary);
  text-align: center;
  padding: var(--space-3);
  border-radius: var(--radius-md);
  background: var(--surface-2);
}
</style>
