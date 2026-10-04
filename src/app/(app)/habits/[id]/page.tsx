"use client";

import { Archive, ArchiveRestore, Bell, Camera, Check, Lock, Pause, Pencil, Play, UserPlus } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useMemo, useState } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { FriendAvatarStack } from "@/components/avatar/FriendAvatarStack";
import { WeekBars } from "@/components/habits/ConsistencySummary";
import { Illustration, IllustrationTile, TINT_SOFT, TINT_SOLID } from "@/components/illustrations/Illustration";
import { Page } from "@/components/shell/Page";
import { ReactionBar } from "@/components/social/ReactionBar";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button, ButtonLink } from "@/components/ui/Button";
import { Toggle } from "@/components/ui/controls";
import { Badge, EmptyState, SectionHeading, Tape } from "@/components/ui/misc";
import { Stamp } from "@/components/ui/Stamp";
import { useToast } from "@/components/ui/Toast";
import { cn } from "@/lib/cn";
import { CATEGORY_META } from "@/lib/data/catalog";
import { addDays, formatDate, formatTime, orderedWeekdays, rangeDates, relativeTime, startOfWeek, timeOfDayFor, weekday, WEEKDAY_LETTER, WEEKDAY_LONG } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { bestStreak, currentStreak, habitById, isComeback, isDone, isScheduled, scheduleLabel, TIME_LABEL } from "@/lib/selectors/habits";
import { habitRate } from "@/lib/selectors/stats";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { AppState, CheckIn, Habit, ID, ISODate, User } from "@/lib/types";

const HISTORY_WEEKS = 12;
const TIME_BUCKET_LABEL = { morning: "Mornings", afternoon: "Afternoons", evening: "Evenings", late: "Late nights" } as const;

function habitStats(state: AppState, h: Habit, userId: ID, today: ISODate) {
  const doneToday = isDone(state, h.id, userId, today);
  const end = doneToday ? today : addDays(today, -1);
  const last28 = habitRate(state, h, userId, addDays(today, -27), end);
  const mine = state.checkIns.filter((c) => c.habitId === h.id && c.userId === userId);
  const comebacks = mine.filter((c) => isComeback(state, c)).length;

  const sched = Array(7).fill(0) as number[];
  const done = Array(7).fill(0) as number[];
  for (const d of rangeDates(addDays(today, -83), end)) {
    if (!isScheduled(h, d)) continue;
    sched[weekday(d)]++;
    if (isDone(state, h.id, userId, d)) done[weekday(d)]++;
  }
  let strongest: number | null = null;
  for (let i = 0; i < 7; i++) {
    if (sched[i] < 2) continue;
    if (strongest === null || done[i] / sched[i] > done[strongest] / sched[strongest]) strongest = i;
  }

  const buckets = { morning: 0, afternoon: 0, evening: 0, late: 0 };
  for (const c of mine) {
    if (Number(c.time.split(":")[0]) >= 22) buckets.late++;
    else buckets[timeOfDayFor(c.time)]++;
  }
  const topBucket = (Object.entries(buckets) as [keyof typeof buckets, number][]).sort((a, b) => b[1] - a[1])[0];

  const weekLabels = ["3 wk ago", "2 wk ago", "Last wk", "This wk"];
  const weeks = weekLabels.map((label, i) => {
    const to = i === 3 ? end : addDays(today, -7 * (3 - i));
    const from = addDays(today, -7 * (3 - i) - 6);
    const r = habitRate(state, h, userId, from, to);
    return { label, rate: r.rate, completed: r.done, scheduled: r.scheduled, detail: `${formatDate(from)} – ${formatDate(addDays(today, -7 * (3 - i)))}` };
  });

  return {
    doneToday,
    last28,
    total: mine.length,
    comebacks,
    strongest: strongest === null ? null : { day: strongest, rate: done[strongest] / sched[strongest] },
    typical: mine.length ? { label: TIME_BUCKET_LABEL[topBucket[0]], share: topBucket[1] / mine.length } : null,
    weeks,
    streak: currentStreak(state, h, userId, today),
    best: bestStreak(state, h, userId, today),
  };
}

