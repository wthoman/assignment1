"use client";

import { motion } from "motion/react";
import { Logo } from "@/components/brand/Logo";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { Mascot } from "@/components/illustrations/Mascot";
import { Button } from "@/components/ui/Button";
import { HandNote, Tape } from "@/components/ui/misc";
import { BRAND } from "@/lib/brand";
import type { IllustrationKey, Tint } from "@/lib/types";

const FLOATERS: { kind: IllustrationKey; tint: Tint; className: string; rotate: number; tape?: number; delay: number }[] = [
  { kind: "shoe", tint: "orange", className: "left-[4%] top-[8%]", rotate: -9, tape: -12, delay: 0 },
  { kind: "book", tint: "gold", className: "right-[3%] top-[2%]", rotate: 8, delay: 0.6 },
  { kind: "water", tint: "sky", className: "left-[10%] bottom-[6%]", rotate: 6, delay: 1.1 },
  { kind: "moon", tint: "sage", className: "right-[8%] bottom-[12%]", rotate: -6, tape: 8, delay: 0.3 },
];

export function WelcomeStep({ onStart, onLogin, onExplore, reduce }: { onStart: () => void; onLogin: () => void; onExplore: () => void; reduce: boolean }) {
  const [lead, tail] = BRAND.tagline.split(/,\s*/);
  return (
    <div className="flex flex-1 flex-col px-5 pb-[max(1.25rem,env(safe-area-inset-bottom))] pt-6 sm:px-8">
      <Logo size={30} className="lg:hidden" />

      <div className="relative mx-auto mt-4 h-60 lg:hidden w-full max-w-[300px] sm:h-64" aria-hidden>
        {FLOATERS.map((f) => (
          <motion.span
            key={f.kind}
            className={`absolute ${f.className}`}
            animate={reduce ? undefined : { y: [0, -6, 0] }}
            transition={{ duration: 4.2, repeat: Infinity, ease: "easeInOut", delay: f.delay }}
          >
            <span className="relative block sticker-shadow">
              <IllustrationTile kind={f.kind} tint={f.tint} size={56} rotate={f.rotate} />
              {f.tape !== undefined && <Tape className="-top-2 left-1" rotate={f.tape} />}
            </span>
          </motion.span>
        ))}
        <div className="absolute inset-x-0 top-1/2 flex -translate-y-1/2 justify-center">
          <Mascot mood="wave" size={150} />
        </div>
        <HandNote className="absolute -bottom-1 right-[22%] text-xl" rotate={-5}>
          hi, I&rsquo;m Pip!
        </HandNote>
      </div>

      <div className="mt-6 text-center lg:mt-auto">
        <h1 tabIndex={-1} className="font-display text-[2.375rem] font-extrabold leading-[1.02] tracking-[-0.04em] text-ink focus:outline-none sm:text-[2.75rem]">
          {tail ? (
            <>
              {lead}, <span className="scribble text-accent">{tail}</span>
            </>
          ) : (
            BRAND.tagline
          )}
        </h1>
        <p className="mx-auto mt-3 max-w-[30ch] text-[0.9875rem] leading-relaxed text-muted">{BRAND.shortPitch}</p>
      </div>

      <div className="mt-auto space-y-2.5 pt-8">
        <Button size="lg" block onClick={onStart}>
          Get started
        </Button>
        <Button size="lg" variant="secondary" block onClick={onLogin}>
          I already have an account
        </Button>
        <div className="flex justify-center pt-1">
          <button type="button" onClick={onExplore} className="min-h-11 px-3 text-sm font-semibold text-muted underline decoration-line-strong decoration-dashed underline-offset-4 transition-colors hover:text-accent">
            Explore with sample data
          </button>
        </div>
      </div>
    </div>
  );
}
