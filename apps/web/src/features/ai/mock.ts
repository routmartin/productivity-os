/**
 * Mock AI content for Milestone 1, aligned with the approved visual
 * reference. Purple is reserved for these surfaces. The product boundary
 * (system.md): AI recommends, the user decides — nothing here mutates
 * user data.
 */
import type { LucideIcon } from "lucide-vue-next";
import { Clock3, Hourglass, Scale } from "lucide-vue-next";

export interface Briefing {
  assistantName: string;
  isNew: boolean;
  recommendation: string;
  /** Task the recommendation suggests rescheduling. */
  suggestionTaskId: string;
  suggestionTaskTitle: string;
  /** Shown when "View details" is expanded. */
  rationale: string;
}

export interface Insight {
  id: string;
  title: string;
  text: string;
  icon: LucideIcon;
  tone: "ai" | "warning" | "info";
}

export const mockBriefing: Briefing = {
  assistantName: "AI Briefing",
  isNew: true,
  recommendation:
    "You have more planned work than available focus time today. Consider moving “Write documentation” to tomorrow.",
  suggestionTaskId: "task-05",
  suggestionTaskTitle: "Write documentation",
  rationale:
    "Nova compared today’s planned estimates (9h) with your remaining focus capacity (about 6h 12m) and picked the lowest-priority task that isn’t due today.",
};

export const mockInsights: Insight[] = [
  {
    id: "insight-focus-time",
    title: "Focus Time Available",
    text: "You have 6.2h of focus time available today.",
    icon: Hourglass,
    tone: "ai",
  },
  {
    id: "insight-task-balance",
    title: "Task Balance",
    text: "Your planned tasks are 45% over your focus capacity.",
    icon: Scale,
    tone: "warning",
  },
  {
    id: "insight-focus-window",
    title: "Best Focus Window",
    text: "You’re most productive between 9AM – 12PM.",
    icon: Clock3,
    tone: "info",
  },
];