/* ---------- History grid ---------- */

type CellState = "done" | "missed" | "open" | "rest" | "future";

function HistoryGrid({ habit, userId, today, weekStart }: { habit: Habit; userId: ID; today: ISODate; weekStart: 0 | 1 }) {
  const state = useAppState();
  const { weeks, summary } = useMemo(() => {
    const start = startOfWeek(addDays(today, -7 * (HISTORY_WEEKS - 1)), weekStart);
    const weeks = Array.from({ length: HISTORY_WEEKS }, (_, w) => {
      const days = Array.from({ length: 7 }, (_, i) => {
        const date = addDays(start, w * 7 + i);
        const isDoneDay = isDone(state, habit.id, userId, date);
        const sched = isScheduled(habit, date);
        let s: CellState;
        if (date > today) s = "future";
        else if (isDoneDay) s = "done";
        else if (!sched) s = "rest";
        else if (date === today) s = "open";
        else s = "missed";
        return { date, s };
      });
      const wDone = days.filter((d) => d.s === "done").length;
      const wSched = days.filter((d) => d.s === "done" || d.s === "missed").length;
      return { start: days[0].date, days, wDone, wSched };
    });
    const summary = weeks.reduce((acc, w) => ({ done: acc.done + w.wDone, scheduled: acc.scheduled + w.wSched }), { done: 0, scheduled: 0 });
    return { weeks, summary };
  }, [state, habit, userId, today, weekStart]);

  const monthLabels = weeks.map((w, i) => {
    const m = w.days.find((d) => d.date.endsWith("-01"))?.date ?? (i === 0 ? w.start : null);
    if (!m) return null;
    if (i === 0 && weeks.slice(1, 3).some((x) => x.days.some((d) => d.date.endsWith("-01")))) return null;
    return formatDate(m, { month: "short" });
  });

  const cellCls: Record<CellState, string> = {
    done: TINT_SOLID[habit.tint],
    missed: "border border-line-strong bg-cream",
    open: "border-2 border-dashed border-accent/60 bg-cream",
    rest: "bg-paper-deep/50",
    future: "bg-paper-deep/20",
  };

  return (
    <div>
      <div
        role="img"
        aria-label={`Last ${HISTORY_WEEKS} weeks: ${summary.done} check-ins${summary.scheduled ? `, ${summary.done} of ${summary.scheduled} scheduled days done` : ""}. Week-by-week details follow.`}
        className="max-w-[26rem]"
      >
        <div className="grid gap-[3px]" style={{ gridTemplateColumns: `1rem repeat(${HISTORY_WEEKS}, minmax(0, 1fr))` }} aria-hidden>
          <span />
          {monthLabels.map((m, i) => (
            <span key={i} className="h-4 overflow-visible whitespace-nowrap text-[0.625rem] font-semibold uppercase tracking-[0.04em] text-faint">
              {m}
            </span>
          ))}
          {orderedWeekdays(weekStart).map((wd, row) => (
            <Row key={wd} letter={row % 2 === 0 ? WEEKDAY_LETTER[wd] : ""}>
              {weeks.map((w) => {
                const c = w.days[row];
                return <span key={c.date} className={cn("aspect-square rounded-[4px]", cellCls[c.s], c.date === today && c.s === "done" && "ring-2 ring-accent ring-offset-1 ring-offset-cream")} title={`${formatDate(c.date, { weekday: "short", month: "short", day: "numeric" })}: ${c.s === "done" ? "done" : c.s === "missed" ? "not logged" : c.s === "open" ? "still open" : c.s === "rest" ? "rest day" : "upcoming"}`} />;
              })}
            </Row>
          ))}
        </div>
      </div>
      <ul className="sr-only">
        {weeks.map((w) => (
          <li key={w.start}>
            Week of {formatDate(w.start, { month: "long", day: "numeric" })}: {w.wSched ? `${w.wDone} of ${w.wSched} scheduled days done` : w.wDone ? `${w.wDone} done` : "nothing scheduled yet"}
          </li>
        ))}
      </ul>
      <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1.5 text-xs text-muted" aria-hidden>
        <LegendSwatch className={TINT_SOLID[habit.tint]}>Done</LegendSwatch>
        <LegendSwatch className="border border-line-strong bg-cream">Not logged</LegendSwatch>
        <LegendSwatch className="bg-paper-deep/50">Rest day</LegendSwatch>
      </div>
    </div>
  );
}

