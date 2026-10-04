import type { ReactNode } from "react";
import type { IllustrationKey, Tint } from "@/lib/types";
import { cn } from "@/lib/cn";

/* Fixed illustration palette so drawings read the same in light and dark themes. */
const C = {
  ink: "#2e1b1a",
  cream: "#fbf6ec",
  beige: "#efe0c2",
  burgundy: "#7a1d2c",
  rose: "#d9a3a0",
  orange: "#e09a5f",
  gold: "#d4ad55",
  sage: "#8fa382",
  sky: "#a9c3d4",
};

const S = { stroke: C.ink, strokeWidth: 2.6, strokeLinecap: "round" as const, strokeLinejoin: "round" as const };

const DRAWINGS: Record<IllustrationKey, ReactNode> = {
  shoe: (
    <>
      <path d="M7 33.5 C7 26 9.5 19.5 14 18 L20.5 17 C21.5 21 25.5 23.4 30 23.8 C35 24.4 40 27 41.5 31 L41.5 33.5 Z" fill={C.orange} {...S} />
      <path d="M5.5 33.5 H42 a2.8 2.8 0 0 1 0 5.6 H9 a3.5 3.5 0 0 1 -3.5 -3.5 Z" fill={C.cream} {...S} />
      <path d="M19.5 21.5 l3.6 -2.2 M22.4 24.6 l3.6 -2.2 M26 27 l3.4 -2" {...S} strokeWidth={2.1} fill="none" />
      <path d="M11 28.5 q6 -2.6 11.5 1.6" {...S} strokeWidth={2} fill="none" stroke={C.burgundy} />
    </>
  ),
  water: (
    <>
      <path d="M11.5 9 H36.5 L33.6 38.6 a3.2 3.2 0 0 1 -3.2 2.9 H17.6 a3.2 3.2 0 0 1 -3.2 -2.9 Z" fill={C.cream} />
      <path d="M13.2 22.5 q5.3 -2.4 10.6 0 t10.8 0 L33.2 38.4 a2.6 2.6 0 0 1 -2.6 2.3 H17.4 a2.6 2.6 0 0 1 -2.6 -2.3 Z" fill={C.sky} />
      <path d="M11.5 9 H36.5 L33.6 38.6 a3.2 3.2 0 0 1 -3.2 2.9 H17.6 a3.2 3.2 0 0 1 -3.2 -2.9 Z" fill="none" {...S} />
      <path d="M13.2 22.5 q5.3 -2.4 10.6 0 t10.8 0" fill="none" {...S} strokeWidth={2} />
      <circle cx="21" cy="30" r="1.7" fill={C.cream} {...S} strokeWidth={1.6} />
      <circle cx="27.5" cy="34.5" r="1.2" fill={C.cream} {...S} strokeWidth={1.4} />
      <path d="M17 13.5 v5" stroke={C.cream} strokeWidth={2.4} strokeLinecap="round" opacity={0.9} />
    </>
  ),
  book: (
    <>
      <path d="M10.5 10.5 H33 a3.5 3.5 0 0 1 3.5 3.5 V38.5 H15 a4.5 4.5 0 0 1 -4.5 -4.5 Z" fill={C.gold} {...S} />
      <path d="M36.5 38.5 H15 a4.3 4.3 0 0 1 0 -8.6 H36.5" fill={C.cream} {...S} />
      <path d="M27 10.5 V20.5 L29.6 18.4 L32.2 20.5 V10.5" fill={C.burgundy} {...S} strokeWidth={2.2} />
      <path d="M16 16.5 h7 M16 21 h5" {...S} strokeWidth={2} fill="none" />
    </>
  ),
  alarm: (
    <>
      <path d="M10 14.5 a6 6 0 0 1 8.5 -4.2 M38 14.5 a6 6 0 0 0 -8.5 -4.2" fill={C.burgundy} {...S} />
      <path d="M15 38.5 l-3 3.5 M33 38.5 l3 3.5" {...S} fill="none" />
      <circle cx="24" cy="26.5" r="13.2" fill={C.rose} {...S} />
      <circle cx="24" cy="26.5" r="9.4" fill={C.cream} {...S} strokeWidth={2} />
      <path d="M24 20.5 V27 L28.5 29.5" {...S} fill="none" />
      <circle cx="24" cy="10.8" r="2" fill={C.gold} {...S} strokeWidth={2} />
    </>
  ),
  flower: (
    <>
      <path d="M24 26 V36" {...S} fill="none" stroke={C.ink} />
      <path d="M24 32 c-4 -4.5 -9 -3.5 -10 -1.5 c3 2.5 7 3.2 10 1.5 Z" fill={C.sage} {...S} strokeWidth={2.2} />
      <path d="M15 35.5 H33 L31 42.5 a1.8 1.8 0 0 1 -1.8 1.4 H18.8 a1.8 1.8 0 0 1 -1.8 -1.4 Z" fill={C.orange} {...S} />
      {[0, 72, 144, 216, 288].map((r) => (
        <ellipse key={r} cx="24" cy="12.2" rx="4.4" ry="5.6" fill={C.rose} {...S} strokeWidth={2.2} transform={`rotate(${r} 24 18.5)`} />
      ))}
      <circle cx="24" cy="18.5" r="3.6" fill={C.gold} {...S} strokeWidth={2.2} />
    </>
  ),
  dumbbell: (
    <>
      <path d="M14 24 H34" {...S} strokeWidth={3.6} fill="none" />
      <rect x="8.5" y="14.5" width="6.4" height="19" rx="2.4" fill={C.burgundy} {...S} />
      <rect x="33.1" y="14.5" width="6.4" height="19" rx="2.4" fill={C.burgundy} {...S} />
      <rect x="4.8" y="18.5" width="4.2" height="11" rx="1.6" fill={C.rose} {...S} strokeWidth={2.2} />
      <rect x="39" y="18.5" width="4.2" height="11" rx="1.6" fill={C.rose} {...S} strokeWidth={2.2} />
    </>
  ),
  moon: (
    <>
      <path d="M30.5 8.5 A16 16 0 1 0 40 33 A13 13 0 0 1 30.5 8.5 Z" fill={C.gold} {...S} />
      <path d="M19 25.5 q2.3 2 4.6 0" {...S} strokeWidth={2.1} fill="none" />
      <circle cx="17" cy="30" r="1.8" fill={C.rose} />
      <path d="M33 12 h4.2 l-4.2 4.6 h4.2 M37.5 19.5 h3 l-3 3.4 h3" {...S} strokeWidth={1.8} fill="none" />
    </>
  ),
  pencil: (
    <>
      <path d="M12.5 35.5 L33 15 L38 20 L17.5 40.5 Z" fill={C.gold} {...S} />
      <path d="M33 15 L36.4 11.6 a2.6 2.6 0 0 1 3.7 0 L41.4 12.9 a2.6 2.6 0 0 1 0 3.7 L38 20 Z" fill={C.rose} {...S} />
      <path d="M31 17 L36 22" {...S} strokeWidth={2} fill="none" />
      <path d="M12.5 35.5 L9 44 L17.5 40.5 Z" fill={C.cream} {...S} strokeWidth={2.2} />
      <path d="M9 44 L10.6 40.2 L12.8 42.4 Z" fill={C.ink} />
      <path d="M16 32 L30 18" stroke={C.cream} strokeWidth={1.8} strokeLinecap="round" opacity={0.7} />
    </>
  ),
  fruit: (
    <>
      <path d="M24 14 C19.5 14 19 20 17 24 C13.5 30 13.5 41 24 41 C34.5 41 34.5 30 31 24 C29 20 28.5 14 24 14 Z" fill={C.sage} {...S} />
      <path d="M24 14 C24 11 25 8.5 27 7" {...S} fill="none" />
      <path d="M26 10.5 C29 7 34 7.5 35 9 C32.5 12 28.5 12.5 26 10.5 Z" fill={C.sage} {...S} strokeWidth={2} />
      <path d="M19.5 30 q-1 4.5 2 7" stroke={C.cream} strokeWidth={2} strokeLinecap="round" fill="none" opacity={0.8} />
    </>
  ),
  mascot: (
    <>
      <path d="M24 9.5 C33.5 9.5 39.5 18 39.5 27 C39.5 36 33 41.5 24 41.5 C15 41.5 8.5 36 8.5 27 C8.5 18 14.5 9.5 24 9.5 Z" fill={C.rose} {...S} />
      <path d="M24 9.5 C24 6.5 25.5 4.5 28 4" {...S} fill="none" />
      <path d="M26.5 5.5 C29 3 32.5 3.5 33.5 4.8 C31.5 7 28.5 7.3 26.5 5.5 Z" fill={C.sage} {...S} strokeWidth={1.9} />
      <circle cx="19" cy="25" r="2.1" fill={C.ink} />
      <circle cx="29" cy="25" r="2.1" fill={C.ink} />
      <path d="M21 30.5 q3 2.8 6 0" {...S} strokeWidth={2.2} fill="none" />
      <ellipse cx="15.5" cy="29.5" rx="2.4" ry="1.5" fill={C.burgundy} opacity={0.35} />
      <ellipse cx="32.5" cy="29.5" rx="2.4" ry="1.5" fill={C.burgundy} opacity={0.35} />
    </>
  ),
  leaf: (
    <>
      <path d="M10 38 C9 22 20 9.5 39 9 C39.5 28 27 39 10 38 Z" fill={C.sage} {...S} />
      <path d="M10 38 C17 30 24 23 33 15 M18 30 h6.5 M22.5 25.5 l-0.5 -6" {...S} strokeWidth={2} fill="none" />
    </>
  ),
  bike: (
    <>
      <circle cx="13" cy="31" r="7.5" fill={C.cream} {...S} />
      <circle cx="35" cy="31" r="7.5" fill={C.cream} {...S} />
      <path d="M13 31 L19.5 19.5 H31 L35 31 M19.5 19.5 L24 31 L31 19.5 M24 31 H13" {...S} stroke={C.burgundy} fill="none" />
      <path d="M17 15.5 H22.5 M29.5 14 l2 5.5 M28 14 h4.5" {...S} fill="none" />
    </>
  ),
  music: (
    <>
      <path d="M18.5 33 V12 L36 8.5 V29" {...S} fill="none" />
      <path d="M18.5 15.5 L36 12" {...S} strokeWidth={4.2} />
      <ellipse cx="14.5" cy="33.5" rx="5" ry="4" fill={C.burgundy} {...S} transform="rotate(-15 14.5 33.5)" />
      <ellipse cx="32" cy="29.5" rx="5" ry="4" fill={C.burgundy} {...S} transform="rotate(-15 32 29.5)" />
    </>
  ),
  coffee: (
    <>
      <path d="M10.5 19 H32 V33 a7 7 0 0 1 -7 7 H17.5 a7 7 0 0 1 -7 -7 Z" fill={C.cream} {...S} />
      <path d="M32 22.5 h2.5 a4.5 4.5 0 0 1 0 9 H32" {...S} fill="none" />
      <path d="M11 25 H31.5" stroke={C.orange} strokeWidth={4} />
      <path d="M10.5 19 H32 V33 a7 7 0 0 1 -7 7 H17.5 a7 7 0 0 1 -7 -7 Z" fill="none" {...S} />
      <path d="M17 14.5 c-2 -2.5 2 -4 0 -7 M23.5 14.5 c-2 -2.5 2 -4 0 -7" {...S} strokeWidth={2} fill="none" />
    </>
  ),
  sun: (
    <>
      {[0, 45, 90, 135, 180, 225, 270, 315].map((r) => (
        <path key={r} d="M24 5.5 V10.5" {...S} transform={`rotate(${r} 24 24)`} />
      ))}
      <circle cx="24" cy="24" r="10" fill={C.gold} {...S} />
      <path d="M20 23 q1.4 -1.5 2.8 0 M25.2 23 q1.4 -1.5 2.8 0 M21.5 27.5 q2.5 2 5 0" {...S} strokeWidth={1.8} fill="none" />
    </>
  ),
  heart: (
    <>
      <path d="M24 40 C12 32 7 25.5 7 18.5 C7 13 11 9.5 15.6 9.5 C19.5 9.5 22.4 12 24 15 C25.6 12 28.5 9.5 32.4 9.5 C37 9.5 41 13 41 18.5 C41 25.5 36 32 24 40 Z" fill={C.rose} {...S} />
      <path d="M13 17.5 c0.5 -2.5 2.2 -3.6 4.3 -3.6" stroke={C.cream} strokeWidth={2.2} strokeLinecap="round" fill="none" />
    </>
  ),
  star: (
    <>
      <path d="M24 6.5 L28.6 17.4 L40.4 18.3 L31.4 26 L34.2 37.6 L24 31.4 L13.8 37.6 L16.6 26 L7.6 18.3 L19.4 17.4 Z" fill={C.gold} {...S} />
      <path d="M21 23.5 q0.8 -1 1.6 0 M25.4 23.5 q0.8 -1 1.6 0" {...S} strokeWidth={1.6} fill="none" />
    </>
  ),
  crown: (
    <>
      <path d="M8.5 33.5 L6.5 15 L16 23 L24 11 L32 23 L41.5 15 L39.5 33.5 Z" fill={C.gold} {...S} />
      <path d="M8.5 33.5 H39.5 V38.5 H8.5 Z" fill={C.burgundy} {...S} />
      <circle cx="24" cy="27.5" r="2.4" fill={C.rose} {...S} strokeWidth={1.8} />
      <circle cx="15" cy="29" r="1.6" fill={C.sky} {...S} strokeWidth={1.6} />
      <circle cx="33" cy="29" r="1.6" fill={C.sage} {...S} strokeWidth={1.6} />
    </>
  ),
  ribbon: (
    <>
      <path d="M17 26 L12.5 43 L18 40 L21 45 L24 30 M31 26 L35.5 43 L30 40 L27 45 L24 30" fill={C.burgundy} {...S} strokeWidth={2.2} />
      <circle cx="24" cy="19.5" r="13" fill={C.rose} {...S} />
      <circle cx="24" cy="19.5" r="8" fill={C.cream} {...S} strokeWidth={2.2} />
      <path d="M20.5 19.5 l2.5 2.6 l4.5 -5" {...S} stroke={C.burgundy} fill="none" />
    </>
  ),
  ticket: (
    <>
      <path d="M7 15 H41 V20.5 a3.5 3.5 0 0 0 0 7 V33 H7 V27.5 a3.5 3.5 0 0 0 0 -7 Z" fill={C.orange} {...S} />
      <path d="M31 16 V32" stroke={C.ink} strokeWidth={2} strokeDasharray="2.5 3" />
      <path d="M13.5 21 h11 M13.5 26.5 h7" {...S} strokeWidth={2.2} fill="none" />
    </>
  ),
  phone: (
    <>
      <rect x="14" y="6.5" width="20" height="35" rx="4.5" fill={C.sky} {...S} />
      <rect x="17.2" y="11" width="13.6" height="22" rx="2" fill={C.cream} {...S} strokeWidth={2} />
      <path d="M24 26 C20 23.4 19 21.5 19 19.8 C19 18.2 20.2 17.2 21.5 17.2 C22.6 17.2 23.4 17.9 24 18.8 C24.6 17.9 25.4 17.2 26.5 17.2 C27.8 17.2 29 18.2 29 19.8 C29 21.5 28 23.4 24 26 Z" fill={C.rose} {...S} strokeWidth={1.6} />
      <path d="M22 37.3 h4" {...S} strokeWidth={2} />
    </>
  ),
};

