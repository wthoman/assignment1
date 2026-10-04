import { addDays, formatTime, startOfWeek, weekday, WEEKDAY_LONG } from "../dates";
import type { AppState, Habit, ID, ISODate, Superlative, SuperlativeSource } from "../types";
import { checkInsBy, habitsFor, isComeback } from "./habits";
import { habitRate, strongestWeekday, windowStats } from "./stats";

/** The week a recap describes: the most recent fully finished week. */
export function recapWeek(today: ISODate, weekStart: 0 | 1) {
  const start = addDays(startOfWeek(today, weekStart), -7);
  return { start, end: addDays(start, 6) };
}

export function circleIds(state: AppState): ID[] {
  const me = state.users[state.meId];
  return [state.meId, ...me.friendIds.filter((id) => state.users[id] && !state.settings.blockedIds.includes(id))];
}

interface PersonWeek {
  userId: ID;
  completed: number;
  scheduled: number;
  rate: number;
  prevRate: number;
  late: number;
  latest?: string;
  nearMidnight: number;
  weekend: number;
  comebacks: number;
  nudgesSent: number;
  reactionsSent: number;
  morning: number;
}

export function personWeek(state: AppState, userId: ID, start: ISODate, end: ISODate): PersonWeek {
  const cis = checkInsBy(state, userId, start, end);
  const s = windowStats(state, userId, start, end);
  const prev = windowStats(state, userId, addDays(start, -7), addDays(start, -1));
  let late = 0;
  let nearMidnight = 0;
  let weekend = 0;
  let comebacks = 0;
  let morning = 0;
  let latest: string | undefined;
  for (const c of cis) {
    const h = Number(c.time.slice(0, 2));
    if (h >= 21) late++;
    if (c.time >= "23:30") nearMidnight++;
    if (h < 9) morning++;
    if (!latest || c.time > latest) latest = c.time;
    const wd = weekday(c.date);
    if (wd === 0 || wd === 6) weekend++;
    if (isComeback(state, c)) comebacks++;
  }
  const inWeek = (ts: string) => ts.slice(0, 10) >= start && ts.slice(0, 10) <= addDays(end, 1);
  const nudgesSent = state.nudges.filter((n) => n.fromId === userId && inWeek(n.at)).length;
  let reactionsSent = 0;
  for (const c of state.checkIns) {
    if (c.date < start || c.date > end) continue;
    for (const r of c.reactions) if (r.userId === userId) reactionsSent++;
  }
  return { userId, completed: cis.length, scheduled: s.scheduled, rate: s.rate, prevRate: prev.rate, late, latest, nearMidnight, weekend, comebacks, nudgesSent, reactionsSent, morning };
}

function quizLeader(state: AppState, tag: string): { userId: ID; votes: number } | null {
  const q = state.quizzes.find((x) => x.tag === tag);
  if (!q) return null;
  const tally: Record<string, number> = {};
  for (const v of Object.values(q.votes)) tally[v] = (tally[v] ?? 0) + 1;
  const top = Object.entries(tally).sort((a, b) => b[1] - a[1])[0];
  return top ? { userId: top[0], votes: top[1] } : null;
}

function leader(weeks: PersonWeek[], key: (p: PersonWeek) => number) {
  return [...weeks].sort((a, b) => key(b) - key(a))[0];
}

const firstName = (state: AppState, id: ID) => (id === state.meId ? "You" : state.users[id]?.name.split(" ")[0] ?? "Someone");