function Row({ letter, children }: { letter: string; children: React.ReactNode }) {
  return (
    <>
      <span className="grid place-items-center text-[0.625rem] font-bold text-faint">{letter}</span>
      {children}
    </>
  );
}

function LegendSwatch({ className, children }: { className: string; children: React.ReactNode }) {
  return (
    <span className="inline-flex items-center gap-1.5">
      <span className={cn("size-3 rounded-[3px]", className)} />
      {children}
    </span>
  );
}

/* ---------- Pieces ---------- */

function Stat({ label, value, sub, className }: { label: string; value: React.ReactNode; sub?: string; className?: string }) {
  return (
    <div className={cn("rounded-[14px] border border-line bg-paper/60 px-3 py-2.5", className)}>
      <dt className="text-xs font-semibold text-muted">{label}</dt>
      <dd>
        <span className="block font-display text-lg font-bold leading-tight text-ink">{value}</span>
        {sub && <span className="block text-xs text-muted">{sub}</span>}
      </dd>
    </div>
  );
}

function ParticipantRow({ habit, user, isMe, today }: { habit: Habit; user: User; isMe: boolean; today: ISODate }) {
  const state = useAppState();
  const days = rangeDates(addDays(today, -6), today);
  const scheduledToday = isScheduled(habit, today);
  const doneToday = isDone(state, habit.id, user.id, today);
  const doneCount = days.filter((d) => isDone(state, habit.id, user.id, d)).length;
  const schedCount = days.filter((d) => isScheduled(habit, d) && d !== today).length + (doneToday && scheduledToday ? 1 : 0);
  return (
    <li className="flex items-center gap-3 py-2.5">
      <Avatar user={user} size={36} />
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-semibold text-ink">{isMe ? "You" : user.name}</p>
        <p className={cn("text-xs font-semibold", doneToday ? "text-sage-ink" : "text-muted")}>{doneToday ? "Done today" : scheduledToday ? "Not yet today" : "Rest day today"}</p>
      </div>
      <div className="flex shrink-0 items-center gap-2">
        <span className="sr-only">
          {doneCount} of the last 7 days done
        </span>
        <span className="flex gap-[3px]" aria-hidden>
          {days.map((d) => {
            const done = isDone(state, habit.id, user.id, d);
            const sched = isScheduled(habit, d);
            return (
              <span
                key={d}
                title={formatDate(d, { weekday: "short" })}
                className={cn("size-4 rounded-[4px] sm:size-5", done ? TINT_SOLID[habit.tint] : sched && d !== today ? "border border-line-strong bg-cream" : "bg-paper-deep/50", d === today && "ring-1 ring-accent/60 ring-offset-1 ring-offset-cream")}
              />
            );
          })}
        </span>
        <span className="w-8 text-right font-display text-xs font-bold tabular-nums text-muted" aria-hidden>
          {doneCount}/{Math.max(schedCount, doneCount)}
        </span>
      </div>
    </li>
  );
}

