/**
 * Centralized date and time formatting.
 *
 * Per ADR-006 the backend is the authority for instants and attributed
 * dates; the client renders wall-clock values in the user's configured
 * IANA timezone (from their profile). Everything goes through `Intl` —
 * no hand-rolled timezone arithmetic.
 */

const LOCALE = "en-US";

function hourInZone(date: Date, timeZone?: string): number {
  const parts = new Intl.DateTimeFormat(LOCALE, {
    hour: "numeric",
    hourCycle: "h23",
    timeZone,
  }).formatToParts(date);
  return Number(parts.find((p) => p.type === "hour")?.value ?? date.getHours());
}

/** "Wednesday, August 12" */
export function formatLongDate(date: Date, timeZone?: string): string {
  return new Intl.DateTimeFormat(LOCALE, {
    weekday: "long",
    month: "long",
    day: "numeric",
    timeZone,
  }).format(date);
}

/** "Aug 12" */
export function formatShortDate(date: Date, timeZone?: string): string {
  return new Intl.DateTimeFormat(LOCALE, {
    month: "short",
    day: "numeric",
    timeZone,
  }).format(date);
}

/** "August 2026" */
export function formatMonthYear(date: Date, timeZone?: string): string {
  return new Intl.DateTimeFormat(LOCALE, {
    month: "long",
    year: "numeric",
    timeZone,
  }).format(date);
}

/** "Mon" / "Tue" … for calendar headers (starting Monday). */
export const WEEKDAY_LABELS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

/** Time-of-day greeting, evaluated in the user's timezone. */
export function greetingFor(date: Date, timeZone?: string): string {
  const hour = hourInZone(date, timeZone);
  if (hour < 5) return "Working late";
  if (hour < 12) return "Good morning";
  if (hour < 18) return "Good afternoon";
  return "Good evening";
}

/** Compact relative time: "just now", "12m ago", "3h ago", "Yesterday", "4d ago". */
export function relativeTime(
  isoInstant: string,
  now: Date = new Date(),
): string {
  const then = new Date(isoInstant);
  const diffMs = now.getTime() - then.getTime();
  if (Number.isNaN(diffMs)) return "";

  const minutes = Math.floor(diffMs / 60_000);
  if (minutes < 1) return "just now";
  if (minutes < 60) return `${minutes}m ago`;

  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  if (hours < 48) return "Yesterday";

  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d ago`;

  return formatShortDate(then);
}

/** ISO calendar date (YYYY-MM-DD) for an ISO instant, in the user's timezone. */
export function toISODate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

/** Display name from an email local part: "martin.dev" → "Martin". */
export function firstNameFromEmail(email: string): string {
  const local = email.split("@")[0] ?? "";
  const first = local.split(/[._-]/).find(Boolean) ?? "";
  if (!first) return "there";
  return first.charAt(0).toUpperCase() + first.slice(1);
}
