"use client";

import { motion, useReducedMotion } from "motion/react";
import { Gift as GiftIcon } from "lucide-react";
import { useState } from "react";
import { Avatar, AvatarArt } from "@/components/avatar/Avatar";
import { Sticker } from "@/components/collection/Sticker";
import { Illustration, TINT_HEX } from "@/components/illustrations/Illustration";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button } from "@/components/ui/Button";
import { EmptyState, HandNote, SectionHeading, Tape } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { COLLECTIBLE_BY_ID, COSMETICS } from "@/lib/data/catalog";
import { relativeTime } from "@/lib/dates";
import { useAppState, useDispatch, useMe } from "@/lib/store/provider";
import type { AvatarConfig, Gift, GiftKind, IllustrationKey, Tint } from "@/lib/types";

export const GIFT_META: Record<GiftKind, { label: string; detail: string; motif: IllustrationKey; tint: Tint }> = {
  "reminder-pass": { label: "Reminder pass", detail: "Lets you send one extra friendly reminder to a friend this week.", motif: "ticket", tint: "sky" },
  "comeback-boost": { label: "Comeback boost", detail: "Your next comeback gets a little extra celebration in the feed.", motif: "sun", tint: "orange" },
  "double-reaction": { label: "Double-reaction token", detail: "Your next reaction shows up twice as big. Purely for show.", motif: "heart", tint: "rose" },
  cosmetic: { label: "Avatar cosmetic", detail: "A new item for your avatar.", motif: "ribbon", tint: "gold" },
  sticker: { label: "Sticker", detail: "A collectible for your sticker book.", motif: "star", tint: "sage" },
};

const PARCEL_TINTS: Tint[] = ["rose", "sage", "gold", "sky", "orange"];

function itemName(g: Gift): string {
  if (g.kind === "cosmetic") return COSMETICS.find((c) => c.id === g.itemId)?.name ?? "Avatar item";
  if (g.kind === "sticker") return (g.itemId && COLLECTIBLE_BY_ID[g.itemId]?.name) || "Sticker";
  return GIFT_META[g.kind].label;
}

/** Hand-drawn wrapped parcel with a bow. */
function Parcel({ tint, size = 88 }: { tint: Tint; size?: number }) {
  return (
    <svg viewBox="0 0 80 80" width={size} height={size} aria-hidden className="overflow-visible">
      <g filter="url(#ink-wobble)" stroke="#2e1b1a" strokeWidth="2.6" strokeLinejoin="round" strokeLinecap="round">
        <ellipse cx="40" cy="74" rx="26" ry="3.5" fill="#2e1b1a" opacity="0.12" stroke="none" />
        <rect x="12" y="32" width="56" height="40" rx="4" fill={TINT_HEX[tint]} />
        <rect x="8" y="24" width="64" height="12" rx="3" fill={TINT_HEX[tint]} />
        <path d="M18 44 l4 4 M50 56 l5 -3 M24 62 l4 -1" stroke="#fbf6ec" strokeWidth="2" opacity="0.7" />
        <rect x="35" y="24" width="10" height="48" fill="#7a1d2c" />
        <path d="M40 24 C30 10 18 14 24 22 C27 25 34 25 40 24 Z" fill="#7a1d2c" />
        <path d="M40 24 C50 10 62 14 56 22 C53 25 46 25 40 24 Z" fill="#7a1d2c" />
        <path d="M38 25 L32 34 M42 25 L48 34" />
      </g>
    </svg>
  );
}

function GiftReveal({ gift, avatar }: { gift: Gift; avatar: AvatarConfig }) {
  const reduce = useReducedMotion();
  const cosmetic = gift.kind === "cosmetic" ? COSMETICS.find((c) => c.id === gift.itemId) : undefined;
  const sticker = gift.kind === "sticker" && gift.itemId ? COLLECTIBLE_BY_ID[gift.itemId] : undefined;
  const meta = GIFT_META[gift.kind];
  return (
    <motion.div
      initial={reduce ? false : { scale: 0.3, rotate: -18, opacity: 0 }}
      animate={{ scale: 1, rotate: 0, opacity: 1 }}
      transition={{ type: "spring", stiffness: 260, damping: 14, delay: 0.12 }}
      className="relative grid place-items-center"
    >
      <div className="absolute inset-[-24px] rounded-full bg-[radial-gradient(circle,var(--gold-soft),transparent_70%)]" aria-hidden />
      {cosmetic ? (
        <AvatarArt config={{ ...avatar, [cosmetic.slot === "accessory" ? "accessory" : cosmetic.slot]: cosmetic.value } as AvatarConfig} size={140} title={`Your avatar with ${cosmetic.name}`} />
      ) : sticker ? (
        <Sticker collectible={sticker} size={140} rotate={-4} />
      ) : (
        <span className="grid size-32 place-items-center rounded-[24px] border border-line" style={{ backgroundColor: TINT_HEX[meta.tint] + "40" }}>
          <Illustration kind={meta.motif} size={96} />
        </span>
      )}
    </motion.div>
  );
}

