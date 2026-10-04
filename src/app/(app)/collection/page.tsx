"use client";

import { BookOpen, LayoutGrid } from "lucide-react";
import Link from "next/link";
import { useMemo, useState } from "react";
import { CollectibleDetail } from "@/components/collection/CollectibleDetail";
import { CollectionGrid } from "@/components/collection/CollectionGrid";
import { StickerBook } from "@/components/collection/StickerBook";
import { Sticker } from "@/components/collection/Sticker";
import { bookItems, nearestLocked, readView, writeView, type BookItem, type CategoryFilter, type CollectionView } from "@/components/collection/bookUtils";
import { Page } from "@/components/shell/Page";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Segmented, ProgressBar } from "@/components/ui/controls";
import { HandNote, SectionHeading, Tape } from "@/components/ui/misc";
import { Stamp } from "@/components/ui/Stamp";
import { COLLECTIBLE_BY_ID, RARITY_META } from "@/lib/data/catalog";
import { addDays, diffDays, startOfWeek } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { cn } from "@/lib/cn";
import { useAppState, useDispatch } from "@/lib/store/provider";

const SHOWCASE_MAX = 6;

/** A ribbon-shaped tally. Streaks and comebacks use the exact same treatment on purpose. */
function Ribbon({ label, owned, total, tint }: { label: string; owned: number; total: number; tint: "orange" | "rose" }) {
  return (
    <div className="relative flex min-w-0 flex-1 items-center gap-2.5 rounded-[12px] border border-line bg-cream py-2 pl-3 pr-4">
      <span
        aria-hidden
        className={cn("absolute -left-1 top-1/2 h-7 w-2 -translate-y-1/2 rounded-[3px]", tint === "orange" ? "bg-orange" : "bg-rose")}
      />
      <span className="min-w-0">
        <span className="block font-display text-[0.6875rem] font-bold uppercase tracking-[0.08em] text-muted">{label}</span>
        <span className="block font-display text-xl font-extrabold leading-tight tabular-nums text-ink">
          {owned}
          <span className="text-sm font-semibold text-faint">/{total}</span>
        </span>
      </span>
    </div>
  );
}

function StatsHeader({ items, showcased }: { items: BookItem[]; showcased: number }) {
  const owned = items.filter((i) => i.owned).length;
  const count = (cat: string) => {
    const all = items.filter((i) => i.collectible.category === cat);
    return { owned: all.filter((i) => i.owned).length, total: all.length };
  };
  const streaks = count("streak");
  const comebacks = count("comeback");
  return (
    <div className="relative mt-3 rounded-[18px] border border-line bg-paper-deep/40 p-3.5">
      <div className="flex items-end justify-between gap-3">
        <p className="font-display text-ink">
          <span className="text-[2rem] font-extrabold leading-none tracking-[-0.04em] tabular-nums text-accent">{owned}</span>
          <span className="ml-1.5 text-[0.9375rem] font-semibold text-muted">of {items.length} collected</span>
        </p>
        <p className="shrink-0 text-right text-[0.8125rem] font-semibold text-muted">
          Showcase on profile{" "}
          <span className="font-display font-extrabold tabular-nums text-ink">
            {showcased}/{SHOWCASE_MAX}
          </span>
        </p>
      </div>
      <ProgressBar value={owned} max={items.length} label={`${owned} of ${items.length} stickers collected`} className="mt-2.5" size="sm" />
      <div className="mt-3 flex flex-wrap items-center gap-2 sm:flex-nowrap">
        <Ribbon label="Streaks" owned={streaks.owned} total={streaks.total} tint="orange" />
        <span aria-hidden className="font-hand text-xl text-accent">=</span>
        <Ribbon label="Comebacks" owned={comebacks.owned} total={comebacks.total} tint="rose" />
      </div>
      <p className="mt-1.5 text-[0.8125rem] text-muted">
        <HandNote rotate={-1} className="text-[1.05rem]">
          Coming back counts just as much as never leaving.
        </HandNote>
      </p>
    </div>
  );
}