export function buildSuperlatives(state: AppState, start: ISODate, end: ISODate): Superlative[] {
  const weeks = circleIds(state).map((id) => personWeek(state, id, start, end));
  const out: Superlative[] = [];
  const name = (id: ID) => firstName(state, id);
  const add = (title: string, userId: ID, explanation: string, source: SuperlativeSource, motif: Superlative["motif"], tint: Superlative["tint"]) =>
    out.push({ id: title.toLowerCase().replace(/[^a-z0-9]+/g, "-"), title, userId, explanation, source, motif, tint });

  const late = leader(weeks, (p) => p.late);
  const lastMinuteVotes = quizLeader(state, "last-minute");
  if (late.late > 0) {
    const agreed = lastMinuteVotes?.userId === late.userId;
    add("Last-Minute Legend", late.userId, `${late.late} check-ins after 9pm${late.latest ? `, the latest at ${formatTime(late.latest)}` : ""}.${agreed ? ` Friends agreed: ${lastMinuteVotes!.votes} quiz votes.` : ""}`, agreed ? "both" : "behavior", "alarm", "burgundy");
  }
  const midnight = leader(weeks, (p) => p.nearMidnight);
  if (midnight.nearMidnight > 0 && midnight.userId !== late.userId) {
    add("Most Likely to Check In at 11:59", midnight.userId, `${midnight.nearMidnight} check-ins after 11:30pm. The day isn't over until it's over.`, "behavior", "moon", "sky");
  } else if (lastMinuteVotes && lastMinuteVotes.userId !== late.userId) {
    add("Most Likely to Check In at 11:59", lastMinuteVotes.userId, `${lastMinuteVotes.votes} friends voted for ${name(lastMinuteVotes.userId)} in “Who always checks in at the last minute?”`, "votes", "moon", "sky");
  }
  const weekend = leader(weeks, (p) => p.weekend);
  if (weekend.weekend > 0) add("Weekend MVP", weekend.userId, `${weekend.weekend} check-ins across Saturday and Sunday. Rest days are for other people.`, "behavior", "crown", "gold");
  const comeback = leader(weeks, (p) => p.comebacks);
  if (comeback.comebacks > 0) add("Comeback Kid", comeback.userId, `Came back after a missed stretch ${comeback.comebacks} time${comeback.comebacks > 1 ? "s" : ""} this week. That's the whole skill.`, "behavior", "sun", "orange");
  const reminderVotes = quizLeader(state, "reminders");
  const nudger = leader(weeks, (p) => p.nudgesSent);
  if (nudger.nudgesSent > 0 || reminderVotes) {
    const id = nudger.nudgesSent > 0 ? nudger.userId : reminderVotes!.userId;
    const both = reminderVotes?.userId === id && nudger.nudgesSent > 0;
    add("Professional Reminder Sender", id, nudger.nudgesSent > 0 ? `Sent ${nudger.nudgesSent} kind nudge${nudger.nudgesSent > 1 ? "s" : ""} this week${both ? ` and won ${reminderVotes!.votes} votes for best reminders` : ""}.` : `${reminderVotes!.votes} friends voted them best reminder sender.`, both ? "both" : nudger.nudgesSent > 0 ? "behavior" : "votes", "phone", "sky");
  }
  const improved = leader(weeks, (p) => (p.scheduled ? p.rate - p.prevRate : -1));
  if (improved.rate - improved.prevRate > 0.05) add("Surprisingly Consistent", improved.userId, `Up ${Math.round((improved.rate - improved.prevRate) * 100)} points on last week, from ${Math.round(improved.prevRate * 100)}% to ${Math.round(improved.rate * 100)}%.`, "behavior", "star", "sage");
  const trainer = leader(weeks, (p) => p.reactionsSent + p.nudgesSent * 2);
  if (trainer.reactionsSent > 0) add("Group Chat Personal Trainer", trainer.userId, `${trainer.reactionsSent} reactions handed out to friends. Somebody has to be the hype.`, "behavior", "dumbbell", "rose");
  const wallet = quizLeader(state, "wallet");
  if (wallet) add("Wouldn't Give My Wallet To", wallet.userId, `${wallet.votes} friends voted in “Who would you not trust with your wallet?” Purely a vibes-based award.`, "votes", "ticket", "orange");
  const early = leader(weeks, (p) => p.morning);
  if (early.morning > 0) add("Up Before the Birds", early.userId, `${early.morning} check-ins before 9am. The sunrise has their number.`, "behavior", "sun", "gold");
  return out;
}

export interface RecapData {
  start: ISODate;
  end: ISODate;
  completed: number;
  scheduled: number;
  rate: number;
  prevRate: number;
  strongestDay: string;
  strongestDayCount: number;
  topHabit?: { habit: Habit; rate: number; done: number };
  improvedHabit?: { habit: Habit; delta: number; rate: number };
  interactions: { reactionsSent: number; reactionsReceived: number; comments: number; nudges: number };
  shared: { title: string; progress: number; goal: number; mine: number }[];
  funniest: string;
  predictions: { question: string; pickedId?: ID; winnerId?: ID; correct?: boolean }[];
  rankings: { userId: ID; rate: number; completed: number }[];
  superlatives: Superlative[];
  collectibleId?: ID;
  perDay: number[];
}

