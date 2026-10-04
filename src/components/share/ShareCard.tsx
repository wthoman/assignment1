"use client";

import { forwardRef, type CSSProperties } from "react";
import { AvatarArt } from "@/components/avatar/Avatar";
import { Sticker } from "@/components/collection/Sticker";
import { Illustration, SvgDefs, TINT_HEX } from "@/components/illustrations/Illustration";
import { Mascot } from "@/components/illustrations/Mascot";
import { Stamp } from "@/components/ui/Stamp";
import { BRAND } from "@/lib/brand";
import { COLLECTIBLE_BY_ID } from "@/lib/data/catalog";
import type { AccentKey } from "@/lib/types";
import type { ShareArt, ShareContent } from "./shareContent";

/**
 * Share cards are exported artifacts, so they use a fixed light palette (they must look
 * the same in dark mode and as PNGs). The accent still follows the user's accent setting.
 */
export const CARD_ACCENT: Record<AccentKey, string> = { burgundy: "#6f1725", forest: "#2f5d3a", ink: "#2b3a55", terracotta: "#9c4320" };
const CREAM = "#fbf6ec";
const PAPER = "#f3e8d2";
const INK = "#271c1b";
const MUTED = "#6d5a4e";

export const CARD_SIZE = { story: { w: 360, h: 640 }, square: { w: 420, h: 420 }, thumb: { w: 300, h: 158 } } as const;

function Art({ art, size, accent }: { art: ShareArt; size: number; accent: string }) {
  switch (art.type) {
    case "habit":
      return (
        <span className="relative grid place-items-center rounded-[22px]" style={{ width: size, height: size, background: TINT_HEX[art.tint] + "38", border: `1.5px solid ${accent}2e`, transform: "rotate(-4deg)" }}>
          <Illustration kind={art.icon} size={size * 0.74} />
        </span>
      );
    case "sticker": {
      const c = COLLECTIBLE_BY_ID[art.collectibleId];
      return c ? <Sticker collectible={c} size={size} rotate={-6} /> : null;
    }
    case "avatar":
      return <AvatarArt config={art.config} size={size} />;
    default:
      return <Mascot mood={art.mood} size={size} />;
  }
}

function MiniBars({ bars, accent, height }: { bars: NonNullable<ShareContent["bars"]>; accent: string; height: number }) {
  const max = Math.max(...bars.map((b) => b.value), 0.0001);
  return (
    <div style={{ display: "flex", alignItems: "flex-end", gap: 8, height: height + 34 }}>
      {bars.map((b, i) => (
        <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
          {b.caption && <span style={{ fontSize: 11, fontWeight: 700, color: MUTED }}>{b.caption}</span>}
          <div style={{ width: "100%", maxWidth: 30, height: Math.max(4, (b.value / max) * height), background: b.value === max ? accent : accent + "40", borderRadius: "4px 4px 0 0" }} />
          <span style={{ fontSize: 11, fontWeight: 700, color: MUTED }}>{b.label}</span>
        </div>
      ))}
    </div>
  );
}

function Grid({ cells, accent, cell }: { cells: (0 | 1 | 2)[]; accent: string; cell: number }) {
  // 12 columns (weeks) × 7 rows (days)
  const weeks = Array.from({ length: Math.ceil(cells.length / 7) }, (_, w) => cells.slice(w * 7, w * 7 + 7));
  return (
    <div style={{ display: "flex", gap: 3 }}>
      {weeks.map((col, w) => (
        <div key={w} style={{ display: "flex", flexDirection: "column", gap: 3 }}>
          {col.map((v, d) => (
            <span key={d} style={{ width: cell, height: cell, borderRadius: 3, background: v === 2 ? accent : v === 1 ? accent + "22" : "transparent", border: v === 0 ? `1px dashed ${accent}33` : "none" }} />
          ))}
        </div>
      ))}
    </div>
  );
}