function LimitedStrip({ items, daysLeft, onOpen }: { items: BookItem[]; daysLeft: number; onOpen: (id: string) => void }) {
  const limited = items.filter((i) => i.collectible.rarity === "limited");
  if (!limited.length) return null;
  return (
    <section aria-labelledby="limited-heading" className="relative mt-6 overflow-hidden rounded-[18px] border border-line-strong bg-cream p-3.5 pt-3">
      <Tape className="-top-1 left-6" rotate={-4} />
      <div className="flex items-center justify-between gap-3">
        <h2 id="limited-heading" className="flex items-center gap-2 font-display text-[1.0625rem] font-bold tracking-[-0.015em] text-ink">
          Limited this week
          <Stamp variant="label" text="limited" rotate={-6} className="text-[0.5625rem]!" />
        </h2>
        <span className="shrink-0 font-hand text-lg text-accent">{daysLeft <= 0 ? "last day!" : `${daysLeft} day${daysLeft > 1 ? "s" : ""} left`}</span>
      </div>
      <p className="mt-0.5 text-[0.8125rem] text-muted">Weekly superlatives come from your activity and friends&apos; quiz votes.</p>
      <ul className="no-scrollbar -mx-3.5 mt-2 flex gap-1 overflow-x-auto px-3.5 pb-1">
        {limited.map((item) => {
          const { collectible: c, owned } = item;
          return (
            <li key={c.id} className="shrink-0">
              <button
                type="button"
                onClick={() => onOpen(c.id)}
                aria-label={`${c.name}, limited, ${owned ? "earned" : "up for grabs"}`}
                className="flex w-[92px] flex-col items-center gap-1 rounded-[14px] px-1 py-2 text-center transition-colors hover:bg-accent-soft/50"
              >
                <Sticker collectible={c} size={58} locked={!owned} rotate={owned ? -5 : 0} />
                <span className="line-clamp-2 font-display text-[0.75rem] font-bold leading-tight text-ink">{c.name}</span>
                <span className={cn("text-[0.6875rem] font-semibold", owned ? "text-accent" : "text-faint")}>{owned ? "Earned" : "Up for grabs"}</span>
              </button>
            </li>
          );
        })}
      </ul>
    </section>
  );
}

function CollectionAside({ items, onOpen }: { items: BookItem[]; onOpen: (id: string) => void }) {
  const favorites = items.filter((i) => i.owned?.favorite);
  const showcased = items.filter((i) => i.owned?.showcased);
  const tips = nearestLocked(items, 3);
  return (
    <>
      <section className="card p-4" aria-labelledby="fav-heading">
        <SectionHeading id="fav-heading" title="Favorites" count={favorites.length} />
        {favorites.length ? (
          <ul className="mt-2 flex flex-wrap gap-1">
            {favorites.map(({ collectible: c }, i) => (
              <li key={c.id}>
                <button type="button" onClick={() => onOpen(c.id)} aria-label={`${c.name}, favorite`} className="grid size-14 place-items-center rounded-[12px] hover:bg-accent-soft/60">
                  <Sticker collectible={c} size={46} rotate={i % 2 ? 6 : -5} />
                </button>
              </li>
            ))}
          </ul>
        ) : (
          <p className="mt-1.5 text-sm text-muted">Tap a sticker and press Favorite to keep it close.</p>
        )}
      </section>

      <section className="card p-4" aria-labelledby="showcase-heading">
        <SectionHeading
          id="showcase-heading"
          title="Showcase on profile"
          count={`${showcased.length}/${SHOWCASE_MAX}`}
          action={
            <Link href="/profile" className="min-h-11 content-center rounded-[10px] px-1 text-sm font-semibold text-accent hover:underline">
              View
            </Link>
          }
        />
        <ul className="mt-2 grid grid-cols-3 gap-2" aria-label="Showcase slots">
          {Array.from({ length: SHOWCASE_MAX }, (_, i) => {
            const item = showcased[i];
            return (
              <li key={i} className="aspect-square">
                {item ? (
                  <button
                    type="button"
                    onClick={() => onOpen(item.collectible.id)}
                    aria-label={`${item.collectible.name}, on your profile`}
                    className="grid size-full place-items-center rounded-[14px] border border-line bg-paper/60 hover:bg-accent-soft/50"
                  >
                    <Sticker collectible={item.collectible} size={52} rotate={(i % 3) * 4 - 4} />
                  </button>
                ) : (
                  <span className="grid size-full place-items-center rounded-[14px] border border-dashed border-line-strong text-faint">
                    <span className="font-hand text-lg" aria-hidden>{i + 1}</span>
                    <span className="sr-only">Empty slot</span>
                  </span>
                )}
              </li>
            );
          })}
        </ul>
      </section>

      {tips.length > 0 && (
        <section className="paper-panel relative rounded-[var(--radius-card)] border border-line p-4" aria-labelledby="tips-heading">
          <Tape className="-top-2 right-8" rotate={5} />
          <SectionHeading id="tips-heading" title="Almost yours" hand="next up" />
          <ul className="mt-2 space-y-3">
            {tips.map(({ collectible: c }) => (
              <li key={c.id}>
                <button type="button" onClick={() => onOpen(c.id)} className="flex w-full items-start gap-3 rounded-[12px] text-left hover:bg-accent-soft/40">
                  <Sticker collectible={c} size={44} locked />
                  <span className="min-w-0 pt-0.5">
                    <span className="block font-display text-sm font-bold text-ink">
                      {c.name} <span className="font-sans text-xs font-semibold text-faint">· {RARITY_META[c.rarity].label}</span>
                    </span>
                    <span className="block text-[0.8125rem] leading-snug text-muted">{c.howToEarn}</span>
                  </span>
                </button>
              </li>
            ))}
          </ul>
        </section>
      )}
    </>
  );
}

