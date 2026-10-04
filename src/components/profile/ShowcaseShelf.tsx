"use client";

import Link from "next/link";
import { Sticker } from "@/components/collection/Sticker";
import { ButtonLink } from "@/components/ui/Button";
import { EmptyState, SectionHeading, Tape } from "@/components/ui/misc";
import { COLLECTIBLE_BY_ID } from "@/lib/data/catalog";
import { useAppState } from "@/lib/store/provider";

const TILTS = [-6, 4, -2, 7, -5, 3];

/** Up to six showcased stickers sitting on a little taped wooden shelf. */
export function ShowcaseShelf() {
  const state = useAppState();
  const items = state.collection.filter((o) => o.showcased && COLLECTIBLE_BY_ID[o.collectibleId]);

  return (
    <section aria-labelledby="shelf-h" className="space-y-3">
      <SectionHeading
        id="shelf-h"
        title="Showcase shelf"
        count={`${items.length}/6`}
        action={
          <Link href="/collection" className="inline-flex min-h-11 items-center px-1 text-sm font-semibold text-accent hover:underline">
            Edit in Collection
          </Link>
        }
      />
      {items.length === 0 ? (
        <EmptyState
          compact
          mood="thinking"
          title="Your shelf is empty"
          body="Pick up to six stickers from your Collection to show off here."
          action={
            <ButtonLink href="/collection" size="sm" variant="soft">
              Open Collection
            </ButtonLink>
          }
        />
      ) : (
        <div className="relative px-1 pt-2">
          <ul className="flex flex-wrap items-end justify-center gap-x-2 gap-y-6 px-2 pb-1 sm:justify-start sm:gap-x-4">
            {items.map((o, i) => {
              const c = COLLECTIBLE_BY_ID[o.collectibleId];
              return (
                <li key={o.collectibleId}>
                  <Link href="/collection" className="group flex w-[84px] flex-col items-center gap-1 rounded-[12px] p-1 text-center" aria-label={`${c.name}: ${o.earnedFor}`}>
                    <span className="transition-transform duration-200 group-hover:-translate-y-1">
                      <Sticker collectible={c} size={68} rotate={TILTS[i % TILTS.length]} />
                    </span>
                    <span className="line-clamp-2 text-[0.6875rem] font-semibold leading-tight text-muted">{c.name}</span>
                  </Link>
                </li>
              );
            })}
          </ul>
          {/* the shelf plank */}
          <div className="relative mx-0 h-3 rounded-[4px] border border-line-strong bg-gold-soft shadow-[0_6px_10px_-6px_rgb(70_30_20/0.5)]" aria-hidden>
            <Tape className="-top-2 left-3" rotate={-10} />
            <Tape className="-top-2 right-3" rotate={8} />
          </div>
        </div>
      )}
    </section>
  );
}
