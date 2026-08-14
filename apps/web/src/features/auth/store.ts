import { defineStore } from "pinia";
import { computed, ref } from "vue";

import { ApiError } from "@/lib/api/client";
import { clearSession, loadSession, saveSession } from "@/lib/auth/session";

import { authApi } from "./api";
import type { UserProfile } from "./types";

export const useAuthStore = defineStore("auth", () => {
  const user = ref<UserProfile | null>(null);
  const accessToken = ref<string | null>(null);
  const isSubmitting = ref(false);
  const loginError = ref<string | null>(null);
  const registerError = ref<string | null>(null);
  const restored = ref(false);

  const isAuthenticated = computed(
    () => accessToken.value !== null && user.value !== null,
  );

  /** Restore a persisted session. Called once by the router guard. */
  function restore(): void {
    if (restored.value) return;
    const session = loadSession();
    if (session) {
      accessToken.value = session.accessToken;
      user.value = session.user;
    }
    restored.value = true;
  }

  async function login(email: string, password: string): Promise<boolean> {
    isSubmitting.value = true;
    loginError.value = null;
    try {
      const response = await authApi.login({ email, password });
      if (!response.user) {
        loginError.value = "Unexpected response from the server.";
        return false;
      }
      accessToken.value = response.accessToken;
      user.value = response.user;
      saveSession({ accessToken: response.accessToken, user: response.user });
      return true;
    } catch (error) {
      loginError.value =
        error instanceof ApiError
          ? error.message
          : "Something went wrong. Please try again.";
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /** Create an account, then sign in immediately (the register endpoint
   *  returns no token — only the created profile). */
  async function register(email: string, password: string): Promise<boolean> {
    isSubmitting.value = true;
    registerError.value = null;
    try {
      await authApi.register({ email, password });
      return await login(email, password);
    } catch (error) {
      registerError.value =
        error instanceof ApiError
          ? error.message
          : "Something went wrong. Please try again.";
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  async function logout(): Promise<void> {
    try {
      await authApi.logout();
    } catch {
      // Logging out locally must succeed even if the server call fails.
    }
    accessToken.value = null;
    user.value = null;
    clearSession();
  }

  return {
    user,
    accessToken,
    isSubmitting,
    loginError,
    registerError,
    isAuthenticated,
    restore,
    login,
    register,
    logout,
  };
});
