"use client";

import { AnimatePresence, motion } from "motion/react";
import { useEffect, useRef, useState, type ReactNode, type Ref } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { BRAND } from "@/lib/brand";
import type { AccentKey, User } from "@/lib/types";
import { CARD_SIZE, ShareCard, ShareThumb } from "./ShareCard";
import type { ShareContent, ShareFormat } from "./shareContent";

/** Scales a fixed-size child down to fit the available width (never up). */
function FitWidth({ width, height, children, max = 1 }: { width: number; height: number; children: ReactNode; max?: number }) {
  const outer = useRef<HTMLDivElement>(null);
  const [avail, setAvail] = useState(width);
  useEffect(() => {
    const el = outer.current;
    if (!el) return;
    const ro = new ResizeObserver((entries) => setAvail(entries[0].contentRect.width));
    ro.observe(el);
    return () => ro.disconnect();
  }, []);
  const scale = Math.min(max, avail / width);
  return (
    <div ref={outer} className="w-full">
      <div className="mx-auto" style={{ width: width * scale, height: height * scale }}>
        <div style={{ width, height, transform: `scale(${scale})`, transformOrigin: "top left" }}>{children}</div>
      </div>
    </div>
  );
}

/**
 * Preview of the share card in its chosen format. `nodeRef` points at the exact node
 * exported as an image (the card itself, or the link thumbnail for messages).
 */
export function SharePreview({
  content,
  format,
  accentKey,
  nodeRef,
  friend,
  hideFriends,
}: {
  content: ShareContent;
  format: ShareFormat;
  accentKey: AccentKey;
  nodeRef: Ref<HTMLDivElement>;
  friend?: User;
  hideFriends: boolean;
}) {
  return (
    <div className="rounded-[20px] border border-line bg-paper-deep/60 p-3 sm:p-4" aria-label={`${format} preview`} role="group">
      <AnimatePresence mode="wait" initial={false}>
        <motion.div key={format} initial={{ opacity: 0, scale: 0.97 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.98 }} transition={{ duration: 0.18 }}>
          {format === "message" ? (
            <div className="mx-auto max-w-[340px] space-y-2 rounded-[18px] bg-cream p-3 shadow-[var(--shadow)]">
              <p className="text-center text-[0.6875rem] font-semibold text-faint">Messages · now</p>
              <div className="flex items-end gap-2">
                {friend && !hideFriends ? <Avatar user={friend} size={28} /> : <span className="size-7 shrink-0 rounded-full bg-paper-deep" aria-hidden />}
                <p className="max-w-[75%] rounded-[16px] rounded-bl-[4px] bg-paper-deep px-3 py-2 text-sm text-ink">{hideFriends || !friend ? "how's the habit thing going??" : `${friend.name.split(" ")[0]}: how's the habit thing going??`}</p>
              </div>
              <div className="ml-auto w-[min(300px,100%)] overflow-hidden rounded-[16px] rounded-br-[4px] border border-line bg-paper shadow-[var(--shadow)]">
                <FitWidth width={CARD_SIZE.thumb.w} height={CARD_SIZE.thumb.h}>
                  <ShareThumb ref={nodeRef} content={content} accentKey={accentKey} />
                </FitWidth>
                <div className="max-w-[300px] border-t border-line px-3 py-2">
                  <p className="truncate text-sm font-semibold text-ink">{content.headline}</p>
                  <p className="line-clamp-2 text-xs text-muted">{content.sub ?? content.shareText}</p>
                  <p className="mt-0.5 text-[0.6875rem] text-faint">{BRAND.shareDomain}</p>
                </div>
              </div>
              <p className="text-right text-[0.6875rem] text-faint">Delivered</p>
            </div>
          ) : (
            <div className="mx-auto" style={{ maxWidth: format === "story" ? 300 : 360 }}>
              <div className="overflow-hidden rounded-[18px] shadow-[var(--shadow-lift)]">
                <FitWidth width={CARD_SIZE[format].w} height={CARD_SIZE[format].h}>
                  <ShareCard ref={nodeRef} content={content} format={format} accentKey={accentKey} />
                </FitWidth>
              </div>
            </div>
          )}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}
