<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { AlertCircle, CheckCircle2, Smartphone, Loader2 } from 'lucide-vue-next'

import SurfaceCard from '@/components/shared/SurfaceCard.vue'
import UiButton from '@/components/ui/UiButton.vue'
import UiInput from '@/components/ui/UiInput.vue'

import { apiClient } from '@/lib/api/client'
import { useAuthStore } from '@/features/auth/store'
import TimezonePicker from '@/features/settings/components/TimezonePicker.vue'
import { useSettingsStore } from '@/features/settings/store'

/** Backend contract: passwords are at least 12 characters (no composition
 *  rules — user-management spec Rule 2). */
const MIN_PASSWORD_LENGTH = 12

const router = useRouter()
const auth = useAuthStore()
const settings = useSettingsStore()

// ——— QR Authentication ———

const qrChallenge = ref<string | null>(null)
const qrExpiresAt = ref<string | null>(null)
const isLoadingQr = ref(false)
const qrError = ref<string | null>(null)

async function generateQr() {
  isLoadingQr.value = true
  qrError.value = null
  try {
    const res = await apiClient.auth.createQrChallenge()
    qrChallenge.value = res.challenge
    qrExpiresAt.value = res.expiresAt
  } catch (err: any) {
    qrError.value = err.message || 'Failed to generate QR code.'
  } finally {
    isLoadingQr.value = false
  }
}

const qrUrl = computed(() => {
  if (!qrChallenge.value) return ''
  return `productivityos://auth?challenge=${qrChallenge.value}`
})

const qrImageUrl = computed(() => {
  if (!qrUrl.value) return ''
  return `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(qrUrl.value)}`
})

// ——— Profile / timezone ———

const timezone = ref(auth.user?.timezone ?? 'UTC')
const timezoneSaved = ref(false)

watch(
  () => auth.user?.timezone,
  (value) => {
    if (value) timezone.value = value
  },
)

const timezoneDirty = computed(
  () => timezone.value !== (auth.user?.timezone ?? 'UTC'),
)
const timezoneSaveEnabled = computed(
  () => timezoneDirty.value && !settings.isSavingTimezone,
)

let saveNoteTimer: ReturnType<typeof setTimeout> | undefined

function onTimezoneSaved() {
  timezoneSaved.value = true
  clearTimeout(saveNoteTimer)
  saveNoteTimer = setTimeout(() => (timezoneSaved.value = false), 3000)
}

async function saveTimezone() {
  if (!timezoneSaveEnabled.value) return
  const ok = await settings.changeTimezone(timezone.value)
  if (ok) onTimezoneSaved()
}

// ——— Password ———

const passwordForm = reactive({
  current: '',
  next: '',
  confirm: '',
})

const passwordTouched = reactive({
  current: false,
  next: false,
  confirm: false,
})

const currentError = computed(() => {
  if (!passwordTouched.current) return null
  return passwordForm.current ? null : 'Enter your current password.'
})

const newError = computed(() => {
  if (!passwordTouched.next) return null
  if (!passwordForm.next) return 'Enter a new password.'
  if (passwordForm.next.length < MIN_PASSWORD_LENGTH) {
    return 'Your new password must be at least 12 characters.'
  }
  return null
})

const confirmError = computed(() => {
  if (!passwordTouched.confirm) return null
  if (!passwordForm.confirm) return 'Confirm your new password.'
  if (passwordForm.confirm !== passwordForm.next) {
    return "Passwords don't match."
  }
  return null
})

const passwordValid = computed(
  () =>
    passwordForm.current.length > 0 &&
    passwordForm.next.length >= MIN_PASSWORD_LENGTH &&
    passwordForm.confirm === passwordForm.next,
)

async function savePassword() {
  passwordTouched.current = true
  passwordTouched.next = true
  passwordTouched.confirm = true
  if (!passwordValid.value || settings.isSavingPassword) return

  const ok = await settings.changePassword(
    passwordForm.current,
    passwordForm.next,
  )
  if (ok) {
    await router.push({ name: 'login', query: { password_changed: '1' } })
  }
}
</script>

