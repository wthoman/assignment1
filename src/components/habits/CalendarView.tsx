"use client";

import { AnimatePresence, motion } from "motion/react";
import { Check, ChevronLeft, ChevronRight, Circle } from "lucide-react";
import Link from "next/link";
import { useMemo, useState } from "react";
import { IllustrationTile, TINT_SOFT, TINT_SOLID } from "@/components/illustrations/Illustration";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button, ButtonLink, IconButton } from "@/components/ui/Button";
import { Badge, EmptyState } from "@/components/ui/misc";
import { cn } from "@/lib/cn";
import { addDays, formatDate, formatLongDate, formatTime, fromISODate, monthGrid, orderedWeekdays, WEEKDAY_LONG, WEEKDAY_SHORT } from "@/lib/dates";
import { useIsWide, useToday } from "@/lib/hooks";
import { checkInFor, habitsFor, isScheduled } from "@/lib/selectors/habits";
import { useAppState } from "@/lib/store/provider";
import type { AppState, CheckIn, Habit, ID, ISODate } from "@/lib/types";

const MAX_MARKS = 4;

interface DayEntry {
  habit: Habit;
  scheduled: boolean;
  checkIn?: CheckIn;
}

function dayEntries(state: AppState, habits: Habit[], date: ISODate): DayEntry[] {
  const out: DayEntry[] = [];
  for (const h of habits) {
    const scheduled = h.status === "active" && isScheduled(h, date);
    const checkIn = checkInFor(state, h.id, state.meId, date);
    if (scheduled || checkIn) out.push({ habit: h, scheduled, checkIn });
  }
  return out;
}

function summarize(entries: DayEntry[]) {
  const required = entries.filter((e) => e.scheduled && !e.habit.optional);
  return {
    done: entries.filter((e) => e.checkIn).length,
    requiredDone: required.filter((e) => e.checkIn).length,
    required: required.length,
    planned: entries.filter((e) => e.scheduled).length,
  };
}

function dayLabel(date: ISODate, today: ISODate, entries: DayEntry[]) {
  const s = summarize(entries);
  const base = formatDate(date, { weekday: "long", month: "long", day: "numeric" });
  const prefix = date === today ? `Today, ${base}` : base;
  if (!entries.length) return `${prefix}: nothing planned`;
  if (date > today) return `${prefix}: ${s.planned} planned`;
  return `${prefix}: ${s.done} of ${Math.max(s.planned, s.done)} done`;
}

