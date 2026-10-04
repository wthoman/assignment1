"use client";

import { useId, type InputHTMLAttributes, type ReactNode, type TextareaHTMLAttributes } from "react";
import { cn } from "@/lib/cn";

/* ---------- Toggle ---------- */
export function Toggle({ checked, onChange, label, disabled, className }: { checked: boolean; onChange: (v: boolean) => void; label: string; disabled?: boolean; className?: string }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={cn(
        "relative inline-flex h-7 w-12 shrink-0 items-center rounded-full border transition-colors duration-200 disabled:opacity-40",
        "before:absolute before:-inset-2 before:content-['']",
        checked ? "border-accent bg-accent" : "border-line-strong bg-paper-deep",
        className,
      )}
    >
      <span
        className={cn(
          "inline-block size-5 rounded-full bg-cream shadow-[0_1px_2px_rgb(0_0_0/0.25)] transition-transform duration-200 ease-[var(--ease-spring)]",
          checked ? "translate-x-[22px]" : "translate-x-[3px]",
        )}
      />
    </button>
  );
}

/* ---------- Segmented control (radio group) ---------- */
export function Segmented<T extends string>({
  value,
  onChange,
  options,
  label,
  className,
  size = "md",
}: {
  value: T;
  onChange: (v: T) => void;
  options: { value: T; label: ReactNode; icon?: ReactNode }[];
  label: string;
  className?: string;
  size?: "sm" | "md";
}) {
  return (
    <div role="radiogroup" aria-label={label} className={cn("flex gap-1 rounded-[14px] border border-line bg-paper-deep/60 p-1", className)}>
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
              "flex flex-1 items-center justify-center gap-1.5 rounded-[10px] px-2.5 font-display font-semibold transition-all duration-200",
              size === "md" ? "min-h-11 text-sm" : "min-h-11 text-[0.8125rem]",
              active ? "bg-cream text-accent shadow-[var(--shadow)]" : "text-muted hover:text-ink",
            )}
          >
            {o.icon}
            {o.label}
          </button>
        );
      })}
    </div>
  );
}

/* ---------- Chip (toggleable tag) ---------- */
export function Chip({
  selected,
  onClick,
  children,
  icon,
  className,
  as = "button",
}: {
  selected?: boolean;
  onClick?: () => void;
  children: ReactNode;
  icon?: ReactNode;
  className?: string;
  as?: "button" | "span";
}) {
  const cls = cn(
    "inline-flex min-h-10 items-center gap-1.5 rounded-[11px] border px-3 text-sm font-semibold transition-all duration-150",
    selected ? "border-accent bg-accent text-on-accent" : "border-line-strong bg-cream text-ink hover:bg-accent-soft",
    className,
  );
  if (as === "span") return <span className={cls}>{icon}{children}</span>;
  return (
    <button type="button" aria-pressed={selected} onClick={onClick} className={cn(cls, "active:scale-[0.97]")}>
      {icon}
      {children}
    </button>
  );
}

/* ---------- Form fields ---------- */
export function Field({ label, hint, error, children, htmlFor, optional }: { label: string; hint?: string; error?: string; children: ReactNode; htmlFor: string; optional?: boolean }) {
  return (
    <div className="space-y-1.5">
      <label htmlFor={htmlFor} className="flex items-baseline justify-between gap-2 font-display text-sm font-semibold text-ink">
        <span>{label}</span>
        {optional && <span className="text-xs font-medium text-faint">Optional</span>}
      </label>
      {children}
      {error ? (
        <p id={`${htmlFor}-error`} role="alert" className="text-[0.8125rem] font-medium text-[#a3301f] dark:text-[#f0a090]">
          {error}
        </p>
      ) : hint ? (
        <p id={`${htmlFor}-hint`} className="text-[0.8125rem] text-muted">
          {hint}
        </p>
      ) : null}
    </div>
  );
}

const inputCls =
  "w-full rounded-[13px] border border-line-strong bg-cream px-3.5 text-[0.9375rem] text-ink placeholder:text-faint transition-shadow focus:border-accent focus:outline-none focus:ring-3 focus:ring-accent/15 aria-[invalid=true]:border-[#a3301f]";

export function TextInput({ invalid, className, ...rest }: InputHTMLAttributes<HTMLInputElement> & { invalid?: boolean }) {
  return <input aria-invalid={invalid || undefined} aria-describedby={rest.id ? (invalid ? `${rest.id}-error` : `${rest.id}-hint`) : undefined} className={cn(inputCls, "min-h-12", className)} {...rest} />;
}

export function TextArea({ invalid, className, ...rest }: TextareaHTMLAttributes<HTMLTextAreaElement> & { invalid?: boolean }) {
  return <textarea aria-invalid={invalid || undefined} className={cn(inputCls, "min-h-24 resize-none py-3 leading-relaxed", className)} {...rest} />;
}

export function CharCount({ value, max }: { value: string; max: number }) {
  const over = value.length > max;
  return (
    <span className={cn("text-xs tabular-nums", over ? "font-semibold text-[#a3301f]" : "text-faint")} aria-live="polite">
      {value.length}/{max}
    </span>
  );
}

/* ---------- Progress ---------- */
export function ProgressBar({ value, max = 1, label, tone = "accent", className, size = "md" }: { value: number; max?: number; label: string; tone?: "accent" | "sage" | "gold" | "orange" | "sky" | "rose"; className?: string; size?: "sm" | "md" }) {
  const pct = Math.max(0, Math.min(1, max ? value / max : 0));
  const fill = { accent: "bg-accent", sage: "bg-sage", gold: "bg-gold", orange: "bg-orange", sky: "bg-sky", rose: "bg-rose" }[tone];
  return (
    <div
      role="progressbar"
      aria-label={label}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={Math.round(pct * 100)}
      className={cn("relative w-full overflow-hidden rounded-full border border-line bg-paper-deep/70", size === "md" ? "h-3" : "h-2", className)}
    >
      <div className={cn("h-full rounded-full transition-[width] duration-700 ease-[var(--ease-out-soft)]", fill)} style={{ width: `${pct * 100}%` }} />
    </div>
  );
}

/** A small, hand-drawn-feeling ring used for daily progress. */
export function ProgressRing({ value, size = 56, stroke = 6, label, children }: { value: number; size?: number; stroke?: number; label: string; children?: ReactNode }) {
  const id = useId();
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const pct = Math.max(0, Math.min(1, value));
  return (
    <div className="relative inline-grid shrink-0 place-items-center" style={{ width: size, height: size }} role="img" aria-label={label} aria-describedby={id}>
      <svg width={size} height={size} className="-rotate-90" aria-hidden>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="var(--paper-deep)" strokeWidth={stroke} />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke="var(--accent)"
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={c}
          strokeDashoffset={c * (1 - pct)}
          style={{ transition: "stroke-dashoffset 700ms var(--ease-out-soft)" }}
        />
      </svg>
      <span id={id} className="absolute inset-0 grid place-items-center">
        {children}
      </span>
    </div>
  );
}
