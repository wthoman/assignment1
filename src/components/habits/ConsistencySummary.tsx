"use client";

import { AnimatePresence, motion } from "motion/react";
import { ChevronDown, Minus, TrendingDown, TrendingUp } from "lucide-react";
import { useId, useMemo, useState } from "react";
import { cn } from "@/lib/cn";
import { addDays, formatDate } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { comebackCount, consistencyScore, rollingWeeks, totalCompletions } from "@/lib/selectors/stats";
import { useAppState } from "@/lib/store/provider";

export function consistencyWord(score: number) {
  if (score >= 90) return "Rock steady";
  if (score >= 75) return "Steady";
  if (score >= 55) return "Finding a rhythm";
  if (score >= 30) return "Warming up";
  return "Fresh start";
}

const WEEK_LABELS = ["3 wk ago", "2 wk ago", "Last wk", "This wk"];

/** Four rolling weekly bars (oldest first). Values are 0–1 rates. */
export function WeekBars({
  weeks,
  height = 64,
  className,
  barClass = "bg-accent",
}: {
  weeks: { rate: number; completed: number; scheduled: number; label: string; detail?: string }[];
  height?: number;
  className?: string;
  barClass?: string;
}) {
  return (
    <div className={className}>
      <div className="flex items-end gap-2 border-b border-line-strong" style={{ height }} aria-hidden>
        {weeks.map((w, i) => {
          const last = i === weeks.length - 1;
          return (
            <div key={w.label} className="flex h-full flex-1 flex-col items-center justify-end" title={`${w.label}: ${Math.round(w.rate * 100)}% (${w.completed} of ${w.scheduled})`}>
              <span className="mb-0.5 font-display text-[0.6875rem] font-bold tabular-nums text-muted">{w.scheduled ? `${Math.round(w.rate * 100)}` : "–"}</span>
              <motion.span
                className={cn("block w-full max-w-9 rounded-t-[4px]", last ? barClass : cn(barClass, "opacity-45"))}
                initial={{ height: 0 }}
                animate={{ height: `${Math.max(w.scheduled ? 4 : 0, w.rate * (height - 18))}px` }}
                transition={{ type: "spring", stiffness: 260, damping: 30, delay: i * 0.05 }}
              />
            </div>
          );
        })}
      </div>
      <div className="mt-1 flex gap-2" aria-hidden>
        {weeks.map((w) => (
          <span key={w.label} className="flex-1 truncate text-center text-[0.625rem] font-semibold uppercase tracking-[0.04em] text-faint">
            {w.label}
          </span>
        ))}
      </div>
      <ul className="sr-only">
        {weeks.map((w) => (
          <li key={w.label}>
            {w.label}
            {w.detail ? ` (${w.detail})` : ""}: {w.scheduled ? `${Math.round(w.rate * 100)}%, ${w.completed} of ${w.scheduled} scheduled check-ins` : "nothing scheduled"}
          </li>
        ))}
      </ul>
    </div>
  );
}

