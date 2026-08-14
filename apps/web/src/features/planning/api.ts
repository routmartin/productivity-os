/**
 * Planning API module — Daily Top 3 + Daily Plan (spec:
 * docs/specs/api-integration.md, plan 002 Step 6). Real endpoints only;
 * the today store keeps the mock switch (`VITE_USE_MOCK_PLANNING=true`)
 * and its milestone seed data.
 *
 * All calls go through the shared apiClient: Bearer token, silent
 * refresh, structured ApiError (ADR-005).
 *
 * "Today" dates are computed in the signed-in user's IANA timezone
 * (ADR-006) — the client never sends UTC dates.
 */

import { apiClient } from "@/lib/api/client";
import { useAuthStore } from "@/features/auth/store";
import { toISODateInZone } from "@/lib/utils/date";

import type {
  CapacityInfo,
  DailyPlanResponse,
  PlanTaskRequest,
  ReorderRequest,
  SelectTaskRequest,
  SetCapacityRequest,
  TopThreeResponse,
} from "./api-types";

/** YYYY-MM-DD for "today" in the user's profile timezone (fallback:
 *  device-local). Backend path variables must be calendar dates. */
export function todayISODate(): string {
  const auth = useAuthStore();
  return toISODateInZone(new Date(), auth.user?.timezone ?? undefined);
}

const BASE = "/daily-top-three";
const PLAN_BASE = "/daily-plan";

/* ------------------------- Daily Top 3 ------------------------- */

async function topThree(date: string): Promise<TopThreeResponse[]> {
  return apiClient.get<TopThreeResponse[]>(`${BASE}/${date}`);
}

/** Select a task (position optional — first free slot). */
async function select(
  date: string,
  request: SelectTaskRequest,
): Promise<TopThreeResponse> {
  return apiClient.post<TopThreeResponse>(`${BASE}/${date}`, request);
}

/** Move a selection; returns the full re-packed list. */
async function reorder(
  date: string,
  selectionId: string,
  request: ReorderRequest,
): Promise<TopThreeResponse[]> {
  return apiClient.put<TopThreeResponse[]>(
    `${BASE}/${date}/${selectionId}/position`,
    request,
  );
}

/** Remove a selection; returns the full re-packed list. */
async function remove(
  date: string,
  selectionId: string,
): Promise<TopThreeResponse[]> {
  return apiClient.delete<TopThreeResponse[]>(
    `${BASE}/${date}/${selectionId}`,
  );
}

/* ------------------------- Daily Plan ------------------------- */

async function dailyPlan(date: string): Promise<DailyPlanResponse[]> {
  return apiClient.get<DailyPlanResponse[]>(`${PLAN_BASE}/${date}`);
}

/** Plan a task for a date (remark optional). */
async function planTask(
  date: string,
  request: PlanTaskRequest,
): Promise<DailyPlanResponse> {
  return apiClient.post<DailyPlanResponse>(`${PLAN_BASE}/${date}`, request);
}

async function removePlan(date: string, planId: string): Promise<void> {
  await apiClient.delete<void>(`${PLAN_BASE}/${date}/${planId}`);
}

/** Set the daily focus capacity in hours. */
async function setCapacity(
  date: string,
  request: SetCapacityRequest,
): Promise<void> {
  await apiClient.put<void>(`${PLAN_BASE}/capacity/${date}`, request);
}

/** Today's capacity + planned hours (defaults to 6h when unset). */
async function capacity(date: string): Promise<CapacityInfo> {
  return apiClient.get<CapacityInfo>(`${PLAN_BASE}/${date}/capacity`);
}

export const planningApi = {
  topThree,
  select,
  reorder,
  remove,
  dailyPlan,
  planTask,
  removePlan,
  setCapacity,
  capacity,
};
