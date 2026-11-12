/**
 * Detects whether an event target is an interactive typing element.
 * Prevents single-key shortcuts from hijacking text input in forms,
 * textareas, selects, or rich text / contenteditable regions (AC-002).
 */
export function isTypingTarget(target: EventTarget | null): boolean {
  if (!(target instanceof HTMLElement)) return false;
  const tag = target.tagName.toUpperCase();
  return (
    tag === "INPUT" ||
    tag === "TEXTAREA" ||
    tag === "SELECT" ||
    target.isContentEditable ||
    Boolean(target.closest('[contenteditable="true"]'))
  );
}

/**
 * Checks if a keydown event corresponds to the global task creation shortcut ('c' / 'C').
 * Disallows modifier keys (Cmd, Ctrl, Alt) to preserve system/browser shortcuts
 * like clipboard copy (Cmd+C / Ctrl+C) and window accelerators (AC-001, AC-003, D2).
 * Ignores IME composition sessions.
 */
export function isTaskCreationKey(event: KeyboardEvent): boolean {
  if (event.isComposing) return false;
  if (event.metaKey || event.ctrlKey || event.altKey) return false;
  const key = event.key.toLowerCase();
  return key === "c" || key === "n";
}
