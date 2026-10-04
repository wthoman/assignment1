"use client";

import { Camera, Check } from "lucide-react";
import { useState } from "react";
import { Stamp } from "@/components/ui/Stamp";
import { cn } from "@/lib/cn";

/**
 * The one-tap check-in control. Unchecked it's an inked, dashed circle; checking it
 * lands a stamp with an ink bloom. Tapping a stamped habit undoes it.
 */
export function CheckInButton({
  done,
  onToggle,
  habitName,
  disabled,
  disabledReason,
  needsProof,
  size = 52,
}: {
  done: boolean;
  onToggle: () => void;
  habitName: string;
  disabled?: boolean;
  disabledReason?: string;
  needsProof?: boolean;
  size?: number;
}) {
  const [justDone, setJustDone] = useState(false);
  const label = disabled ? `${habitName}: ${disabledReason ?? "unavailable"}` : done ? `Undo check-in for ${habitName}` : needsProof ? `Check in ${habitName} with photo proof` : `Check in ${habitName}`;

  return (
    <button
      type="button"
      onClick={() => {
        if (!done && !needsProof) setJustDone(true);
        else setJustDone(false);
        onToggle();
      }}
      disabled={disabled}
      aria-pressed={done}
      aria-label={label}
      title={disabled ? disabledReason : undefined}
      className={cn(
        "group relative grid shrink-0 place-items-center rounded-full transition-transform duration-150 active:scale-90 disabled:cursor-not-allowed disabled:opacity-40",
        "before:absolute before:-inset-1 before:content-['']",
      )}
      style={{ width: size, height: size }}
    >
      {done ? (
        <span className="relative grid place-items-center">
          {justDone && <span className="animate-ink absolute inset-0 rounded-full bg-accent" aria-hidden />}
          <Stamp size={size} animate={justDone} />
        </span>
      ) : (
        <span
          className={cn(
            "grid size-full place-items-center rounded-full border-[2.5px] border-dashed border-accent/45 bg-cream text-accent/40 transition-colors",
            !disabled && "group-hover:border-accent group-hover:bg-accent-soft group-hover:text-accent",
          )}
          aria-hidden
        >
          {needsProof ? <Camera size={size * 0.38} strokeWidth={2.2} /> : <Check size={size * 0.42} strokeWidth={3} />}
        </span>
      )}
    </button>
  );
}
