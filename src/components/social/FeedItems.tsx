"use client";

import { ArrowRight, BellRing, Check, ChevronRight, Crown, Gift, HeartHandshake, MessageCircle, PartyPopper, Send, TrendingUp } from "lucide-react";
import Link from "next/link";
import { AnimatePresence, motion } from "motion/react";
import { useId, useState, type FormEvent, type ReactNode } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { FriendAvatarStack } from "@/components/avatar/FriendAvatarStack";
import { Illustration, IllustrationTile, TINT_SOFT } from "@/components/illustrations/Illustration";
import { ReactionBar } from "@/components/social/ReactionBar";
import { Button } from "@/components/ui/Button";
import { HandNote, Tape } from "@/components/ui/misc";
import { Stamp } from "@/components/ui/Stamp";
import { haptic, useToast } from "@/components/ui/Toast";
import { cn } from "@/lib/cn";
import { formatTime, relativeTime } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { CheckIn, Habit, ID, Nudge, NudgeKind, User } from "@/lib/types";
import { firstName, weeklyBoard } from "./social-helpers";

export type EncourageFn = (toId: ID, habitId?: ID, kind?: NudgeKind) => void;

/* ---------- Comments ---------- */

const COMMENT_MAX = 200;

/** Existing comments + an inline composer. Rendered under a check-in when expanded. */
export function CommentSection({ checkIn, open }: { checkIn: CheckIn; open: boolean }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const inputId = useId();
  const [text, setText] = useState("");
  const comments = checkIn.comments.filter((c) => !state.settings.blockedIds.includes(c.userId));
  const over = text.length > COMMENT_MAX;

  const submit = (e: FormEvent) => {
    e.preventDefault();
    if (!text.trim() || over) return;
    dispatch({ type: "checkin/comment", id: checkIn.id, text });
    haptic(state.settings.haptics);
    setText("");
  };

  return (
    <AnimatePresence initial={false}>
      {open && (
        <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} exit={{ height: 0, opacity: 0 }} transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }} className="overflow-hidden">
          <div className="space-y-2 pt-3">
            {comments.length > 0 && (
              <ul className="space-y-2" aria-label="Comments">
                {comments.map((c) => {
                  const u = state.users[c.userId];
                  return (
                    <li key={c.id} className="flex items-start gap-2">
                      {u && <Avatar user={u} size={26} />}
                      <p className="min-w-0 flex-1 rounded-[12px] rounded-tl-[4px] bg-paper/70 px-3 py-1.5 text-sm leading-snug text-ink">
                        <span className="font-semibold">{firstName(state, c.userId)}</span> {c.text}
                      </p>
                    </li>
                  );
                })}
              </ul>
            )}
            <form onSubmit={submit} className="flex items-center gap-2">
              <label htmlFor={inputId} className="sr-only">
                Write a comment
              </label>
              <input
                id={inputId}
                value={text}
                onChange={(e) => setText(e.target.value)}
                placeholder="Say something nice…"
                maxLength={COMMENT_MAX + 20}
                aria-invalid={over || undefined}
                className="min-h-11 min-w-0 flex-1 rounded-[12px] border border-line-strong bg-cream px-3 text-sm text-ink placeholder:text-faint focus:border-accent focus:outline-none focus:ring-3 focus:ring-accent/15"
              />
              <button type="submit" disabled={!text.trim() || over} aria-label="Post comment" className="grid size-11 shrink-0 place-items-center rounded-[12px] bg-accent text-on-accent transition-transform active:scale-95 disabled:opacity-40">
                <Send size={17} aria-hidden />
              </button>
            </form>
            {over && <p className="text-xs font-medium text-[#a3301f]">Comments are capped at {COMMENT_MAX} characters.</p>}
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

function CommentToggle({ count, open, onClick, size = "md" }: { count: number; open: boolean; onClick: () => void; size?: "sm" | "md" }) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-expanded={open}
      aria-label={open ? "Hide comments" : count ? `Show ${count} comment${count > 1 ? "s" : ""} and reply` : "Comment"}
      className={cn(
        "inline-flex items-center gap-1 rounded-[10px] border px-2 text-xs font-semibold tabular-nums transition-colors",
        size === "sm" ? "h-10 min-w-10 justify-center" : "h-11 min-w-11 justify-center",
        open ? "border-accent/40 bg-accent-soft text-accent" : "border-line bg-cream text-muted hover:text-accent",
      )}
    >
      <MessageCircle size={16} aria-hidden />
      {count > 0 && count}
    </button>
  );
}

