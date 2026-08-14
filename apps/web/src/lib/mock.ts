/**
 * Global mock-data switch (spec Rule 8, AC-010).
 *
 * Every feature defaults to the REAL API. Mock mode is opt-in, in
 * priority order:
 *
 *   1. VITE_USE_MOCK_DATA=true  — global: mocks EVERY feature at once
 *   2. VITE_USE_MOCK_{FEATURE}=true — per-feature override on top of
 *      the global (e.g. VITE_USE_MOCK_TASKS, VITE_USE_MOCK_AUTH)
 *
 * Design-review flows:
 *   make web-mock  → VITE_USE_MOCK_DATA=true  (everything mocked)
 *   make preview   → nothing set             (everything real, e2e)
 */

export const USE_MOCK_DATA =
  import.meta.env.VITE_USE_MOCK_DATA === "true";

/** Mock flag for one feature: global switch OR the per-feature override. */
export function useMock(feature: string): boolean {
  return USE_MOCK_DATA || import.meta.env[`VITE_USE_MOCK_${feature}`] === "true";
}
