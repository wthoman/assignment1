"use client";

import { AnimatePresence, motion } from "motion/react";
import { RotateCcw, Save } from "lucide-react";
import { useState } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { AvatarBuilder } from "@/components/profile/AvatarBuilder";
import { GiftsInbox, GIFT_META } from "@/components/profile/GiftsInbox";
import { Page } from "@/components/shell/Page";
import { GiftSheet } from "@/components/social/GiftSheet";
import { Illustration } from "@/components/illustrations/Illustration";
import { Button } from "@/components/ui/Button";
import { useToast } from "@/components/ui/Toast";
import { useAppState, useDispatch, useMe } from "@/lib/store/provider";
import type { AvatarConfig, GiftKind, User } from "@/lib/types";

function sameAvatar(a: AvatarConfig, b: AvatarConfig) {
  return (Object.keys(a) as (keyof AvatarConfig)[]).every((k) => a[k] === b[k]);
}

const GIFT_ORDER: GiftKind[] = ["reminder-pass", "comeback-boost", "double-reaction", "cosmetic", "sticker"];

export default function AvatarPage() {
  const me = useMe();
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const [draft, setDraft] = useState<AvatarConfig>(me.avatar);
  const [giftTo, setGiftTo] = useState<string | null>(null);
  const [giftOpen, setGiftOpen] = useState(false);
  const dirty = !sameAvatar(draft, me.avatar);
  const friends = me.friendIds.map((id) => state.users[id]).filter((u): u is User => Boolean(u) && !state.settings.blockedIds.includes(u.id));

  const save = () => {
    dispatch({ type: "profile/avatar", patch: draft });
    toast({ title: "Avatar saved", body: "Your friends will see the new look.", motif: "star" });
  };

  return (
    <Page
      title="Avatar & cosmetics"
      back="/profile"
      aside={
        <section aria-labelledby="send-gift-h" className="card p-4">
          <h2 id="send-gift-h" className="eyebrow">
            Send a gift
          </h2>
          <p className="mt-2 text-sm leading-relaxed text-muted">Friends can send each other little power-ups. They&apos;re social or cosmetic only and never change scores or rankings.</p>
          <ul className="mt-3 space-y-2">
            {GIFT_ORDER.map((k) => (
              <li key={k} className="flex items-start gap-2.5">
                <Illustration kind={GIFT_META[k].motif} size={28} />
                <span className="min-w-0 text-[0.8125rem] leading-snug">
                  <span className="block font-semibold text-ink">{GIFT_META[k].label}</span>
                  <span className="text-muted">{GIFT_META[k].detail}</span>
                </span>
              </li>
            ))}
          </ul>
          <p className="mt-4 text-sm font-semibold text-ink">Pick a friend</p>
          {friends.length === 0 ? (
            <p className="mt-1 text-sm text-muted">Add friends to start sending gifts.</p>
          ) : (
            <ul className="mt-2 flex flex-wrap gap-1">
              {friends.map((f) => (
                <li key={f.id}>
                  <button
                    type="button"
                    onClick={() => {
                      setGiftTo(f.id);
                      setGiftOpen(true);
                    }}
                    className="flex w-16 flex-col items-center gap-1 rounded-[12px] p-1.5 transition-colors hover:bg-accent-soft"
                    aria-label={`Send a gift to ${f.name}`}
                  >
                    <Avatar user={f} size={40} />
                    <span className="w-full truncate text-center text-[0.6875rem] font-semibold text-muted">{f.name.split(" ")[0]}</span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </section>
      }
    >
      <div className="space-y-8">
        <AvatarBuilder value={draft} onChange={setDraft} />

        <div className="flex gap-2">
          <Button variant="secondary" block icon={<RotateCcw size={16} aria-hidden />} disabled={!dirty} onClick={() => setDraft(me.avatar)}>
            Reset
          </Button>
          <Button block icon={<Save size={16} aria-hidden />} disabled={!dirty} onClick={save}>
            {dirty ? "Save avatar" : "Saved"}
          </Button>
        </div>

        <div className="hand-divider" aria-hidden />
        <GiftsInbox />
      </div>

      {/* Floating save bar on phones while there are unsaved changes */}
      <AnimatePresence>
        {dirty && (
          <motion.div
            initial={{ y: 80, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: 80, opacity: 0 }}
            transition={{ type: "spring", stiffness: 420, damping: 36 }}
            className="fixed inset-x-3 bottom-[calc(5rem+env(safe-area-inset-bottom))] z-30 flex items-center gap-2 rounded-[16px] border border-line bg-cream p-2 pl-4 shadow-[var(--shadow-lift)] md:hidden"
          >
            <span className="min-w-0 flex-1 text-sm font-semibold text-ink">Unsaved changes</span>
            <Button size="sm" variant="ghost" onClick={() => setDraft(me.avatar)}>
              Reset
            </Button>
            <Button size="sm" onClick={save}>
              Save
            </Button>
          </motion.div>
        )}
      </AnimatePresence>

      {giftTo && <GiftSheet open={giftOpen} onClose={() => setGiftOpen(false)} toId={giftTo} />}
    </Page>
  );
}