function useHabit(id: ID): Habit | undefined {
  const state = useAppState();
  return state.habits.find((h) => h.id === id);
}

/* ---------- Check-in variants ---------- */

/** Compact one-line activity row for plain check-ins. */
export function CheckInRow({ checkIn }: { checkIn: CheckIn }) {
  const state = useAppState();
  const habit = useHabit(checkIn.habitId);
  const user = state.users[checkIn.userId];
  const [open, setOpen] = useState(false);
  if (!habit || !user) return null;
  return (
    <li className="px-3 py-2">
      <div className="flex items-center gap-2.5">
        <Link href={`/friends/${user.id}`} className="shrink-0 rounded-full" aria-label={user.name}>
          <Avatar user={user} size={30} />
        </Link>
        <p className="min-w-0 flex-1 text-sm leading-snug text-ink">
          <span className="font-semibold">{firstName(state, user.id)}</span> <span className="text-muted">did</span> {habit.name}
          <span className="ml-1.5 whitespace-nowrap text-xs text-faint">{formatTime(checkIn.time)}</span>
        </p>
        <IllustrationTile kind={habit.icon} tint={habit.tint} size={26} className="hidden sm:inline-grid" />
        <ReactionBar checkIn={checkIn} />
        <CommentToggle count={checkIn.comments.length} open={open} onClick={() => setOpen((o) => !o)} />
      </div>
      <CommentSection checkIn={checkIn} open={open} />
    </li>
  );
}

/** A check-in with a note or conversation: a fuller card with a quoted note. */
export function CheckInNoteCard({ checkIn }: { checkIn: CheckIn }) {
  const state = useAppState();
  const habit = useHabit(checkIn.habitId);
  const user = state.users[checkIn.userId];
  const [open, setOpen] = useState(checkIn.comments.length > 0 && checkIn.comments.length < 3);
  if (!habit || !user) return null;
  return (
    <article className="card p-4" aria-label={`${user.name} checked in: ${habit.name}`}>
      <header className="flex items-center gap-3">
        <Link href={`/friends/${user.id}`} className="shrink-0 rounded-full" aria-label={user.name}>
          <Avatar user={user} size={40} />
        </Link>
        <div className="min-w-0 flex-1">
          <p className="truncate text-[0.9375rem] text-ink">
            <span className="font-display font-bold">{firstName(state, user.id)}</span> checked in
          </p>
          <p className="flex items-center gap-1.5 text-xs text-muted">
            <IllustrationTile kind={habit.icon} tint={habit.tint} size={18} className="rounded-[6px]" />
            <span className="truncate">{habit.name}</span> · {formatTime(checkIn.time)}
          </p>
        </div>
      </header>
      {checkIn.note && (
        <blockquote className="paper-panel mt-3 rounded-[12px] border border-line px-3.5 py-1 font-hand text-xl leading-[28px] text-ink">
          {checkIn.note}
        </blockquote>
      )}
      <div className="mt-3 flex items-center justify-end gap-1.5">
        <ReactionBar checkIn={checkIn} />
        <CommentToggle count={checkIn.comments.length} open={open} onClick={() => setOpen((o) => !o)} />
      </div>
      <CommentSection checkIn={checkIn} open={open} />
    </article>
  );
}

/** Photo-proof check-in as a taped polaroid. */
export function PolaroidCheckIn({ checkIn, tilt = -1.5 }: { checkIn: CheckIn; tilt?: number }) {
  const state = useAppState();
  const habit = useHabit(checkIn.habitId);
  const user = state.users[checkIn.userId];
  const [open, setOpen] = useState(false);
  if (!habit || !user || !checkIn.photo) return null;
  const photo = checkIn.photo;
  return (
    <article className="flex flex-col gap-3 sm:flex-row sm:items-start" aria-label={`${user.name} shared photo proof for ${habit.name}`}>
      <figure className="relative mx-auto w-[min(100%,15rem)] shrink-0 rounded-[6px] border border-line bg-[#fffaf0] p-2.5 pb-3 shadow-[var(--shadow-lift)] dark:bg-cream sm:mx-0" style={{ transform: `rotate(${tilt}deg)` }}>
        <Tape className="-top-2.5 left-1/2 -translate-x-1/2" rotate={-4} />
        <div className={cn("grid aspect-square place-items-center overflow-hidden rounded-[3px]", TINT_SOFT[photo.tint])} role="img" aria-label={`Photo: ${photo.caption}`}>
          <Illustration kind={photo.motif} size={120} />
        </div>
        <figcaption className="mt-2 text-center font-hand text-xl leading-tight text-ink">{photo.caption}</figcaption>
      </figure>
      <div className="min-w-0 flex-1 sm:pt-3">
        <div className="flex items-center gap-2.5">
          <Link href={`/friends/${user.id}`} className="shrink-0 rounded-full" aria-label={user.name}>
            <Avatar user={user} size={36} />
          </Link>
          <p className="min-w-0 text-sm text-ink">
            <span className="font-display font-bold">{firstName(state, user.id)}</span> brought proof for <span className="font-semibold">{habit.name}</span>
            <span className="block text-xs text-faint">{formatTime(checkIn.time)}</span>
          </p>
        </div>
        {checkIn.note && <p className="mt-2 text-sm leading-relaxed text-muted">“{checkIn.note}”</p>}
        <div className="mt-2.5 flex items-center gap-1.5">
          <ReactionBar checkIn={checkIn} />
          <CommentToggle count={checkIn.comments.length} open={open} onClick={() => setOpen((o) => !o)} />
        </div>
        <CommentSection checkIn={checkIn} open={open} />
      </div>
    </article>
  );
}