export function Illustration({ kind, size = 40, className, title, wobble = true }: { kind: IllustrationKey; size?: number; className?: string; title?: string; wobble?: boolean }) {
  return (
    <svg
      viewBox="0 0 48 48"
      width={size}
      height={size}
      className={cn("shrink-0 overflow-visible", className)}
      role={title ? "img" : undefined}
      aria-hidden={title ? undefined : true}
      aria-label={title}
    >
      <g filter={wobble ? "url(#ink-wobble)" : undefined}>{DRAWINGS[kind]}</g>
    </svg>
  );
}

export const TINT_SOFT: Record<Tint, string> = {
  burgundy: "bg-accent-soft",
  rose: "bg-rose-soft",
  orange: "bg-orange-soft",
  gold: "bg-gold-soft",
  sage: "bg-sage-soft",
  sky: "bg-sky-soft",
  cream: "bg-paper",
};

export const TINT_SOLID: Record<Tint, string> = {
  burgundy: "bg-accent",
  rose: "bg-rose",
  orange: "bg-orange",
  gold: "bg-gold",
  sage: "bg-sage",
  sky: "bg-sky",
  cream: "bg-paper-deep",
};

export const TINT_HEX: Record<Tint, string> = {
  burgundy: "#6f1725",
  rose: "#d9a3a0",
  orange: "#e09a5f",
  gold: "#c9a24a",
  sage: "#8fa382",
  sky: "#a9c3d4",
  cream: "#efe0c2",
};

