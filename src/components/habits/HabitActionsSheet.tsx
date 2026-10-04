"use client";

import { AnimatePresence, motion } from "motion/react";
import { Archive, Bell, ChevronLeft, History, NotebookPen, Pause, Pencil, UserPlus } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button } from "@/components/ui/Button";
import { ConfirmationDialog } from "@/components/ui/ConfirmationDialog";
import { Toggle } from "@/components/ui/controls";
import { useToast } from "@/components/ui/Toast";
import { formatTime } from "@/lib/dates";
import { cn } from "@/lib/cn";
import { scheduleLabel } from "@/lib/selectors/habits";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { Habit } from "@/lib/types";

/** Contextual actions for a habit, opened from the card's overflow button. */
export function HabitActionsSheet({ open, onClose, habit, onNote }: { open: boolean; onClose: () => void; habit: Habit; onNote: () => void }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const [view, setView] = useState<"main" | "invite">("main");
  const [picked, setPicked] = useState<string[]>([]);
  const [confirm, setConfirm] = useState<"archive" | "pause" | null>(null);
  const me = state.users[state.meId];
  const friends = me.friendIds.map((id) => state.users[id]).filter((u) => u && !state.settings.blockedIds.includes(u.id));
  const invitable = friends.filter((f) => !habit.participantIds.includes(f.id));

  const close = () => {
    onClose();
    setTimeout(() => {
      setView("main");
      setPicked([]);
    }, 250);
  };

  const row = "flex min-h-13 w-full items-center gap-3 rounded-[14px] px-3 text-left transition-colors hover:bg-accent-soft/60";
  const icon = "grid size-9 shrink-0 place-items-center rounded-[11px] bg-accent-soft text-accent";

  return (
    <>
      <BottomSheet
        open={open}
        onClose={close}
        title={view === "invite" ? "Invite friends" : habit.name}
        description={view === "invite" ? "They'll get an invite to do this habit with you." : scheduleLabel(habit)}
        footer={
          view === "invite" ? (
            <Button
              block
              disabled={!picked.length}
              onClick={() => {
                dispatch({ type: "habit/invite", id: habit.id, userIds: picked });
                toast({ title: `Invited ${picked.length} friend${picked.length > 1 ? "s" : ""}`, body: `“${habit.name}” is now shared.`, motif: habit.icon });
                close();
              }}
            >
              Send invite{picked.length > 1 ? "s" : ""}
            </Button>
          ) : undefined
        }
      >
        <AnimatePresence mode="wait" initial={false}>
          {view === "main" ? (
            <motion.div key="main" initial={{ opacity: 0, x: -16 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -16 }} transition={{ duration: 0.18 }} className="space-y-1">
              <div className="mb-3 flex items-center gap-3 rounded-[16px] bg-paper/70 p-3">
                <IllustrationTile kind={habit.icon} tint={habit.tint} size={44} rotate={-3} />
                <p className="text-sm leading-snug text-muted">{habit.description || "No description yet."}</p>
              </div>
              <button type="button" className={row} onClick={() => { close(); setTimeout(onNote, 260); }}>
                <span className={icon}><NotebookPen size={18} aria-hidden /></span>
                <span className="flex-1 font-semibold">Note or photo proof</span>
              </button>
              <Link href={`/habits/${habit.id}`} className={row} onClick={close}>
                <span className={icon}><History size={18} aria-hidden /></span>
                <span className="flex-1 font-semibold">View history</span>
              </Link>
              <Link href={`/habits/${habit.id}/edit`} className={row} onClick={close}>
                <span className={icon}><Pencil size={18} aria-hidden /></span>
                <span className="flex-1 font-semibold">Edit habit</span>
              </Link>
              <div className={cn(row, "hover:bg-transparent")}>
                <span className={icon}><Bell size={18} aria-hidden /></span>
                <span className="min-w-0 flex-1">
                  <span className="block font-semibold">Reminders</span>
                  <span className="block truncate text-xs text-muted">
                    {habit.reminderTimes.length ? habit.reminderTimes.map(formatTime).join(", ") : "No times set — edit to add one"}
                  </span>
                </span>
                <Toggle
                  label={`Reminders for ${habit.name}`}
                  checked={habit.remindersOn}
                  onChange={(v) => {
                    dispatch({ type: "habit/update", id: habit.id, patch: { remindersOn: v } });
                    toast({ title: v ? "Reminders on" : "Reminders paused", body: habit.name });
                  }}
                />
              </div>
              <button type="button" className={row} onClick={() => setView("invite")}>
                <span className={icon}><UserPlus size={18} aria-hidden /></span>
                <span className="flex-1 font-semibold">Invite friends</span>
              </button>
              <div className="hand-divider my-2" aria-hidden />
              <button type="button" className={row} onClick={() => { setConfirm("pause"); close(); }}>
                <span className={icon}><Pause size={18} aria-hidden /></span>
                <span className="min-w-0 flex-1">
                  <span className="block font-semibold">Pause habit</span>
                  <span className="block text-xs text-muted">Hide it from Today. Your history stays.</span>
                </span>
              </button>
              <button type="button" className={row} onClick={() => { setConfirm("archive"); close(); }}>
                <span className={icon}><Archive size={18} aria-hidden /></span>
                <span className="min-w-0 flex-1">
                  <span className="block font-semibold">Archive habit</span>
                  <span className="block text-xs text-muted">Retire it. Stickers and stats are kept.</span>
                </span>
              </button>
            </motion.div>
          ) : (
            <motion.div key="invite" initial={{ opacity: 0, x: 16 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: 16 }} transition={{ duration: 0.18 }}>
              <button type="button" onClick={() => setView("main")} className="-ml-2 mb-2 flex min-h-10 items-center gap-1 rounded-[10px] px-2 text-sm font-semibold text-accent hover:bg-accent-soft">
                <ChevronLeft size={16} aria-hidden /> Back
              </button>
              {invitable.length === 0 ? (
                <p className="rounded-[14px] bg-paper/70 p-4 text-sm text-muted">Everyone in your circle is already on this one. Nice.</p>
              ) : (
                <ul className="space-y-1">
                  {invitable.map((f) => {
                    const on = picked.includes(f.id);
                    return (
                      <li key={f.id}>
                        <button
                          type="button"
                          role="checkbox"
                          aria-checked={on}
                          onClick={() => setPicked((p) => (on ? p.filter((x) => x !== f.id) : [...p, f.id]))}
                          className={cn(row, on && "bg-accent-soft")}
                        >
                          <Avatar user={f} size={38} />
                          <span className="min-w-0 flex-1">
                            <span className="block font-semibold">{f.name}</span>
                            <span className="block truncate text-xs text-muted">@{f.handle}</span>
                          </span>
                          <span className={cn("grid size-6 place-items-center rounded-[7px] border-2", on ? "border-accent bg-accent text-on-accent" : "border-line-strong")} aria-hidden>
                            {on && <svg viewBox="0 0 12 12" className="size-3"><path d="M2 6.5 L5 9 L10 3" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" /></svg>}
                          </span>
                        </button>
                      </li>
                    );
                  })}
                </ul>
              )}
            </motion.div>
          )}
        </AnimatePresence>
      </BottomSheet>
      <ConfirmationDialog
        open={confirm === "pause"}
        onClose={() => setConfirm(null)}
        title={`Pause “${habit.name}”?`}
        body="It'll leave Today and won't count toward your consistency while paused. Resume any time from the habit's page."
        confirmLabel="Pause habit"
        onConfirm={() => {
          dispatch({ type: "habit/status", id: habit.id, status: "paused" });
          toast({ title: "Habit paused", body: "Take the time you need.", action: { label: "Undo", onClick: () => dispatch({ type: "habit/status", id: habit.id, status: "active" }) } });
          close();
        }}
      />
      <ConfirmationDialog
        open={confirm === "archive"}
        onClose={() => setConfirm(null)}
        title={`Archive “${habit.name}”?`}
        body="Archived habits are hidden everywhere except your history. You keep every check-in and sticker."
        confirmLabel="Archive"
        onConfirm={() => {
          dispatch({ type: "habit/status", id: habit.id, status: "archived" });
          toast({ title: "Habit archived", action: { label: "Undo", onClick: () => dispatch({ type: "habit/status", id: habit.id, status: "active" }) } });
          close();
        }}
      />
    </>
  );
}
