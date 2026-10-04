import { CATEGORY_META } from "@/lib/data/catalog";
import type { HabitDraft } from "@/lib/store/actions";
import type { ClockTime, FrequencyPreset, HabitCategory, IllustrationKey, ISODate, TimeOfDay } from "@/lib/types";

/** The quick-create form only offers the presets, not "custom". */
export type QuickFrequency = Exclude<FrequencyPreset, "custom">;

export const FREQUENCY_OPTIONS: { value: QuickFrequency; label: string; detail: string; days: number[]; timesPerWeek: number }[] = [
  { value: "daily", label: "Every day", detail: "7 days", days: [0, 1, 2, 3, 4, 5, 6], timesPerWeek: 7 },
  { value: "weekdays", label: "Weekdays", detail: "Mon–Fri", days: [1, 2, 3, 4, 5], timesPerWeek: 5 },
  { value: "weekends", label: "Weekends", detail: "Sat & Sun", days: [0, 6], timesPerWeek: 2 },
  { value: "three-per-week", label: "3× a week", detail: "Any 3 days", days: [1, 3, 5], timesPerWeek: 3 },
];

export const TIME_OPTIONS: { value: TimeOfDay; label: string; reminder: ClockTime }[] = [
  { value: "morning", label: "Morning", reminder: "08:00" },
  { value: "afternoon", label: "Afternoon", reminder: "13:00" },
  { value: "evening", label: "Evening", reminder: "20:00" },
  { value: "anytime", label: "Anytime", reminder: "12:00" },
];

/** A small, friendly icon set for the first habit. */
export const QUICK_ICONS: IllustrationKey[] = ["shoe", "water", "book", "moon", "pencil", "flower", "dumbbell", "fruit", "leaf", "bike", "coffee", "phone"];

const ICON_CATEGORY: Partial<Record<IllustrationKey, HabitCategory>> = {
  shoe: "movement",
  dumbbell: "movement",
  bike: "movement",
  water: "hydration",
  book: "study",
  pencil: "creative",
  music: "creative",
  moon: "sleep",
  alarm: "sleep",
  flower: "mind",
  sun: "mind",
  heart: "mind",
  phone: "mind",
  fruit: "nourish",
  leaf: "outdoors",
  coffee: "home",
};

export function categoryForIcon(icon: IllustrationKey): HabitCategory {
  return ICON_CATEGORY[icon] ?? "mind";
}

/** Turns catalog copy like "Weekdays · evening" or "3× per week" into form values. */
export function parseSchedule(schedule: string): { frequency: QuickFrequency; timeOfDay: TimeOfDay } {
  const s = schedule.toLowerCase();
  const frequency: QuickFrequency = s.includes("3×") || s.includes("3x") ? "three-per-week" : s.startsWith("weekdays") ? "weekdays" : s.startsWith("weekends") ? "weekends" : "daily";
  const timeOfDay: TimeOfDay = s.includes("morning") ? "morning" : s.includes("afternoon") ? "afternoon" : s.includes("evening") ? "evening" : "anytime";
  return { frequency, timeOfDay };
}

export function defaultReminder(timeOfDay: TimeOfDay): ClockTime {
  return TIME_OPTIONS.find((t) => t.value === timeOfDay)?.reminder ?? "09:00";
}

export interface QuickHabitInput {
  name: string;
  icon: IllustrationKey;
  frequency: QuickFrequency;
  timeOfDay: TimeOfDay;
  remindersOn: boolean;
  reminderTime: ClockTime;
}

/** Fills a complete HabitDraft with sensible defaults from the quick form. */
export function buildHabitDraft(input: QuickHabitInput, today: ISODate): HabitDraft {
  const category = categoryForIcon(input.icon);
  const freq = FREQUENCY_OPTIONS.find((f) => f.value === input.frequency) ?? FREQUENCY_OPTIONS[0];
  return {
    name: input.name.trim(),
    description: "",
    icon: input.icon,
    category,
    tint: CATEGORY_META[category].tint,
    frequency: freq.value,
    days: freq.days,
    timesPerWeek: freq.timesPerWeek,
    timeOfDay: input.timeOfDay,
    remindersOn: input.remindersOn,
    reminderTimes: input.remindersOn ? [input.reminderTime] : [],
    shared: false,
    participantIds: [],
    proof: "optional",
    notesEnabled: true,
    showStreak: true,
    privacy: "friends",
    startDate: today,
    optional: false,
  };
}
