"use client";

import { CalendarDays, Check, Sprout, Users } from "lucide-react";
import { motion } from "motion/react";
import { useEffect, useState, type ReactNode } from "react";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { Mascot } from "@/components/illustrations/Mascot";
import { Button } from "@/components/ui/Button";
import { HandNote, Tape } from "@/components/ui/misc";
import { Stamp } from "@/components/ui/Stamp";
import { CATEGORY_META, PERSONALITIES } from "@/lib/data/catalog";
import { useDispatch } from "@/lib/store/provider";
import type { PersonalityKey } from "@/lib/types";
import { categoryForIcon } from "../habitDraft";
import { describeSettings, PERSONALITY_SETTINGS } from "../personality";
import { StepShell } from "../StepShell";

const TALLY_MS = 1100;

function Section({ title, icon, children, delay, reduce }: { title: string; icon: ReactNode; children: ReactNode; delay: number; reduce: boolean }) {
  return (
    <motion.section
      initial={reduce ? { opacity: 0 } : { opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: reduce ? 0 : delay, ease: [0.22, 1, 0.36, 1] }}
      className="space-y-2.5"
    >
      <h2 className="flex items-center gap-2 font-display text-[0.9375rem] font-bold text-ink">
        <span className="grid size-7 place-items-center rounded-[9px] bg-accent-soft text-accent" aria-hidden>
          {icon}
        </span>
        {title}
      </h2>
      {children}
    </motion.section>
  );
}

