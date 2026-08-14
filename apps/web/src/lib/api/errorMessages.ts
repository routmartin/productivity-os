/**
 * User-facing error message resolution (spec: api-integration.md
 * AC-009, Rule 4). The backend's structured errors carry a safe
 * `message` (ADR-005); network failures map to NETWORK_ERROR.
 * Known codes map to a friendly string; everything else falls back
 * to the server's message.
 */

import { ApiError } from "./client";

const CODE_MESSAGES: Record<string, string> = {
  NETWORK_ERROR: "Could not reach the server. Check your connection and try again.",
  CONFLICT: "That change wasn't allowed. Check the current state and try again.",
  VALIDATION_ERROR: "Some fields are invalid. Review them and try again.",
  INVALID_TIMEZONE: "That timezone isn't valid.",
  NOT_FOUND: "That item no longer exists.",
  INTERNAL_ERROR: "Something went wrong on the server. Please try again.",
};

/** Resolve any thrown value to a safe, user-facing message. */
export function errorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    return CODE_MESSAGES[error.code] ?? error.message;
  }
  return "Something went wrong. Please try again.";
}