export function buildRecap(state: AppState, today: ISODate): RecapData {
  const { start, end } = recapWeek(today, state.settings.weekStart);
  const me = state.meId;
  const p = personWeek(state, me, start, end);
  const habits = habitsFor(state, me, { includeInactive: true }).filter((h) => h.status !== "archived");

  const perDay = Array.from({ length: 7 }, (_, i) => checkInsBy(state, me, addDays(start, i), addDays(start, i)).length);
  const strongestIdx = perDay.indexOf(Math.max(...perDay));
  const strongest = strongestWeekday(state, me, start, end);

  const rated = habits
    .map((h) => {
      const now = habitRate(state, h, me, start, end);
      const prev = habitRate(state, h, me, addDays(start, -7), addDays(start, -1));
      return { habit: h, rate: now.rate, done: now.done, scheduled: now.scheduled, delta: now.rate - prev.rate };
    })
    .filter((r) => r.scheduled > 0);
  const top = [...rated].sort((a, b) => b.rate - a.rate || b.done - a.done)[0];
  const improved = [...rated].filter((r) => r.habit.id !== top?.habit.id).sort((a, b) => b.delta - a.delta)[0];

  let reactionsReceived = 0;
  let comments = 0;
  for (const c of state.checkIns) {
    if (c.userId !== me || c.date < start || c.date > end) continue;
    reactionsReceived += c.reactions.length;
    comments += c.comments.length;
  }

  const shared = state.challenges
    .filter((c) => c.participantIds.includes(me))
    .map((c) => ({ title: c.title, progress: Object.values(c.contributions).reduce((a, b) => a + b, 0), goal: c.goal, mine: c.contributions[me] ?? 0 }));

  const lateHabit = state.checkIns
    .filter((c) => c.userId === me && c.date >= start && c.date <= end && c.time >= "21:00")
    .reduce<Record<string, number>>((acc, c) => ((acc[c.habitId] = (acc[c.habitId] ?? 0) + 1), acc), {});
  const lateTop = Object.entries(lateHabit).sort((a, b) => b[1] - a[1])[0];
  const lateName = lateTop ? state.habits.find((h) => h.id === lateTop[0])?.name : undefined;
  const funniest = lateTop && lateName
    ? `You did “${lateName}” after 9pm ${lateTop[1]} time${lateTop[1] > 1 ? "s" : ""}. Bold scheduling.`
    : p.morning > 3
      ? `${p.morning} check-ins before 9am. Who are you?`
      : `Your busiest hour was the same every day. Creature of habit (literally).`;

  const predictions = state.predictions.map((pr) => ({ question: pr.question, pickedId: pr.votes[me], winnerId: pr.winnerId, correct: pr.winnerId ? pr.votes[me] === pr.winnerId : undefined }));

  const rankings = circleIds(state)
    .map((id) => {
      const w = windowStats(state, id, start, end);
      return { userId: id, rate: w.rate, completed: checkInsBy(state, id, start, end).length };
    })
    .sort((a, b) => b.rate - a.rate);

  const recentAward = [...state.collection].sort((a, b) => b.earnedAt.localeCompare(a.earnedAt))[0];

  return {
    start,
    end,
    completed: p.completed,
    scheduled: p.scheduled,
    rate: p.rate,
    prevRate: p.prevRate,
    strongestDay: perDay[strongestIdx] > 0 ? WEEKDAY_LONG[weekday(addDays(start, strongestIdx))] : strongest.name,
    strongestDayCount: perDay[strongestIdx],
    topHabit: top ? { habit: top.habit, rate: top.rate, done: top.done } : undefined,
    improvedHabit: improved && improved.delta > 0 ? { habit: improved.habit, delta: improved.delta, rate: improved.rate } : undefined,
    interactions: { reactionsSent: p.reactionsSent, reactionsReceived, comments, nudges: p.nudgesSent },
    shared,
    funniest,
    predictions,
    rankings,
    superlatives: buildSuperlatives(state, start, end),
    collectibleId: recentAward?.collectibleId,
    perDay,
  };
}
