"use client";

import { ArrowRight, LoaderCircle } from "lucide-react";
import { motion } from "motion/react";
import { useState, type ReactNode } from "react";
import { AvatarArt } from "@/components/avatar/Avatar";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { Mascot } from "@/components/illustrations/Mascot";
import { Button } from "@/components/ui/Button";
import { HandNote, Tape } from "@/components/ui/misc";
import { Stamp } from "@/components/ui/Stamp";
import { GOAL_OPTIONS, PERSONALITIES } from "@/lib/data/catalog";
import { useAppState } from "@/lib/store/provider";
import type { PersonalityKey } from "@/lib/types";
import { FREQUENCY_OPTIONS } from "../habitDraft";
import { StepShell } from "../StepShell";

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="flex min-h-14 items-center gap-3 px-4 py-2.5">
      <dt className="w-20 shrink-0 text-[0.8125rem] font-semibold text-muted">{label}</dt>
      <dd className="min-w-0 flex-1">{children}</dd>
    </div>
  );
}

export function DoneStep({ personality, habitId, onFinish, reduce }: { personality: PersonalityKey | null; habitId: string | null; onFinish: () => void; reduce: boolean }) {
  const state = useAppState();
  const me = state.users[state.meId];
  const habit = habitId ? state.habits.find((h) => h.id === habitId) : undefined;
  const p = personality ? PERSONALITIES[personality] : undefined;
  const goals = GOAL_OPTIONS.filter((g) => state.session.goals.includes(g.key));
  const [leaving, setLeaving] = useState(false);

  const finish = () => {
    if (leaving) return;
    setLeaving(true);
    onFinish();
  };

  return (
    <StepShell
      onSubmit={finish}
      heading={
        <header className="mb-6 flex flex-col items-center text-center">
          <div className="relative">
            <motion.div initial={reduce ? { opacity: 0 } : { opacity: 0, y: 18, scale: 0.9 }} animate={{ opacity: 1, y: 0, scale: 1 }} transition={reduce ? { duration: 0.2 } : { type: "spring", stiffness: 240, damping: 15 }}>
              <Mascot mood="cheer" size={120} />
            </motion.div>
            <span className="absolute -right-10 top-2">
              <Stamp variant="label" text="All set" animate rotate={10} className="[animation-delay:300ms]" />
            </span>
          </div>
          <h1 tabIndex={-1} className="mt-2 font-display text-[2rem] font-extrabold leading-[1.05] tracking-[-0.035em] text-ink focus:outline-none">
            You&rsquo;re all set, <span className="text-accent">{me.name.split(" ")[0]}</span>
          </h1>
          <p className="mt-2 max-w-[34ch] text-[0.9375rem] leading-relaxed text-muted">Here&rsquo;s the first page of your daybook. Today is a great day to stamp it.</p>
        </header>
      }
      footer={
        <Button type="submit" size="lg" block disabled={leaving} icon={leaving ? <LoaderCircle size={18} className="animate-spin" aria-hidden /> : undefined}>
          Open Today
          {!leaving && <ArrowRight size={18} aria-hidden />}
        </Button>
      }
    >
      <div className="relative">
        <Tape className="-top-2 left-1/2 -translate-x-1/2" rotate={-3} />
        <div className="card overflow-hidden">
          <div className="paper-panel flex items-center gap-4 px-4 pb-4 pt-5">
            <AvatarArt config={me.avatar} size={84} title={`${me.name}'s avatar`} />
            <div className="min-w-0">
              <p className="truncate font-display text-xl font-bold leading-tight text-ink">{me.name}</p>
              <p className="truncate text-sm text-muted">
                @{me.handle}
                {me.pronouns && ` · ${me.pronouns}`}
              </p>
              {p && <HandNote className="mt-1 text-[1.0625rem]">{p.name}</HandNote>}
            </div>
          </div>
          <dl className="divide-y divide-line border-t border-line">
            <Row label="Type">
              {p ? (
                <span className="flex items-center gap-2">
                  <IllustrationTile kind={p.motif} tint={p.tint} size={32} />
                  <span className="min-w-0">
                    <span className="block font-semibold leading-tight text-ink">{p.name}</span>
                    <span className="block text-[0.8125rem] text-muted">{p.tagline}</span>
                  </span>
                </span>
              ) : (
                <span className="text-sm text-muted">Take the quiz any time from your profile.</span>
              )}
            </Row>
            <Row label="First habit">
              {habit ? (
                <span className="flex items-center gap-2">
                  <IllustrationTile kind={habit.icon} tint={habit.tint} size={32} rotate={-3} />
                  <span className="min-w-0">
                    <span className="block truncate font-semibold leading-tight text-ink">{habit.name}</span>
                    <span className="block text-[0.8125rem] text-muted">{FREQUENCY_OPTIONS.find((f) => f.value === habit.frequency)?.label ?? "Custom"}</span>
                  </span>
                </span>
              ) : (
                <span className="text-sm text-muted">None yet. Add one from Today.</span>
              )}
            </Row>
            {goals.length > 0 && (
              <Row label="Goals">
                <span className="flex flex-wrap gap-1.5">
                  {goals.map((g) => (
                    <span key={g.key} className="rounded-[8px] bg-paper-deep/70 px-2 py-0.5 text-[0.8125rem] font-semibold text-ink">
                      {g.label}
                    </span>
                  ))}
                </span>
              </Row>
            )}
            <Row label="Friends">
              <span className="text-sm font-semibold text-ink">{me.friendIds.length} in your circle</span>
            </Row>
          </dl>
        </div>
      </div>
    </StepShell>
  );
}
