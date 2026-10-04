import { BRAND } from "@/lib/brand";
import { COLLECTIBLE_BY_ID, RARITY_META } from "@/lib/data/catalog";
import { addDays, formatDate, formatTime, WEEKDAY_LETTER, weekday } from "@/lib/dates";
import { hashString } from "@/lib/random";
import { currentStreak, habitById, habitsFor, isDone, isScheduled } from "@/lib/selectors/habits";
import { buildRecap } from "@/lib/selectors/recap";
import { comebackCount, consistencyScore, habitRate, pct, rollingWeeks } from "@/lib/selectors/stats";
import type { AppState, AvatarConfig, ID, IllustrationKey, ISODate, Tint } from "@/lib/types";

export type ShareKind = "completion" | "award" | "recap" | "group" | "invite" | "history" | "report";
export type ShareFormat = "story" | "square" | "message";

export interface SharePrivacy {
  hideName: boolean;
  hideTimes: boolean;
  hideFriends: boolean;
  hideHabits: boolean;
}

export type ShareArt =
  | { type: "habit"; icon: IllustrationKey; tint: Tint }
  | { type: "sticker"; collectibleId: ID }
  | { type: "mascot"; mood: "proud" | "wave" | "cheer" | "happy" }
  | { type: "avatar"; config: AvatarConfig };

export interface ShareContent {
  kind: ShareKind;
  eyebrow: string;
  headline: string;
  sub?: string;
  note?: string;
  stat?: { value: string; label: string };
  art: ShareArt;
  stamp?: string;
  bars?: { label: string; value: number; caption?: string }[];
  /** History grid cells, oldest first: 0 = not scheduled, 1 = missed, 2 = done. */
  grid?: (0 | 1 | 2)[];
  progress?: { value: number; max: number; label: string };
  people?: AvatarConfig[];
  footer?: { name: string; avatar: AvatarConfig };
  url: string;
  /** Plain text for the system share sheet. */
  shareText: string;
}

export const SHARE_KINDS: { key: ShareKind; label: string; icon: IllustrationKey; needs?: "habit" | "award" | "challenge" }[] = [
  { key: "completion", label: "Check-in", icon: "shoe", needs: "habit" },
  { key: "award", label: "Award", icon: "star", needs: "award" },
  { key: "recap", label: "Weekly recap", icon: "sun" },
  { key: "group", label: "Group progress", icon: "ribbon", needs: "challenge" },
  { key: "invite", label: "Invitation", icon: "ticket" },
  { key: "history", label: "Habit history", icon: "book", needs: "habit" },
  { key: "report", label: "Progress report", icon: "pencil" },
];

export function parseKind(raw: string | null): ShareKind {
  if (raw === "recap-card") return "recap";
  return SHARE_KINDS.some((k) => k.key === raw) ? (raw as ShareKind) : "completion";
}

/** Options for the per-kind picker. */
export function pickerOptions(state: AppState, kind: ShareKind): { id: ID; label: string }[] {
  const me = state.meId;
  const need = SHARE_KINDS.find((k) => k.key === kind)?.needs;
  if (need === "habit") return habitsFor(state, me, { includeInactive: true }).map((h) => ({ id: h.id, label: h.status === "active" ? h.name : `${h.name} (${h.status})` }));
  if (need === "award")
    return [...state.collection]
      .sort((a, b) => b.earnedAt.localeCompare(a.earnedAt))
      .filter((o) => COLLECTIBLE_BY_ID[o.collectibleId])
      .map((o) => ({ id: o.collectibleId, label: COLLECTIBLE_BY_ID[o.collectibleId].name }));
  if (need === "challenge")
    return state.challenges
      .filter((c) => c.participantIds.includes(me))
      .map((c) => ({ id: c.id, label: `${c.title} · ${state.groups.find((g) => g.id === c.groupId)?.name ?? "Group"}` }));
  return [];
}

