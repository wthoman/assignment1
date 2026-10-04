"use client";

import { AnimatePresence, LayoutGroup, motion } from "motion/react";
import { CalendarDays, ChevronRight, Pause, Plus, Undo2 } from "lucide-react";
import Link from "next/link";
import { useMemo, useState } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { HabitCard } from "@/components/habits/HabitCard";
import { ProgressGrid, type PlannerDay } from "@/components/habits/ProgressGrid";
import { WeeklyDateStrip } from "@/components/habits/WeeklyDateStrip";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { Mascot } from "@/components/illustrations/Mascot";
import { HeaderActions } from "@/components/shell/AppShell";
import { ButtonLink } from "@/components/ui/Button";
import { ProgressBar, ProgressRing } from "@/components/ui/controls";
import { EmptyState, HandNote, SectionHeading, Tape } from "@/components/ui/misc";
import { dayMessage } from "@/lib/encouragement";
import { formatDate, formatLongDate, formatTime, greeting, weekDates } from "@/lib/dates";
import { cn } from "@/lib/cn";
import { useToday } from "@/lib/hooks";
import { dayProgress, isScheduled, myHabits, todayEntries, type TodaySection } from "@/lib/selectors/habits";
import { consistencyScore, rollingWeeks } from "@/lib/selectors/stats";
import { useAppState, useMe } from "@/lib/store/provider";

const SECTIONS: { key: TodaySection; title: string; hand?: string; empty?: string }[] = [
  { key: "up-next", title: "Up next" },
  { key: "shared", title: "Shared today", hand: "with friends" },
  { key: "completed", title: "Completed" },
  { key: "optional", title: "Optional today", hand: "bonus round" },
];

