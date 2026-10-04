import { addDays, startOfWeek } from "@/lib/dates";
import { circleIds } from "@/lib/selectors/recap";
import { checkInsBy } from "@/lib/selectors/habits";
import { windowStats } from "@/lib/selectors/stats";
import type { AppState, Challenge, CheckIn, ID, ISODate, User } from "@/lib/types";

/** First name, or "You" for the current user. */
export function firstName(state: AppState, id: ID): string {
  if (id === state.meId) return "You";
  return state.users[id]?.name.split(" ")[0] ?? "Someone";
}

/** My friends, minus anyone blocked, sorted by name. */
export function visibleFriends(state: AppState): User[] {
  const me = state.users[state.meId];
  return me.friendIds
    .filter((id) => !state.settings.blockedIds.includes(id))
    .map((id) => state.users[id])
    .filter((u): u is User => Boolean(u))
    .sort((a, b) => a.name.localeCompare(b.name));
}

export function isFriend(state: AppState, id: ID): boolean {
  return state.users[state.meId].friendIds.includes(id) && !state.settings.blockedIds.includes(id);
}

/** A friend's check-in is visible in the feed when its habit isn't private and they aren't blocked. */
export function visibleCheckIn(state: AppState, c: CheckIn): boolean {
  if (c.userId === state.meId || !isFriend(state, c.userId)) return false;
  const h = state.habits.find((x) => x.id === c.habitId);
  return Boolean(h && h.privacy !== "private");
}

export function challengeTotal(c: Challenge): number {
  return Object.values(c.contributions).reduce((a, b) => a + b, 0);
}

export const MILESTONES = [25, 50, 75, 100] as const;

/**
 * Week-so-far leaderboard framed positively: the top three get a podium, everyone else is
 * simply "on the board" (alphabetical, no numbers). Also surfaces the most improved person.
 */
export function weeklyBoard(state: AppState, today: ISODate) {
  const start = startOfWeek(today, state.settings.weekStart);
  const yesterday = addDays(today, -1);
  const rows = circleIds(state).map((userId) => {
    const s = windowStats(state, userId, start, yesterday < start ? start : yesterday);
    const prev = windowStats(state, userId, addDays(start, -7), addDays(start, -1));
    const completed = checkInsBy(state, userId, start, today).length;
    return { userId, rate: s.rate, completed, delta: s.scheduled ? s.rate - prev.rate : 0 };
  });
  const ranked = [...rows].filter((r) => r.completed > 0).sort((a, b) => b.completed - a.completed || b.rate - a.rate);
  const podium = ranked.slice(0, 3);
  const podiumIds = new Set(podium.map((p) => p.userId));
  const others = rows
    .filter((r) => !podiumIds.has(r.userId))
    .sort((a, b) => firstName(state, a.userId).localeCompare(firstName(state, b.userId)));
  const improved = [...rows].sort((a, b) => b.delta - a.delta)[0];
  return { podium, others, improved: improved && improved.delta > 0.05 ? improved : undefined, start };
}

export function dayLabel(date: ISODate, today: ISODate): string {
  if (date === today) return "Today";
  if (date === addDays(today, -1)) return "Yesterday";
  return new Date(`${date}T12:00:00`).toLocaleDateString("en-US", { weekday: "long" });
}
