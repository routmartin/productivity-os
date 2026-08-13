import { ref } from "vue";

/**
 * Theme state — Dark is the default (the approved visual reference is dark);
 * Light Calm is kept as an alternate. Persisted to localStorage; applied as
 * [data-theme] on <html>. The inline script in index.html applies the saved
 * theme before first paint.
 */

export type Theme = "light" | "dark";

const STORAGE_KEY = "productivity-os.theme";

function readInitial(): Theme {
  try {
    return localStorage.getItem(STORAGE_KEY) === "light" ? "light" : "dark";
  } catch {
    return "dark";
  }
}

export const theme = ref<Theme>(readInitial());

export function setTheme(next: Theme): void {
  theme.value = next;
  document.documentElement.dataset.theme = next;
  try {
    localStorage.setItem(STORAGE_KEY, next);
  } catch {
    // Private mode etc. — theme just won't persist.
  }
}

export function toggleTheme(): void {
  setTheme(theme.value === "light" ? "dark" : "light");
}