<template>
  <div class="settings-page">
    <header class="page-header">
      <h1 class="title">Settings</h1>
      <p class="subtitle">Your account and workspace preferences.</p>
    </header>

    <SurfaceCard title="Profile">
      <div class="profile-grid">
        <UiInput :model-value="auth.user?.email ?? ''" label="Email" disabled />

        <div class="tz-field">
          <span class="tz-label">Timezone</span>
          <TimezonePicker
            v-model="timezone"
            :disabled="settings.isSavingTimezone"
            :error="settings.timezoneError"
          />
          <p class="tz-hint">
            Days, Top 3, and schedules follow this timezone going forward.
          </p>
        </div>
      </div>

      <div class="form-footer">
        <Transition name="fade">
          <span v-if="timezoneSaved" class="saved-note" role="status">
            <CheckCircle2 :size="14" :stroke-width="2" />
            Timezone updated.
          </span>
        </Transition>
        <UiButton
          variant="primary"
          :disabled="!timezoneSaveEnabled"
          :loading="settings.isSavingTimezone"
          @click="saveTimezone"
        >
          Save timezone
        </UiButton>
      </div>
    </SurfaceCard>

    <SurfaceCard title="Connect iPhone">
      <div class="qr-section">
        <div v-if="!qrChallenge && !isLoadingQr" class="qr-placeholder">
          <Smartphone :size="48" class="icon" />
          <p>Securely connect your iPhone to your Productivity OS account.</p>
          <UiButton variant="primary" @click="generateQr">
            Generate Login QR
          </UiButton>
        </div>

        <div v-else-if="isLoadingQr" class="qr-loading">
          <Loader2 :size="32" class="spin" />
          <p>Generating secure challenge...</p>
        </div>

        <div v-else-if="qrChallenge" class="qr-display">
          <div class="qr-code-wrapper">
            <img :src="qrImageUrl" alt="Authentication QR Code" class="qr-image" />
          </div>
          <div class="qr-info">
            <h3>Scan with Productivity OS</h3>
            <p>Open the app on your iPhone and tap <strong>Scan QR</strong>.</p>
            <p class="expiry-note">Expires in 2 minutes.</p>
            <UiButton variant="secondary" size="sm" @click="generateQr">
              Refresh QR
            </UiButton>
          </div>
        </div>

        <div v-if="qrError" class="qr-error">
          <AlertCircle :size="16" />
          <span>{{ qrError }}</span>
        </div>
      </div>
    </SurfaceCard>

    <SurfaceCard title="Password">
      <form class="password-form" novalidate @submit.prevent="savePassword">
        <Transition name="fade">
          <div v-if="settings.passwordError" class="form-error" role="alert">
            <AlertCircle :size="15" :stroke-width="1.75" />
            <span>{{ settings.passwordError }}</span>
          </div>
        </Transition>

        <UiInput
          v-model="passwordForm.current"
          label="Current password"
          type="password"
          autocomplete="current-password"
          :error="currentError"
          :disabled="settings.isSavingPassword"
          @blur="passwordTouched.current = true"
        />

        <div class="field-row">
          <UiInput
            v-model="passwordForm.next"
            label="New password"
            type="password"
            autocomplete="new-password"
            :error="newError"
            :disabled="settings.isSavingPassword"
            @blur="passwordTouched.next = true"
          />
          <UiInput
            v-model="passwordForm.confirm"
            label="Confirm new password"
            type="password"
            autocomplete="new-password"
            :error="confirmError"
            :disabled="settings.isSavingPassword"
            @blur="passwordTouched.confirm = true"
          />
        </div>

        <div class="form-footer">
          <p class="pw-note">
            At least 12 characters. Changing your password signs you out
            everywhere.
          </p>
          <UiButton
            type="submit"
            variant="primary"
            :disabled="!passwordValid"
            :loading="settings.isSavingPassword"
          >
            Update password
          </UiButton>
        </div>
      </form>
    </SurfaceCard>
  </div>
</template>

<style scoped>
.settings-page {
  max-width: 720px;
  margin: 0 auto;
  padding: var(--space-8) var(--space-10) var(--space-16);
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.page-header {
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

.profile-grid {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.tz-field {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.tz-label {
  font-size: var(--text-sm);
  font-weight:500;
  color: var(--text-secondary);
}

.tz-hint {
  font-size: var(--text-xs);
  color: var(--text-disabled);
}

.password-form {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.field-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
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

.form-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  margin-top: var(--space-2);
}

.saved-note {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--success);
}

.pw-note {
  font-size: var(--text-xs);
  color: var(--text-disabled);
  max-width: 360px;
}

.qr-section {
  padding: var(--space-4) 0;
}

.qr-placeholder, .qr-loading, .qr-display {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: var(--space-4);
}

.qr-placeholder .icon {
  color: var(--text-tertiary);
  margin-bottom: var(--space-2);
}

.qr-placeholder p {
  color: var(--text-secondary);
  max-width: 300px;
}

.qr-loading {
  color: var(--text-tertiary);
  padding: var(--space-8) 0;
}

.spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.qr-code-wrapper {
  padding: var(--space-4);
  background: white;
  border-radius: var(--radius-lg);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.qr-image {
  display: block;
}

.qr-info h3 {
  font-size: var(--text-lg);
  font-weight: 600;
  margin-bottom: var(--space-1);
}

.qr-info p {
  font-size: var(--text-sm);
  color: var(--text-secondary);
}

.expiry-note {
  font-size: var(--text-xs) !important;
  color: var(--text-disabled) !important;
  margin-top: var(--space-2);
  margin-bottom: var(--space-4);
}

.qr-error {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-top: var(--space-4);
  color: var(--danger);
  font-size: var(--text-sm);
  justify-content: center;
}

@media (max-width: 640px) {
  .field-row {
    grid-template-columns: 1fr;
  }
}
</style>