export default function CollectionPage() {
  const state = useAppState();
  const dispatch = useDispatch();
  const today = useToday();
  const [view, setViewState] = useState<CollectionView>(readView);
  const [category, setCategory] = useState<CategoryFilter>("all");
  const [openId, setOpenId] = useState<string | null>(null);
  // Keep the last opened id so the sheet's contents stay put while it animates closed.
  const [shownId, setShownId] = useState<string | null>(null);

  const items = useMemo(() => bookItems(state.collection), [state.collection]);
  const showcased = state.collection.filter((o) => o.showcased).length;
  const weekEnd = addDays(startOfWeek(today, state.settings.weekStart), 6);
  const daysLeft = diffDays(weekEnd, today);

  const setView = (v: CollectionView) => {
    setViewState(v);
    writeView(v);
  };

  const open = (id: string) => {
    setOpenId(id);
    setShownId(id);
    const owned = state.collection.find((o) => o.collectibleId === id);
    if (owned && !owned.seen) dispatch({ type: "collection/seen", id });
  };

  const shown = shownId ? COLLECTIBLE_BY_ID[shownId] : undefined;

  return (
    <Page
      title="Collection"
      eyebrow="Your sticker book"
      aside={<CollectionAside items={items} onOpen={open} />}
      headerExtra={<StatsHeader items={items} showcased={showcased} />}
    >
      <LimitedStrip items={items} daysLeft={daysLeft} onOpen={open} />

      <div className="mb-3 mt-7 flex flex-wrap items-center justify-between gap-3">
        <h2 className="font-display text-[1.0625rem] font-bold tracking-[-0.015em] text-ink">{view === "book" ? "Sticker book" : "All stickers"}</h2>
        <Segmented
          label="Collection view"
          size="sm"
          value={view}
          onChange={setView}
          className="w-full sm:w-72"
          options={[
            { value: "book", label: "Sticker book", icon: <BookOpen size={16} aria-hidden /> },
            { value: "grid", label: "Organized grid", icon: <LayoutGrid size={16} aria-hidden /> },
          ]}
        />
      </div>

      {view === "book" ? (
        <StickerBook items={items} category={category} onCategory={setCategory} onOpen={open} />
      ) : (
        <CollectionGrid items={items} category={category} onCategory={setCategory} onOpen={open} />
      )}

      <BottomSheet open={Boolean(openId)} onClose={() => setOpenId(null)} title={shown?.name ?? "Sticker"} hideTitle>
        {shownId && <CollectibleDetail id={shownId} />}
      </BottomSheet>
    </Page>
  );
}
