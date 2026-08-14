import "@fontsource-variable/inter";
import "@/styles/tokens.css";
import "@/styles/base.css";

import { createPinia } from "pinia";
import { createApp } from "vue";

import App from "@/App.vue";
import { router } from "@/app/router";
import { setSessionHandlers, setTokenProvider } from "@/lib/api/client";
import { clearSession, loadSession, saveSession } from "@/lib/auth/session";

// The API client reads the access token from the persisted session, so the
// real Bearer flow (ADR-004) works the moment the mock adapter is disabled.
setTokenProvider(() => loadSession()?.accessToken ?? null);

// Silent refresh wiring (docs/specs/api-integration.md AC-006/AC-007):
// a refreshed token replaces the persisted one (user profile is kept — the
// refresh response carries no user); an expired/revoked refresh token ends
// the session and returns to the login screen.
setSessionHandlers({
  onRefreshed(accessToken) {
    const session = loadSession();
    if (session) {
      saveSession({ ...session, accessToken });
    }
  },
  onSessionExpired() {
    clearSession();
    if (router.currentRoute.value.name !== "login") {
      void router.push({ name: "login" });
    }
  },
});

const app = createApp(App);

app.use(createPinia());
app.use(router);

app.mount("#app");
