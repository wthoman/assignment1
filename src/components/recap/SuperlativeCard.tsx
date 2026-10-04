"use client";

import { Activity, Layers, Vote } from "lucide-react";
import { Avatar } from "@/components/avatar/Avatar";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { Stamp } from "@/components/ui/Stamp";
import { cn } from "@/lib/cn";
import { useAppState } from "@/lib/store/provider";
import type { Superlative, SuperlativeSource } from "@/lib/types";
import { AwardRibbon, StampedPortrait, T } from "./RecapSlide";

export const SOURCE_META: Record<SuperlativeSource, { label: string; icon: typeof Activity }> = {
  behavior: { label: "From app activity", icon: Activity },
  votes: { label: "From friend votes", icon: Vote },
  both: { label: "App activity + votes", icon: Layers },
};

export function SourceBadge({ source, className }: { source: SuperlativeSource; className?: string }) {
  const meta = SOURCE_META[source];
  const Icon = meta.icon;
  return (
    <span className={cn("inline-flex items-center gap-1.5 rounded-[8px] border border-current/25 px-2 py-1 text-[0.75rem] font-semibold", className)}>
      <Icon size={13} aria-hidden />
      {meta.label}
    </span>
  );
}

/**
 * A weekly superlative. `slide` is the full award-show moment used in the recap player;
 * `compact` is a list row for the recap hub and profile.
 */
export function SuperlativeCard({ superlative, variant = "compact", className }: { superlative: Superlative; variant?: "slide" | "compact"; className?: string }) {
  const state = useAppState();
  const winner = state.users[superlative.userId];
  const isMe = superlative.userId === state.meId;
  const name = isMe ? "You" : winner?.name.split(" ")[0] ?? "Someone";

  if (variant === "compact") {
    return (
      <article className={cn("card relative flex gap-3 overflow-hidden p-3.5", className)}>
        <div className="relative shrink-0">
          {winner ? <Avatar user={winner} size={52} /> : <IllustrationTile kind={superlative.motif} tint={superlative.tint} size={52} />}
          <span className="absolute -bottom-1 -right-2">
            <IllustrationTile kind={superlative.motif} tint={superlative.tint} size={26} rotate={8} />
          </span>
        </div>
        <div className="min-w-0 flex-1">
          <h3 className="font-display text-[1rem] font-extrabold leading-tight tracking-[-0.02em] text-accent">{superlative.title}</h3>
          <p className="mt-0.5 font-display text-sm font-semibold text-ink">
            {isMe ? "You took this one" : `Awarded to ${name}`}
          </p>
          <p className="mt-1 text-[0.8125rem] leading-snug text-muted">{superlative.explanation}</p>
          <SourceBadge source={superlative.source} className="mt-2 text-muted" />
        </div>
      </article>
    );
  }

  return (
    <div className={cn("flex h-full flex-col items-center justify-center text-center", className)}>
      <p className={cn(T.kicker, "text-accent/80")}>And the award for</p>
      <h2 className={cn(T.headline, "mt-2 text-balance text-accent")}>{superlative.title}</h2>
      <p className={cn(T.hand, "mt-1 text-muted [@media(max-height:640px)]:hidden")}>goes to…</p>
      <div className="relative mt-4">
        {winner ? <StampedPortrait user={winner} size={96} rotate={-5} /> : <IllustrationTile kind={superlative.motif} tint={superlative.tint} size={120} />}
        <span className="absolute -right-6 -top-4">
          <IllustrationTile kind={superlative.motif} tint={superlative.tint} size={52} rotate={10} />
        </span>
        <span className="absolute -bottom-3 -left-7">
          <Stamp variant="check" size={50} animate />
        </span>
      </div>
      <AwardRibbon className="mt-5">{name}</AwardRibbon>
      <p className={cn(T.body, "mt-4 line-clamp-4 max-w-[34ch] text-pretty text-ink")}>{superlative.explanation}</p>
      <SourceBadge source={superlative.source} className="mt-3 text-muted" />
    </div>
  );
}