function Brand({ accent }: { accent: string }) {
  return (
    <span style={{ display: "inline-flex", alignItems: "center", gap: 6, color: accent }} className="font-display">
      <svg viewBox="0 0 40 40" width={20} height={20} aria-hidden>
        <rect x="5" y="4" width="28" height="32" rx="6" fill={accent} />
        <rect x="9" y="4" width="24" height="32" rx="5" fill={CREAM} stroke={accent} strokeWidth="2.4" />
        <circle cx="25" cy="27" r="7.2" fill={accent} />
        <path d="M21.6 27.2 l2.4 2.4 l4.4 -4.8" fill="none" stroke={CREAM} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
      <span style={{ fontWeight: 800, fontSize: 15, letterSpacing: "-0.03em" }}>{BRAND.name}</span>
    </span>
  );
}

const base: CSSProperties = { position: "relative", overflow: "hidden", background: CREAM, color: INK, fontFamily: "var(--font-sans)" };

/** A purpose-built story (9:16) or square (1:1) share card. */
export const ShareCard = forwardRef<HTMLDivElement, { content: ShareContent; format: "story" | "square"; accentKey: AccentKey }>(function ShareCard({ content: c, format, accentKey }, ref) {
  const accent = CARD_ACCENT[accentKey];
  const story = format === "story";
  const { w, h } = CARD_SIZE[format];
  const artSize = story ? (c.grid || c.bars ? 120 : 168) : c.grid || c.bars || c.progress ? 92 : 128;
  const headlineSize = c.headline.length > 22 ? (story ? 34 : 30) : story ? 44 : 38;

  return (
    <div ref={ref} style={{ ...base, width: w, height: h, borderRadius: 22 }} className="font-sans">
      {/* filter defs travel with the node so exported images keep the hand-drawn wobble */}
      <SvgDefs />
      {/* paper edge + ruled corner */}
      <div style={{ position: "absolute", inset: 10, border: `1.5px dashed ${accent}33`, borderRadius: 16 }} aria-hidden />
      <span className="tape" style={{ top: -4, left: w / 2 - 27, transform: "rotate(-3deg)" }} aria-hidden />
      <div style={{ position: "relative", height: "100%", display: "flex", flexDirection: "column", padding: story ? "34px 28px 26px" : "26px 26px 22px" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8 }}>
          <Brand accent={accent} />
          {c.stamp && <Stamp variant="label" text={c.stamp} color={accent} rotate={6} />}
        </div>

        <div style={{ flex: 1, display: "flex", flexDirection: story ? "column" : "row", alignItems: story ? "flex-start" : "center", justifyContent: "center", gap: story ? 18 : 18, marginTop: story ? 10 : 6 }}>
          <div style={{ flexShrink: 0, position: "relative", alignSelf: story ? "center" : undefined, marginBottom: story ? 6 : 0 }}>
            <Art art={c.art} size={artSize} accent={accent} />
            {c.stamp === "Done" && (
              <span style={{ position: "absolute", right: -14, bottom: -10 }}>
                <Stamp size={story ? 56 : 44} color={accent} />
              </span>
            )}
          </div>
          <div style={{ minWidth: 0, flex: story ? undefined : 1 }}>
            <p style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.08em", textTransform: "uppercase", color: accent, margin: 0 }} className="font-display">
              {c.eyebrow}
            </p>
            <p style={{ fontSize: headlineSize, lineHeight: 1.02, fontWeight: 800, letterSpacing: "-0.04em", color: accent, margin: "6px 0 0" }} className="font-display">
              {c.headline}
            </p>
            {c.sub && <p style={{ fontSize: story ? 15 : 14, lineHeight: 1.4, color: MUTED, margin: "10px 0 0" }}>{c.sub}</p>}
            {c.note && <p style={{ fontSize: 13, lineHeight: 1.35, color: INK, margin: "8px 0 0", fontWeight: 600 }}>{c.note}</p>}
          </div>
        </div>

        {(c.bars || c.grid || c.progress || c.stat) && (
          <div style={{ marginTop: 14, padding: "14px 14px 12px", background: PAPER, borderRadius: 16, border: `1px solid ${accent}22` }}>
            {c.bars && <MiniBars bars={c.bars} accent={accent} height={story ? 70 : 44} />}
            {c.grid && <Grid cells={c.grid} accent={accent} cell={story ? 17 : 14} />}
            {c.progress && (
              <div>
                <div style={{ height: 14, borderRadius: 999, background: accent + "22", overflow: "hidden" }}>
                  <div style={{ width: `${Math.min(100, (c.progress.value / c.progress.max) * 100)}%`, height: "100%", background: accent, borderRadius: 999 }} />
                </div>
                <p style={{ margin: "6px 0 0", fontSize: 12, fontWeight: 700, color: MUTED }}>{c.progress.label}</p>
                {c.people && (
                  <div style={{ display: "flex", marginTop: 8 }}>
                    {c.people.map((p, i) => (
                      <span key={i} style={{ marginLeft: i ? -8 : 0, borderRadius: 999, background: CREAM }}>
                        <AvatarArt config={{ ...p, companion: "none" }} size={30} />
                      </span>
                    ))}
                  </div>
                )}
              </div>
            )}
            {c.stat && (
              <p style={{ margin: c.bars || c.grid ? "10px 0 0" : 0, display: "flex", alignItems: "baseline", gap: 8 }}>
                <span className="font-display" style={{ fontSize: 26, fontWeight: 800, color: accent, letterSpacing: "-0.03em" }}>
                  {c.stat.value}
                </span>
                <span style={{ fontSize: 13, color: MUTED }}>{c.stat.label}</span>
              </p>
            )}
          </div>
        )}

        <div style={{ marginTop: 16, display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8 }}>
          {c.footer ? (
            <span style={{ display: "inline-flex", alignItems: "center", gap: 8, fontSize: 13, fontWeight: 700 }}>
              <AvatarArt config={{ ...c.footer.avatar, companion: "none" }} size={28} />
              {c.footer.name}
            </span>
          ) : (
            <span className="font-hand" style={{ fontSize: 20, color: accent }}>
              small habits, kept
            </span>
          )}
          <span style={{ fontSize: 12, color: MUTED, fontWeight: 600 }}>{c.url.replace(/^https:\/\//, "")}</span>
        </div>
      </div>
    </div>
  );
});

/** 1.91:1 link-preview thumbnail used inside the message format. */
export const ShareThumb = forwardRef<HTMLDivElement, { content: ShareContent; accentKey: AccentKey }>(function ShareThumb({ content: c, accentKey }, ref) {
  const accent = CARD_ACCENT[accentKey];
  const { w, h } = CARD_SIZE.thumb;
  return (
    <div ref={ref} style={{ ...base, width: w, height: h, display: "flex", alignItems: "center", gap: 14, padding: "14px 18px" }}>
      <SvgDefs />
      <div style={{ position: "absolute", inset: 6, border: `1.5px dashed ${accent}33`, borderRadius: 10 }} aria-hidden />
      <div style={{ flexShrink: 0, position: "relative" }}>
        <Art art={c.art} size={88} accent={accent} />
      </div>
      <div style={{ minWidth: 0, position: "relative" }}>
        <p className="font-display" style={{ margin: 0, fontSize: 10, fontWeight: 700, letterSpacing: "0.08em", textTransform: "uppercase", color: accent }}>
          {c.eyebrow}
        </p>
        <p className="font-display" style={{ margin: "4px 0 0", fontSize: c.headline.length > 20 ? 20 : 24, lineHeight: 1.05, fontWeight: 800, letterSpacing: "-0.035em", color: accent }}>
          {c.headline}
        </p>
        {c.stamp && (
          <span style={{ display: "inline-block", marginTop: 8 }}>
            <Stamp variant="label" text={c.stamp} color={accent} rotate={-4} />
          </span>
        )}
      </div>
    </div>
  );
});