/** Rolling consistency card: score, how it's calculated, 4-week bars, totals and change vs the previous period. */
export function ConsistencySummary({ userId, compact = false, className }: { userId?: string; compact?: boolean; className?: string }) {
  const state = useAppState();
  const today = useToday();
  const uid = userId ?? state.meId;
  const isMe = uid === state.meId;
  const [open, setOpen] = useState(false);
  const panelId = useId();

  const data = useMemo(() => {
    const now = consistencyScore(state, uid, today);
    const prev = consistencyScore(state, uid, addDays(today, -28));
    const weeks = rollingWeeks(state, uid, today, 4).map((w, i) => ({ ...w, label: WEEK_LABELS[i], detail: `${formatDate(w.from)} – ${formatDate(w.to)}` }));
    return {
      now,
      delta: prev.scheduled ? now.score - prev.score : null,
      weeks,
      total: totalCompletions(state, uid),
      comebacks: comebackCount(state, uid, addDays(today, -27), today),
    };
  }, [state, uid, today]);

  const { now, delta } = data;
  const DeltaIcon = delta === null || delta === 0 ? Minus : delta > 0 ? TrendingUp : TrendingDown;
  const deltaText =
    delta === null ? "First full period" : delta === 0 ? "Same as the 4 weeks before" : delta > 0 ? `${delta} pts up on the 4 weeks before` : `${Math.abs(delta)} pts below the 4 weeks before — totally normal`;

  return (
    <section className={cn("card relative overflow-hidden", compact ? "p-4" : "p-5", className)} aria-labelledby={`${panelId}-title`}>
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h2 id={`${panelId}-title`} className="eyebrow">
            Consistency
          </h2>
          <p className="mt-1 flex items-baseline gap-1">
            <span className={cn("font-display font-extrabold leading-none tracking-[-0.04em] text-ink tabular-nums", compact ? "text-[2.5rem]" : "text-[3.25rem]")}>{now.scheduled ? now.score : "–"}</span>
            {now.scheduled > 0 && <span className="font-display text-xl font-bold text-muted">%</span>}
          </p>
          <p className="mt-1 font-hand text-xl leading-none text-accent">{now.scheduled ? consistencyWord(now.score) : "Nothing scheduled yet"}</p>
        </div>
        <p className={cn("mt-1 inline-flex max-w-[11rem] items-start gap-1.5 rounded-[10px] px-2 py-1.5 text-xs font-semibold leading-snug", delta !== null && delta > 0 ? "bg-sage-soft text-sage-ink" : "bg-paper-deep/70 text-muted")}>
          <DeltaIcon size={14} className="mt-px shrink-0" aria-hidden />
          <span>{deltaText}</span>
        </p>
      </div>

      <WeekBars weeks={data.weeks} height={compact ? 56 : 72} className="mt-4" />

      {!compact && (
        <dl className="mt-4 grid grid-cols-2 gap-2">
          <div className="rounded-[12px] border border-line bg-paper/60 px-3 py-2">
            <dt className="text-xs font-semibold text-muted">Total check-ins</dt>
            <dd className="font-display text-xl font-bold tabular-nums text-ink">{data.total}</dd>
          </div>
          <div className="rounded-[12px] border border-line bg-paper/60 px-3 py-2">
            <dt className="text-xs font-semibold text-muted">Comebacks · 28 days</dt>
            <dd className="font-display text-xl font-bold tabular-nums text-ink">{data.comebacks}</dd>
          </div>
        </dl>
      )}

      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        aria-controls={panelId}
        className="-mx-2 mt-3 flex min-h-11 w-[calc(100%+1rem)] items-center justify-between gap-2 rounded-[10px] px-2 text-left text-sm font-semibold text-accent hover:bg-accent-soft/60"
      >
        How it&apos;s calculated
        <ChevronDown size={16} className={cn("transition-transform duration-200", open && "rotate-180")} aria-hidden />
      </button>
      <AnimatePresence initial={false}>
        {open && (
          <motion.div
            id={panelId}
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }}
            className="overflow-hidden"
          >
            <ul className="space-y-1.5 pb-1 pt-1 text-[0.8125rem] leading-relaxed text-muted">
              <li>
                <strong className="font-semibold text-ink">Rolling 28 days.</strong> Completed check-ins divided by scheduled ones — old weeks roll off on their own.
              </li>
              <li>
                <strong className="font-semibold text-ink">One forgiven miss a week.</strong> Life happens; {isMe ? "you get" : "everyone gets"} {now.grace > 0 ? `${now.grace} grace ${now.grace === 1 ? "day" : "days"} applied right now` : "up to 4 grace days"}.
              </li>
              <li>
                <strong className="font-semibold text-ink">Today counts once it&apos;s done.</strong> An unfinished morning never drags the number down.
              </li>
              <li>Optional habits and paused days never count against {isMe ? "you" : "anyone"}.</li>
            </ul>
          </motion.div>
        )}
      </AnimatePresence>
    </section>
  );
}
