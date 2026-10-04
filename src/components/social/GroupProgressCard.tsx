"use client";

import { Crown, LogOut, PartyPopper, Plus, UserPlus } from "lucide-react";
import Link from "next/link";
import { Avatar } from "@/components/avatar/Avatar";
import { FriendAvatarStack } from "@/components/avatar/FriendAvatarStack";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { Button } from "@/components/ui/Button";
import { HandNote } from "@/components/ui/misc";
import { Stamp } from "@/components/ui/Stamp";
import { haptic, useToast } from "@/components/ui/Toast";
import { cn } from "@/lib/cn";
import { diffDays, formatDate } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { Challenge, Tint, User } from "@/lib/types";
import { challengeTotal, firstName, MILESTONES } from "./social-helpers";

const FILL: Record<Tint, string> = {
  burgundy: "bg-accent",
  rose: "bg-rose",
  orange: "bg-orange",
  gold: "bg-gold",
  sage: "bg-sage",
  sky: "bg-sky",
  cream: "bg-accent",
};

/** Collective progress bar with milestone ticks at 25/50/75/100%. */
export function CollectiveBar({ total, goal, tint = "burgundy", label, size = "md" }: { total: number; goal: number; tint?: Tint; label: string; size?: "sm" | "md" }) {
  const pct = Math.max(0, Math.min(1, goal ? total / goal : 0));
  return (
    <div className="relative">
      <div
        role="progressbar"
        aria-label={label}
        aria-valuemin={0}
        aria-valuemax={goal}
        aria-valuenow={Math.min(total, goal)}
        aria-valuetext={`${total} of ${goal}`}
        className={cn("relative w-full overflow-hidden rounded-[8px] border border-line bg-paper-deep/70", size === "md" ? "h-4" : "h-2.5")}
      >
        <div className={cn("h-full rounded-[7px] transition-[width] duration-700 ease-[var(--ease-out-soft)]", FILL[tint])} style={{ width: `${pct * 100}%` }} />
        {MILESTONES.slice(0, 3).map((m) => (
          <span key={m} aria-hidden className={cn("absolute inset-y-0 w-px", pct * 100 >= m ? "bg-cream/70" : "bg-line-strong")} style={{ left: `${m}%` }} />
        ))}
      </div>
    </div>
  );
}

function endsLabel(endDate: string, today: string) {
  const d = diffDays(endDate, today);
  if (d < 0) return `Ended ${formatDate(endDate)}`;
  if (d === 0) return "Ends today";
  if (d === 1) return "Ends tomorrow";
  if (d < 7) return `Ends ${formatDate(endDate, { weekday: "long" })}`;
  return `Ends ${formatDate(endDate)}`;
}

/**
 * A group challenge. `summary` is a compact block for feeds and lists; `full` adds milestone
 * reactions, kind contribution list, and logging/joining controls.
 */
