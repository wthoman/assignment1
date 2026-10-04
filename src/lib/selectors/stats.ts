import { addDays, rangeDates, startOfWeek, timeOfDayFor, weekday, WEEKDAY_LONG } from "../dates";
import type { AppState, Habit, ID, ISODate } from "../types";
import { checkInsBy, habitsFor, isComeback, isDone, isScheduled } from "./habits";

export interface WindowStats {
  scheduled: number;
  completed: number;
  /** Completions of optional habits; they never hurt the score. */
  bonus: number;
  rate: number;
}

/** Scheduled vs completed for required habits in [from, to]. */
export function windowStats(state: AppState, userId: ID, from: ISODate, to: ISODate, habitFilter?: (h: Habit) => boolean): WindowStats {
  let scheduled = 0;
  let completed = 0;
  let bonus = 0;
  const habits = habitsFor(state, userId, { includeInactive: true }).filter((h) => h.status !== "archived" && (!habitFilter || habitFilter(h)));
  for (const d of rangeDates(from, to)) {
    for (const h of habits) {
      if (!isScheduled(h, d)) continue;
      if (h.status === "paused" && !isDone(state, h.id, userId, d)) continue;
      const done = isDone(state, h.id, userId, d);
      if (h.optional) {
        if (done) bonus++;
        continue;
      }
      scheduled++;
      if (done) completed++;
    }
  }
  return { scheduled, completed, bonus, rate: scheduled ? completed / scheduled : 0 };
}

export const CONSISTENCY_WINDOW = 28;
/** One forgiven miss per seven days in the window. */
export const GRACE_PER_WEEK = 1;

export interface ConsistencyScore {
  score: number;
  completed: number;
  scheduled: number;
  grace: number;
  windowDays: number;
}

/**
 * Forgiving rolling score: (completed + grace) / scheduled over the last 28 days,
 * where grace = up to one missed day per week. A single miss never drops the score.
 */
export function consistencyScore(state: AppState, userId: ID, today: ISODate, windowDays = CONSISTENCY_WINDOW): ConsistencyScore {
  const from = addDays(today, -(windowDays - 1));
  // Today counts only once it's done, so an unfinished morning doesn't drag the score.
  const past = windowStats(state, userId, from, addDays(today, -1));
  const todayStats = windowStats(state, userId, today, today);
  const completed = past.completed + todayStats.completed;
  const scheduled = past.scheduled + todayStats.completed;
  const misses = scheduled - completed;
  const grace = Math.min(misses, Math.floor(windowDays / 7) * GRACE_PER_WEEK);
  const score = scheduled ? Math.min(100, Math.round(((completed + grace) / scheduled) * 100)) : 0;
  return { score, completed, scheduled, grace, windowDays };
}

export interface WeekSummary {
  start: ISODate;
  end: ISODate;
  stats: WindowStats;
  perDay: { date: ISODate; done: number; scheduled: number }[];
}

export function weekSummary(state: AppState, userId: ID, anyDayInWeek: ISODate, weekStart: 0 | 1): WeekSummary {
  const start = startOfWeek(anyDayInWeek, weekStart);
  const end = addDays(start, 6);
  const perDay = rangeDates(start, end).map((date) => {
    const s = windowStats(state, userId, date, date);
    return { date, done: s.completed + s.bonus, scheduled: s.scheduled };
  });
  return { start, end, stats: windowStats(state, userId, start, end), perDay };
}

/** Four rolling weekly rates, oldest first, ending with the week containing `today`. */
export function rollingWeeks(state: AppState, userId: ID, today: ISODate, weeks = 4) {
  return Array.from({ length: weeks }, (_, i) => {
    const to = addDays(today, -7 * (weeks - 1 - i));
    const from = addDays(to, -6);
    const s = windowStats(state, userId, from, i === weeks - 1 ? addDays(today, -1) : to);
    return { from, to, rate: s.rate, completed: s.completed, scheduled: s.scheduled };
  });
}

export function totalCompletions(state: AppState, userId: ID): number {
  return state.checkIns.reduce((n, c) => n + (c.userId === userId ? 1 : 0), 0);
}

export function comebackCount(state: AppState, userId: ID, from?: ISODate, to?: ISODate): number {
  return checkInsBy(state, userId, from, to).filter((c) => isComeback(state, c)).length;
}

export function strongestWeekday(state: AppState, userId: ID, from: ISODate, to: ISODate) {
  const counts = Array(7).fill(0) as number[];
  const sched = Array(7).fill(0) as number[];
  for (const d of rangeDates(from, to)) {
    const s = windowStats(state, userId, d, d);
    counts[weekday(d)] += s.completed;
    sched[weekday(d)] += s.scheduled;
  }
  const rates = counts.map((c, i) => (sched[i] ? c / sched[i] : 0));
  let best = 0;
  rates.forEach((r, i) => {
    if (r > rates[best]) best = i;
  });
  return { day: best, name: WEEKDAY_LONG[best], rate: rates[best], rates };
}

export function timeOfDayPattern(state: AppState, userId: ID, from?: ISODate, to?: ISODate) {
  const buckets = { morning: 0, afternoon: 0, evening: 0, late: 0 };
  for (const c of checkInsBy(state, userId, from, to)) {
    const h = Number(c.time.split(":")[0]);
    if (h >= 22) buckets.late++;
    else buckets[timeOfDayFor(c.time)]++;
  }
  const total = Object.values(buckets).reduce((a, b) => a + b, 0) || 1;
  const top = (Object.entries(buckets) as [keyof typeof buckets, number][]).sort((a, b) => b[1] - a[1])[0][0];
  return { buckets, total, top };
}

export function habitRate(state: AppState, h: Habit, userId: ID, from: ISODate, to: ISODate) {
  let scheduled = 0;
  let done = 0;
  for (const d of rangeDates(from < h.startDate ? h.startDate : from, to)) {
    if (!isScheduled(h, d)) continue;
    scheduled++;
    if (isDone(state, h.id, userId, d)) done++;
  }
  return { scheduled, done, rate: scheduled ? done / scheduled : 0 };
}

export function pct(n: number) {
  return `${Math.round(n * 100)}%`;
}