/** Monthly planner with per-day completion marks, habit filters and a day detail panel. */
export function CalendarView({ initialDate }: { initialDate?: ISODate }) {
  const state = useAppState();
  const today = useToday();
  const wide = useIsWide();
  const weekStart = state.settings.weekStart;
  const start = fromISODate(initialDate ?? today);
  const [cursor, setCursor] = useState({ y: start.getFullYear(), m: start.getMonth() });
  const [selected, setSelected] = useState<ISODate>(initialDate ?? today);
  const [sheetOpen, setSheetOpen] = useState(false);
  const [filter, setFilter] = useState<ID[]>([]);
  const [dir, setDir] = useState(0);

  const habits = useMemo(() => habitsFor(state, state.meId, { includeInactive: true }).filter((h) => h.status !== "archived"), [state]);
  const visible = useMemo(() => (filter.length ? habits.filter((h) => filter.includes(h.id)) : habits), [habits, filter]);
  const cells = useMemo(() => monthGrid(cursor.y, cursor.m, weekStart), [cursor, weekStart]);
  const byDate = useMemo(() => {
    const m = new Map<ISODate, DayEntry[]>();
    for (const d of cells) if (d) m.set(d, dayEntries(state, visible, d));
    return m;
  }, [cells, state, visible]);

  const now = fromISODate(today);
  const isThisMonth = cursor.y === now.getFullYear() && cursor.m === now.getMonth();
  const monthTitle = new Date(cursor.y, cursor.m, 1, 12).toLocaleDateString("en-US", { month: "long", year: "numeric" });

  const shift = (n: number) => {
    setDir(n);
    setCursor((c) => {
      const d = new Date(c.y, c.m + n, 1, 12);
      return { y: d.getFullYear(), m: d.getMonth() };
    });
  };
  const goToday = () => {
    setDir(0);
    setCursor({ y: now.getFullYear(), m: now.getMonth() });
    setSelected(today);
  };
  const pick = (d: ISODate) => {
    setSelected(d);
    if (!wide) setSheetOpen(true);
  };
  const onGridKey = (e: React.KeyboardEvent<HTMLDivElement>) => {
    const step = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -7, ArrowDown: 7 }[e.key];
    const from = (e.target as HTMLElement).closest<HTMLElement>("[data-date]")?.dataset.date;
    if (!step || !from) return;
    const target = e.currentTarget.querySelector<HTMLElement>(`[data-date="${addDays(from, step)}"]`);
    if (target) {
      e.preventDefault();
      target.focus();
    }
  };
  const toggleFilter = (id: ID) => setFilter((f) => (f.includes(id) ? f.filter((x) => x !== id) : [...f, id]));

  const monthStats = useMemo(() => {
    let done = 0;
    let fullDays = 0;
    for (const [d, entries] of byDate) {
      if (d > today) continue;
      const s = summarize(entries);
      done += s.done;
      if (s.required > 0 && s.requiredDone === s.required) fullDays++;
    }
    return { done, fullDays };
  }, [byDate, today]);

  const selectedEntries = dayEntries(state, visible, selected);

  return (
    <div className="lg:grid lg:grid-cols-[minmax(0,1fr)_300px] lg:gap-6">
      <div className="min-w-0 space-y-3">
        <div role="group" aria-label="Filter by habit" className="no-scrollbar -mx-4 flex gap-1.5 overflow-x-auto px-4 pb-1 sm:mx-0 sm:flex-wrap sm:px-0">
          <FilterChip active={filter.length === 0} onClick={() => setFilter([])}>
            All habits
          </FilterChip>
          {habits.map((h) => (
            <FilterChip key={h.id} active={filter.includes(h.id)} onClick={() => toggleFilter(h.id)} swatch={TINT_SOLID[h.tint]}>
              {h.name}
            </FilterChip>
          ))}
        </div>

        <section className="card overflow-hidden" aria-labelledby="cal-month">
          <div className="flex items-center gap-1 border-b border-line px-2 py-2 sm:px-3">
            <IconButton label="Previous month" onClick={() => shift(-1)}>
              <ChevronLeft size={20} aria-hidden />
            </IconButton>
            <h2 id="cal-month" className="min-w-0 flex-1 text-center font-display text-lg font-bold tracking-[-0.02em] text-ink" aria-live="polite">
              {monthTitle}
            </h2>
            <IconButton label="Next month" onClick={() => shift(1)}>
              <ChevronRight size={20} aria-hidden />
            </IconButton>
          </div>
          <div className="flex items-center justify-between gap-2 px-3 pt-2 text-xs text-muted sm:px-4">
            <span>
              <strong className="font-display font-bold text-ink tabular-nums">{monthStats.done}</strong> check-ins ·{" "}
              <strong className="font-display font-bold text-ink tabular-nums">{monthStats.fullDays}</strong> all-done days
            </span>
            {!isThisMonth && (
              <Button variant="ghost" size="sm" onClick={goToday} className="-my-1 min-h-9">
                This month
              </Button>
            )}
          </div>

          <div className="px-1.5 pb-2 pt-2 sm:px-3 sm:pb-3">
            <div className="grid grid-cols-7 gap-0.5 sm:gap-1" aria-hidden>
              {orderedWeekdays(weekStart).map((d) => (
                <span key={d} className="pb-1 text-center text-[0.6875rem] font-bold uppercase tracking-[0.06em] text-faint">
                  <span className="sm:hidden">{WEEKDAY_SHORT[d].slice(0, 2)}</span>
                  <span className="hidden sm:inline">{WEEKDAY_SHORT[d]}</span>
                </span>
              ))}
            </div>
            <AnimatePresence mode="popLayout" initial={false} custom={dir}>
              <motion.div
                key={`${cursor.y}-${cursor.m}`}
                custom={dir}
                initial={{ opacity: 0, x: dir * 24 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: dir * -24 }}
                transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
                className="grid grid-cols-7 gap-0.5 sm:gap-1"
                role="grid"
                aria-labelledby="cal-month"
                onKeyDown={onGridKey}
              >
                {Array.from({ length: cells.length / 7 }, (_, row) => (
                  <div role="row" key={row} className="contents">
                    {cells.slice(row * 7, row * 7 + 7).map((d, i) =>
                      d ? (
                        <DayCell key={d} date={d} today={today} entries={byDate.get(d) ?? []} selected={d === selected} onPick={pick} />
                      ) : (
                        <div role="gridcell" key={`e-${row}-${i}`} aria-hidden className="min-h-14 sm:min-h-[5.5rem]" />
                      ),
                    )}
                  </div>
                ))}
              </motion.div>
            </AnimatePresence>
          </div>

          <div className="flex flex-wrap items-center gap-x-4 gap-y-1.5 border-t border-line px-3 py-2.5 text-xs text-muted sm:px-4" aria-label="Legend">
            <span className="inline-flex items-center gap-1.5">
              <span className="flex gap-0.5" aria-hidden>
                <span className="size-1.5 rounded-full bg-orange" />
                <span className="size-1.5 rounded-full bg-sky" />
              </span>
              Completed (habit colour)
            </span>
            <span className="inline-flex items-center gap-1.5">
              <span className="size-3.5 rounded-[5px] bg-sage-soft ring-1 ring-sage/50" aria-hidden />
              Everything done
            </span>
            <span className="inline-flex items-center gap-1.5">
              <span className="size-3.5 rounded-[5px] ring-2 ring-accent" aria-hidden />
              Today
            </span>
          </div>
        </section>
      </div>

      {wide && (
        <aside className="sticky top-6 self-start" aria-label="Selected day">
          <div className="card p-4">
            <DayDetail date={selected} today={today} entries={selectedEntries} />
          </div>
        </aside>
      )}

      {!wide && (
        <BottomSheet open={sheetOpen} onClose={() => setSheetOpen(false)} title={selected === today ? "Today" : formatDate(selected, { weekday: "long" })} description={formatDate(selected, { month: "long", day: "numeric", year: "numeric" })}>
          <DayDetail date={selected} today={today} entries={selectedEntries} hideHeading />
        </BottomSheet>
      )}
    </div>
  );
}

