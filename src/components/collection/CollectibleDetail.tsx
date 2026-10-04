"use client";

import { Heart, Pin, Share2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { Avatar } from "@/components/avatar/Avatar";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/misc";
import { COLLECTIBLE_BY_ID, COLLECTIBLE_CATEGORY_META, RARITY_META } from "@/lib/data/catalog";
import { cn } from "@/lib/cn";
import { useAppState, useDispatch } from "@/lib/store/provider";
import { Sticker } from "./Sticker";

/** Body of the collectible sheet: big sticker, provenance, rarity and actions. */
export function CollectibleDetail({ id, reveal = false, onShare }: { id: string; reveal?: boolean; onShare?: () => void }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const router = useRouter();
  const c = COLLECTIBLE_BY_ID[id];
  if (!c) return null;
  const owned = state.collection.find((o) => o.collectibleId === id);
  const rarity = RARITY_META[c.rarity];
  const giftedBy = owned?.giftedBy ? state.users[owned.giftedBy] : undefined;
  const showcasedCount = state.collection.filter((o) => o.showcased).length;

  return (
    <div className="flex flex-col items-center text-center">
      <div className={cn("relative my-3 grid place-items-center", reveal && "animate-pop")}>
        <div className="absolute inset-[-18px] rounded-full bg-[radial-gradient(circle,var(--gold-soft),transparent_70%)]" aria-hidden />
        <Sticker collectible={c} size={150} locked={!owned} rotate={reveal ? -4 : -2} />
      </div>
      <p className="eyebrow">{COLLECTIBLE_CATEGORY_META[c.category].label}</p>
      <h3 className="mt-1 font-display text-2xl font-extrabold tracking-[-0.03em] text-ink">{c.name}</h3>
      <p className="mt-1 max-w-xs font-hand text-xl leading-snug text-accent">“{c.blurb}”</p>

      <div className="mt-3 flex flex-wrap items-center justify-center gap-2">
        <Badge tone={c.rarity === "limited" || c.rarity === "legendary" ? "gold" : c.rarity === "rare" ? "orange" : "muted"}>
          <span aria-hidden className="tracking-[-0.1em]">{"●".repeat(rarity.dots)}</span>
          {rarity.label}
        </Badge>
        {giftedBy && <Badge tone="sage">Gift from {giftedBy.name.split(" ")[0]}</Badge>}
      </div>

      <dl className="mt-4 w-full divide-y divide-line rounded-[16px] border border-line bg-paper/60 text-left text-sm">
        <div className="flex gap-3 px-4 py-3">
          <dt className="w-24 shrink-0 font-semibold text-muted">How to earn</dt>
          <dd className="text-ink">{c.howToEarn}</dd>
        </div>
        {owned ? (
          <>
            <div className="flex gap-3 px-4 py-3">
              <dt className="w-24 shrink-0 font-semibold text-muted">Earned for</dt>
              <dd className="text-ink">{owned.earnedFor}</dd>
            </div>
            <div className="flex gap-3 px-4 py-3">
              <dt className="w-24 shrink-0 font-semibold text-muted">Earned on</dt>
              <dd className="text-ink">
                {new Date(owned.earnedAt).toLocaleDateString("en-US", { weekday: "short", month: "long", day: "numeric", year: "numeric" })}
              </dd>
            </div>
            {giftedBy && (
              <div className="flex items-center gap-3 px-4 py-3">
                <dt className="w-24 shrink-0 font-semibold text-muted">From</dt>
                <dd className="flex items-center gap-2 text-ink">
                  <Avatar user={giftedBy} size={24} /> {giftedBy.name}
                </dd>
              </div>
            )}
          </>
        ) : (
          <div className="flex gap-3 px-4 py-3">
            <dt className="w-24 shrink-0 font-semibold text-muted">Status</dt>
            <dd className="text-ink">Not yet earned. It&apos;ll pop into your book when you do.</dd>
          </div>
        )}
      </dl>

      {owned && (
        <div className="mt-4 grid w-full grid-cols-3 gap-2">
          <Button variant={owned.favorite ? "soft" : "secondary"} size="md" aria-pressed={owned.favorite} onClick={() => dispatch({ type: "collection/favorite", id })} icon={<Heart size={17} fill={owned.favorite ? "currentColor" : "none"} />}>
            {owned.favorite ? "Loved" : "Favorite"}
          </Button>
          <Button
            variant={owned.showcased ? "soft" : "secondary"}
            aria-pressed={owned.showcased}
            disabled={!owned.showcased && showcasedCount >= 6}
            title={!owned.showcased && showcasedCount >= 6 ? "Your showcase holds 6 stickers" : undefined}
            onClick={() => dispatch({ type: "collection/showcase", id })}
            icon={<Pin size={17} />}
          >
            {owned.showcased ? "On profile" : "Showcase"}
          </Button>
          <Button variant="secondary" onClick={() => (onShare ? onShare() : router.push(`/share?kind=award&id=${id}`))} icon={<Share2 size={17} />}>
            Share
          </Button>
        </div>
      )}
    </div>
  );
}