export default function TodayPage() {
  const state = useAppState();
  const me = useMe();
  const today = useToday();
  const [selected, setSelected] = useState(today);
  const ws = state.settings.weekStart;

  const entries = useMemo(() => todayEntries(state, selected), [state, selected]);
  const progress = dayProgress(state, state.meId, selected);
  const week: PlannerDay[] = useMemo(
    () =>
      weekDates(selected, ws).map((d) => {
        const p = dayProgress(state, state.meId, d);
        return { date: d, done: p.done, total: p.total, bonus: p.bonus };
      }),
    [state, selected, ws],
  );
  const score = useMemo(() => consistencyScore(state, state.meId, today), [state, today]);
  const paused = myHabits(state, { includeInactive: true }).filter((h) => h.status === "paused");
  const isToday = selected === today;
  const firstName = me.name.split(" ")[0];
  const allDone = progress.total > 0 && progress.done >= progress.total;

  return (
    <div className="mx-auto w-full max-w-[1120px] px-4 sm:px-6">
      <header className="pt-[max(0.75rem,env(safe-area-inset-top))] md:pt-7">
        <div className="flex min-h-12 items-center gap-2">
          <div className="min-w-0 flex-1">
            <p className="eyebrow">{formatLongDate(today)}</p>
            <h1 className="truncate font-display text-[1.625rem] font-extrabold leading-tight tracking-[-0.035em] md:text-[1.875rem]">
              {greeting()}, <span className="scribble">{firstName}</span>
            </h1>
          </div>
          <HeaderActions />
        </div>
      </header>

      <div className="lg:grid lg:grid-cols-[minmax(0,1fr)_320px] lg:gap-8">
        <div className="min-w-0">
          <div className="mt-3 space-y-3">
            <WeeklyDateStrip selected={selected} today={today} weekStart={ws} onSelect={setSelected} fillFor={(d) => dayProgress(state, state.meId, d)} />

            <AnimatePresence initial={false}>
              {!isToday && (
                <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} exit={{ height: 0, opacity: 0 }} className="overflow-hidden">
                  <div className="flex items-center gap-3 rounded-[14px] border border-dashed border-line-strong bg-cream/70 px-3 py-2">
                    <p className="min-w-0 flex-1 text-sm text-muted">
                      {selected > today ? (
                        <>Peeking at <b className="text-ink">{formatDate(selected, { weekday: "long", month: "short", day: "numeric" })}</b>. Check-ins open on the day.</>
                      ) : (
                        <>Viewing <b className="text-ink">{formatDate(selected, { weekday: "long", month: "short", day: "numeric" })}</b>. Forgot to log something? You still can.</>
                      )}
                    </p>
                    <button type="button" onClick={() => setSelected(today)} className="inline-flex min-h-10 shrink-0 items-center gap-1 rounded-[10px] px-2.5 text-sm font-semibold text-accent hover:bg-accent-soft">
                      <Undo2 size={15} aria-hidden /> Today
                    </button>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Planner summary */}
            <section aria-labelledby="summary-h" className="card relative overflow-hidden p-4">
              <Tape className="-top-1.5 right-10" rotate={4} />
              <h2 id="summary-h" className="sr-only">
                Daily progress
              </h2>
              <div className="flex items-center gap-4">
                <ProgressRing value={progress.ratio} size={68} stroke={7} label={`${progress.done} of ${progress.total} habits done`}>
                  <span className="text-center font-display leading-none">
                    <span className="text-xl font-extrabold text-ink tabular-nums">{progress.done}</span>
                    <span className="text-sm font-bold text-faint">/{progress.total}</span>
                  </span>
                </ProgressRing>
                <div className="min-w-0 flex-1">
                  <p className="font-display text-[1.0625rem] font-bold leading-snug text-ink">
                    {progress.total === 0 ? "A free day. Rest counts too." : dayMessage(state.settings.encouragement, { done: progress.done, total: progress.total, name: firstName })}
                  </p>
                  <p className="mt-1 flex flex-wrap gap-x-3 gap-y-0.5 text-[0.8125rem] text-muted">
                    <span>
                      <b className="font-semibold text-ink">{score.score}%</b> consistency · 4 wks
                    </span>
                    {progress.bonus > 0 && (
                      <span>
                        <b className="font-semibold text-sage-ink">+{progress.bonus}</b> bonus
                      </span>
                    )}
                  </p>
                </div>
              </div>
              <div className="hand-divider my-3" aria-hidden />
              <div className="flex items-center justify-between">
                <p className="eyebrow">This week</p>
                <Link href="/today/calendar" className="-mr-1 inline-flex min-h-9 items-center gap-1 rounded-[10px] px-2 text-[0.8125rem] font-semibold text-accent hover:bg-accent-soft">
                  <CalendarDays size={15} aria-hidden /> Month view
                </Link>
              </div>
              <div className="mt-1">
                <ProgressGrid days={week} today={today} selected={selected} onSelect={setSelected} />
              </div>
            </section>
          </div>

          {/* Habit sections */}
          <LayoutGroup>
            <div className="mt-6 space-y-6">
              {entries.length === 0 ? (
                <EmptyState
                  mood="sleepy"
                  title={myHabits(state).length ? "Nothing scheduled" : "No habits yet"}
                  body={myHabits(state).length ? "No habits land on this day. Enjoy the blank page." : "Start with something tiny. You can always add more later."}
                  action={
                    <ButtonLink href="/habits/new" icon={<Plus size={18} />}>
                      Add a habit
                    </ButtonLink>
                  }
                />
              ) : (
                <>
                  {allDone && isToday && (
                    <motion.div initial={{ opacity: 0, scale: 0.97 }} animate={{ opacity: 1, scale: 1 }} className="relative flex items-center gap-4 overflow-hidden rounded-[var(--radius-card)] bg-accent p-4 text-on-accent">
                      <Mascot mood="proud" size={76} className="shrink-0" />
                      <div>
                        <p className="font-display text-lg font-extrabold leading-tight">Every box is stamped.</p>
                        <p className="mt-0.5 text-sm opacity-85">Nothing else required today. Optional ones are pure bonus.</p>
                      </div>
                    </motion.div>
                  )}
                  {SECTIONS.map((sec) => {
                    const list = entries.filter((e) => e.section === sec.key);
                    if (!list.length) return null;
                    return (
                      <section key={sec.key} aria-labelledby={`sec-${sec.key}`} className="space-y-2.5">
                        <SectionHeading id={`sec-${sec.key}`} title={sec.title} count={list.length} hand={sec.hand} />
                        <div className="space-y-2.5">
                          <AnimatePresence initial={false} mode="popLayout">
                            {list.map((e, i) => (
                              <HabitCard key={e.habit.id} habit={e.habit} date={selected} today={today} index={i} />
                            ))}
                          </AnimatePresence>
                        </div>
                      </section>
                    );
                  })}
                </>
              )}

              {paused.length > 0 && (
                <Link href={`/habits/${paused[0].id}`} className="flex min-h-12 items-center gap-2 rounded-[14px] border border-dashed border-line-strong px-3 text-sm text-muted hover:bg-cream/70">
                  <Pause size={15} aria-hidden />
                  <span className="flex-1">
                    {paused.length} paused: {paused.map((p) => p.name).join(", ")}
                  </span>
                  <ChevronRight size={16} aria-hidden />
                </Link>
              )}
            </div>
          </LayoutGroup>
        </div>

        <TodayAside today={today} score={score.score} />
      </div>
    </div>
  );
}