/** A friend came back after a missed stretch. Celebrated with a stamp. */
export function ComebackItem({ checkIn, onCelebrate }: { checkIn: CheckIn; onCelebrate: EncourageFn }) {
  const state = useAppState();
  const habit = useHabit(checkIn.habitId);
  const user = state.users[checkIn.userId];
  if (!habit || !user) return null;
  const alreadyCheered = state.nudges.some((n) => n.fromId === state.meId && n.toId === user.id && n.kind === "comeback" && n.at.slice(0, 10) >= checkIn.date);
  return (
    <article className="relative overflow-hidden rounded-[var(--radius-card)] border border-orange/40 bg-orange-soft p-4" aria-label={`${user.name} is back on ${habit.name}`}>
      <div className="flex items-center gap-3">
        <Avatar user={user} size={48} />
        <div className="min-w-0 flex-1">
          <p className="font-display text-[1.0625rem] font-bold leading-snug text-ink">{firstName(state, user.id)} is back!</p>
          <p className="text-sm text-muted">
            Picked “{habit.name}” up again at {formatTime(checkIn.time)}.
          </p>
          <HandNote className="mt-0.5 text-base" rotate={-2}>
            coming back is the skill
          </HandNote>
        </div>
      </div>
      <div className="mt-3 flex flex-wrap items-center gap-2">
        <Button size="sm" className="min-h-11" variant={alreadyCheered ? "secondary" : "primary"} icon={<HeartHandshake size={16} aria-hidden />} onClick={() => onCelebrate(user.id, habit.id, "comeback")}>
          {alreadyCheered ? "Celebrate again" : "Celebrate"}
        </Button>
        <ReactionBar checkIn={checkIn} />
        <Stamp variant="label" text="Back again" rotate={-8} className="ml-auto" />
      </div>
    </article>
  );
}

/* ---------- Nudges ---------- */

const NUDGE_ICON: Record<NudgeKind, typeof BellRing> = { nudge: BellRing, cheer: PartyPopper, comeback: HeartHandshake };
const NUDGE_VERB: Record<NudgeKind, string> = { nudge: "nudged", cheer: "cheered on", comeback: "welcomed back" };

/** Speech-bubble style nudge between friends. */
export function NudgeBubble({ nudge }: { nudge: Nudge }) {
  const state = useAppState();
  const from = state.users[nudge.fromId];
  const to = state.users[nudge.toId];
  if (!from || !to) return null;
  const Icon = NUDGE_ICON[nudge.kind];
  const habit = nudge.habitId ? state.habits.find((h) => h.id === nudge.habitId) : undefined;
  const mine = nudge.fromId === state.meId;
  return (
    <article className={cn("flex items-end gap-2", mine && "flex-row-reverse")} aria-label={`${firstName(state, from.id)} ${NUDGE_VERB[nudge.kind]} ${firstName(state, to.id)}`}>
      <Avatar user={from} size={32} />
      <div className={cn("min-w-0 max-w-[85%]", mine && "text-right")}>
        <p className="mb-1 px-1 text-xs text-muted">
          <span className="font-semibold text-ink">{firstName(state, from.id)}</span> {NUDGE_VERB[nudge.kind]} <span className="font-semibold text-ink">{to.id === state.meId ? "you" : firstName(state, to.id)}</span>
          {habit && <> · {habit.name}</>} · {relativeTime(nudge.at)}
        </p>
        <div
          className={cn(
            "relative inline-flex items-start gap-2 rounded-[18px] border px-3.5 py-2.5 text-left text-[0.9375rem] leading-snug text-ink",
            mine ? "rounded-br-[6px] border-accent/30 bg-accent-soft" : "rounded-bl-[6px] border-line bg-cream",
          )}
        >
          <Icon size={16} className="mt-0.5 shrink-0 text-accent" aria-hidden />
          <span>{nudge.message}</span>
        </div>
      </div>
    </article>
  );
}