export function ResultStep({ personality, onNext, reduce }: { personality: PersonalityKey; onNext: () => void; reduce: boolean }) {
  const dispatch = useDispatch();
  const p = PERSONALITIES[personality];
  const patch = PERSONALITY_SETTINGS[personality];
  const [revealed, setRevealed] = useState(reduce);

  useEffect(() => {
    if (revealed) return;
    const t = setTimeout(() => setRevealed(true), TALLY_MS);
    return () => clearTimeout(t);
  }, [revealed]);

  const apply = (useSettings: boolean) => {
    if (useSettings) dispatch({ type: "settings/update", patch });
    dispatch({ type: "session/personality", personality });
    onNext();
  };

  if (!revealed) {
    return (
      <StepShell
        key="tally"
        heading={
          <div className="flex min-h-[60dvh] flex-col items-center justify-center gap-4 text-center md:min-h-[480px]" role="status" aria-live="polite">
            <Mascot mood="thinking" size={120} />
            <h1 tabIndex={-1} className="font-display text-xl font-bold text-ink focus:outline-none">
              Tallying your answers…
            </h1>
            <div className="flex gap-1.5" aria-hidden>
              {[0, 1, 2].map((i) => (
                <motion.span key={i} className="size-2 rounded-full bg-accent" animate={{ opacity: [0.25, 1, 0.25] }} transition={{ duration: 0.9, repeat: Infinity, delay: i * 0.15 }} />
              ))}
            </div>
          </div>
        }
      />
    );
  }

  const settingsList = describeSettings(patch);

  return (
    <StepShell
      key="reveal"
      onSubmit={() => apply(true)}
      heading={
        <header className="relative mb-7 flex flex-col items-center pt-2 text-center">
          <div className="relative">
            <motion.div
              initial={reduce ? { opacity: 0 } : { opacity: 0, scale: 0.6, rotate: -14 }}
              animate={{ opacity: 1, scale: 1, rotate: -4 }}
              transition={reduce ? { duration: 0.2 } : { type: "spring", stiffness: 260, damping: 16 }}
              className="sticker-shadow relative"
            >
              <IllustrationTile kind={p.motif} tint={p.tint} size={104} />
              <Tape className="-top-2.5 left-6" rotate={-4} />
            </motion.div>
            <span className="absolute -bottom-3 -right-5">
              <Stamp size={52} animate className="[animation-delay:380ms]" />
            </span>
          </div>

          <motion.div
            initial={reduce ? { opacity: 0 } : { opacity: 0, y: 10, scaleX: 0.7 }}
            animate={{ opacity: 1, y: 0, scaleX: 1 }}
            transition={{ duration: 0.45, delay: reduce ? 0 : 0.35, ease: [0.22, 1, 0.36, 1] }}
            className="mt-7 bg-accent px-7 py-1.5 font-display text-[0.6875rem] font-bold uppercase tracking-[0.12em] text-on-accent"
            style={{ clipPath: "polygon(0 0, 100% 0, 94% 50%, 100% 100%, 0 100%, 6% 50%)" }}
          >
            Your habit personality
          </motion.div>

          <motion.div initial={reduce ? { opacity: 0 } : { opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5, delay: reduce ? 0 : 0.55, ease: [0.22, 1, 0.36, 1] }}>
            <h1 tabIndex={-1} className="mt-3 font-display text-[2.5rem] font-extrabold leading-[1] tracking-[-0.045em] text-accent focus:outline-none sm:text-[2.875rem]">
              {p.name}
            </h1>
            <HandNote className="mt-2 text-[1.375rem]" rotate={-2}>
              {p.tagline}
            </HandNote>
            <p className="mx-auto mt-3 max-w-[36ch] text-[0.9375rem] leading-relaxed text-muted">{p.summary}</p>
          </motion.div>
        </header>
      }
      footer={
        <div className="space-y-1.5">
          <Button type="submit" size="lg" block>
            Use these settings
          </Button>
          <Button variant="ghost" block onClick={() => apply(false)}>
            Keep my defaults
          </Button>
        </div>
      }
    >
      <div className="space-y-6">
        <Section title="Strengths" icon={<Check size={15} strokeWidth={2.6} />} delay={0.7} reduce={reduce}>
          <ul className="flex flex-wrap gap-2">
            {p.strengths.map((s) => (
              <li key={s} className="inline-flex min-h-9 items-center gap-1.5 rounded-[10px] border border-line bg-cream px-3 text-sm font-semibold text-ink">
                <Check size={14} className="text-accent" aria-hidden />
                {s}
              </li>
            ))}
          </ul>
          <div className="relative rounded-[14px] border border-dashed border-line-strong bg-gold-soft/60 px-4 py-3">
            <p className="font-display text-xs font-bold uppercase tracking-[0.08em] text-[#6b5016] dark:text-gold">Watch out for</p>
            <p className="mt-1 text-sm leading-relaxed text-ink">{p.watchOut}</p>
          </div>
        </Section>

        <Section title="Habits that suit you" icon={<Sprout size={15} />} delay={0.8} reduce={reduce}>
          <ul className="card divide-y divide-line overflow-hidden">
            {p.habits.map((h, i) => (
              <li key={h.name} className="flex items-center gap-3 px-3.5 py-3">
                <IllustrationTile kind={h.icon} tint={CATEGORY_META[categoryForIcon(h.icon)].tint} size={42} rotate={i % 2 ? 3 : -3} />
                <div className="min-w-0">
                  <p className="font-display text-[0.9375rem] font-semibold leading-tight text-ink">{h.name}</p>
                  <p className="mt-0.5 text-[0.8125rem] text-muted">{h.schedule}</p>
                </div>
              </li>
            ))}
          </ul>
        </Section>

        <Section title="Suggested rhythm" icon={<CalendarDays size={15} />} delay={0.9} reduce={reduce}>
          <p className="text-sm leading-relaxed text-ink">{p.schedule}</p>
        </Section>

        <Section title="Accountability" icon={<Users size={15} />} delay={1} reduce={reduce}>
          <ul className="space-y-1.5">
            {p.accountability.map((a) => (
              <li key={a} className="flex items-start gap-2 text-sm text-ink">
                <Check size={16} className="mt-0.5 shrink-0 text-sage-ink" aria-hidden />
                {a}
              </li>
            ))}
          </ul>
          {settingsList.length > 0 && (
            <p className="rounded-[12px] bg-paper-deep/60 px-3.5 py-2.5 text-[0.8125rem] leading-relaxed text-muted">
              <span className="font-semibold text-ink">“Use these settings” sets:</span> {settingsList.join(" · ")}. You can change any of it in Settings.
            </p>
          )}
        </Section>
      </div>
    </StepShell>
  );
}
