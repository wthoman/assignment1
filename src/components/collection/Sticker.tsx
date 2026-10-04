import { Lock } from "lucide-react";
import { Illustration, TINT_HEX } from "@/components/illustrations/Illustration";
import { cn } from "@/lib/cn";
import type { Collectible, StickerShape } from "@/lib/types";

const INK = "#2e1b1a";

function scallopPath(cx: number, cy: number, r: number, bumps: number) {
  let d = "";
  for (let i = 0; i <= bumps; i++) {
    const a = (i / bumps) * Math.PI * 2;
    const x = cx + Math.cos(a) * r;
    const y = cy + Math.sin(a) * r;
    if (i === 0) d += `M${x.toFixed(2)} ${y.toFixed(2)}`;
    else d += ` A${(r * Math.PI) / bumps} ${(r * Math.PI) / bumps} 0 0 1 ${x.toFixed(2)} ${y.toFixed(2)}`;
  }
  return d + "Z";
}

function starPath(cx: number, cy: number, outer: number, inner: number, points: number) {
  let d = "";
  for (let i = 0; i < points * 2; i++) {
    const r = i % 2 ? inner : outer;
    const a = (i / (points * 2)) * Math.PI * 2 - Math.PI / 2;
    d += `${i ? "L" : "M"}${(cx + Math.cos(a) * r).toFixed(2)} ${(cy + Math.sin(a) * r).toFixed(2)}`;
  }
  return d + "Z";
}

const SHAPES: Record<StickerShape, string> = {
  circle: "M50 6 A44 44 0 1 1 49.9 6 Z",
  scallop: scallopPath(50, 50, 42, 14),
  star: starPath(50, 52, 47, 30, 8),
  ticket: "M8 22 H92 V40 A10 10 0 0 0 92 60 V78 H8 V60 A10 10 0 0 0 8 40 Z",
  stamp: "M10 10 H90 V90 H10 Z",
  ribbon: "M50 4 A36 36 0 1 1 49.9 4 Z",
  heart: "M50 90 C20 70 6 52 6 34 C6 20 17 10 29 10 C39 10 46 16 50 24 C54 16 61 10 71 10 C83 10 94 20 94 34 C94 52 80 70 50 90 Z",
  badge: "M50 4 L88 20 V52 C88 72 72 88 50 96 C28 88 12 72 12 52 V20 Z",
};

/**
 * Die-cut sticker: a white border around a tinted shape with the collectible's
 * illustration. Locked stickers render as a dashed paper outline.
 */
export function Sticker({
  collectible,
  size = 96,
  locked = false,
  rotate = 0,
  className,
  peel = false,
}: {
  collectible: Pick<Collectible, "shape" | "motif" | "tint" | "name" | "rarity">;
  size?: number;
  locked?: boolean;
  rotate?: number;
  className?: string;
  peel?: boolean;
}) {
  const shape = SHAPES[collectible.shape];
  const fill = TINT_HEX[collectible.tint];
  const isStamp = collectible.shape === "stamp";

  if (locked) {
    return (
      <span className={cn("relative inline-grid place-items-center", className)} style={{ width: size, height: size, transform: `rotate(${rotate}deg)` }}>
        <svg viewBox="0 0 100 100" width={size} height={size} aria-hidden className="absolute inset-0">
          <path d={shape} fill="var(--paper-deep)" stroke="var(--line-strong)" strokeWidth="2.5" strokeDasharray="5 5" />
        </svg>
        <Lock className="relative text-faint" size={Math.max(14, size * 0.2)} aria-hidden />
      </span>
    );
  }

  return (
    <span className={cn("sticker-shadow relative inline-block", className)} style={{ width: size, height: size, transform: `rotate(${rotate}deg)` }}>
      <svg viewBox="-6 -6 112 112" width={size} height={size} aria-hidden className="absolute inset-0 overflow-visible">
        {/* die-cut white border */}
        <path d={shape} fill="#fffaf0" stroke="#fffaf0" strokeWidth="12" strokeLinejoin="round" />
        {isStamp ? (
          <>
            <path d={shape} fill="#fffaf0" stroke={fill} strokeWidth="4" strokeDasharray="4 4" />
            <rect x="18" y="18" width="64" height="64" fill={fill} opacity="0.85" />
          </>
        ) : (
          <path d={shape} fill={fill} stroke={INK} strokeWidth="2.6" strokeLinejoin="round" filter="url(#ink-wobble)" />
        )}
        {collectible.shape === "ribbon" && (
          <>
            <path d="M30 70 L22 100 L33 94 L38 104 L46 78 Z M70 70 L78 100 L67 94 L62 104 L54 78 Z" fill="#7a1d2c" stroke={INK} strokeWidth="2.4" strokeLinejoin="round" />
            <path d="M50 4 A36 36 0 1 1 49.9 4 Z" fill={fill} stroke={INK} strokeWidth="2.6" />
          </>
        )}
        <circle cx="50" cy={collectible.shape === "ribbon" ? 40 : 50} r={collectible.shape === "ticket" ? 22 : 27} fill="#fffaf0" opacity="0.55" />
        {collectible.rarity === "legendary" || collectible.rarity === "limited" ? (
          <path d="M18 30 l3 -6 l3 6 l-3 6 Z M80 74 l2.4 -5 l2.4 5 l-2.4 5 Z" fill="#fff6d8" stroke={INK} strokeWidth="1.4" />
        ) : null}
        {peel && <path d="M76 96 Q90 92 96 78 L96 96 Z" fill="#e8dcc4" stroke={INK} strokeWidth="1.4" opacity="0.9" />}
      </svg>
      <span className="absolute inset-0 grid place-items-center" style={{ paddingBottom: collectible.shape === "ribbon" ? size * 0.2 : 0 }}>
        <Illustration kind={collectible.motif} size={size * (collectible.shape === "ticket" ? 0.42 : 0.5)} />
      </span>
    </span>
  );
}
