"use client";

import { AnimatePresence, motion } from "motion/react";
import { BellRing, Camera, Flame, MoreHorizontal, NotebookPen } from "lucide-react";
import { useState } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { FriendAvatarStack } from "@/components/avatar/FriendAvatarStack";
import { IllustrationTile, TINT_SOFT, TINT_SOLID } from "@/components/illustrations/Illustration";
import { ReactionBar } from "@/components/social/ReactionBar";
import { haptic, useToast } from "@/components/ui/Toast";
import { checkInMessage, comebackMessage } from "@/lib/encouragement";
import { formatTime, WEEKDAY_LETTER, weekday } from "@/lib/dates";
import { cn } from "@/lib/cn";
import { checkInFor, currentStreak, habitWeek, missedBefore, TIME_LABEL, weekCount } from "@/lib/selectors/habits";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { Habit, ISODate } from "@/lib/types";
import { CheckInButton } from "./CheckInButton";
import { CheckInSheet } from "./CheckInSheet";
import { HabitActionsSheet } from "./HabitActionsSheet";

/** Seven tiny day indicators for the habit's current week. */
function WeekDots({ habit, date, today }: { habit: Habit; date: ISODate; today: ISODate }) {
  const state = useAppState();
  const days = habitWeek(state, habit, state.meId, date, state.settings.weekStart);
  const doneCount = days.filter((d) => d.done).length;
  const scheduled = days.filter((d) => d.scheduled).length;
  return (
    <span className="flex items-center gap-[3px]" role="img" aria-label={`This week: ${doneCount} of ${scheduled} scheduled days done`}>
      {days.map((d) => {
        const isToday = d.date === today;
        return (
          <span key={d.date} className="flex flex-col items-center" aria-hidden>
            <span
              className={cn(
                "grid size-[15px] place-items-center rounded-[5px] text-[0.5rem] font-bold leading-none transition-colors duration-500",
                d.done ? cn(TINT_SOLID[habit.tint], habit.tint === "burgundy" ? "text-on-accent" : "text-[#2e1b1a]") : d.scheduled ? (d.date > today ? "border border-dashed border-line-strong text-faint" : "border border-line-strong bg-cream text-faint") : "text-faint/60",
                isToday && "ring-[1.5px] ring-accent ring-offset-1 ring-offset-cream",
              )}
            >
              {WEEKDAY_LETTER[weekday(d.date)]}
            </span>
          </span>
        );
      })}
    </span>
  );
}

