"use client";

import { fromISODate, WEEKDAY_LETTER, weekday } from "@/lib/dates";
import { cn } from "@/lib/cn";
import type { ISODate } from "@/lib/types";

export interface PlannerDay {
  date: ISODate;
  done: number;
  total: number;
  bonus: number;
}

/**
 * Paper-planner week: seven narrow columns, one ruled cell per scheduled habit.
 * Done cells fill with muted ink; the current day is circled.
 */
export function ProgressGrid({ days, today, onSelect, selected }: { days: PlannerDay[]; today: ISODate; selected?: ISODate; onSelect?: (d: ISODate) => void }) {
  const maxRows = Math.max(3, ...days.map((d) => d.total));
  const doneDays = days.filter((d) => d.date <= today && d.total > 0 && d.done >= d.total).length;
  const summary = days.map((d) => `${fromISODate(d.date).toLocaleDateString("en-US", { weekday: "long" })}: ${d.date > today ? "upcoming" : `${d.done} of ${d.total}`}`).join("; ");
  return (
    <div className="relative">
      <p className="sr-only">This week. {summary}.</p>
      <div className="grid grid-cols-7 gap-1.5" aria-hidden={!onSelect}>
        {days.map((d) => {
          const isToday = d.date === today;
          const future = d.date > today;
          const full = !future && d.total > 0 && d.done >= d.total;
          const Cell = onSelect ? "button" : "div";
          return (
            <Cell
              key={d.date}
              {...(onSelect ? { type: "button" as const, onClick: () => onSelect(d.date), "aria-label": `${fromISODate(d.date).toLocaleDateString("en-US", { weekday: "long" })}, ${future ? "upcoming" : `${d.done} of ${d.total} done`}`, "aria-pressed": selected === d.date } : {})}
              className={cn(
                "group relative flex flex-col items-center gap-1.5 rounded-[10px] px-0.5 pb-1.5 pt-1 transition-colors",
                onSelect && "hover:bg-accent-soft/60",
                selected === d.date && "bg-accent-soft/70",
              )}
            >
              <span className={cn("relative grid size-6 place-items-center font-display text-[0.6875rem] font-bold", isToday ? "text-accent" : "text-accent/70")}>
                {WEEKDAY_LETTER[weekday(d.date)]}
                {isToday && (
                  <svg viewBox="0 0 30 30" className="absolute inset-[-3px] size-[30px]" aria-hidden>
                    <path d="M15 3 C23 2.5 27.5 8 27 15.5 C26.5 23 21 27.5 14 27 C7 26.5 2.5 21.5 3 14.5 C3.5 8 8.5 3.5 16.5 3.8" fill="none" stroke="var(--accent)" strokeWidth="1.8" strokeLinecap="round" />
                  </svg>
                )}
              </span>
              <div className="flex w-full flex-col-reverse gap-[3px]">
                {Array.from({ length: maxRows }, (_, i) => {
                  const exists = i < d.total;
                  const filled = !future && i < d.done;
                  return (
                    <span
                      key={i}
                      className={cn(
                        "h-[7px] w-full rounded-[3px] transition-colors duration-500",
                        !exists ? "bg-transparent" : filled ? (full ? "bg-accent/85" : "bg-rose") : future ? "border border-dashed border-line-strong" : "border border-line-strong bg-cream",
                      )}
                      style={{ transitionDelay: `${i * 40}ms` }}
                    />
                  );
                })}
              </div>
              <span className={cn("text-[0.625rem] font-semibold tabular-nums", future ? "text-faint" : "text-muted")}>
                {future ? fromISODate(d.date).getDate() : d.bonus > 0 ? `${d.done}+${d.bonus}` : `${d.done}/${d.total}`}
              </span>
            </Cell>
          );
        })}
      </div>
      {doneDays > 0 && (
        <p className="mt-1 text-right font-hand text-base leading-none text-accent" aria-hidden>
          {doneDays} full {doneDays === 1 ? "day" : "days"} so far
        </p>
      )}
    </div>
  );
}