function Polaroid({ photo }: { photo: NonNullable<CheckIn["photo"]> }) {
  return (
    <figure className="relative mt-3 w-40 rotate-[-2deg] rounded-[4px] border border-line bg-[#fffdf7] p-2 pb-1.5 shadow-[var(--shadow)] dark:bg-[#f3e8d2]">
      <Tape className="-top-2 left-1/2 -translate-x-1/2" rotate={4} />
      <div className={cn("grid aspect-[4/3] place-items-center rounded-[2px]", TINT_SOFT[photo.tint])}>
        <Illustration kind={photo.motif} size={64} />
      </div>
      <figcaption className="mt-1 truncate font-hand text-lg leading-tight text-[#2e1b1a]">
        <span className="sr-only">Photo proof: </span>
        {photo.caption || "proof!"}
      </figcaption>
    </figure>
  );
}

function CheckInItem({ c }: { c: CheckIn }) {
  const state = useAppState();
  const user = state.users[c.userId];
  const isMe = c.userId === state.meId;
  const comeback = isComeback(state, c);
  if (!user) return null;
  return (
    <li className="card p-3.5">
      <div className="flex items-start gap-2.5">
        <Avatar user={user} size={34} />
        <div className="min-w-0 flex-1">
          <p className="flex flex-wrap items-center gap-x-2 gap-y-0.5 text-sm">
            <span className="font-semibold text-ink">{isMe ? "You" : user.name.split(" ")[0]}</span>
            <span className="text-muted">
              {formatDate(c.date, { weekday: "short", month: "short", day: "numeric" })} · {formatTime(c.time)}
            </span>
            {comeback && <Badge tone="sage">Comeback</Badge>}
          </p>
          {c.note && <p className="mt-1.5 text-[0.9375rem] leading-relaxed text-ink">{c.note}</p>}
          {c.photo && <Polaroid photo={c.photo} />}
          <ReactionBar checkIn={c} size="sm" className="mt-2.5" />
          {c.comments.length > 0 && (
            <ul className="mt-2.5 space-y-2 border-l-2 border-line pl-3" aria-label="Comments">
              {c.comments.map((cm) => {
                const author = state.users[cm.userId];
                return (
                  <li key={cm.id} className="flex items-start gap-2">
                    {author && <Avatar user={author} size={22} />}
                    <p className="min-w-0 text-[0.8125rem] leading-snug text-ink">
                      <span className="font-semibold">{cm.userId === state.meId ? "You" : author?.name.split(" ")[0] ?? "Someone"}</span> {cm.text}
                      <span className="ml-1.5 text-xs text-faint">{relativeTime(cm.at)}</span>
                    </p>
                  </li>
                );
              })}
            </ul>
          )}
        </div>
      </div>
    </li>
  );
}