/* ---------- Do it together ---------- */

/** Horizontal strip of shared habits a friend did today that I haven't yet. */
export function SharedHabitsStrip({ habits }: { habits: Habit[] }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const today = useToday();
  if (!habits.length) return null;
  return (
    <section aria-labelledby="together-heading" className="relative">
      <div className="mb-2 flex items-baseline justify-between gap-2">
        <h2 id="together-heading" className="font-display text-[1.0625rem] font-bold tracking-[-0.015em] text-ink">
          Do it together
        </h2>
        <HandNote className="text-base">they&apos;re waiting on you</HandNote>
      </div>
      <ul className="no-scrollbar -mx-4 flex snap-x gap-3 overflow-x-auto px-4 pb-2 sm:-mx-0 sm:px-0">
        {habits.map((h, i) => {
          const doneFriends = h.participantIds
            .filter((p) => p !== state.meId && state.checkIns.some((c) => c.habitId === h.id && c.userId === p && c.date === today))
            .map((id) => state.users[id])
            .filter((u): u is User => Boolean(u));
          return (
            <li key={h.id} className="w-[13.5rem] shrink-0 snap-start">
              <div className="card flex h-full flex-col gap-3 p-3.5" style={{ transform: `rotate(${i % 2 ? 0.6 : -0.6}deg)` }}>
                <div className="flex items-center gap-2.5">
                  <IllustrationTile kind={h.icon} tint={h.tint} size={40} rotate={-5} />
                  <p className="min-w-0 font-display text-[0.9375rem] font-bold leading-tight text-ink">{h.name}</p>
                </div>
                <p className="flex items-center gap-2 text-xs text-muted">
                  <FriendAvatarStack users={doneFriends} size={22} doneIds={doneFriends.map((u) => u.id)} />
                  {doneFriends.map((u) => u.name.split(" ")[0]).join(" & ")} done
                </p>
                <Button
                  size="sm"
                  className="min-h-11 mt-auto"
                  icon={<Check size={16} strokeWidth={2.6} aria-hidden />}
                  onClick={() => {
                    dispatch({ type: "checkin/complete", habitId: h.id, date: today });
                    haptic(state.settings.haptics, [12, 30, 12]);
                    toast({ title: `${h.name}: done together`, body: "Your friends will see you matched them.", motif: h.icon, action: { label: "Undo", onClick: () => dispatch({ type: "checkin/undo", habitId: h.id, date: today }) } });
                  }}
                >
                  Mark mine done
                </Button>
              </div>
            </li>
          );
        })}
      </ul>
    </section>
  );
}

/* ---------- Weekly board ---------- */

const PODIUM_STYLE = [
  { h: "h-20", bg: "bg-gold-soft", label: "1st" },
  { h: "h-14", bg: "bg-accent-soft", label: "2nd" },
  { h: "h-10", bg: "bg-sage-soft", label: "3rd" },
];