export function HabitCard({ habit, date, today, index = 0 }: { habit: Habit; date: ISODate; today: ISODate; index?: number }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const [sheet, setSheet] = useState<"note" | "complete" | "actions" | null>(null);
  const me = state.meId;
  const checkIn = checkInFor(state, habit.id, me, date);
  const done = Boolean(checkIn);
  const future = date > today;
  const style = state.settings.encouragement;
  const showStreak = state.settings.showStreaks && habit.showStreak;
  const streak = showStreak ? currentStreak(state, habit, me, today) : 0;
  const partners = habit.participantIds.filter((p) => p !== me).map((p) => state.users[p]).filter(Boolean);
  const partnersDone = partners.filter((p) => checkInFor(state, habit.id, p.id, date)).map((p) => p.id);
  const perWeek = habit.frequency === "three-per-week" ? weekCount(state, habit, me, date, state.settings.weekStart) : null;
  const rotate = index % 2 ? 2.5 : -3;

  const toggle = () => {
    if (future) return;
    if (done) {
      const snapshot = checkIn!;
      dispatch({ type: "checkin/undo", habitId: habit.id, date });
      toast({
        title: "Check-in removed",
        body: habit.name,
        action: { label: "Redo", onClick: () => dispatch({ type: "checkin/complete", habitId: habit.id, date, time: snapshot.time, note: snapshot.note, photo: snapshot.photo }) },
      });
      return;
    }
    if (habit.proof === "required") {
      setSheet("complete");
      return;
    }
    const { missed, hadPrior } = missedBefore(state, habit, me, date);
    dispatch({ type: "checkin/complete", habitId: habit.id, date });
    haptic(state.settings.haptics, [10, 30, 14]);
    toast({
      title: hadPrior && missed >= 2 ? comebackMessage(style) : checkInMessage(style, habit.name.length + new Date().getMinutes()),
      body: date === today ? habit.name : `${habit.name} · logged for ${new Date(date + "T12:00").toLocaleDateString("en-US", { weekday: "long" })}`,
      motif: habit.icon,
      action: { label: "Undo", onClick: () => dispatch({ type: "checkin/undo", habitId: habit.id, date }) },
    });
  };

  const meta = [
    TIME_LABEL[habit.timeOfDay],
    perWeek !== null ? `${perWeek} of ${habit.timesPerWeek} this week` : null,
    habit.optional ? "Optional" : null,
  ].filter(Boolean);

  return (
    <motion.article
      layout="position"
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.98 }}
      transition={{ duration: 0.25, delay: Math.min(index, 6) * 0.03 }}
      className={cn("card relative isolate overflow-hidden transition-[border-color] duration-500", done && "border-line-strong")}
      aria-label={`${habit.name}${done ? ", done" : ""}`}
    >
      {/* colour fill that spreads from the check button when completed */}
      <span
        aria-hidden
        className={cn("absolute inset-0 -z-10 transition-[clip-path] duration-700 ease-[var(--ease-out-soft)]", TINT_SOFT[habit.tint])}
        style={{ clipPath: done ? "circle(150% at calc(100% - 40px) 38px)" : "circle(0% at calc(100% - 40px) 38px)" }}
      />
      <div className="flex items-start gap-3 p-3 pr-3.5">
        <IllustrationTile kind={habit.icon} tint={habit.tint} size={50} rotate={rotate} muted={future} className={cn(done && "border-line-strong bg-cream!")} />
        <div className="min-w-0 flex-1 pt-0.5">
          <h3 className="font-display text-[1.0625rem] font-bold leading-tight tracking-[-0.015em] text-ink">{habit.name}</h3>
          <p className="mt-0.5 flex flex-wrap items-center gap-x-1.5 text-[0.8125rem] text-muted">
            {done && checkIn ? <span className="font-semibold text-accent">Done {formatTime(checkIn.time)}</span> : null}
            {done && <span aria-hidden>·</span>}
            {meta.join(" · ")}
            {streak >= 3 && (
              <span className="inline-flex items-center gap-0.5 text-orange" title={`${streak}-day streak`}>
                <Flame size={13} aria-hidden />
                <span className="text-muted">{streak}</span>
                <span className="sr-only">day streak</span>
              </span>
            )}
          </p>
          <div className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1.5">
            <WeekDots habit={habit} date={date} today={today} />
            {partners.length > 0 && <FriendAvatarStack users={partners} size={22} doneIds={partnersDone} label={`Shared with ${partners.map((p) => p.name.split(" ")[0]).join(", ")}; ${partnersDone.length} done`} />}
            {checkIn?.note && (
              <span className="inline-flex items-center gap-1 text-xs text-muted" title={checkIn.note}>
                <NotebookPen size={13} aria-hidden /> <span className="sr-only">Has a note</span>
              </span>
            )}
            {checkIn?.photo && (
              <span className="inline-flex items-center gap-1 text-xs text-muted">
                <Camera size={13} aria-hidden /> <span className="sr-only">Has photo proof</span>
              </span>
            )}
          </div>
        </div>
        <div className="flex flex-col items-center gap-1">
          <CheckInButton
            done={done}
            onToggle={toggle}
            habitName={habit.name}
            disabled={future}
            disabledReason="Not yet — this day hasn't happened"
            needsProof={habit.proof === "required"}
          />
          <button
            type="button"
            onClick={() => setSheet("actions")}
            className="grid size-9 place-items-center rounded-[10px] text-muted transition-colors hover:bg-accent-soft hover:text-accent"
            aria-label={`More options for ${habit.name}`}
          >
            <MoreHorizontal size={18} aria-hidden />
          </button>
        </div>
      </div>

      <AnimatePresence initial={false}>
        {done && checkIn && !checkIn.note && !checkIn.photo && habit.notesEnabled && date === today && (
          <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} exit={{ height: 0, opacity: 0 }} className="overflow-hidden">
            <div className="flex gap-2 px-3 pb-3 pl-[4.4rem]">
              <button type="button" onClick={() => setSheet("note")} className="inline-flex min-h-9 items-center gap-1.5 rounded-[10px] border border-line-strong bg-cream/80 px-2.5 text-xs font-semibold text-accent hover:bg-cream">
                <NotebookPen size={14} aria-hidden /> Add a note
              </button>
              {habit.proof !== "off" && (
                <button type="button" onClick={() => setSheet("note")} className="inline-flex min-h-9 items-center gap-1.5 rounded-[10px] border border-line-strong bg-cream/80 px-2.5 text-xs font-semibold text-accent hover:bg-cream">
                  <Camera size={14} aria-hidden /> Photo proof
                </button>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {checkIn && (checkIn.note || checkIn.photo || checkIn.reactions.length > 0) && (
        <div className="flex items-center gap-2 border-t border-line/70 px-3 py-2 pl-[4.4rem]">
          <button type="button" onClick={() => setSheet("note")} className="min-w-0 flex-1 truncate text-left text-[0.8125rem] text-muted hover:text-ink">
            {checkIn.note ? <span className="font-hand text-[1.05rem] text-ink">“{checkIn.note}”</span> : checkIn.photo ? `Photo: ${checkIn.photo.caption}` : "See who reacted"}
          </button>
          <ReactionBar checkIn={checkIn} size="sm" />
        </div>
      )}

      {partners.length > 0 && (
        <ul className="border-t border-dashed border-line-strong/60 px-3 py-1.5 pl-[4.4rem]">
          {partners.map((p) => {
            const ci = checkInFor(state, habit.id, p.id, date);
            const nudged = state.nudges.some((n) => n.fromId === me && n.toId === p.id && n.habitId === habit.id && n.at.slice(0, 10) === new Date().toISOString().slice(0, 10));
            return (
              <li key={p.id} className="flex min-h-11 items-center gap-2">
                <Avatar user={p} size={24} />
                <span className="min-w-0 flex-1 truncate text-[0.8125rem]">
                  <span className="font-semibold text-ink">{p.name.split(" ")[0]}</span>{" "}
                  <span className="text-muted">{ci ? `checked in ${formatTime(ci.time)}` : future ? "not yet" : "hasn't checked in yet"}</span>
                </span>
                {ci ? (
                  <ReactionBar checkIn={ci} size="sm" />
                ) : !future && date === today ? (
                  <button
                    type="button"
                    disabled={nudged}
                    onClick={() => {
                      dispatch({ type: "social/nudge", toId: p.id, habitId: habit.id, kind: "nudge", message: style === "cheeky" ? `${habit.name}? I already did mine.` : `Want to do ${habit.name.toLowerCase()} together?` });
                      toast({ title: `Nudged ${p.name.split(" ")[0]}`, body: "A friendly tap, nothing more." });
                    }}
                    className="inline-flex min-h-9 items-center gap-1 rounded-[10px] px-2 text-xs font-semibold text-accent hover:bg-accent-soft disabled:text-faint"
                  >
                    <BellRing size={14} aria-hidden /> {nudged ? "Nudged" : "Nudge"}
                  </button>
                ) : null}
              </li>
            );
          })}
        </ul>
      )}

      <CheckInSheet open={sheet === "note" || sheet === "complete"} onClose={() => setSheet(null)} habit={habit} date={date} mode={sheet === "complete" ? "complete" : "edit"} />
      <HabitActionsSheet open={sheet === "actions"} onClose={() => setSheet(null)} habit={habit} onNote={() => setSheet("note")} />
    </motion.article>
  );
}