function InviteSheet({ open, onClose, habit }: { open: boolean; onClose: () => void; habit: Habit }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const [picked, setPicked] = useState<ID[]>([]);
  const me = state.users[state.meId];
  const candidates = me.friendIds.map((id) => state.users[id]).filter((u): u is User => Boolean(u) && !habit.participantIds.includes(u.id));
  const close = () => {
    setPicked([]);
    onClose();
  };
  const send = () => {
    dispatch({ type: "habit/invite", id: habit.id, userIds: picked });
    toast({ title: picked.length === 1 ? "Invite sent" : `${picked.length} invites sent`, body: "They'll get a gentle heads-up.", motif: habit.icon });
    close();
  };
  return (
    <BottomSheet
      open={open}
      onClose={close}
      title="Invite friends"
      description={`Do “${habit.name}” together.`}
      footer={
        candidates.length > 0 ? (
          <Button block disabled={!picked.length} onClick={send} icon={<UserPlus size={18} aria-hidden />}>
            {picked.length ? `Invite ${picked.length}` : "Pick someone"}
          </Button>
        ) : undefined
      }
    >
      {candidates.length === 0 ? (
        <EmptyState compact mood="happy" title="Everyone's already in" body="All your friends are part of this habit." />
      ) : (
        <ul className="space-y-1.5" role="group" aria-label="Friends">
          {candidates.map((f) => {
            const on = picked.includes(f.id);
            return (
              <li key={f.id}>
                <button
                  type="button"
                  role="checkbox"
                  aria-checked={on}
                  onClick={() => setPicked((p) => (on ? p.filter((x) => x !== f.id) : [...p, f.id]))}
                  className={cn("flex min-h-14 w-full items-center gap-3 rounded-[14px] border px-3 py-2 text-left transition-colors", on ? "border-accent bg-accent-soft" : "border-line bg-cream hover:bg-accent-soft/50")}
                >
                  <Avatar user={f} size={38} />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate font-semibold text-ink">{f.name}</span>
                    <span className="block truncate text-xs text-muted">@{f.handle}</span>
                  </span>
                  <span className={cn("grid size-6 place-items-center rounded-[7px] border-2", on ? "border-accent bg-accent text-on-accent" : "border-line-strong")} aria-hidden>
                    {on && <Check size={14} strokeWidth={3} />}
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </BottomSheet>
  );
}

/* ---------- Page ---------- */

export default function HabitDetailPage() {
  const { id } = useParams<{ id: string }>();
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const today = useToday();
  const [inviteOpen, setInviteOpen] = useState(false);
  const [logLimit, setLogLimit] = useState(6);
  const habit = habitById(state, id);

  const subject = habit && habit.participantIds.includes(state.meId) ? state.meId : habit?.ownerId;
  const stats = useMemo(() => (habit && subject ? habitStats(state, habit, subject, today) : null), [state, habit, subject, today]);
  const log = useMemo(
    () => (habit ? state.checkIns.filter((c) => c.habitId === habit.id).sort((a, b) => (a.date === b.date ? b.time.localeCompare(a.time) : b.date.localeCompare(a.date))) : []),
    [state.checkIns, habit],
  );

  if (!habit || !stats || !subject) {
    return (
      <Page back="/today" title="Habit">
        <EmptyState
          title="We couldn't find that habit"
          body="It may have been deleted, or the link is a little off."
          action={
            <ButtonLink href="/today" variant="secondary">
              Back to Today
            </ButtonLink>
          }
        />
      </Page>
    );
  }

  const settings = state.settings;
  const participants = habit.participantIds.map((pid) => state.users[pid]).filter((u): u is User => Boolean(u));
  const others = participants.filter((u) => u.id !== state.meId);
  const paused = habit.status === "paused";
  const archived = habit.status === "archived";
  const showStreak = habit.showStreak && settings.showStreaks;
  const isParticipant = subject === state.meId;
  const setStatus = (status: Habit["status"], title: string, body: string) => {
    dispatch({ type: "habit/status", id: habit.id, status });
    toast({ title, body, motif: habit.icon });
  };

  return (
    <Page back="/today" eyebrow={CATEGORY_META[habit.category].label} title={habit.name} wide>
      <div className="space-y-6">
        {(paused || archived) && (
          <div role="status" className={cn("flex flex-col gap-3 rounded-[16px] border p-3.5 sm:flex-row sm:items-center", paused ? "border-gold/40 bg-gold-soft" : "border-line-strong bg-paper-deep/60")}>
            <span className="grid size-10 shrink-0 place-items-center rounded-[12px] bg-cream/70 text-ink">{paused ? <Pause size={18} aria-hidden /> : <Archive size={18} aria-hidden />}</span>
            <p className="min-w-0 flex-1 text-sm leading-snug text-ink">
              <strong className="font-display font-bold">{paused ? "Taking a break." : "Archived."}</strong>{" "}
              {paused ? "It's off your Today list and won't count against your consistency." : "Tucked away with every check-in kept safe."}
            </p>
            <Button
              size="sm"
              variant="secondary"
              className="min-h-11 self-start sm:self-auto"
              icon={paused ? <Play size={16} aria-hidden /> : <ArchiveRestore size={16} aria-hidden />}
              onClick={() => setStatus("active", paused ? "Welcome back" : "Habit restored", `“${habit.name}” is back on Today.`)}
            >
              {paused ? "Resume" : "Restore"}
            </Button>
          </div>
        )}

        <section className="card relative p-4 sm:p-5" aria-label="About this habit">
          <div className="flex items-start gap-4">
            <IllustrationTile kind={habit.icon} tint={habit.tint} size={72} rotate={-4} muted={paused || archived} />
            <div className="min-w-0 flex-1">
              <p className="font-display text-base font-bold text-ink">
                {scheduleLabel(habit)} <span className="font-sans font-medium text-muted">· {TIME_LABEL[habit.timeOfDay]}</span>
              </p>
              {habit.description && <p className="mt-1 text-[0.9375rem] leading-relaxed text-muted">{habit.description}</p>}
              <div className="mt-2 flex flex-wrap items-center gap-1.5">
                {habit.optional && <Badge tone="muted">Optional</Badge>}
                {habit.privacy === "private" && (
                  <Badge tone="muted">
                    <Lock size={10} aria-hidden /> Private
                  </Badge>
                )}
                {habit.proof !== "off" && (
                  <Badge tone="gold">
                    <Camera size={10} aria-hidden /> Photo {habit.proof}
                  </Badge>
                )}
                {habit.targetDate && <Badge tone="orange">Until {formatDate(habit.targetDate)}</Badge>}
              </div>
            </div>
            {stats.doneToday && (
              <span className="shrink-0" role="img" aria-label="Done today">
                <Stamp size={46} />
              </span>
            )}
          </div>
          {others.length > 0 && (
            <div className="mt-4 flex items-center gap-2.5 border-t border-line pt-3">
              <FriendAvatarStack users={participants} size={28} max={5} doneIds={participants.filter((u) => isDone(state, habit.id, u.id, today)).map((u) => u.id)} />
              <p className="min-w-0 text-sm text-muted">
                With {others.map((u) => u.name.split(" ")[0]).join(", ")}
              </p>
            </div>
          )}
          <div className="mt-4 flex flex-wrap gap-2">
            <ButtonLink href={`/habits/${habit.id}/edit`} variant="secondary" size="sm" className="min-h-11" icon={<Pencil size={16} aria-hidden />}>
              Edit
            </ButtonLink>
            {!archived && (
              <Button
                variant="secondary"
                size="sm"
                className="min-h-11"
                icon={paused ? <Play size={16} aria-hidden /> : <Pause size={16} aria-hidden />}
                onClick={() => (paused ? setStatus("active", "Welcome back", `“${habit.name}” is back on Today.`) : setStatus("paused", "Habit paused", "Rest is part of the plan. Resume whenever."))}
              >
                {paused ? "Resume" : "Pause"}
              </Button>
            )}
            <Button variant="secondary" size="sm" className="min-h-11" icon={<UserPlus size={16} aria-hidden />} onClick={() => setInviteOpen(true)}>
              Invite
            </Button>
          </div>
          {isParticipant && (
            <div className="mt-3 flex min-h-12 items-center gap-3 rounded-[14px] border border-line bg-paper/50 px-3">
              <Bell size={17} className="shrink-0 text-muted" aria-hidden />
              <p className="min-w-0 flex-1 text-sm">
                <span className="font-semibold text-ink">Reminders</span>{" "}
                <span className="text-muted">
                  {habit.remindersOn && habit.reminderTimes.length ? habit.reminderTimes.map(formatTime).join(", ") : habit.remindersOn ? "on, no times set" : "off"}
                </span>
              </p>
              <Toggle
                checked={habit.remindersOn}
                label="Reminders"
                onChange={(v) => {
                  dispatch({ type: "habit/update", id: habit.id, patch: { remindersOn: v } });
                  toast({ title: v ? "Reminders on" : "Reminders off", body: v ? "We'll give you a gentle nudge." : "You can turn them back on any time." });
                }}
              />
            </div>
          )}
        </section>

        <section aria-labelledby="h-stats">
          <SectionHeading id="h-stats" title="How it's going" hand={!isParticipant ? undefined : stats.last28.rate >= 0.7 ? "nice rhythm" : stats.comebacks ? "you keep coming back" : undefined} className="mb-3" />
          <div className="grid gap-3 md:grid-cols-[minmax(0,1fr)_minmax(0,1.1fr)]">
            <div className="card p-4">
              <p className="eyebrow">Last 28 days</p>
              <p className="mt-1 flex items-baseline gap-1">
                <span className="font-display text-[2.75rem] font-extrabold leading-none tracking-[-0.04em] text-ink tabular-nums">{stats.last28.scheduled ? Math.round(stats.last28.rate * 100) : "–"}</span>
                {stats.last28.scheduled > 0 && <span className="font-display text-lg font-bold text-muted">%</span>}
              </p>
              <p className="mt-1 text-sm text-muted">
                {stats.last28.scheduled ? `${stats.last28.done} of ${stats.last28.scheduled} scheduled days` : "Nothing scheduled yet — give it a few days."}
              </p>
              <WeekBars weeks={stats.weeks} height={64} className="mt-4" barClass={TINT_SOLID[habit.tint]} />
            </div>
            <dl className="grid grid-cols-2 gap-2 self-start">
              <Stat label="Total check-ins" value={stats.total} />
              <Stat label="Comebacks" value={stats.comebacks} sub={stats.comebacks ? "Back after a break" : "None needed yet"} />
              <Stat label="Strongest day" value={stats.strongest ? WEEKDAY_LONG[stats.strongest.day] : "–"} sub={stats.strongest ? `${Math.round(stats.strongest.rate * 100)}% done` : "Still learning"} />
              <Stat label="Usually" value={stats.typical?.label ?? "–"} sub={stats.typical ? `${Math.round(stats.typical.share * 100)}% of check-ins` : "No check-ins yet"} />
              {showStreak && (
                <div className="col-span-2 flex items-center justify-between gap-3 rounded-[14px] border border-dashed border-line-strong px-3 py-2 text-sm text-muted">
                  <span>Streak</span>
                  <span className="font-display font-semibold tabular-nums">
                    {stats.streak} now · best {stats.best}
                  </span>
                </div>
              )}
            </dl>
          </div>
        </section>

        <section aria-labelledby="h-history" className="card p-4 sm:p-5">
          <SectionHeading id="h-history" title="12-week history" className="mb-3" />
          <HistoryGrid habit={habit} userId={subject} today={today} weekStart={settings.weekStart} />
        </section>

        {others.length > 0 && (
          <section aria-labelledby="h-together" className="card p-4 sm:p-5">
            <SectionHeading id="h-together" title="Together" count={participants.length} hand="last 7 days" />
            <ul className="mt-1 divide-y divide-line">
              {participants.map((u) => (
                <ParticipantRow key={u.id} habit={habit} user={u} isMe={u.id === state.meId} today={today} />
              ))}
            </ul>
          </section>
        )}

        <section aria-labelledby="h-log">
          <SectionHeading id="h-log" title="Recent check-ins" count={log.length || undefined} className="mb-3" />
          {log.length === 0 ? (
            <EmptyState compact mood="wave" title="No check-ins yet" body="The first one is the hardest. It'll show up here." />
          ) : (
            <>
              <ul className="space-y-2.5">
                {log.slice(0, logLimit).map((c) => (
                  <CheckInItem key={c.id} c={c} />
                ))}
              </ul>
              {log.length > logLimit && (
                <Button variant="ghost" className="mt-3 w-full" onClick={() => setLogLimit((n) => n + 10)}>
                  Show older check-ins
                </Button>
              )}
            </>
          )}
          <p className="mt-4 text-center text-sm text-muted">
            <Link href="/today/calendar" className="font-semibold text-accent underline-offset-4 hover:underline">
              See everything in the calendar
            </Link>
          </p>
        </section>
      </div>
      <InviteSheet open={inviteOpen} onClose={() => setInviteOpen(false)} habit={habit} />
    </Page>
  );
}
