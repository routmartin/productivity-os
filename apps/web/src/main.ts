import "@fontsource-variable/inter";
import "@/styles/tokens.css";
import "@/styles/base.css";

import { createPinia } from "pinia";
import { createApp } from "vue";

import App from "@/App.vue";
import { router } from "@/app/router";
import { setTokenProvider } from "@/lib/api/client";
import { loadSession } from "@/lib/auth/session";

// The API client reads the access token from the persisted session, so the
// real Bearer flow (ADR-004) works the moment the mock adapter is disabled.
setTokenProvider(() => loadSession()?.accessToken ?? null);

const app = createApp(App);

app.use(createPinia());
app.use(router);

app.mount("#app");