function shareUrl(kind: ShareKind, id: string, state: AppState, privacy: SharePrivacy) {
  const me = state.users[state.meId];
  if (kind === "invite") return `https://${BRAND.shareDomain}/i/${privacy.hideName ? hashString(me.id + "invite").toString(36).slice(0, 7) : me.handle}`;
  return `https://${BRAND.shareDomain}/s/${hashString(`${kind}:${id}:${state.meId}`).toString(36)}`;
}

const dateLabel = (d: ISODate) => formatDate(d, { weekday: "short", month: "short", day: "numeric" });

export function buildShareContent(state: AppState, today: ISODate, kind: ShareKind, id: string | undefined, privacy: SharePrivacy): ShareContent | null {
  const meId = state.meId;
  const me = state.users[meId];
  const first = me.name.split(" ")[0];
  const footer = privacy.hideName ? undefined : { name: first, avatar: me.avatar };
  const url = shareUrl(kind, id ?? "", state, privacy);
  const habitName = (n: string) => (privacy.hideHabits ? "a habit" : n);

  switch (kind) {
    case "completion": {
      const h = id ? habitById(state, id) : undefined;
      if (!h) return null;
      const last = state.checkIns.filter((c) => c.userId === meId && c.habitId === h.id).sort((a, b) => b.date.localeCompare(a.date) || b.time.localeCompare(a.time))[0];
      const streak = currentStreak(state, h, meId, today);
      const month = habitRate(state, h, meId, addDays(today, -27), today);
      const showStreak = state.settings.showStreaks && h.showStreak && streak > 1;
      return {
        kind,
        eyebrow: last && !privacy.hideTimes ? `Checked in · ${dateLabel(last.date)} at ${formatTime(last.time)}` : "Checked in",
        headline: privacy.hideHabits ? "Showed up for a habit" : h.name,
        sub: showStreak ? `${streak} in a row and counting.` : `${month.done} times in the last four weeks.`,
        stat: { value: pct(month.rate), label: "kept this month" },
        art: { type: "habit", icon: h.icon, tint: h.tint },
        stamp: "Done",
        footer,
        url,
        shareText: `I just checked in on ${habitName(h.name)} in ${BRAND.name}.`,
      };
    }
    case "award": {
      const c = id ? COLLECTIBLE_BY_ID[id] : undefined;
      const owned = state.collection.find((o) => o.collectibleId === id);
      if (!c || !owned) return null;
      return {
        kind,
        eyebrow: privacy.hideTimes ? "New sticker" : `New sticker · ${new Date(owned.earnedAt).toLocaleDateString("en-US", { month: "short", day: "numeric" })}`,
        headline: c.name,
        sub: `“${c.blurb}”`,
        note: !privacy.hideHabits && !privacy.hideFriends ? owned.earnedFor : undefined,
        stat: { value: RARITY_META[c.rarity].label.split(" ·")[0], label: "rarity" },
        art: { type: "sticker", collectibleId: c.id },
        stamp: "Earned",
        footer,
        url,
        shareText: `I earned the “${c.name}” sticker in ${BRAND.name}.`,
      };
    }
    case "recap": {
      const r = buildRecap(state, today);
      const mine = r.superlatives.find((s) => s.userId === meId);
      return {
        kind,
        eyebrow: privacy.hideTimes ? "Last week" : `Week of ${formatDate(r.start)}`,
        headline: `${pct(r.rate)} consistent`,
        sub: `${r.completed} check-ins. Best day: ${r.strongestDay}.`,
        note: r.topHabit ? `Top habit: ${privacy.hideHabits ? "one I’m proud of" : r.topHabit.habit.name}` : undefined,
        bars: r.perDay.map((v, i) => ({ label: WEEKDAY_LETTER[weekday(addDays(r.start, i))], value: v })),
        art: { type: "mascot", mood: "proud" },
        stamp: mine ? mine.title : "Recap",
        footer,
        url,
        shareText: `My week in ${BRAND.name}: ${pct(r.rate)} consistent, ${r.completed} check-ins.`,
      };
    }
    case "group": {
      const ch = state.challenges.find((c) => c.id === id);
      if (!ch) return null;
      const g = state.groups.find((x) => x.id === ch.groupId);
      const total = Object.values(ch.contributions).reduce((a, b) => a + b, 0);
      const mine = ch.contributions[meId] ?? 0;
      const people = ch.participantIds
        .filter((p) => (p === meId ? !privacy.hideName : !privacy.hideFriends))
        .map((p) => state.users[p]?.avatar)
        .filter((a): a is AvatarConfig => Boolean(a))
        .slice(0, 5);
      return {
        kind,
        eyebrow: privacy.hideFriends ? "Group challenge" : g?.name ?? "Group challenge",
        headline: privacy.hideHabits ? "Our group challenge" : ch.title,
        sub: `${ch.participantIds.length} of us, ${Math.min(100, Math.round((total / ch.goal) * 100))}% there. I added ${mine}.`,
        progress: { value: total, max: ch.goal, label: `${total} / ${ch.goal} ${ch.unit}` },
        people: people.length ? people : undefined,
        art: { type: "habit", icon: ch.icon, tint: g?.tint ?? "sage" },
        stamp: total >= ch.goal ? "Goal!" : "Together",
        footer,
        url,
        shareText: `${total} of ${ch.goal} ${ch.unit} so far. Group goals hit different.`,
      };
    }
    case "invite":
      return {
        kind,
        eyebrow: "You're invited",
        headline: "Keep a habit with me",
        sub: `Join ${privacy.hideName ? "me" : first} on ${BRAND.name}. ${BRAND.tagline}`,
        art: privacy.hideName ? { type: "mascot", mood: "wave" } : { type: "avatar", config: me.avatar },
        stamp: "Invite",
        footer,
        url,
        shareText: `Come keep a habit with me on ${BRAND.name}.`,
      };
    case "history": {
      const h = id ? habitById(state, id) : undefined;
      if (!h) return null;
      const from = addDays(today, -83);
      const grid: (0 | 1 | 2)[] = [];
      let done = 0;
      let scheduled = 0;
      for (let i = 0; i < 84; i++) {
        const d = addDays(from, i);
        const sched = isScheduled(h, d);
        const ok = isDone(state, h.id, meId, d);
        if (sched && d < today) scheduled++;
        if (ok) done++;
        grid.push(ok ? 2 : sched && d < today ? 1 : 0);
      }
      return {
        kind,
        eyebrow: privacy.hideTimes ? "Twelve weeks of" : `${formatDate(from)} – ${formatDate(today)}`,
        headline: privacy.hideHabits ? "Showing up" : h.name,
        sub: `${done} check-ins across 12 weeks.`,
        stat: { value: scheduled ? pct(Math.min(1, done / scheduled)) : "–", label: "of scheduled days" },
        grid,
        art: { type: "habit", icon: h.icon, tint: h.tint },
        footer,
        url,
        shareText: `12 weeks of ${habitName(h.name)} in ${BRAND.name}.`,
      };
    }
    case "report": {
      const weeks = rollingWeeks(state, meId, today, 4);
      const score = consistencyScore(state, meId, today);
      const comebacks = comebackCount(state, meId, addDays(today, -27), today);
      return {
        kind,
        eyebrow: privacy.hideTimes ? "Four-week report" : `Four weeks to ${formatDate(today)}`,
        headline: `${score.score}% consistent`,
        sub: `${score.completed} check-ins${comebacks ? `, ${comebacks} comeback${comebacks > 1 ? "s" : ""}` : ""}. Forgiving score: a miss a week is on the house.`,
        bars: weeks.map((w, i) => ({ label: privacy.hideTimes ? `W${i + 1}` : formatDate(w.from, { month: "numeric", day: "numeric" }), value: w.rate, caption: pct(w.rate) })),
        art: { type: "mascot", mood: "cheer" },
        stamp: "Report",
        footer,
        url,
        shareText: `${score.score}% consistent over four weeks in ${BRAND.name}.`,
      };
    }
  }
}
