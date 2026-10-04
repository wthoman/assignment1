import Link from "next/link";
import { ChevronRight } from "lucide-react";
import type { ReactNode } from "react";
import { Mascot } from "@/components/illustrations/Mascot";
import { cn } from "@/lib/cn";

export function EmptyState({
  title,
  body,
  action,
  mood = "thinking",
  className,
  compact,
}: {
  title: string;
  body?: string;
  action?: ReactNode;
  mood?: "happy" | "sleepy" | "thinking" | "wave";
  className?: string;
  compact?: boolean;
}) {
  return (
    <div className={cn("flex flex-col items-center rounded-[var(--radius-card)] border border-dashed border-line-strong bg-cream/60 text-center", compact ? "gap-2 px-4 py-6" : "gap-3 px-6 py-10", className)}>
      <Mascot mood={mood} size={compact ? 64 : 92} />
      <div>
        <p className="font-display text-lg font-bold text-ink">{title}</p>
        {body && <p className="mx-auto mt-1 max-w-xs text-sm leading-relaxed text-muted">{body}</p>}
      </div>
      {action}
    </div>
  );
}

export function SectionHeading({ title, count, action, className, id, hand }: { title: string; count?: number | string; action?: ReactNode; className?: string; id?: string; hand?: string }) {
  return (
    <div className={cn("flex items-end justify-between gap-3", className)}>
      <h2 id={id} className="flex items-baseline gap-2 font-display text-[1.0625rem] font-bold tracking-[-0.015em] text-ink">
        {title}
        {count !== undefined && <span className="font-sans text-sm font-semibold text-faint tabular-nums">{count}</span>}
        {hand && <span className="font-hand text-lg font-medium text-accent">{hand}</span>}
      </h2>
      {action}
    </div>
  );
}

/** One row in a settings list. Renders as a link, a button or a static row with a trailing control. */
export function SettingsRow({
  icon,
  label,
  detail,
  href,
  onClick,
  control,
  tone = "default",
  value,
}: {
  icon?: ReactNode;
  label: string;
  detail?: string;
  href?: string;
  onClick?: () => void;
  control?: ReactNode;
  tone?: "default" | "danger";
  value?: string;
}) {
  const inner = (
    <>
      {icon && <span className={cn("grid size-9 shrink-0 place-items-center rounded-[11px]", tone === "danger" ? "bg-[#f6ddd6] text-[#8e2a1e]" : "bg-accent-soft text-accent")}>{icon}</span>}
      <span className="min-w-0 flex-1">
        <span className={cn("block text-[0.9375rem] font-semibold", tone === "danger" ? "text-[#8e2a1e] dark:text-[#f0a090]" : "text-ink")}>{label}</span>
        {detail && <span className="mt-0.5 block text-[0.8125rem] leading-snug text-muted">{detail}</span>}
      </span>
      {value && <span className="shrink-0 text-sm text-muted">{value}</span>}
      {control}
      {(href || onClick) && !control && <ChevronRight size={18} className="shrink-0 text-faint" aria-hidden />}
    </>
  );
  const cls = "flex min-h-14 w-full items-center gap-3 px-4 py-2.5 text-left";
  if (href)
    return (
      <Link href={href} className={cn(cls, "transition-colors hover:bg-accent-soft/50")}>
        {inner}
      </Link>
    );
  if (onClick)
    return (
      <button type="button" onClick={onClick} className={cn(cls, "transition-colors hover:bg-accent-soft/50")}>
        {inner}
      </button>
    );
  return <div className={cls}>{inner}</div>;
}

export function SettingsGroup({ title, children, footer }: { title?: string; children: ReactNode; footer?: string }) {
  return (
    <section className="space-y-2">
      {title && <h3 className="eyebrow px-1">{title}</h3>}
      <div className="card divide-y divide-line overflow-hidden">{children}</div>
      {footer && <p className="px-1 text-[0.8125rem] leading-relaxed text-muted">{footer}</p>}
    </section>
  );
}

export function Tape({ className, rotate = -6 }: { className?: string; rotate?: number }) {
  return <span aria-hidden className={cn("tape", className)} style={{ transform: `rotate(${rotate}deg)` }} />;
}

export function HandNote({ children, className, rotate = -3 }: { children: ReactNode; className?: string; rotate?: number }) {
  return (
    <span className={cn("inline-block font-hand text-lg leading-tight text-accent", className)} style={{ transform: `rotate(${rotate}deg)` }}>
      {children}
    </span>
  );
}

export function Skeleton({ className }: { className?: string }) {
  return <div className={cn("skeleton rounded-[12px]", className)} aria-hidden />;
}

export function Badge({ children, tone = "accent", className }: { children: ReactNode; tone?: "accent" | "sage" | "gold" | "muted" | "orange"; className?: string }) {
  const tones = {
    accent: "bg-accent-soft text-accent",
    sage: "bg-sage-soft text-sage-ink",
    gold: "bg-gold-soft text-[#6b5016] dark:text-gold",
    orange: "bg-orange-soft text-[#7a3f12] dark:text-orange",
    muted: "bg-paper-deep text-muted",
  };
  return <span className={cn("inline-flex items-center gap-1 rounded-[7px] px-1.5 py-0.5 text-[0.6875rem] font-bold uppercase tracking-[0.06em]", tones[tone], className)}>{children}</span>;
}
