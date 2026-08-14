/**
 * Shared API contract types (ADR-005).
 *
 * The structured error body is the only error contract; `Page<T>` matches
 * Spring Data's paginated response for collection endpoints that opt into
 * pagination. Note: some V1 list endpoints (e.g. tasks, focus sessions)
 * return plain arrays — feature API modules declare the actual shape.
 */

/** Structured error body returned by the backend for every error. */
export interface ApiErrorResponse {
  /** Stable machine-readable identifier, e.g. TOP3_FULL. */
  code: string;
  /** Human-readable explanation safe to show to the user. */
  message: string;
  /** Optional structured context, e.g. field-level validation failures. */
  details?: Record<string, unknown>;
  /** Correlation identifier for support and log lookup. */
  traceId?: string;
}

/** Spring Data page response for paginated collection endpoints. */
export interface Page<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
}

export function isPage<T>(value: unknown): value is Page<T> {
  if (typeof value !== "object" || value === null) return false;
  const candidate = value as Partial<Page<T>>;
  return (
    Array.isArray(candidate.content) &&
    typeof candidate.page === "number" &&
    typeof candidate.size === "number" &&
    typeof candidate.totalElements === "number" &&
    typeof candidate.totalPages === "number"
  );
}
