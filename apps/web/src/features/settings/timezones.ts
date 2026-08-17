/**
 * IANA timezone list for the Settings picker (spec Resolved Question 2).
 *
 * The full list comes from `Intl.supportedValuesOf('timeZone')` — browser
 * native, always current, no bundled list. The browser-detected local zone
 * is pinned first, a short "common" group follows, then the full list
 * grouped by region, each entry showing its current UTC offset. Browsers
 * without `supportedValuesOf` fall back to a small static list.
 */

export interface TimezoneOption {
  /** IANA identifier, e.g. "Asia/Phnom_Penh". */
  id: string;
  /** Human-readable city portion, e.g. "Phnom Penh". */
  city: string;
  /** First IANA segment, e.g. "Asia". */
  region: string;
  /** Current UTC offset, e.g. "UTC+07:00" (empty when unknown). */
  offset: string;
}

export interface TimezoneGroup {
  label: string;
  zones: TimezoneOption[];
}

/** A short, curated list surfaced above the full regional list. */
const COMMON_ZONE_IDS = [
  "UTC",
  "America/Los_Angeles",
  "America/Denver",
  "America/Chicago",
  "America/New_York",
  "Europe/London",
  "Europe/Paris",
  "Europe/Berlin",
  "Europe/Madrid",
  "Asia/Dubai",
  "Asia/Kolkata",
  "Asia/Singapore",
  "Asia/Hong_Kong",
  "Asia/Tokyo",
  "Australia/Sydney",
];

/** Static fallback when `Intl.supportedValuesOf` is unavailable. */
const FALLBACK_ZONE_IDS = [
  ...COMMON_ZONE_IDS,
  "America/Sao_Paulo",
  "Africa/Cairo",
  "Africa/Johannesburg",
  "Asia/Phnom_Penh",
  "Asia/Bangkok",
  "Asia/Seoul",
  "Pacific/Auckland",
];

/** The device's own timezone, e.g. "Asia/Phnom_Penh". */
export function detectLocalTimeZone(): string {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
  } catch {
    return "UTC";
  }
}

function cityLabel(id: string): string {
  const parts = id.split("/");
  const region = parts[0] ?? id;
  const rest = parts.slice(1).join("/");
  return (rest || region).replace(/_/g, " ");
}

function regionLabel(id: string): string {
  return (id.split("/")[0] ?? id).replace(/_/g, " ");
}

/** Current UTC offset for a zone, e.g. "UTC+07:00" (or "" when unknown). */
export function offsetFor(id: string, date: Date = new Date()): string {
  try {
    const part = new Intl.DateTimeFormat("en-US", {
      timeZone: id,
      timeZoneName: "longOffset",
    })
      .formatToParts(date)
      .find((p) => p.type === "timeZoneName");
    return (part?.value ?? "").replace("GMT", "UTC");
  } catch {
    return "";
  }
}

/** Label + offset for the current selection, independent of the group list. */
export function describeTimezone(id: string): { label: string; offset: string } {
  return { label: cityLabel(id), offset: offsetFor(id) };
}

function toOption(id: string, date: Date): TimezoneOption {
  return {
    id,
    city: cityLabel(id),
    region: regionLabel(id),
    offset: offsetFor(id, date),
  };
}

function supportedTimezones(): string[] {
  const intl = Intl as unknown as {
    supportedValuesOf?: (key: string) => string[];
  };
  if (typeof intl.supportedValuesOf === "function") {
    try {
      const list = intl.supportedValuesOf("timeZone");
      if (Array.isArray(list) && list.length > 0) return list;
    } catch {
      // Fall through to the static fallback.
    }
  }
  return FALLBACK_ZONE_IDS;
}

/** Grouped options: "Your timezone", "Common", then regions (A–Z). */
export function buildTimezoneGroups(): TimezoneGroup[] {
  const date = new Date();
  const ids = supportedTimezones();
  const localId = detectLocalTimeZone();

  const groups: TimezoneGroup[] = [
    { label: "Your timezone", zones: [toOption(localId, date)] },
  ];

  const common = COMMON_ZONE_IDS.filter((id) => ids.includes(id)).map((id) =>
    toOption(id, date),
  );
  groups.push({ label: "Common", zones: common });

  const excluded = new Set([localId, ...COMMON_ZONE_IDS]);
  const byRegion = new Map<string, TimezoneOption[]>();
  for (const id of ids) {
    if (excluded.has(id)) continue;
    const option = toOption(id, date);
    const list = byRegion.get(option.region) ?? [];
    list.push(option);
    byRegion.set(option.region, list);
  }

  const regions = [...byRegion.entries()]
    .map(([region, zones]) => ({
      label: region,
      zones: zones.sort((a, b) => a.city.localeCompare(b.city)),
    }))
    .sort((a, b) => a.label.localeCompare(b.label));

  groups.push(...regions);
  return groups;
}
