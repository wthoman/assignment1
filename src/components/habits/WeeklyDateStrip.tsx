"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import { addDays, formatDate, fromISODate, weekDates, WEEKDAY_SHORT, weekday } from "@/lib/dates";
import { cn } from "@/lib/cn";
import type { ISODate } from "@/lib/types";

export interface DayFill {
  done: number;
  total: number;
}

/**
 * Horizontal week selector. Each day shows a tiny ink fill for how much got done.
 * Future days can be viewed but not checked in.
 */
export function WeeklyDateStrip({
  selected,
  today,
  weekStart,
  onSelect,
  fillFor,
}: {
  selected: ISODate;
  today: ISODate;
  weekStart: 0 | 1;
  onSelect: (d: ISODate) => void;
  fillFor: (d: ISODate) => DayFill;
}) {
  const days = weekDates(selected, weekStart);
  const monthLabel = fromISODate(days[3]).toLocaleDateString("en-US", { month: "long", year: "numeric" });
  return (
    <div className="flex items-stretch gap-1">
      <button type="button" onClick={() => onSelect(addDays(selected, -7))} className="grid w-8 shrink-0 place-items-center rounded-[10px] text-muted hover:bg-accent-soft hover:text-accent" aria-label="Previous week">
        <ChevronLeft size={18} aria-hidden />
      </button>
      <div role="tablist" aria-label={`Week of ${monthLabel}`} className="grid min-w-0 flex-1 grid-cols-7 gap-1">
        {days.map((d) => {
          const isToday = d === today;
          const isSel = d === selected;
          const future = d > today;
          const { done, total } = fillFor(d);
          const ratio = total ? Math.min(1, done / total) : 0;
          return (
            <button
              key={d}
              type="button"
              role="tab"
              aria-selected={isSel}
              aria-label={`${formatDate(d, { weekday: "long", month: "long", day: "numeric" })}${isToday ? ", today" : ""}${future ? "" : `, ${done} of ${total} done`}`}
              onClick={() => onSelect(d)}
              className={cn(
                "relative flex min-h-[3.75rem] flex-col items-center justify-center gap-0.5 overflow-hidden rounded-[12px] border transition-colors duration-200",
                isSel ? "border-accent bg-accent text-on-accent shadow-[0_2px_0_rgb(0_0_0/0.15)]" : "border-line bg-cream hover:border-line-strong",
                future && !isSel && "border-dashed bg-transparent",
              )}
            >
              {!isSel && !future && ratio > 0 && (
                <span className="absolute inset-x-0 bottom-0 bg-rose-soft transition-[height] duration-500" style={{ height: `${ratio * 100}%` }} aria-hidden />
              )}
              <span className={cn("relative text-[0.625rem] font-bold uppercase tracking-[0.08em]", isSel ? "text-on-accent/80" : "text-accent")}>{WEEKDAY_SHORT[weekday(d)].slice(0, 2)}</span>
              <span className={cn("relative font-display text-[1.0625rem] font-bold leading-none tabular-nums", !isSel && (future ? "text-faint" : "text-ink"))}>{fromISODate(d).getDate()}</span>
              {isToday && <span className={cn("relative mt-0.5 size-1.5 rounded-full", isSel ? "bg-on-accent" : "bg-accent")} aria-hidden />}
              {!isToday && total > 0 && done >= total && !future && <span className={cn("relative mt-0.5 size-1.5 rounded-full", isSel ? "bg-on-accent/70" : "bg-sage")} aria-hidden />}
            </button>
          );
        })}
      </div>
      <button type="button" onClick={() => onSelect(addDays(selected, 7))} className="grid w-8 shrink-0 place-items-center rounded-[10px] text-muted hover:bg-accent-soft hover:text-accent" aria-label="Next week">
        <ChevronRight size={18} aria-hidden />
      </button>
    </div>
  );
}
