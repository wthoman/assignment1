import type { ISODate, TimeOfDay } from "./types";

const pad = (n: number) => String(n).padStart(2, "0");

export function toISODate(d: Date): ISODate {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

/** Parses YYYY-MM-DD as a local date at noon (avoids DST edge cases). */
export function fromISODate(iso: ISODate): Date {
  const [y, m, d] = iso.split("-").map(Number);
  return new Date(y, m - 1, d, 12);
}

export function todayISO(): ISODate {
  return toISODate(new Date());
}

export function addDays(iso: ISODate, n: number): ISODate {
  const d = fromISODate(iso);
  d.setDate(d.getDate() + n);
  return toISODate(d);
}

export function diffDays(a: ISODate, b: ISODate): number {
  return Math.round((fromISODate(a).getTime() - fromISODate(b).getTime()) / 86_400_000);
}

export function weekday(iso: ISODate): number {
  return fromISODate(iso).getDay();
}

/** Start of the week containing `iso`; weekStart 0 = Sunday, 1 = Monday. */
export function startOfWeek(iso: ISODate, weekStart: 0 | 1 = 1): ISODate {
  const wd = weekday(iso);
  const offset = (wd - weekStart + 7) % 7;
  return addDays(iso, -offset);
}

export function weekDates(iso: ISODate, weekStart: 0 | 1 = 1): ISODate[] {
  const start = startOfWeek(iso, weekStart);
  return Array.from({ length: 7 }, (_, i) => addDays(start, i));
}

export function rangeDates(from: ISODate, to: ISODate): ISODate[] {
  const out: ISODate[] = [];
  for (let d = from; d <= to; d = addDays(d, 1)) out.push(d);
  return out;
}

export function monthGrid(year: number, month: number, weekStart: 0 | 1 = 1): (ISODate | null)[] {
  const first = new Date(year, month, 1, 12);
  const days = new Date(year, month + 1, 0).getDate();
  const lead = (first.getDay() - weekStart + 7) % 7;
  const cells: (ISODate | null)[] = Array(lead).fill(null);
  for (let i = 1; i <= days; i++) cells.push(toISODate(new Date(year, month, i, 12)));
  while (cells.length % 7) cells.push(null);
  return cells;
}

export const WEEKDAY_SHORT = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
export const WEEKDAY_LETTER = ["S", "M", "T", "W", "T", "F", "S"];
export const WEEKDAY_LONG = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

export function orderedWeekdays(weekStart: 0 | 1): number[] {
  return Array.from({ length: 7 }, (_, i) => (i + weekStart) % 7);
}

export function formatDate(iso: ISODate, opts: Intl.DateTimeFormatOptions = { month: "short", day: "numeric" }) {
  return fromISODate(iso).toLocaleDateString("en-US", opts);
}

export function formatLongDate(iso: ISODate) {
  return formatDate(iso, { weekday: "long", month: "long", day: "numeric" });
}

export function formatTime(hhmm: string) {
  const [h, m] = hhmm.split(":").map(Number);
  const suffix = h >= 12 ? "pm" : "am";
  const hr = h % 12 === 0 ? 12 : h % 12;
  return m === 0 ? `${hr}${suffix}` : `${hr}:${pad(m)}${suffix}`;
}

export function nowClock(): string {
  const d = new Date();
  return `${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export function timeOfDayFor(hhmm: string): Exclude<TimeOfDay, "anytime"> {
  const h = Number(hhmm.split(":")[0]);
  if (h < 12) return "morning";
  if (h < 17) return "afternoon";
  return "evening";
}

export function greeting(date = new Date()): string {
  const h = date.getHours();
  if (h < 5) return "Up late";
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  if (h < 22) return "Good evening";
  return "Winding down";
}

/** "just now", "12m", "3h", "Tue", "Sep 14" */
export function relativeTime(ts: string, now = new Date()): string {
  const then = new Date(ts);
  const mins = Math.round((now.getTime() - then.getTime()) / 60_000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.round(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.round(hrs / 24);
  if (days < 7) return then.toLocaleDateString("en-US", { weekday: "short" });
  return then.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

/** Builds an ISO timestamp from a date + clock time in local time. */
export function stamp(iso: ISODate, hhmm: string): string {
  const [h, m] = hhmm.split(":").map(Number);
  const d = fromISODate(iso);
  d.setHours(h, m, 0, 0);
  return d.toISOString();
}
