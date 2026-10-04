import { BRAND } from "@/lib/brand";
import { cn } from "@/lib/cn";

/** Placeholder mark: a tiny stamped daybook page. Replace this file to rebrand. */
export function LogoMark({ size = 32, className }: { size?: number; className?: string }) {
  return (
    <svg viewBox="0 0 40 40" width={size} height={size} className={cn("shrink-0", className)} aria-hidden>
      <g filter="url(#ink-wobble)">
        <rect x="5" y="4" width="28" height="32" rx="6" fill="var(--accent)" />
        <rect x="9" y="4" width="24" height="32" rx="5" fill="var(--cream)" stroke="var(--accent)" strokeWidth="2.4" />
        <path d="M14 13 h13 M14 18 h9" stroke="var(--accent)" strokeWidth="2.2" strokeLinecap="round" opacity="0.45" />
        <circle cx="25" cy="27" r="7.2" fill="var(--accent)" />
        <path d="M21.6 27.2 l2.4 2.4 l4.4 -4.8" fill="none" stroke="var(--cream)" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" />
      </g>
    </svg>
  );
}

export function Logo({ size = 28, className, showName = true }: { size?: number; className?: string; showName?: boolean }) {
  return (
    <span className={cn("inline-flex items-center gap-2", className)}>
      <LogoMark size={size} />
      {showName && <span className="font-display text-xl font-extrabold tracking-[-0.03em] text-accent">{BRAND.name}</span>}
    </span>
  );
}
