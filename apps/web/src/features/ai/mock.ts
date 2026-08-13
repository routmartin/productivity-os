/**
 * Mock AI content, aligned with the approved visual reference. Purple is
 * reserved for these surfaces. The product boundary (system.md): AI
 * recommends, the user decides — nothing here mutates user data.
 */

/** Today hero briefing — one strong insight and one primary action. */
export interface Briefing {
  /** Headline count: "You have {focusCount} important things…". */
  focusCount: number;
  subline: string;
  ctaLabel: string;
}

export const mockBriefing: Briefing = {
  focusCount: 3,
  subline: "Based on your tasks, goals, and recent progress.",
  ctaLabel: "Plan My Day",
};

/** Small ambient tip at the bottom of the Today right rail. */
export interface FocusTip {
  title: string;
  body: string;
}

export const mockFocusTip: FocusTip = {
  title: "Focus Tip",
  body: "Turn off notifications and stay in the zone.",
};
