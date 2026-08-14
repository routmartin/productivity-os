<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { AlertCircle } from 'lucide-vue-next'

import UiButton from '@/components/ui/UiButton.vue'
import UiInput from '@/components/ui/UiInput.vue'

import { useAuthStore } from '../store'

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
/** Backend contract: passwords are at least 12 characters (no composition
 *  rules, no forced rotation — user-management spec Rule 2). */
const MIN_PASSWORD_LENGTH = 12

const auth = useAuthStore()
const router = useRouter()
const route = useRoute()

const mode = ref<'login' | 'register'>('login')

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
  if (mode.value === 'login') {
    if (form.password.length < 8) return 'Passwords are at least 8 characters.'
  } else if (form.password.length < MIN_PASSWORD_LENGTH) {
    return 'Passwords are at least 12 characters.'
  }
  return null
})

const isValid = computed(() => {
  if (!EMAIL_PATTERN.test(form.email.trim()) || form.password.length === 0) return false
  return mode.value === 'login'
    ? form.password.length >= 8
    : form.password.length >= MIN_PASSWORD_LENGTH
})

const heading = computed(() =>
  mode.value === 'login' ? 'Welcome back' : 'Create your account',
)

const subtitle = computed(() =>
  mode.value === 'login'
    ? 'Sign in to your calm command center.'
    : 'Start your calm command center.',
)

const formError = computed(() =>
  mode.value === 'login' ? auth.loginError : auth.registerError,
)

function switchMode() {
  mode.value = mode.value === 'login' ? 'register' : 'login'
  auth.loginError = null
  auth.registerError = null
  touched.email = false
  touched.password = false
}

async function onSubmit() {
  touched.email = true
  touched.password = true
  if (!isValid.value || auth.isSubmitting) return

  const ok =
    mode.value === 'login'
      ? await auth.login(form.email.trim(), form.password)
      : await auth.register(form.email.trim(), form.password)
  if (ok) {
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/today'
    router.push(redirect)
  }
}
</script>

<template>
  <form class="login-form" novalidate @submit.prevent="onSubmit">
    <div class="panel-header">
      <h1 class="title">{{ heading }}</h1>
      <p class="subtitle">{{ subtitle }}</p>
    </div>

    <Transition name="fade">
      <div v-if="formError" class="form-error" role="alert">
        <AlertCircle :size="15" :stroke-width="1.75" />
        <span>{{ formError }}</span>
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
      :autocomplete="mode === 'login' ? 'current-password' : 'new-password'"
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
      {{ mode === 'login' ? 'Sign in' : 'Create account' }}
    </UiButton>

    <p class="register">
      <template v-if="mode === 'login'">
        New to Productivity OS?
        <button class="register-link" type="button" @click="switchMode">
          Create an account
        </button>
      </template>
      <template v-else>
        Already have an account?
        <button class="register-link" type="button" @click="switchMode">
          Sign in
        </button>
      </template>
    </p>
  </form>
</template>

<style scoped>
.login-form {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
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
</style>