function FilterChip({ active, onClick, children, swatch }: { active: boolean; onClick: () => void; children: React.ReactNode; swatch?: string }) {
  return (
    <button
      type="button"
      aria-pressed={active}
      onClick={onClick}
      className={cn(
        "inline-flex min-h-10 max-w-[12rem] shrink-0 items-center gap-1.5 rounded-[11px] border px-3 text-sm font-semibold transition-colors",
        active ? "border-accent bg-accent text-on-accent" : "border-line-strong bg-cream text-ink hover:bg-accent-soft",
      )}
    >
      {swatch && <span className={cn("size-2.5 shrink-0 rounded-[3px]", swatch, active && "ring-1 ring-on-accent/70")} aria-hidden />}
      <span className="truncate">{children}</span>
    </button>
  );
}

function DayCell({ date, today, entries, selected, onPick }: { date: ISODate; today: ISODate; entries: DayEntry[]; selected: boolean; onPick: (d: ISODate) => void }) {
  const done = entries.filter((e) => e.checkIn);
  const s = summarize(entries);
  const isToday = date === today;
  const future = date > today;
  const allDone = !future && s.required > 0 && s.requiredDone === s.required;
  const shown = done.slice(0, MAX_MARKS);
  const extra = done.length - shown.length;
  const labelShown = done.slice(0, 3);
  const labelExtra = done.length - labelShown.length;
  return (
    <div role="gridcell" aria-selected={selected}>
      <button
        type="button"
        onClick={() => onPick(date)}
        data-date={date}
        aria-label={dayLabel(date, today, entries)}
        aria-current={isToday ? "date" : undefined}
        className={cn(
          "relative flex h-full min-h-14 w-full flex-col items-center gap-1 rounded-[10px] border p-1 text-left transition-colors sm:min-h-[5.5rem] sm:items-stretch sm:rounded-[12px] sm:p-1.5",
          selected ? "border-accent bg-accent-soft" : allDone ? "border-sage/40 bg-sage-soft/80 hover:bg-sage-soft" : "border-transparent hover:border-line hover:bg-paper/60",
          isToday && "ring-2 ring-accent ring-offset-1 ring-offset-cream",
        )}
      >
        <span className={cn("font-display text-sm font-bold tabular-nums leading-none sm:text-[0.9375rem]", isToday ? "text-accent" : future ? "text-faint" : "text-ink")}>{Number(date.slice(8))}</span>
        <span className="flex flex-wrap justify-center gap-[3px] sm:hidden" aria-hidden>
          {shown.map((e) => (
            <span key={e.habit.id} className={cn("size-1.5 rounded-full", TINT_SOLID[e.habit.tint])} />
          ))}
          {extra > 0 && <span className="text-[0.5625rem] font-bold leading-[6px] text-muted">+{extra}</span>}
        </span>
        <span className="hidden min-w-0 flex-col gap-0.5 sm:flex" aria-hidden>
          {labelShown.map((e) => (
            <span key={e.habit.id} className={cn("flex min-w-0 items-center gap-1 rounded-[5px] px-1 py-px text-[0.625rem] font-semibold leading-tight text-ink", TINT_SOFT[e.habit.tint])}>
              <span className={cn("size-1.5 shrink-0 rounded-full", TINT_SOLID[e.habit.tint])} />
              <span className="truncate">{e.habit.name}</span>
            </span>
          ))}
          {labelExtra > 0 && <span className="px-1 text-[0.625rem] font-bold text-muted">+{labelExtra} more</span>}
          {!future && done.length === 0 && s.planned > 0 && <span className="px-1 text-[0.625rem] text-faint">{s.planned} planned</span>}
        </span>
      </button>
    </div>
  );
}

