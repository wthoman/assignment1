"use client";

import { createContext, useContext, useEffect, useRef, type FormEvent, type ReactNode } from "react";
import { cn } from "@/lib/cn";

/** True once the person has navigated at least once, so new steps take focus (not on first load). */
export const StepFocusContext = createContext(false);

/**
 * Layout for one onboarding step: heading, scrolling body and a sticky footer.
 * Wrapped in a <form>, so pressing Enter in a field triggers the primary action.
 */
export function StepShell({
  eyebrow,
  title,
  description,
  heading,
  children,
  footer,
  onSubmit,
  className,
}: {
  eyebrow?: string;
  title?: ReactNode;
  description?: ReactNode;
  /** Replaces the default heading block. Must contain the step's <h1 tabIndex={-1}>. */
  heading?: ReactNode;
  children?: ReactNode;
  footer?: ReactNode;
  onSubmit?: () => void;
  className?: string;
}) {
  const ref = useRef<HTMLFormElement>(null);
  const shouldFocus = useContext(StepFocusContext);
  useEffect(() => {
    if (shouldFocus) ref.current?.querySelector<HTMLElement>("h1")?.focus({ preventScroll: true });
  }, [shouldFocus]);

  const submit = (e: FormEvent) => {
    e.preventDefault();
    onSubmit?.();
  };

  return (
    <form ref={ref} onSubmit={submit} noValidate className={cn("flex flex-1 flex-col", className)}>
      <div className="flex-1 px-4 pb-8 pt-3 sm:px-7">
        {heading ?? (
          <header className="mb-6">
            {eyebrow && <p className="eyebrow mb-2">{eyebrow}</p>}
            <h1 tabIndex={-1} className="font-display text-[1.75rem] font-extrabold leading-[1.1] tracking-[-0.03em] text-ink focus:outline-none sm:text-[2rem]">
              {title}
            </h1>
            {description && <p className="mt-2 max-w-[38ch] text-[0.9375rem] leading-relaxed text-muted">{description}</p>}
          </header>
        )}
        {children}
      </div>
      {footer && (
        <div className="sticky bottom-0 z-10 border-t border-line bg-paper px-4 pb-[max(1rem,env(safe-area-inset-bottom))] pt-3 sm:px-7 md:rounded-b-[var(--radius-card)] md:bg-cream">
          {footer}
        </div>
      )}
    </form>
  );
}

/** Radio group of chunky option buttons, laid out as a grid. */
export function ChoiceGroup<T extends string>({
  label,
  value,
  onChange,
  options,
  className,
  hideLabel,
}: {
  label: string;
  value: T;
  onChange: (v: T) => void;
  options: { value: T; label: string; detail?: string; icon?: ReactNode }[];
  className?: string;
  hideLabel?: boolean;
}) {
  return (
    <fieldset className="space-y-2">
      <legend className={cn("mb-2 font-display text-sm font-semibold text-ink", hideLabel && "sr-only")}>{label}</legend>
      <div role="radiogroup" aria-label={label} className={cn("grid gap-2", className)}>
        {options.map((o) => {
          const active = o.value === value;
          return (
            <button
              key={o.value}
              type="button"
              role="radio"
              aria-checked={active}
              onClick={() => onChange(o.value)}
              className={cn(
                "flex min-h-12 items-center gap-2 rounded-[13px] border px-3 py-2 text-left transition-[background-color,border-color,transform] duration-150 active:scale-[0.98]",
                active ? "border-accent bg-accent-soft text-accent" : "border-line-strong bg-cream text-ink hover:bg-accent-soft/50",
              )}
            >
              {o.icon}
              <span className="min-w-0">
                <span className="block font-display text-sm font-semibold leading-tight">{o.label}</span>
                {o.detail && <span className={cn("block text-xs", active ? "text-accent/80" : "text-muted")}>{o.detail}</span>}
              </span>
            </button>
          );
        })}
      </div>
    </fieldset>
  );
}