export function GroupProgressCard({ challenge: c, variant = "summary", tint, showGroup = true, className }: { challenge: Challenge; variant?: "summary" | "full"; tint?: Tint; showGroup?: boolean; className?: string }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const today = useToday();
  const me = state.meId;
  const group = state.groups.find((g) => g.id === c.groupId);
  const t = tint ?? group?.tint ?? "burgundy";
  const total = challengeTotal(c);
  const pct = c.goal ? Math.min(100, Math.round((total / c.goal) * 100)) : 0;
  const done = total >= c.goal;
  const joined = c.participantIds.includes(me);
  const isMember = group?.memberIds.includes(me) ?? false;
  const ended = c.endDate < today;
  const participants = c.participantIds.map((id) => state.users[id]).filter((u): u is User => Boolean(u) && !state.settings.blockedIds.includes(u.id));
  const mine = c.contributions[me] ?? 0;

  const log = () => {
    dispatch({ type: "challenge/log", id: c.id });
    haptic(state.settings.haptics);
    const after = total + 1;
    toast({ title: after >= c.goal && total < c.goal ? "Goal reached together!" : `Logged one ${c.unit.replace(/s$/, "")}`, body: `${Math.min(after, c.goal)} of ${c.goal} ${c.unit}`, motif: c.icon });
  };

  if (variant === "summary") {
    return (
      <article className={cn("card relative p-4", className)} aria-label={`Challenge: ${c.title}`}>
        <div className="flex items-start gap-3">
          <IllustrationTile kind={c.icon} tint={t} size={44} rotate={-4} />
          <div className="min-w-0 flex-1">
            {showGroup && group && <p className="eyebrow truncate">{group.name}</p>}
            <h3 className="font-display text-[1.0625rem] font-bold leading-snug text-ink">
              <Link href={`/groups/${c.groupId}`} className="after:absolute after:inset-0 after:rounded-[var(--radius-card)] hover:underline focus-visible:outline-none">
                {c.title}
              </Link>
            </h3>
          </div>
          {done ? <Stamp variant="label" text="Done!" rotate={8} className="shrink-0" /> : <span className="shrink-0 font-display text-lg font-extrabold tabular-nums text-accent">{pct}%</span>}
        </div>
        <div className="mt-3">
          <CollectiveBar total={total} goal={c.goal} tint={t} label={`${c.title}: ${total} of ${c.goal} ${c.unit}`} size="sm" />
        </div>
        <div className="mt-2.5 flex flex-wrap items-center justify-between gap-2 text-xs text-muted">
          <span className="tabular-nums">
            <span className="font-semibold text-ink">{total}</span> of {c.goal} {c.unit} · {endsLabel(c.endDate, today)}
          </span>
          <span className="flex items-center gap-2">
            {joined && mine > 0 && <span>You chipped in {mine}</span>}
            <FriendAvatarStack users={participants} size={22} max={5} label={`${participants.length} taking part`} />
          </span>
        </div>
      </article>
    );
  }

  // Full variant
  const contributors = participants.filter((u) => (c.contributions[u.id] ?? 0) > 0);
  const topValue = Math.max(0, ...contributors.map((u) => c.contributions[u.id] ?? 0));
  const tops = contributors.filter((u) => (c.contributions[u.id] ?? 0) === topValue);
  const top = tops.length === 1 ? tops[0] : undefined;
  const rest = contributors.filter((u) => u.id !== top?.id).sort((a, b) => firstName(state, a.id).localeCompare(firstName(state, b.id)));
  const notYet = participants.filter((u) => !(c.contributions[u.id] > 0));

  return (
    <article className={cn("card relative overflow-hidden p-4 sm:p-5", className)} aria-labelledby={`ch-${c.id}`}>
      <div className="flex items-start gap-3">
        <IllustrationTile kind={c.icon} tint={t} size={52} rotate={-4} />
        <div className="min-w-0 flex-1">
          <h3 id={`ch-${c.id}`} className="font-display text-lg font-bold leading-snug text-ink">
            {c.title}
          </h3>
          {c.description && <p className="mt-0.5 text-sm leading-relaxed text-muted">{c.description}</p>}
          <p className="mt-1 text-xs text-faint">
            {formatDate(c.startDate)} – {formatDate(c.endDate)} · {endsLabel(c.endDate, today)}
          </p>
        </div>
        {done && <Stamp variant="label" text="Goal met" rotate={8} className="shrink-0" />}
      </div>

      <div className="mt-4">
        <div className="mb-1.5 flex items-baseline justify-between gap-2">
          <p className="font-display text-sm text-muted">
            <span className="text-2xl font-extrabold tabular-nums text-ink">{total}</span> / {c.goal} {c.unit}
          </p>
          <span className="font-display text-sm font-bold tabular-nums text-accent">{pct}%</span>
        </div>
        <CollectiveBar total={total} goal={c.goal} tint={t} label={`${c.title}: ${total} of ${c.goal} ${c.unit}`} />
      </div>

      <ul className="mt-3 grid grid-cols-4 gap-1.5" aria-label="Milestones">
        {MILESTONES.map((m) => {
          const reached = pct >= m;
          const reactors = c.milestoneReactions[String(m)] ?? [];
          const mineReacted = reactors.includes(me);
          return (
            <li key={m}>
              <button
                type="button"
                disabled={!reached}
                aria-pressed={mineReacted}
                aria-label={reached ? `${m}% milestone reached. ${mineReacted ? "Remove your toast" : "Toast it"}. ${reactors.length} toasted.` : `${m}% milestone, not reached yet`}
                onClick={() => {
                  dispatch({ type: "challenge/reactMilestone", id: c.id, milestone: m });
                  haptic(state.settings.haptics);
                }}
                className={cn(
                  "flex min-h-12 w-full flex-col items-center justify-center rounded-[12px] border px-1 py-1.5 transition-colors",
                  !reached && "border-dashed border-line-strong text-faint",
                  reached && !mineReacted && "border-line bg-paper/60 text-ink hover:bg-accent-soft/60",
                  mineReacted && "border-accent bg-accent-soft text-accent",
                )}
              >
                <span className="font-display text-sm font-bold tabular-nums">{m}%</span>
                <span className="flex items-center gap-1 text-[0.6875rem] font-semibold tabular-nums">
                  {reached ? (
                    <>
                      <PartyPopper size={12} aria-hidden /> {reactors.length || "Toast"}
                    </>
                  ) : (
                    "Soon"
                  )}
                </span>
              </button>
            </li>
          );
        })}
      </ul>

      <section className="mt-5" aria-label="Everyone who chipped in">
        <h4 className="eyebrow">Everyone who chipped in</h4>
        {top && (
          <div className="mt-2 flex items-center gap-3 rounded-[14px] bg-gold-soft px-3 py-2.5">
            <span className="relative">
              <Avatar user={top} size={40} />
              <Crown size={16} className="absolute -right-1 -top-2 rotate-12 text-gold" fill="currentColor" aria-hidden />
            </span>
            <p className="min-w-0 flex-1 text-sm text-ink">
              <span className="font-display font-bold">{firstName(state, top.id)}</span> led the way with {topValue} {c.unit}
            </p>
            <HandNote className="hidden text-base sm:inline-block" rotate={-5}>
              thank you!
            </HandNote>
          </div>
        )}
        {rest.length > 0 && (
          <ul className="mt-2 space-y-1.5">
            {rest.map((u) => {
              const v = c.contributions[u.id] ?? 0;
              return (
                <li key={u.id} className="flex items-center gap-2.5">
                  <Avatar user={u} size={28} />
                  <span className="w-16 shrink-0 truncate text-sm font-semibold text-ink">{firstName(state, u.id)}</span>
                  <span className="h-2 flex-1 overflow-hidden rounded-full bg-paper-deep/70" aria-hidden>
                    <span className={cn("block h-full rounded-full opacity-70", FILL[t])} style={{ width: `${topValue ? (v / topValue) * 100 : 0}%` }} />
                  </span>
                  <span className="sr-only">chipped in</span>
                  {u.id === me && <span className="shrink-0 text-xs tabular-nums text-muted">{v}</span>}
                </li>
              );
            })}
          </ul>
        )}
        {contributors.length === 0 && <p className="mt-2 text-sm text-muted">Nobody has logged yet. The first one is the best one.</p>}
        {notYet.length > 0 && contributors.length > 0 && (
          <p className="mt-2 flex items-center gap-2 text-xs text-muted">
            <FriendAvatarStack users={notYet} size={20} max={4} /> also in the challenge
          </p>
        )}
      </section>

      {!ended && isMember && (
        <div className="mt-5 flex flex-wrap items-center gap-2">
          {joined ? (
            <>
              <Button onClick={log} icon={<Plus size={17} aria-hidden />}>
                Log one
              </Button>
              <span className="text-sm text-muted">You&apos;ve added {mine}</span>
              <Button
                variant="ghost"
                size="sm"
                className="min-h-11 ml-auto"
                icon={<LogOut size={15} aria-hidden />}
                onClick={() => {
                  dispatch({ type: "challenge/leave", id: c.id });
                  toast({ title: "You stepped out of the challenge", body: "Your earlier contributions still count." });
                }}
              >
                Step out
              </Button>
            </>
          ) : (
            <Button
              variant="soft"
              icon={<UserPlus size={17} aria-hidden />}
              onClick={() => {
                dispatch({ type: "challenge/join", id: c.id });
                toast({ title: `Joined “${c.title}”`, motif: c.icon });
              }}
            >
              Join challenge
            </Button>
          )}
        </div>
      )}
    </article>
  );
}
