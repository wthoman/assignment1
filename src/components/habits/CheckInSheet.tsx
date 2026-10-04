"use client";

import { AnimatePresence, motion } from "motion/react";
import { Camera, ImagePlus, Trash2 } from "lucide-react";
import { useId, useState } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { ReactionBar } from "@/components/social/ReactionBar";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button } from "@/components/ui/Button";
import { CharCount, TextArea, TextInput } from "@/components/ui/controls";
import { useToast } from "@/components/ui/Toast";
import { formatLongDate, formatTime, relativeTime } from "@/lib/dates";
import { uid } from "@/lib/random";
import { checkInFor } from "@/lib/selectors/habits";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { Habit, IllustrationKey, ISODate, PhotoProof } from "@/lib/types";
import { Polaroid } from "./Polaroid";

const LIBRARY: { motif: IllustrationKey; caption: string }[] = [
  { motif: "sun", caption: "Morning light" },
  { motif: "leaf", caption: "Out in the park" },
  { motif: "coffee", caption: "Post-workout mug" },
  { motif: "flower", caption: "Proof, with flowers" },
];

/**
 * Notes and photo proof for a day's check-in. In "complete" mode (photo required)
 * it gathers proof first and completes the habit on save.
 */
export function CheckInSheet({ open, onClose, habit, date, mode = "edit" }: { open: boolean; onClose: () => void; habit: Habit; date: ISODate; mode?: "edit" | "complete" }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const existing = checkInFor(state, habit.id, state.meId, date);
  const noteId = useId();
  const captionId = useId();
  const [note, setNote] = useState(existing?.note ?? "");
  const [photo, setPhoto] = useState<PhotoProof | undefined>(existing?.photo);
  const [shutter, setShutter] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastOpen, setLastOpen] = useState(false);

  // Reset local edits each time the sheet opens.
  if (open !== lastOpen) {
    setLastOpen(open);
    if (open) {
      setNote(existing?.note ?? "");
      setPhoto(existing?.photo);
      setError(null);
    }
  }

  const takePhoto = () => {
    setShutter(true);
    setTimeout(() => {
      setShutter(false);
      setPhoto({ id: uid("ph"), caption: `${habit.name}, ${formatTime(new Date().toTimeString().slice(0, 5))}`, motif: habit.icon, tint: habit.tint });
      setError(null);
    }, 650);
  };

  const save = () => {
    if (note.length > 280) return setError("Notes can be up to 280 characters.");
    if (habit.proof === "required" && !photo) return setError("This habit asks for photo proof. Add one to check in.");
    if (existing) {
      dispatch({ type: "checkin/update", id: existing.id, note, photo: photo ?? null });
      toast({ title: "Check-in updated", motif: habit.icon });
    } else {
      dispatch({ type: "checkin/complete", habitId: habit.id, date, note: note || undefined, photo });
      toast({ title: "Checked in with proof", body: "Stamped and saved.", motif: habit.icon });
    }
    onClose();
  };

  const canPhoto = habit.proof !== "off";

  return (
    <BottomSheet
      open={open}
      onClose={onClose}
      title={mode === "complete" ? `Check in: ${habit.name}` : existing ? "Your check-in" : `Note for ${habit.name}`}
      description={formatLongDate(date) + (existing ? ` · ${formatTime(existing.time)}` : "")}
      footer={
        <div className="flex gap-2">
          <Button variant="secondary" block onClick={onClose}>
            Cancel
          </Button>
          <Button block onClick={save}>
            {existing ? "Save" : "Check in"}
          </Button>
        </div>
      }
    >
      <div className="space-y-5">
        {habit.notesEnabled && (
          <div className="space-y-1.5">
            <div className="flex items-baseline justify-between">
              <label htmlFor={noteId} className="font-display text-sm font-semibold">
                Quick note
              </label>
              <CharCount value={note} max={280} />
            </div>
            <TextArea id={noteId} value={note} onChange={(e) => setNote(e.target.value)} placeholder="How did it go? One line is plenty." maxLength={320} data-autofocus />
          </div>
        )}

        {canPhoto && (
          <div className="space-y-2">
            <p className="font-display text-sm font-semibold">
              Photo proof {habit.proof === "required" ? <span className="text-accent">· required</span> : <span className="font-sans text-xs font-medium text-faint">· optional</span>}
            </p>
            <AnimatePresence mode="wait" initial={false}>
              {photo ? (
                <motion.div key="photo" initial={{ opacity: 0, rotate: -8, scale: 0.9 }} animate={{ opacity: 1, rotate: 0, scale: 1 }} exit={{ opacity: 0, scale: 0.9 }} className="flex items-end gap-4">
                  <Polaroid photo={photo} size={132} rotate={-4} />
                  <div className="min-w-0 flex-1 space-y-2 pb-2">
                    <label htmlFor={captionId} className="text-xs font-semibold text-muted">
                      Caption
                    </label>
                    <TextInput id={captionId} value={photo.caption} maxLength={40} onChange={(e) => setPhoto({ ...photo, caption: e.target.value })} />
                    <Button variant="ghost" size="sm" icon={<Trash2 size={15} />} onClick={() => setPhoto(undefined)}>
                      Remove photo
                    </Button>
                  </div>
                </motion.div>
              ) : (
                <motion.div key="pick" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="space-y-3">
                  <button
                    type="button"
                    onClick={takePhoto}
                    disabled={shutter}
                    className="relative flex h-28 w-full flex-col items-center justify-center gap-1.5 overflow-hidden rounded-[16px] border-2 border-dashed border-line-strong bg-paper/60 text-accent transition-colors hover:bg-accent-soft"
                  >
                    <Camera size={26} aria-hidden />
                    <span className="font-display text-sm font-semibold">{shutter ? "Snap…" : "Take a photo"}</span>
                    <span className="text-xs text-muted">Simulated camera — nothing leaves your device</span>
                    <AnimatePresence>{shutter && <motion.span initial={{ opacity: 0.9 }} animate={{ opacity: 0 }} exit={{ opacity: 0 }} transition={{ duration: 0.6 }} className="absolute inset-0 bg-white" aria-hidden />}</AnimatePresence>
                  </button>
                  <div>
                    <p className="mb-2 flex items-center gap-1.5 text-xs font-semibold text-muted">
                      <ImagePlus size={14} aria-hidden /> Or pick from your library
                    </p>
                    <div className="grid grid-cols-4 gap-2">
                      {LIBRARY.map((l, i) => (
                        <button
                          key={l.motif}
                          type="button"
                          onClick={() => {
                            setPhoto({ id: uid("ph"), caption: l.caption, motif: l.motif, tint: i % 2 ? "sage" : "gold" });
                            setError(null);
                          }}
                          className="rounded-[10px] p-1 transition-transform hover:-rotate-2 hover:bg-accent-soft"
                          aria-label={`Use photo: ${l.caption}`}
                        >
                          <Polaroid photo={{ id: l.motif, caption: "", motif: l.motif, tint: i % 2 ? "sage" : "gold" }} size={64} rotate={0} tape={false} className="w-full!" />
                        </button>
                      ))}
                    </div>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        )}

        {error && (
          <p role="alert" className="rounded-[12px] bg-orange-soft px-3 py-2 text-sm font-medium text-ink">
            {error}
          </p>
        )}

        {existing && (existing.reactions.length > 0 || existing.comments.length > 0) && (
          <div className="space-y-3 border-t border-line pt-4">
            <div className="flex items-center justify-between">
              <p className="font-display text-sm font-semibold">From friends</p>
              <ReactionBar checkIn={existing} size="sm" />
            </div>
            {existing.comments.map((c) => {
              const u = state.users[c.userId];
              return (
                <div key={c.id} className="flex items-start gap-2.5">
                  {u && <Avatar user={u} size={30} />}
                  <div className="min-w-0 rounded-[14px] rounded-tl-[4px] bg-paper px-3 py-2">
                    <p className="text-xs font-semibold text-muted">
                      {u?.name.split(" ")[0]} · {relativeTime(c.at)}
                    </p>
                    <p className="text-sm text-ink">{c.text}</p>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </BottomSheet>
  );
}
