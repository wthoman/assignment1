"use client";

import { AnimatePresence, motion } from "motion/react";
import { Flame, Heart, PartyPopper, SmilePlus, Sparkles, ThumbsUp, type LucideIcon } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { haptic } from "@/components/ui/Toast";
import { cn } from "@/lib/cn";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { CheckIn, ReactionKind } from "@/lib/types";

export const REACTIONS: { kind: ReactionKind; label: string; icon: LucideIcon; color: string }[] = [
  { kind: "cheer", label: "Cheer", icon: PartyPopper, color: "text-orange" },
  { kind: "fire", label: "On fire", icon: Flame, color: "text-[#c4532d]" },
  { kind: "clap", label: "Nice one", icon: ThumbsUp, color: "text-gold" },
  { kind: "heart", label: "Love", icon: Heart, color: "text-[#b8434f]" },
  { kind: "wow", label: "Wow", icon: Sparkles, color: "text-sky" },
];
export const REACTION_BY_KIND = Object.fromEntries(REACTIONS.map((r) => [r.kind, r])) as Record<ReactionKind, (typeof REACTIONS)[number]>;

/**
 * Reaction summary + picker for a check-in. The current user can hold one reaction;
 * picking the same one again removes it.
 */
export function ReactionBar({ checkIn, className, size = "md" }: { checkIn: CheckIn; className?: string; size?: "sm" | "md" }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const [open, setOpen] = useState(false);
  const [burst, setBurst] = useState<{ kind: ReactionKind; n: number } | null>(null);
  const wrapRef = useRef<HTMLDivElement>(null);
  const burstId = useRef(0);
  const mine = checkIn.reactions.find((r) => r.userId === state.meId);
  const isOwn = checkIn.userId === state.meId;

  useEffect(() => {
    if (!open) return;
    const onDown = (e: PointerEvent) => {
      if (!wrapRef.current?.contains(e.target as Node)) setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    document.addEventListener("pointerdown", onDown);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("pointerdown", onDown);
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);

  const counts = REACTIONS.map((r) => ({ ...r, n: checkIn.reactions.filter((x) => x.kind === r.kind).length })).filter((r) => r.n > 0);
  const reactorNames = checkIn.reactions.map((r) => (r.userId === state.meId ? "You" : state.users[r.userId]?.name.split(" ")[0])).filter(Boolean);

  const pick = (kind: ReactionKind) => {
    dispatch({ type: "checkin/react", id: checkIn.id, kind });
    haptic(state.settings.haptics);
    if (mine?.kind !== kind) setBurst({ kind, n: ++burstId.current });
    setOpen(false);
  };

  return (
    <div ref={wrapRef} className={cn("relative flex items-center gap-1.5", className)}>
      {counts.length > 0 && (
        <span className="flex items-center gap-1" aria-label={`Reactions from ${reactorNames.join(", ")}`} title={reactorNames.join(", ")}>
          {counts.map((r) => {
            const Icon = r.icon;
            return (
              <motion.span
                key={r.kind}
                layout
                initial={{ scale: 0.5, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                className={cn(
                  "inline-flex items-center gap-0.5 rounded-[8px] border px-1.5 font-semibold tabular-nums",
                  size === "sm" ? "h-6 text-[0.6875rem]" : "h-7 text-xs",
                  mine?.kind === r.kind ? "border-accent/40 bg-accent-soft text-accent" : "border-line bg-paper/70 text-muted",
                )}
              >
                <Icon size={size === "sm" ? 12 : 13} className={r.color} fill={r.kind === "heart" ? "currentColor" : "none"} aria-hidden />
                {r.n}
              </motion.span>
            );
          })}
        </span>
      )}
      {!isOwn && (
        <button
          type="button"
          onClick={() => setOpen((o) => !o)}
          aria-expanded={open}
          aria-haspopup="true"
          aria-label={mine ? `Change your reaction (currently ${REACTION_BY_KIND[mine.kind].label})` : "React"}
          className={cn(
            "relative inline-grid place-items-center rounded-[10px] border transition-colors before:absolute before:-inset-1 before:content-['']",
            size === "sm" ? "size-9" : "size-10",
            mine ? "border-accent/40 bg-accent-soft text-accent" : "border-line bg-cream text-muted hover:text-accent",
          )}
        >
          {mine ? (() => {
            const Icon = REACTION_BY_KIND[mine.kind].icon;
            return <Icon size={17} fill={mine.kind === "heart" ? "currentColor" : "none"} aria-hidden />;
          })() : <SmilePlus size={17} aria-hidden />}
          <AnimatePresence>
            {burst && (
              <motion.span
                key={burst.n}
                initial={{ y: 0, opacity: 1, scale: 0.8 }}
                animate={{ y: -30, opacity: 0, scale: 1.3 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.8, ease: "easeOut" }}
                onAnimationComplete={() => setBurst(null)}
                className={cn("pointer-events-none absolute", REACTION_BY_KIND[burst.kind].color)}
                aria-hidden
              >
                {(() => {
                  const Icon = REACTION_BY_KIND[burst.kind].icon;
                  return <Icon size={20} fill={burst.kind === "heart" ? "currentColor" : "none"} />;
                })()}
              </motion.span>
            )}
          </AnimatePresence>
        </button>
      )}
      <AnimatePresence>
        {open && (
          <motion.div
            role="menu"
            aria-label="Pick a reaction"
            initial={{ opacity: 0, y: 6, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 4, scale: 0.94 }}
            transition={{ type: "spring", stiffness: 520, damping: 32 }}
            className="absolute bottom-full right-0 z-30 mb-2 flex origin-bottom-right gap-0.5 rounded-[16px] border border-line bg-cream p-1 shadow-[var(--shadow-lift)]"
          >
            {REACTIONS.map((r, i) => {
              const Icon = r.icon;
              const active = mine?.kind === r.kind;
              return (
                <motion.button
                  key={r.kind}
                  type="button"
                  role="menuitemradio"
                  aria-checked={active}
                  aria-label={r.label}
                  title={r.label}
                  autoFocus={i === 0}
                  initial={{ scale: 0.4, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  transition={{ delay: i * 0.03, type: "spring", stiffness: 600, damping: 25 }}
                  whileHover={{ scale: 1.15, y: -2 }}
                  whileTap={{ scale: 0.9 }}
                  onClick={() => pick(r.kind)}
                  className={cn("grid size-11 place-items-center rounded-[12px]", active ? "bg-accent-soft" : "hover:bg-paper")}
                >
                  <Icon size={21} className={r.color} fill={r.kind === "heart" ? "currentColor" : "none"} aria-hidden />
                </motion.button>
              );
            })}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