/** Notebook-style weekly ranking: podium for the top three, everyone else simply "on the board". */
export function WeeklyBoard() {
  const state = useAppState();
  const today = useToday();
  const { podium, others, improved } = weeklyBoard(state, today);
  if (!podium.length) return null;
  const order = podium.length === 3 ? [1, 0, 2] : podium.map((_, i) => i);
  return (
    <section aria-labelledby="board-heading" className="paper-panel relative overflow-hidden rounded-[var(--radius-card)] border border-line px-4 pb-4 pt-3 shadow-[var(--shadow)]">
      <span aria-hidden className="absolute inset-y-0 left-8 w-px bg-rose/50" />
      <div className="flex items-baseline justify-between gap-2 pl-6">
        <h2 id="board-heading" className="font-display text-[1.0625rem] font-bold text-ink">
          This week&apos;s board
        </h2>
        <Link href="/recap" className="inline-flex min-h-11 items-center gap-0.5 text-sm font-semibold text-accent hover:underline">
          Recap <ChevronRight size={16} aria-hidden />
        </Link>
      </div>
      <ol className="mt-2 flex items-end justify-center gap-3 pl-6" aria-label="Top check-ins this week">
        {order.map((idx) => {
          const p = podium[idx];
          const u = state.users[p.userId];
          const s = PODIUM_STYLE[idx];
          return (
            <li key={p.userId} className="flex w-20 flex-col items-center gap-1 text-center">
              {idx === 0 && <Crown size={18} className="text-gold" fill="currentColor" aria-hidden />}
              {u && <Avatar user={u} size={idx === 0 ? 48 : 40} />}
              <span className="max-w-full truncate font-display text-sm font-bold text-ink">{firstName(state, p.userId)}</span>
              <span className={cn("flex w-full flex-col items-center justify-start rounded-t-[10px] border border-b-0 border-line pt-1", s.h, s.bg)}>
                <span className="font-display text-xs font-extrabold text-ink">{s.label}</span>
                <span className="text-[0.6875rem] tabular-nums text-muted">{p.completed} done</span>
              </span>
            </li>
          );
        })}
      </ol>
      {improved && (
        <p className="mt-3 flex items-center gap-2 pl-6 text-sm text-ink">
          <TrendingUp size={16} className="shrink-0 text-sage-ink" aria-hidden />
          <span>
            <span className="font-semibold">{firstName(state, improved.userId)}</span> {improved.userId === state.meId ? "are" : "is"} the most improved, up {Math.round(improved.delta * 100)} points.
          </span>
        </p>
      )}
      {others.length > 0 && (
        <p className="mt-2 flex flex-wrap items-center gap-2 pl-6 text-sm text-muted">
          <span className="font-hand text-lg text-accent">also on the board:</span>
          {others.map((o) => firstName(state, o.userId)).join(", ")}
        </p>
      )}
    </section>
  );
}

/* ---------- Teasers ---------- */

export function QuizTeaser() {
  const state = useAppState();
  const unanswered = state.quizzes.filter((q) => !q.votes[state.meId]).length;
  const sample = state.quizzes.find((q) => !q.votes[state.meId]) ?? state.quizzes[0];
  return (
    <Link href="/friends/quizzes" className="group relative block overflow-hidden rounded-[var(--radius-card)] border border-line bg-sky-soft p-4 transition-transform hover:-translate-y-0.5">
      <div className="flex items-start gap-3">
        <span className="grid size-11 shrink-0 rotate-[-6deg] place-items-center rounded-[12px] border border-line bg-cream font-display text-xl font-extrabold text-accent" aria-hidden>
          ?
        </span>
        <div className="min-w-0 flex-1">
          <p className="eyebrow">Friend quizzes</p>
          <p className="mt-0.5 font-display text-[1.0625rem] font-bold leading-snug text-ink">{sample ? `“${sample.prompt}”` : "Ask your circle something silly"}</p>
          <p className="mt-1 text-sm text-muted">{unanswered ? `${unanswered} question${unanswered > 1 ? "s" : ""} waiting for your vote` : "You're all caught up. Ask a new one?"}</p>
        </div>
        <ArrowRight size={18} className="mt-1 shrink-0 text-accent transition-transform group-hover:translate-x-0.5" aria-hidden />
      </div>
    </Link>
  );
}

export function DayDivider({ children }: { children: ReactNode }) {
  return (
    <div className="flex items-center gap-3 pt-2" role="presentation">
      <span className="font-hand text-xl text-accent">{children}</span>
      <span className="hand-divider flex-1" aria-hidden />
    </div>
  );
}

/** Friend row for sidebars: avatar, name, and quick Nudge / Gift actions. */
export function FriendQuickRow({ user, onNudge, onGift }: { user: User; onNudge: () => void; onGift: () => void }) {
  return (
    <li className="flex items-center gap-2.5 py-1.5">
      <Link href={`/friends/${user.id}`} className="flex min-h-11 min-w-0 flex-1 items-center gap-2.5 rounded-[12px] hover:text-accent">
        <Avatar user={user} size={34} />
        <span className="min-w-0">
          <span className="block truncate text-sm font-semibold text-ink">{user.name}</span>
          <span className="block truncate text-xs text-muted">@{user.handle}</span>
        </span>
      </Link>
      <button type="button" onClick={onNudge} aria-label={`Nudge ${user.name.split(" ")[0]}`} title="Nudge" className="grid size-11 shrink-0 place-items-center rounded-[11px] text-muted transition-colors hover:bg-accent-soft hover:text-accent">
        <BellRing size={17} aria-hidden />
      </button>
      <button type="button" onClick={onGift} aria-label={`Send ${user.name.split(" ")[0]} a gift`} title="Gift" className="grid size-11 shrink-0 place-items-center rounded-[11px] text-muted transition-colors hover:bg-accent-soft hover:text-accent">
        <Gift size={17} aria-hidden />
      </button>
    </li>
  );
}
