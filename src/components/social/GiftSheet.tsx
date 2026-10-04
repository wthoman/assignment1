"use client";

import { BellRing, Gift, Info, Palette, Sparkles, Sticker as StickerIcon, Sunrise, type LucideIcon } from "lucide-react";
import { useId, useState } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { Sticker } from "@/components/collection/Sticker";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button } from "@/components/ui/Button";
import { CharCount, Field, TextInput } from "@/components/ui/controls";
import { haptic, useToast } from "@/components/ui/Toast";
import { COLLECTIBLE_BY_ID, COSMETICS } from "@/lib/data/catalog";
import { cn } from "@/lib/cn";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { GiftKind, ID } from "@/lib/types";

const MAX = 120;

export const GIFT_KINDS: { kind: GiftKind; label: string; detail: string; icon: LucideIcon }[] = [
  { kind: "reminder-pass", label: "Reminder pass", detail: "Lets them pick a friend to send one cheerful reminder on their behalf.", icon: BellRing },
  { kind: "comeback-boost", label: "Comeback boost", detail: "A bright welcome-back card waiting for their next first day back.", icon: Sunrise },
  { kind: "double-reaction", label: "Double reaction", detail: "One extra-big animated reaction to send on a friend's check-in.", icon: Sparkles },
  { kind: "cosmetic", label: "Avatar item", detail: "Share one of your unlocked avatar items.", icon: Palette },
  { kind: "sticker", label: "Decorative sticker", detail: "A copy of a sticker from your collection. Yours stays put.", icon: StickerIcon },
];

/** Send a friend a social or cosmetic power-up. Nothing here affects scores or rankings. */
export function GiftSheet({ open, onClose, toId }: { open: boolean; onClose: () => void; toId: ID }) {
  return (
    <BottomSheet open={open} onClose={onClose} title="Send a little something" description="Gifts are social and cosmetic only." size="md">
      {open && <GiftBody onClose={onClose} toId={toId} />}
    </BottomSheet>
  );
}

