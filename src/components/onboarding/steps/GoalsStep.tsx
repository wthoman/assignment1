"use client";

import { useState } from "react";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { Button } from "@/components/ui/Button";
import { Stamp } from "@/components/ui/Stamp";
import { cn } from "@/lib/cn";
import { GOAL_OPTIONS } from "@/lib/data/catalog";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { Tint } from "@/lib/types";
import { StepShell } from "../StepShell";

const MAX = 5;
const TINTS: Tint[] = ["orange", "sky", "gold", "sky", "rose", "sage", "sage", "sage", "burgundy", "rose", "gold", "rose"];
const ROTATIONS = [-4, 3, -2, 4, -3, 2];

export function GoalsStep({ onNext }: { onNext: () => void }) {
  const { session } = useAppState();
  const dispatch = useDispatch();
  const [selected, setSelected] = useState<string[]>(() => session.goals.filter((g) => GOAL_OPTIONS.some((o) => o.key === g)).slice(0, MAX));
  const [error, setError] = useState<string | null>(null);
  const full = selected.length >= MAX;

  const toggle = (key: string) => {
    if (selected.includes(key)) {
      setSelected(selected.filter((k) => k !== key));
      setError(null);
    } else if (full) {
      setError(`That's ${MAX}. Unpick one to swap it out.`);
    } else {
      setSelected([...selected, key]);
      setError(null);
    }
  };

  const submit = () => {
    if (selected.length === 0) {
      setError("Pick at least one. You can change these later.");
      return;
    }
    dispatch({ type: "session/goals", goals: selected });
    onNext();
  };

  return (
    <StepShell
      eyebrow="Goals"
      title="What would you like more of?"
      description={`Pick up to ${MAX}. We'll use these to suggest your first habits.`}
      onSubmit={submit}
      footer={
        <div className="space-y-2">
          <p className={cn("text-center text-sm font-semibold tabular-nums", error ? "text-[#a3301f] dark:text-[#f0a090]" : "text-muted")} role="status" aria-live="polite">
            {error ?? (selected.length === 0 ? "Nothing picked yet" : `${selected.length} of ${MAX} picked`)}
          </p>
          <Button type="submit" size="lg" block>
            Continue
          </Button>
        </div>
      }
    >
      <ul className="grid grid-cols-3 gap-2.5">
        {GOAL_OPTIONS.map((g, i) => {
          const on = selected.includes(g.key);
          return (
            <li key={g.key}>
              <button
                type="button"
                aria-pressed={on}
                aria-disabled={!on && full ? true : undefined}
                onClick={() => toggle(g.key)}
                className={cn(
                  "relative flex h-full min-h-[6.5rem] w-full flex-col items-center justify-start gap-2 rounded-[14px] border px-1.5 pb-2.5 pt-3 text-center transition-[background-color,border-color,transform,opacity] duration-150 active:scale-[0.97]",
                  on ? "border-accent bg-accent-soft shadow-[var(--shadow)]" : "border-line bg-cream hover:border-line-strong",
                  !on && full && "opacity-55",
                )}
              >
                <IllustrationTile kind={g.icon} tint={TINTS[i % TINTS.length]} size={44} rotate={on ? ROTATIONS[i % ROTATIONS.length] : 0} muted={!on && full} />
                <span className={cn("text-[0.8125rem] font-semibold leading-tight", on ? "text-accent" : "text-ink")}>{g.label}</span>
                {on && <Stamp size={24} animate className="absolute -right-1.5 -top-1.5" />}
              </button>
            </li>
          );
        })}
      </ul>
    </StepShell>
  );
}
