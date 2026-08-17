import { defineStore } from "pinia";
import { computed, ref } from "vue";

import { useAuthStore } from "@/features/auth/store";
import { errorMessage } from "@/lib/api/errorMessages";

import { settingsApi } from "./api";

export type SaveStatus = "idle" | "saving" | "error";

/**
 * Settings state for the Account Settings page.
 *
 * The auth store owns the session profile (single source of truth); this
 * store owns only the per-form submit/error state and mutates the profile
 * through the auth store on a successful timezone change (AC-001/AC-009).
 */
export const useSettingsStore = defineStore("settings", () => {
  const auth = useAuthStore();

  const timezoneStatus = ref<SaveStatus>("idle");
  const passwordStatus = ref<SaveStatus>("idle");
  const timezoneError = ref<string | null>(null);
  const passwordError = ref<string | null>(null);

  const isSavingTimezone = computed(() => timezoneStatus.value === "saving");
  const isSavingPassword = computed(() => passwordStatus.value === "saving");

  function clearError(): void {
    timezoneError.value = null;
    passwordError.value = null;
  }

  /** Save a new timezone. On success the shared session profile is updated
   *  (and persisted) so Today and date bucketing follow the new zone. */
  async function changeTimezone(timezone: string): Promise<boolean> {
    timezoneStatus.value = "saving";
    timezoneError.value = null;
    try {
      const response = await settingsApi.changeTimezone({ timezone });
      auth.setTimezone(response.timezone);
      timezoneStatus.value = "idle";
      return true;
    } catch (error) {
      timezoneError.value = errorMessage(error);
      timezoneStatus.value = "error";
      return false;
    }
  }

  /** Change the password. On success the session ends immediately (spec
   *  Rule 3: the server revoked all refresh tokens, so no silent refresh
   *  is attempted); the caller redirects to login. */
  async function changePassword(
    currentPassword: string,
    newPassword: string,
  ): Promise<boolean> {
    passwordStatus.value = "saving";
    passwordError.value = null;
    try {
      await settingsApi.changePassword({ currentPassword, newPassword });
      auth.endSession();
      passwordStatus.value = "idle";
      return true;
    } catch (error) {
      passwordError.value = errorMessage(error);
      passwordStatus.value = "error";
      return false;
    }
  }

  return {
    timezoneStatus,
    passwordStatus,
    timezoneError,
    passwordError,
    isSavingTimezone,
    isSavingPassword,
    changeTimezone,
    changePassword,
    clearError,
  };
});