/** Secondary column: friends' day, group challenge and upcoming reminders. */
function TodayAside({ today, score }: { today: string; score: number }) {
  const state = useAppState();
  const me = state.users[state.meId];
  const weeks = useMemo(() => rollingWeeks(state, state.meId, today), [state, today]);
  const friendsToday = me.friendIds
    .map((id) => {
      const cis = state.checkIns.filter((c) => c.userId === id && c.date === today);
      return { user: state.users[id], count: cis.length, last: cis.map((c) => c.time).sort().pop() };
    })
    .filter((f) => f.user && f.count > 0)
    .sort((a, b) => b.count - a.count);
  const challenge = state.challenges.find((c) => c.participantIds.includes(state.meId) && c.endDate >= today);
  const total = challenge ? Object.values(challenge.contributions).reduce((a, b) => a + b, 0) : 0;
  const reminders = myHabits(state)
    .filter((h) => h.remindersOn && isScheduled(h, today))
    .flatMap((h) => h.reminderTimes.map((t) => ({ h, t })))
    .filter(({ h }) => !state.checkIns.some((c) => c.habitId === h.id && c.userId === state.meId && c.date === today))
    .sort((a, b) => a.t.localeCompare(b.t))
    .slice(0, 3);

  return (
    <aside aria-label="Your circle today" className="mt-8 space-y-5 lg:sticky lg:top-6 lg:mt-7 lg:self-start">
      <section className="card p-4">
        <div className="flex items-baseline justify-between">
          <h2 className="font-display text-base font-bold">Rolling consistency</h2>
          <span className="font-display text-2xl font-extrabold text-accent tabular-nums">{score}%</span>
        </div>
        <div className="mt-3 flex h-16 items-end gap-2" role="img" aria-label={`Last four weeks: ${weeks.map((w) => Math.round(w.rate * 100) + "%").join(", ")}`}>
          {weeks.map((w, i) => (
            <div key={w.from} className="flex flex-1 flex-col items-center gap-1">
              <div className={cn("w-full rounded-[6px] transition-[height] duration-700", i === weeks.length - 1 ? "bg-accent" : "bg-rose")} style={{ height: `${Math.max(8, w.rate * 52)}px` }} />
              <span className="text-[0.625rem] font-semibold text-faint">{i === weeks.length - 1 ? "now" : `-${weeks.length - 1 - i}w`}</span>
            </div>
          ))}
        </div>
        <p className="mt-2 text-xs leading-relaxed text-muted">Missed days don&apos;t reset anything. One per week is forgiven automatically.</p>
        <Link href="/profile" className="mt-1 inline-flex min-h-9 items-center text-[0.8125rem] font-semibold text-accent hover:underline">
          How it&apos;s calculated
        </Link>
      </section>

      <section className="space-y-2">
        <SectionHeading title="Friends today" action={<Link href="/friends" className="text-[0.8125rem] font-semibold text-accent hover:underline">Feed</Link>} />
        {friendsToday.length ? (
          <ul className="card-flat divide-y divide-line">
            {friendsToday.slice(0, 5).map((f) => (
              <li key={f.user.id}>
                <Link href={`/friends/${f.user.id}`} className="flex min-h-13 items-center gap-3 px-3 py-2 hover:bg-accent-soft/40">
                  <Avatar user={f.user} size={34} />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-semibold">{f.user.name}</span>
                    <span className="block text-xs text-muted">
                      {f.count} check-in{f.count > 1 ? "s" : ""}
                      {f.last ? ` · last at ${formatTime(f.last)}` : ""}
                    </span>
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        ) : (
          <EmptyState compact mood="sleepy" title="Quiet so far" body="Nobody's checked in yet today." />
        )}
      </section>

      {challenge && (
        <Link href={`/groups/${challenge.groupId}`} className="card relative block overflow-hidden p-4 transition-transform hover:-translate-y-0.5">
          <div className="flex items-center gap-3">
            <IllustrationTile kind={challenge.icon} tint="sky" size={40} rotate={-4} />
            <div className="min-w-0">
              <p className="eyebrow">Group challenge</p>
              <p className="truncate font-display font-bold">{challenge.title}</p>
            </div>
          </div>
          <ProgressBar className="mt-3" value={total} max={challenge.goal} label={`${challenge.title} progress`} tone="sky" />
          <p className="mt-1.5 text-xs text-muted">
            {total} of {challenge.goal} {challenge.unit} · you added {challenge.contributions[state.meId] ?? 0}
          </p>
        </Link>
      )}

      {reminders.length > 0 && (
        <section className="paper-panel rounded-[var(--radius-card)] border border-line px-4 pb-3 pt-2.5">
          <h2 className="font-display text-sm font-bold leading-7">Reminders still open today</h2>
          <ul>
            {reminders.map(({ h, t }) => (
              <li key={h.id + t} className="flex h-7 items-center justify-between text-sm">
                <span className="truncate">{h.name}</span>
                <span className="font-hand text-lg text-accent">{formatTime(t)}</span>
              </li>
            ))}
          </ul>
        </section>
      )}
      <HandNote className="hidden px-2 lg:block" rotate={-2}>
        p.s. comebacks earn stickers too
      </HandNote>
    </aside>
  );
}