/** Gifts inbox: unopened parcels you can open, then a list of opened gifts. */
export function GiftsInbox() {
  const state = useAppState();
  const me = useMe();
  const dispatch = useDispatch();
  const toast = useToast();
  const reduce = useReducedMotion();
  const mine = state.gifts.filter((g) => g.toId === state.meId).sort((a, b) => b.at.localeCompare(a.at));
  const unopened = mine.filter((g) => !g.opened);
  const opened = mine.filter((g) => g.opened);
  const [opening, setOpening] = useState<string | null>(null);
  const [revealId, setRevealId] = useState<string | null>(null);
  const [revealOpen, setRevealOpen] = useState(false);
  const revealGift = state.gifts.find((g) => g.id === revealId);

  const open = (g: Gift) => {
    setOpening(g.id);
    window.setTimeout(
      () => {
        dispatch({ type: "social/openGift", id: g.id });
        setOpening(null);
        setRevealId(g.id);
        setRevealOpen(true);
        const from = state.users[g.fromId]?.name.split(" ")[0] ?? "A friend";
        toast({ title: `${itemName(g)} unwrapped`, body: g.kind === "cosmetic" ? "Added to your avatar cosmetics." : g.kind === "sticker" ? "Added to your Collection." : `From ${from}.`, motif: GIFT_META[g.kind].motif });
      },
      reduce ? 0 : 520,
    );
  };

  return (
    <section aria-labelledby="gifts-h" className="space-y-3">
      <SectionHeading id="gifts-h" title="Gifts inbox" count={unopened.length ? `${unopened.length} new` : undefined} />
      {mine.length === 0 && <EmptyState compact mood="wave" title="No gifts yet" body="When friends send you something, it'll be waiting here, wrapped." />}

      {unopened.length > 0 && (
        <ul className="grid gap-3 sm:grid-cols-2">
          {unopened.map((g, i) => {
            const from = state.users[g.fromId];
            const isOpening = opening === g.id;
            return (
              <li key={g.id} className="card relative flex items-center gap-4 p-4">
                <Tape className="-top-2 left-6" rotate={-8} />
                <motion.div
                  animate={isOpening && !reduce ? { rotate: [0, -10, 10, -8, 8, 0], scale: [1, 1.05, 1.1, 1.15, 1.25, 0.2], opacity: [1, 1, 1, 1, 1, 0] } : { rotate: i % 2 ? 4 : -4 }}
                  transition={{ duration: 0.5 }}
                  className="shrink-0"
                >
                  <Parcel tint={PARCEL_TINTS[i % PARCEL_TINTS.length]} />
                </motion.div>
                <div className="min-w-0 flex-1">
                  <p className="font-display text-[0.9375rem] font-bold text-ink">From {from?.name.split(" ")[0] ?? "a friend"}</p>
                  {g.message && <p className="mt-0.5 font-hand text-lg leading-tight text-accent">“{g.message}”</p>}
                  <p className="mt-0.5 text-xs text-muted">{relativeTime(g.at)}</p>
                  <Button size="sm" className="mt-2" icon={<GiftIcon size={15} aria-hidden />} onClick={() => open(g)} disabled={isOpening} aria-label={`Open gift from ${from?.name ?? "a friend"}`}>
                    {isOpening ? "Unwrapping…" : "Open"}
                  </Button>
                </div>
              </li>
            );
          })}
        </ul>
      )}

      {opened.length > 0 && (
        <div>
          <h3 className="mb-2 mt-4 font-display text-sm font-bold text-muted">Opened</h3>
          <ul className="card divide-y divide-line overflow-hidden">
            {opened.map((g) => {
              const from = state.users[g.fromId];
              const meta = GIFT_META[g.kind];
              return (
                <li key={g.id} className="flex items-start gap-3 px-4 py-3">
                  {from ? <Avatar user={from} size={36} /> : <Illustration kind={meta.motif} size={36} />}
                  <div className="min-w-0 flex-1">
                    <p className="text-sm text-ink">
                      <span className="font-semibold">{from?.name ?? "A friend"}</span> sent {g.kind === "cosmetic" || g.kind === "sticker" ? `“${itemName(g)}”` : `a ${meta.label.toLowerCase()}`}
                    </p>
                    {g.message && <p className="mt-0.5 text-[0.8125rem] italic text-muted">“{g.message}”</p>}
                    <p className="mt-0.5 text-xs text-faint">{relativeTime(g.at)}</p>
                  </div>
                  <span className="grid size-9 shrink-0 place-items-center rounded-[10px] bg-paper-deep/60">
                    <Illustration kind={meta.motif} size={26} />
                  </span>
                </li>
              );
            })}
          </ul>
        </div>
      )}

      <BottomSheet
        open={revealOpen}
        onClose={() => setRevealOpen(false)}
        title="You got a gift!"
        size="sm"
        footer={
          <Button block onClick={() => setRevealOpen(false)} data-autofocus>
            Lovely, thanks
          </Button>
        }
      >
        {revealGift && (
          <div className="flex flex-col items-center py-4 text-center">
            <GiftReveal gift={revealGift} avatar={me.avatar} />
            <p className="eyebrow mt-6">{GIFT_META[revealGift.kind].label}</p>
            <p className="mt-1 font-display text-2xl font-extrabold tracking-[-0.03em] text-ink">{itemName(revealGift)}</p>
            <p className="mt-1 max-w-xs text-sm text-muted">{GIFT_META[revealGift.kind].detail}</p>
            {revealGift.message && (
              <HandNote className="mt-3 text-xl" rotate={-2}>
                “{revealGift.message}” — {state.users[revealGift.fromId]?.name.split(" ")[0]}
              </HandNote>
            )}
          </div>
        )}
      </BottomSheet>
    </section>
  );
}
