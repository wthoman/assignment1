"use client";

import { Eye, EyeOff } from "lucide-react";
import Link from "next/link";
import { useMemo } from "react";
import { ProgressRing } from "@/components/ui/controls";
import { HandNote, SectionHeading } from "@/components/ui/misc";
import { cn } from "@/lib/cn";
import { addDays, orderedWeekdays, WEEKDAY_LONG, WEEKDAY_SHORT } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { consistencyScore, comebackCount, strongestWeekday, timeOfDayPattern, totalCompletions } from "@/lib/selectors/stats";
import { useAppState } from "@/lib/store/provider";

/** Consistency score with a plain-language breakdown of how it's calculated. */
export function ConsistencyCard() {
  const state = useAppState();
  const today = useToday();
  const c = useMemo(() => consistencyScore(state, state.meId, today), [state, today]);
  const misses = c.scheduled - c.completed;
  const visible = state.settings.showConsistencyOnProfile && state.settings.profileVisibility !== "private";

  return (
    <section aria-labelledby="consistency-h" className="card overflow-hidden">
      <div className="flex items-center gap-4 p-5">
        <ProgressRing value={c.score / 100} size={92} stroke={8} label={`Consistency score ${c.score} percent`}>
          <span className="font-display text-2xl font-extrabold tracking-[-0.04em] text-ink">
            {c.score}
            <span className="text-sm text-muted">%</span>
          </span>
        </ProgressRing>
        <div className="min-w-0 flex-1">
          <p className="eyebrow">Rolling 28 days</p>
          <h2 id="consistency-h" className="font-display text-lg font-bold leading-snug tracking-[-0.015em] text-ink">
            Consistency score
          </h2>
          <p className="mt-0.5 text-sm text-muted">
            {c.completed} of {c.scheduled} scheduled check-ins, with {c.grace} miss{c.grace === 1 ? "" : "es"} forgiven.
          </p>
          <p className="mt-1.5 inline-flex items-center gap-1.5 text-xs font-semibold text-muted">
            {visible ? <Eye size={14} aria-hidden /> : <EyeOff size={14} aria-hidden />}
            {visible ? "Friends can see this score" : "Only you can see this score"}
          </p>
        </div>
      </div>
      <div className="paper-panel border-t border-line px-5 pb-4 pt-3">
        <h3 className="font-display text-sm font-bold text-ink">How it&apos;s worked out</h3>
        <p className="mt-1 font-display text-[0.8125rem] font-semibold text-accent">(completed + forgiven misses) ÷ scheduled</p>
        <ul className="mt-2 space-y-2 text-[0.8125rem] leading-[1.45] text-muted">
          <li>
            <strong className="text-ink">A forgiving 28-day window.</strong> Every required habit scheduled in the last four weeks counts once. Old weeks roll off, so a rough patch fades.
          </li>
          <li>
            <strong className="text-ink">One forgiven miss per week.</strong> Up to {Math.floor(c.windowDays / 7)} misses are let off{misses > 0 ? ` (you’re using ${c.grace})` : ""}. A single off day never drops your score.
          </li>
          <li>
            <strong className="text-ink">Optional habits never count against you.</strong> Do them for bonus points; skip them for free.
          </li>
          <li>
            <strong className="text-ink">Today counts only once it’s done.</strong> An unfinished morning won’t drag the number down. Paused habits are left out too.
          </li>
        </ul>
      </div>
    </section>
  );
}

