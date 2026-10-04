import type { CSSProperties, ReactNode } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { cn } from "@/lib/cn";
import type { User } from "@/lib/types";

export type SlideTone = "cream" | "accent" | "paper";

const GRAIN =
  "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='160' height='160'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.85' numOctaves='3' stitchTiles='stitch'/%3E%3CfeColorMatrix values='0 0 0 0 .35 0 0 0 0 .2 0 0 0 0 .14 0 0 0 .12 0'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E\")";

/**
 * Two warm, softly swaying stage lights. Pure decoration; the sway is a CSS animation
 * so the global reduced-motion guard freezes it.
 */
export function Spotlights({ tone = "cream", paused, className }: { tone?: SlideTone; paused?: boolean; className?: string }) {
  const warm = tone === "accent" ? "rgb(255 214 160 / 0.26)" : "rgb(240 178 92 / 0.34)";
  const rose = tone === "accent" ? "rgb(255 190 190 / 0.16)" : "rgb(217 140 135 / 0.22)";
  const play: CSSProperties = { animationPlayState: paused ? "paused" : "running" };
  return (
    <div aria-hidden className={cn("pointer-events-none absolute inset-0 overflow-hidden", className)}>
      <span
        className="absolute -left-[30%] -top-[12%] h-[115%] w-[95%] origin-top animate-[spotlight-sway_9s_ease-in-out_infinite]"
        style={{ ...play, background: `radial-gradient(ellipse 50% 70% at 50% 0%, ${warm}, transparent 72%)` }}
      />
      <span
        className="absolute -right-[30%] -top-[12%] h-[115%] w-[95%] origin-top animate-[spotlight-sway_11s_ease-in-out_-4s_infinite]"
        style={{ ...play, background: `radial-gradient(ellipse 50% 70% at 50% 0%, ${rose}, transparent 72%)` }}
      />
    </div>
  );
}

/** Banner with notched tails, for award titles and labels. */
export function AwardRibbon({ children, className, tone = "accent" }: { children: ReactNode; className?: string; tone?: "accent" | "cream" | "gold" }) {
  return (
    <span
      className={cn(
        "inline-flex items-center justify-center px-[1.4em] py-[0.45em] font-display text-[clamp(0.68rem,3.3cqw,0.85rem)] font-extrabold uppercase leading-none tracking-[0.14em]",
        tone === "accent" && "bg-accent text-on-accent",
        tone === "cream" && "bg-cream text-accent",
        tone === "gold" && "bg-gold text-[#3b2a10]",
        className,
      )}
      style={{ clipPath: "polygon(0 0, 100% 0, calc(100% - 0.7em) 50%, 100% 100%, 0 100%, 0.7em 50%)" }}
    >
      {children}
    </span>
  );
}

/** A friend's portrait inside a perforated postage-stamp frame. */
export function StampedPortrait({ user, size = 96, rotate = -4, className, tone = "cream" }: { user: Pick<User, "name" | "avatar">; size?: number; rotate?: number; className?: string; tone?: "cream" | "paper" }) {
  const pad = Math.max(6, Math.round(size * 0.09));
  const hole = Math.max(3, Math.round(pad * 0.55));
  const fill = tone === "cream" ? "var(--cream)" : "var(--paper)";
  return (
    <span
      className={cn("relative inline-grid shrink-0 place-items-center drop-shadow-[0_6px_10px_rgb(70_30_20/0.25)]", className)}
      style={{
        width: size + pad * 2,
        height: size + pad * 2.4,
        rotate: `${rotate}deg`,
        background: `radial-gradient(circle at ${hole}px ${hole}px, transparent ${hole * 0.62}px, ${fill} ${hole * 0.68}px) ${-hole}px ${-hole}px / ${hole * 2}px ${hole * 2}px`,
      }}
    >
      <span className="absolute grid place-items-center overflow-hidden rounded-[4px] border border-line" style={{ inset: pad * 0.55, background: fill }}>
        <Avatar user={user} size={size} />
      </span>
    </span>
  );
}

/** Small display primitives shared by every slide, sized against the slide container (cqw). */
export const T = {
  kicker: "font-display text-[clamp(0.68rem,3.3cqw,0.85rem)] font-bold uppercase tracking-[0.16em]",
  huge: "font-display font-extrabold leading-[0.82] tracking-[-0.065em] text-[clamp(4.5rem,40cqw,10.5rem)] tabular-nums",
  headline: "font-display font-extrabold leading-[0.95] tracking-[-0.04em] text-[clamp(1.75rem,10cqw,3.1rem)]",
  title: "font-display font-bold leading-tight tracking-[-0.025em] text-[clamp(1.1rem,5.6cqw,1.6rem)]",
  body: "text-[clamp(0.9rem,4.2cqw,1.1rem)] leading-snug",
  hand: "font-hand leading-tight text-[clamp(1.25rem,6.4cqw,1.8rem)]",
};

/**
 * One recap sheet. Each sheet is a sheet of paper with grain, warm stage lights and
 * room at the top and bottom for the player's chrome.
 */
export function RecapSlide({
  index,
  total,
  title,
  tone = "cream",
  spotlight = true,
  paused,
  children,
  className,
}: {
  index: number;
  total: number;
  title: string;
  tone?: SlideTone;
  spotlight?: boolean;
  paused?: boolean;
  children: ReactNode;
  className?: string;
}) {
  return (
    <section
      role="group"
      aria-roledescription="slide"
      aria-label={`${index + 1} of ${total}: ${title}`}
      data-slide-index={index}
      className={cn(
        "@container relative isolate size-full overflow-hidden",
        tone === "accent" && "bg-accent text-on-accent",
        tone === "cream" && "bg-cream text-ink",
        tone === "paper" && "bg-paper text-ink",
        className,
      )}
    >
      <span aria-hidden className="pointer-events-none absolute inset-0 opacity-70 mix-blend-multiply" style={{ backgroundImage: GRAIN }} />
      {spotlight && <Spotlights tone={tone} paused={paused} />}
      <span
        aria-hidden
        className="pointer-events-none absolute inset-0"
        style={{ boxShadow: tone === "accent" ? "inset 0 0 80px rgb(0 0 0 / 0.25)" : "inset 0 0 70px rgb(110 60 30 / 0.14)" }}
      />
      <div className="relative z-[1] flex h-full flex-col px-[7cqw] pb-[5.5rem] pt-[4.75rem]">{children}</div>
    </section>
  );
}