/** Illustrated tile: a softly tinted, slightly rotated square holding a drawing. */
export function IllustrationTile({
  kind,
  tint,
  size = 48,
  rotate = 0,
  muted = false,
  className,
}: {
  kind: IllustrationKey;
  tint: Tint;
  size?: number;
  rotate?: number;
  muted?: boolean;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "relative inline-grid shrink-0 place-items-center rounded-[var(--radius-tile)] border border-line transition-[filter,background-color] duration-500",
        TINT_SOFT[tint],
        muted && "grayscale-[0.7] opacity-80",
        className,
      )}
      style={{ width: size, height: size, transform: rotate ? `rotate(${rotate}deg)` : undefined }}
      aria-hidden
    >
      <Illustration kind={kind} size={Math.round(size * 0.78)} />
    </span>
  );
}

/** Shared SVG filter definitions. Rendered once at the app root. */
export function SvgDefs() {
  return (
    <svg width="0" height="0" className="absolute" aria-hidden focusable="false">
      <defs>
        <filter id="ink-wobble" x="-10%" y="-10%" width="120%" height="120%">
          <feTurbulence type="fractalNoise" baseFrequency="0.045" numOctaves="2" seed="7" result="noise" />
          <feDisplacementMap in="SourceGraphic" in2="noise" scale="1.6" xChannelSelector="R" yChannelSelector="G" />
        </filter>
        <filter id="ink-rough" x="-10%" y="-10%" width="120%" height="120%">
          <feTurbulence type="fractalNoise" baseFrequency="0.6" numOctaves="2" seed="3" result="noise" />
          <feDisplacementMap in="SourceGraphic" in2="noise" scale="2.2" />
        </filter>
      </defs>
    </svg>
  );
}
