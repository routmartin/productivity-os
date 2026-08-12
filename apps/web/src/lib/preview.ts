import { ref } from "vue";

/**
 * Milestone 1–2 UI runs on mock data. Controls that would normally call
 * the API use this tiny shared note to say so honestly, instead of
 * pretending a mutation happened.
 */

export const previewMessage = ref<string | null>(null);

let timer: ReturnType<typeof setTimeout> | undefined;

export function showPreviewNote(message: string): void {
  previewMessage.value = message;
  clearTimeout(timer);
  timer = setTimeout(() => (previewMessage.value = null), 3000);
}