function GiftBody({ onClose, toId }: { onClose: () => void; toId: ID }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const msgId = useId();
  const [kind, setKind] = useState<GiftKind>("comeback-boost");
  const [itemId, setItemId] = useState<ID | undefined>();
  const [message, setMessage] = useState("");
  const [tried, setTried] = useState(false);

  const friend = state.users[toId];
  if (!friend) return <p className="text-sm text-muted">This person isn&apos;t available right now.</p>;
  const name = friend.name.split(" ")[0];

  const cosmetics = COSMETICS.filter((c) => state.unlockedCosmetics.includes(c.id) && c.value !== "none" && c.unlock !== "Starter");
  const stickers = state.collection.map((o) => COLLECTIBLE_BY_ID[o.collectibleId]).filter(Boolean);
  const needsItem = kind === "cosmetic" || kind === "sticker";
  const itemError = tried && needsItem && !itemId ? `Pick ${kind === "cosmetic" ? "an item" : "a sticker"} to send.` : undefined;
  const msgError = message.length > MAX ? `Keep it under ${MAX} characters.` : undefined;

  const send = () => {
    setTried(true);
    if ((needsItem && !itemId) || msgError) return;
    const meta = GIFT_KINDS.find((g) => g.kind === kind)!;
    const itemName = kind === "cosmetic" ? COSMETICS.find((c) => c.id === itemId)?.name : kind === "sticker" && itemId ? COLLECTIBLE_BY_ID[itemId]?.name : undefined;
    dispatch({ type: "social/gift", toId, kind, itemId: needsItem ? itemId : undefined, message: message.trim() || `A little something from ${state.users[state.meId].name.split(" ")[0]}` });
    haptic(state.settings.haptics, [10, 40, 10]);
    toast({ title: `Gift on its way to ${name}`, body: itemName ?? meta.label, motif: "ribbon" });
    onClose();
  };

  return (
    <div className="space-y-5">
      <div className="flex items-center gap-3">
        <Avatar user={friend} size={44} />
        <p className="min-w-0 flex-1 font-display font-bold text-ink">For {friend.name}</p>
      </div>

      <fieldset>
        <legend className="mb-2 font-display text-sm font-semibold text-ink">What to send</legend>
        <div role="radiogroup" aria-label="Gift type" className="grid gap-2 sm:grid-cols-2">
          {GIFT_KINDS.map((g) => {
            const Icon = g.icon;
            const active = kind === g.kind;
            return (
              <button
                key={g.kind}
                type="button"
                role="radio"
                aria-checked={active}
                onClick={() => {
                  setKind(g.kind);
                  setItemId(undefined);
                }}
                className={cn(
                  "flex min-h-11 items-start gap-3 rounded-[14px] border p-3 text-left transition-colors",
                  active ? "border-accent bg-accent-soft" : "border-line bg-cream hover:bg-accent-soft/50",
                )}
              >
                <span className={cn("grid size-9 shrink-0 place-items-center rounded-[10px]", active ? "bg-accent text-on-accent" : "bg-paper text-accent")}>
                  <Icon size={18} aria-hidden />
                </span>
                <span className="min-w-0">
                  <span className="block font-display text-sm font-bold text-ink">{g.label}</span>
                  <span className="block text-xs leading-snug text-muted">{g.detail}</span>
                </span>
              </button>
            );
          })}
        </div>
      </fieldset>

      {kind === "cosmetic" && (
        <fieldset>
          <legend className="mb-2 font-display text-sm font-semibold text-ink">Choose an avatar item</legend>
          {cosmetics.length ? (
            <div className="flex flex-wrap gap-2">
              {cosmetics.map((c) => (
                <button
                  key={c.id}
                  type="button"
                  aria-pressed={itemId === c.id}
                  onClick={() => setItemId(c.id)}
                  className={cn(
                    "min-h-11 rounded-[12px] border px-3 text-sm font-semibold transition-colors",
                    itemId === c.id ? "border-accent bg-accent text-on-accent" : "border-line-strong bg-cream text-ink hover:bg-accent-soft",
                  )}
                >
                  {c.name}
                  <span className={cn("ml-1.5 text-xs font-medium capitalize", itemId === c.id ? "opacity-80" : "text-faint")}>{c.slot}</span>
                </button>
              ))}
            </div>
          ) : (
            <p className="rounded-[14px] border border-dashed border-line-strong p-3 text-sm text-muted">Unlock a special avatar item first, then you can share it here.</p>
          )}
          {itemError && <p role="alert" className="mt-2 text-[0.8125rem] font-medium text-[#a3301f] dark:text-[#f0a090]">{itemError}</p>}
        </fieldset>
      )}

      {kind === "sticker" && (
        <fieldset>
          <legend className="mb-2 font-display text-sm font-semibold text-ink">Choose a sticker</legend>
          {stickers.length ? (
            <div className="grid grid-cols-4 gap-2 sm:grid-cols-5">
              {stickers.map((c) => (
                <button
                  key={c.id}
                  type="button"
                  aria-pressed={itemId === c.id}
                  aria-label={c.name}
                  title={c.name}
                  onClick={() => setItemId(c.id)}
                  className={cn(
                    "grid aspect-square min-h-11 place-items-center rounded-[14px] border transition-colors",
                    itemId === c.id ? "border-accent bg-accent-soft" : "border-line bg-paper/50 hover:bg-accent-soft/50",
                  )}
                >
                  <Sticker collectible={c} size={48} />
                </button>
              ))}
            </div>
          ) : (
            <p className="rounded-[14px] border border-dashed border-line-strong p-3 text-sm text-muted">Earn a sticker first and you can share copies here.</p>
          )}
          {itemError && <p role="alert" className="mt-2 text-[0.8125rem] font-medium text-[#a3301f] dark:text-[#f0a090]">{itemError}</p>}
        </fieldset>
      )}

      <Field label="Short message" htmlFor={msgId} optional error={msgError}>
        <TextInput id={msgId} value={message} onChange={(e) => setMessage(e.target.value)} placeholder="Saw this and thought of you" invalid={Boolean(msgError)} maxLength={MAX + 20} />
        <div className="flex justify-end">
          <CharCount value={message} max={MAX} />
        </div>
      </Field>

      <p className="flex gap-2 rounded-[14px] bg-gold-soft px-3 py-2.5 text-[0.8125rem] leading-relaxed text-ink">
        <Info size={16} className="mt-0.5 shrink-0 text-accent" aria-hidden />
        Power-ups are just for fun. They never add check-ins, change streaks, or give anyone an edge in rankings or challenges.
      </p>

      <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <Button variant="secondary" onClick={onClose}>
          Not now
        </Button>
        <Button onClick={send} icon={<Gift size={17} aria-hidden />}>
          Send gift
        </Button>
      </div>
    </div>
  );
}
