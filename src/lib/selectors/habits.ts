import { addDays, rangeDates, startOfWeek, weekday } from "../dates";
import type { AppState, CheckIn, Habit, ID, ISODate, TimeOfDay } from "../types";

export function isScheduled(h: Habit, date: ISODate): boolean {
  if (date < h.startDate) return false;
  if (h.targetDate && date > h.targetDate) return false;
  return h.days.includes(weekday(date));
}

export function habitsFor(state: AppState, userId: ID, opts: { includeInactive?: boolean } = {}): Habit[] {
  return state.habits.filter(
    (h) => h.participantIds.includes(userId) && (opts.includeInactive || h.status === "active"),
  );
}

export function myHabits(state: AppState, opts?: { includeInactive?: boolean }) {
  return habitsFor(state, state.meId, opts);
}

export function habitById(state: AppState, id: ID): Habit | undefined {
  return state.habits.find((h) => h.id === id);
}

/** Index of check-ins keyed by `${habitId}|${userId}|${date}` for O(1) lookups. */
export function indexCheckIns(checkIns: CheckIn[]): Map<string, CheckIn> {
  const m = new Map<string, CheckIn>();
  for (const c of checkIns) m.set(`${c.habitId}|${c.userId}|${c.date}`, c);
  return m;
}

const indexCache = new WeakMap<CheckIn[], Map<string, CheckIn>>();
function cachedIndex(checkIns: CheckIn[]) {
  let idx = indexCache.get(checkIns);
  if (!idx) {
    idx = indexCheckIns(checkIns);
    indexCache.set(checkIns, idx);
  }
  return idx;
}

export function checkInFor(state: AppState, habitId: ID, userId: ID, date: ISODate): CheckIn | undefined {
  return cachedIndex(state.checkIns).get(`${habitId}|${userId}|${date}`);
}

export function isDone(state: AppState, habitId: ID, userId: ID, date: ISODate) {
  return cachedIndex(state.checkIns).has(`${habitId}|${userId}|${date}`);
}

export type TodaySection = "up-next" | "shared" | "completed" | "optional";

export interface TodayEntry {
  habit: Habit;
  section: TodaySection;
  checkIn?: CheckIn;
}

const TIME_ORDER: Record<TimeOfDay, number> = { morning: 0, afternoon: 1, anytime: 2, evening: 3 };

/** Habits relevant to a date, sorted into the four Today sections. */
export function todayEntries(state: AppState, date: ISODate): TodayEntry[] {
  const me = state.meId;
  const entries: TodayEntry[] = [];
  for (const h of myHabits(state)) {
    if (!isScheduled(h, date)) continue;
    const ci = checkInFor(state, h.id, me, date);
    const section: TodaySection = ci ? "completed" : h.optional ? "optional" : h.shared ? "shared" : "up-next";
    entries.push({ habit: h, section, checkIn: ci });
  }
  return entries.sort((a, b) => TIME_ORDER[a.habit.timeOfDay] - TIME_ORDER[b.habit.timeOfDay]);
}

export interface DayProgress {
  done: number;
  total: number;
  bonus: number;
  ratio: number;
}

/** Required (non-optional) habits for the day; optional completions count as bonus. */
export function dayProgress(state: AppState, userId: ID, date: ISODate): DayProgress {
  let done = 0;
  let total = 0;
  let bonus = 0;
  for (const h of habitsFor(state, userId)) {
    if (!isScheduled(h, date)) continue;
    const d = isDone(state, h.id, userId, date);
    if (h.optional) {
      if (d) bonus++;
      continue;
    }
    total++;
    if (d) done++;
  }
  return { done, total, bonus, ratio: total ? done / total : 0 };
}

/** Week-row dots for a habit: one entry per day in the week. */
export function habitWeek(state: AppState, h: Habit, userId: ID, anchor: ISODate, weekStart: 0 | 1) {
  const start = startOfWeek(anchor, weekStart);
  return Array.from({ length: 7 }, (_, i) => {
    const date = addDays(start, i);
    return {
      date,
      scheduled: isScheduled(h, date),
      done: isDone(state, h.id, userId, date),
    };
  });
}

/** Completions this week for "N× per week" habits. */
export function weekCount(state: AppState, h: Habit, userId: ID, anchor: ISODate, weekStart: 0 | 1) {
  const start = startOfWeek(anchor, weekStart);
  return rangeDates(start, addDays(start, 6)).filter((d) => isDone(state, h.id, userId, d)).length;
}

/** Consecutive scheduled days completed, ending today (or yesterday if today is still open). */
export function currentStreak(state: AppState, h: Habit, userId: ID, today: ISODate): number {
  let streak = 0;
  let d = today;
  if (!isDone(state, h.id, userId, d)) d = addDays(d, -1);
  for (let guard = 0; guard < 400 && d >= h.startDate; guard++, d = addDays(d, -1)) {
    if (!isScheduled(h, d)) continue;
    if (!isDone(state, h.id, userId, d)) break;
    streak++;
  }
  return streak;
}

export function bestStreak(state: AppState, h: Habit, userId: ID, today: ISODate): number {
  let best = 0;
  let run = 0;
  for (const d of rangeDates(h.startDate, today)) {
    if (!isScheduled(h, d)) continue;
    if (isDone(state, h.id, userId, d)) {
      run++;
      best = Math.max(best, run);
    } else if (d !== today) run = 0;
  }
  return best;
}

/** Number of missed scheduled days immediately before `date` (stops at the previous completion). */
export function missedBefore(state: AppState, h: Habit, userId: ID, date: ISODate): { missed: number; hadPrior: boolean } {
  let missed = 0;
  let d = addDays(date, -1);
  for (let guard = 0; guard < 120 && d >= h.startDate; guard++, d = addDays(d, -1)) {
    if (!isScheduled(h, d)) continue;
    if (isDone(state, h.id, userId, d)) return { missed, hadPrior: true };
    missed++;
  }
  return { missed, hadPrior: false };
}

/** A comeback is a check-in after 2+ consecutive missed scheduled days. */
export function isComeback(state: AppState, c: CheckIn): boolean {
  const h = habitById(state, c.habitId);
  if (!h) return false;
  const { missed, hadPrior } = missedBefore(state, h, c.userId, c.date);
  return hadPrior && missed >= 2;
}

export function checkInsBy(state: AppState, userId: ID, from?: ISODate, to?: ISODate): CheckIn[] {
  return state.checkIns.filter((c) => c.userId === userId && (!from || c.date >= from) && (!to || c.date <= to));
}

export const FREQUENCY_LABEL: Record<Habit["frequency"], string> = {
  daily: "Every day",
  weekdays: "Weekdays",
  weekends: "Weekends",
  "three-per-week": "3× a week",
  custom: "Custom days",
};

export const TIME_LABEL: Record<TimeOfDay, string> = {
  morning: "Morning",
  afternoon: "Afternoon",
  evening: "Evening",
  anytime: "Anytime",
};

export function scheduleLabel(h: Habit): string {
  if (h.frequency === "custom") {
    const names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return h.days.map((d) => names[d]).join(", ");
  }
  if (h.frequency === "three-per-week") return `${h.timesPerWeek}× a week`;
  return FREQUENCY_LABEL[h.frequency];
}
