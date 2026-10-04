"use client";

import { AnimatePresence, motion } from "motion/react";
import { Logo } from "@/components/brand/Logo";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { Mascot } from "@/components/illustrations/Mascot";
import { HandNote, Tape } from "@/components/ui/misc";
import { Stamp } from "@/components/ui/Stamp";
import { BRAND } from "@/lib/brand";
import { cn } from "@/lib/cn";
import { useToday } from "@/lib/hooks";

type Mood = "happy" | "sleepy" | "cheer" | "wave" | "thinking" | "proud";

const NOTES: Record<string, { note: string; mood: Mood }> = {
  welcome: { note: "hi! I'm Pip.", mood: "wave" },
  account: { note: "no spam, promise", mood: "happy" },
  name: { note: "nice to meet you", mood: "happy" },
  avatar: { note: "ooh, looking good", mood: "proud" },
  goals: { note: "pick what matters", mood: "thinking" },
  quiz: { note: "no wrong answers", mood: "thinking" },
  result: { note: "called it.", mood: "proud" },
  habit: { note: "start tiny", mood: "happy" },
  friends: { note: "better together", mood: "cheer" },
  notifications: { note: "we'll be polite", mood: "sleepy" },
  done: { note: "see you tomorrow!", mood: "cheer" },
};

/** Decorative left panel on wide screens: a scrapbook page with Pip reacting to each step. */
export function SideIllustration({ stepKey, reduce, className }: { stepKey: string; reduce: boolean; className?: string }) {
  const n = NOTES[stepKey] ?? NOTES.welcome;
  const today = useToday();
  return (
    <aside aria-hidden className={cn("relative flex-col overflow-hidden border-r border-line bg-paper-deep/40 px-10 py-9", className)}>
      <Logo size={30} />
      <div
        className="pointer-events-none absolute inset-0 opacity-60"
        style={{ backgroundImage: "linear-gradient(to bottom, transparent 39px, var(--line) 40px)", backgroundSize: "100% 40px" }}
      />
      <div className="pointer-events-none absolute bottom-0 left-[4.5rem] top-0 w-px bg-rose/50" />

      <div className="relative flex flex-1 items-center justify-center">
        <div className="relative h-[420px] w-[380px]">
          <span className="absolute left-2 top-6 sticker-shadow">
            <IllustrationTile kind="sun" tint="gold" size={72} rotate={-10} />
            <Tape className="-top-2 left-2" rotate={-14} />
          </span>
          <span className="absolute right-4 top-0 sticker-shadow">
            <IllustrationTile kind="book" tint="rose" size={64} rotate={8} />
          </span>
          <span className="absolute bottom-10 left-0 sticker-shadow">
            <IllustrationTile kind="leaf" tint="sage" size={60} rotate={6} />
          </span>
          <span className="absolute bottom-4 right-6 sticker-shadow">
            <IllustrationTile kind="coffee" tint="orange" size={68} rotate={-5} />
            <Tape className="-top-2 right-2" rotate={10} />
          </span>
          <span className="absolute right-0 top-1/2">
            <Stamp variant="date" text={String(Number(today.slice(8, 10)))} size={64} rotate={12} />
          </span>

          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <AnimatePresence mode="wait" initial={false}>
              <motion.div
                key={n.mood}
                initial={reduce ? { opacity: 0 } : { opacity: 0, y: 10, rotate: -3 }}
                animate={{ opacity: 1, y: 0, rotate: 0 }}
                exit={reduce ? { opacity: 0 } : { opacity: 0, y: -6 }}
                transition={{ duration: 0.3 }}
              >
                <Mascot mood={n.mood} size={210} />
              </motion.div>
            </AnimatePresence>
            <AnimatePresence mode="wait" initial={false}>
              <motion.div key={stepKey} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.25 }} className="mt-2">
                <HandNote className="text-[1.75rem]" rotate={-4}>
                  {n.note}
                </HandNote>
              </motion.div>
            </AnimatePresence>
          </div>
        </div>
      </div>

      <p className="relative max-w-[30ch] font-display text-sm font-semibold leading-relaxed text-muted">{BRAND.shortPitch}</p>
    </aside>
  );
}