function DayDetail({ date, today, entries, hideHeading }: { date: ISODate; today: ISODate; entries: DayEntry[]; hideHeading?: boolean }) {
  const s = summarize(entries);
  const future = date > today;
  const isToday = date === today;
  const sorted = [...entries].sort((a, b) => Number(Boolean(b.checkIn)) - Number(Boolean(a.checkIn)) || Number(a.habit.optional) - Number(b.habit.optional));
  return (
    <div>
      {!hideHeading && (
        <>
          <p className="eyebrow">{isToday ? "Today" : WEEKDAY_LONG[fromISODate(date).getDay()]}</p>
          <h2 className="font-display text-xl font-bold tracking-[-0.02em] text-ink">{formatLongDate(date).split(", ").slice(1).join(", ") || formatLongDate(date)}</h2>
        </>
      )}
      <p className={cn("text-sm text-muted", !hideHeading && "mt-0.5")} aria-live="polite">
        {!entries.length
          ? "Nothing planned — a free day."
          : future
            ? `${s.planned} planned`
            : s.required > 0
              ? `${s.requiredDone} of ${s.required} done${s.done > s.requiredDone ? ` · ${s.done - s.requiredDone} bonus` : ""}`
              : `${s.done} done`}
      </p>

      {entries.length === 0 ? (
        <EmptyState compact mood="sleepy" title="A rest day" body="Rest days are part of the rhythm." className="mt-3" />
      ) : (
        <ul className="mt-3 space-y-1.5">
          {sorted.map((e) => {
            const state = e.checkIn ? "done" : future ? "planned" : isToday ? "open" : "missed";
            return (
              <li key={e.habit.id}>
                <Link href={`/habits/${e.habit.id}`} className="flex min-h-14 items-center gap-3 rounded-[14px] border border-line bg-cream px-2.5 py-2 transition-colors hover:bg-accent-soft/50">
                  <IllustrationTile kind={e.habit.icon} tint={e.habit.tint} size={38} muted={state === "missed" || state === "planned"} />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-semibold text-ink">{e.habit.name}</span>
                    <span className="flex items-center gap-1.5 text-xs text-muted">
                      {state === "done" && <>Done at {formatTime(e.checkIn!.time)}</>}
                      {state === "planned" && "Planned"}
                      {state === "open" && "Still open"}
                      {state === "missed" && "Not logged — that's okay"}
                      {e.habit.optional && <Badge tone="muted">Optional</Badge>}
                      {!e.scheduled && e.checkIn && <Badge tone="sage">Extra</Badge>}
                    </span>
                  </span>
                  <span
                    className={cn(
                      "grid size-7 shrink-0 place-items-center rounded-[8px]",
                      state === "done" ? "bg-accent text-on-accent" : state === "missed" ? "border border-line-strong text-faint" : "border border-dashed border-line-strong text-faint",
                    )}
                    aria-hidden
                  >
                    {state === "done" ? <Check size={15} strokeWidth={3} /> : <Circle size={8} />}
                  </span>
                </Link>
              </li>
            );
          })}
        </ul>
      )}
      {isToday && (
        <ButtonLink href="/today" variant="soft" block className="mt-3">
          Go to Today
        </ButtonLink>
      )}
    </div>
  );
}
