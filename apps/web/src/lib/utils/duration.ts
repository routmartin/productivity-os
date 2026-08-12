/** Duration formatting shared by tasks, plans, and focus surfaces. */

/** 45 → "45m", 90 → "1h 30m", 120 → "2h" */
export function formatMinutes(minutes: number): string {
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  const rest = minutes % 60;
  return rest === 0 ? `${hours}h` : `${hours}h ${rest}m`;
}
