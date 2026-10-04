import { cn } from "@/lib/cn";

/**
 * Ink stamp mark. `animate` plays the landing animation (used right after a check-in).
 * Variants: "check" (completion), "date" (circular dated stamp), "label" (rectangular word stamp).
 */
export function Stamp({
  variant = "check",
  text,
  size = 44,
  animate,
  className,
  color = "var(--accent)",
  rotate = -8,
}: {
  variant?: "check" | "date" | "label";
  text?: string;
  size?: number;
  animate?: boolean;
  className?: string;
  color?: string;
  rotate?: number;
}) {
  if (variant === "label") {
    return (
      <span
        className={cn("inline-block rounded-[6px] border-[2.5px] px-2 py-0.5 font-display text-[0.7rem] font-extrabold uppercase tracking-[0.12em]", animate && "animate-stamp", className)}
        style={{ color, borderColor: color, transform: `rotate(${rotate}deg)`, filter: "url(#ink-rough)", opacity: 0.9 }}
      >
        {text}
      </span>
    );
  }
  if (variant === "date") {
    return (
      <svg viewBox="0 0 80 80" width={size} height={size} className={cn(animate && "animate-stamp", className)} style={{ transform: `rotate(${rotate}deg)` }} aria-hidden>
        <g filter="url(#ink-rough)" fill="none" stroke={color} opacity="0.88">
          <circle cx="40" cy="40" r="36" strokeWidth="3" />
          <circle cx="40" cy="40" r="29" strokeWidth="1.5" strokeDasharray="2 3" />
          <text x="40" y="47" textAnchor="middle" fill={color} stroke="none" fontFamily="var(--font-display)" fontWeight="800" fontSize="20">
            {text}
          </text>
        </g>
      </svg>
    );
  }
  return (
    <svg viewBox="0 0 48 48" width={size} height={size} className={cn(animate && "animate-stamp", className)} style={animate ? undefined : { transform: `rotate(${rotate}deg)` }} aria-hidden>
      <g filter="url(#ink-rough)">
        <circle cx="24" cy="24" r="20.5" fill={color} opacity="0.95" />
        <circle cx="24" cy="24" r="16.5" fill="none" stroke="var(--on-accent)" strokeWidth="1.4" strokeDasharray="2.2 2.6" opacity="0.7" />
        <path d="M15.5 24.5 L21.5 30.5 L33 17.5" fill="none" stroke="var(--on-accent)" strokeWidth="4.2" strokeLinecap="round" strokeLinejoin="round" />
      </g>
    </svg>
  );
}