/** Strongest weekdays (8 weeks) and time-of-day pattern. */
export function PatternsCard() {
  const state = useAppState();
  const today = useToday();
  const weekStart = state.settings.weekStart;
  const { strongest, times } = useMemo(() => {
    const from = addDays(today, -56);
    return { strongest: strongestWeekday(state, state.meId, from, addDays(today, -1)), times: timeOfDayPattern(state, state.meId, from, today) };
  }, [state, today]);
  const order = orderedWeekdays(weekStart);
  const hasData = strongest.rates.some((r) => r > 0);
  const timeRows: { key: keyof typeof times.buckets; label: string; range: string }[] = [
    { key: "morning", label: "Morning", range: "before noon" },
    { key: "afternoon", label: "Afternoon", range: "noon–5pm" },
    { key: "evening", label: "Evening", range: "5–10pm" },
    { key: "late", label: "Late night", range: "after 10pm" },
  ];
  const topTime = timeRows.find((r) => r.key === times.top);

  return (
    <section aria-labelledby="patterns-h" className="space-y-3">
      <SectionHeading id="patterns-h" title="Your rhythm" hand="last 8 weeks" />
      <div className="grid gap-3 sm:grid-cols-2">
        <figure className="card-flat p-4">
          <figcaption>
            <p className="eyebrow">Strongest day</p>
            <p className="font-display text-lg font-bold text-ink">{hasData ? `${strongest.name}s` : "Not enough data yet"}</p>
            {hasData && <p className="text-xs text-muted">{Math.round(strongest.rate * 100)}% of scheduled habits done</p>}
          </figcaption>
          <div className="mt-3 flex h-24 items-end gap-1.5" role="img" aria-label={`Completion rate by weekday. Best: ${strongest.name}, ${Math.round(strongest.rate * 100)} percent.`}>
            {order.map((d) => {
              const r = strongest.rates[d];
              const best = hasData && d === strongest.day;
              return (
                <div key={d} className="flex h-full flex-1 flex-col items-center justify-end gap-1" title={`${WEEKDAY_LONG[d]}: ${Math.round(r * 100)}%`}>
                  <div className={cn("w-full max-w-7 rounded-t-[4px]", best ? "bg-accent" : "bg-accent/25")} style={{ height: `${Math.max(4, r * 100)}%` }} />
                </div>
              );
            })}
          </div>
          <div className="mt-1.5 flex gap-1.5" aria-hidden>
            {order.map((d) => (
              <span key={d} className={cn("flex-1 text-center text-[0.6875rem] font-semibold", hasData && d === strongest.day ? "text-accent" : "text-faint")}>
                {WEEKDAY_SHORT[d].slice(0, 2)}
              </span>
            ))}
          </div>
          <table className="sr-only">
            <caption>Completion rate by weekday</caption>
            <tbody>
              {order.map((d) => (
                <tr key={d}>
                  <th scope="row">{WEEKDAY_LONG[d]}</th>
                  <td>{Math.round(strongest.rates[d] * 100)}%</td>
                </tr>
              ))}
            </tbody>
          </table>
        </figure>
        <figure className="card-flat p-4">
          <figcaption>
            <p className="eyebrow">Favourite time</p>
            <p className="font-display text-lg font-bold text-ink">{times.total > 1 && topTime ? topTime.label : "Still figuring you out"}</p>
            {topTime && <p className="text-xs text-muted">Most check-ins land {topTime.range}</p>}
          </figcaption>
          <dl className="mt-3 space-y-2">
            {timeRows.map((row) => {
              const v = times.buckets[row.key] / times.total;
              return (
                <div key={row.key} className="grid grid-cols-[5.5rem_1fr_2.5rem] items-center gap-2 text-[0.8125rem]">
                  <dt className={cn("font-semibold", row.key === times.top ? "text-accent" : "text-muted")}>{row.label}</dt>
                  <dd className="h-2.5 overflow-hidden rounded-full bg-paper-deep" aria-hidden>
                    <div className={cn("h-full rounded-full", row.key === times.top ? "bg-accent" : "bg-accent/30")} style={{ width: `${v * 100}%` }} />
                  </dd>
                  <dd className="text-right tabular-nums text-muted">{Math.round(v * 100)}%</dd>
                </div>
              );
            })}
          </dl>
        </figure>
      </div>
    </section>
  );
}

/** Compact stat column for the desktop aside. */
export function StatsSummary() {
  const state = useAppState();
  const today = useToday();
  const stats = useMemo(() => {
    const me = state.meId;
    return {
      score: consistencyScore(state, me, today).score,
      total: totalCompletions(state, me),
      comebacks: comebackCount(state, me),
      stickers: state.collection.length,
    };
  }, [state, today]);
  const rows = [
    { label: "Consistency", value: `${stats.score}%`, note: "28-day, forgiving" },
    { label: "Check-ins", value: stats.total.toLocaleString(), note: "all time" },
    { label: "Comebacks", value: String(stats.comebacks), note: "the whole skill" },
    { label: "Stickers", value: String(stats.stickers), note: "in your book" },
  ];
  return (
    <section aria-labelledby="glance-h" className="card p-4">
      <h2 id="glance-h" className="eyebrow">
        At a glance
      </h2>
      <dl className="mt-2 grid grid-cols-2 gap-x-3 gap-y-3">
        {rows.map((r) => (
          <div key={r.label} className="min-w-0">
            <dt className="text-xs font-semibold text-muted">{r.label}</dt>
            <dd className="font-display text-2xl font-extrabold tracking-[-0.04em] text-ink">{r.value}</dd>
            <dd className="text-[0.6875rem] text-faint">{r.note}</dd>
          </div>
        ))}
      </dl>
      {stats.comebacks > 0 && (
        <p className="mt-3 border-t border-dashed border-line pt-2">
          <HandNote className="text-base">{stats.comebacks} comebacks. Coming back counts more than never missing.</HandNote>
        </p>
      )}
      <Link href="/recap" className="mt-2 inline-flex min-h-11 items-center text-sm font-semibold text-accent hover:underline">
        See your weekly recap
      </Link>
    </section>
  );
}
