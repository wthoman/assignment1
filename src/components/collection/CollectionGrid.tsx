"use client";

import { Heart, Pin } from "lucide-react";
import { useState } from "react";
import { Chip, Segmented } from "@/components/ui/controls";
import { EmptyState } from "@/components/ui/misc";
import { COLLECTIBLE_CATEGORY_META, RARITY_META } from "@/lib/data/catalog";
import { cn } from "@/lib/cn";
import type { Rarity } from "@/lib/types";
import { CATEGORY_ORDER, RARITY_RANK, shortDate, stickerLabel, type BookItem, type CategoryFilter } from "./bookUtils";
import { Sticker } from "./Sticker";

type StatusFilter = "all" | "owned" | "locked" | "favorites" | "showcased";
type SortKey = "recent" | "rarity";

const STATUS_OPTIONS: { value: StatusFilter; label: string }[] = [
  { value: "all", label: "Everything" },
  { value: "owned", label: "Collected" },
  { value: "locked", label: "Locked" },
  { value: "favorites", label: "Favorites" },
  { value: "showcased", label: "Showcased" },
];

const RARITIES = Object.keys(RARITY_META) as Rarity[];

function matchesStatus(item: BookItem, status: StatusFilter) {
  switch (status) {
    case "owned":
      return Boolean(item.owned);
    case "locked":
      return !item.owned;
    case "favorites":
      return Boolean(item.owned?.favorite);
    case "showcased":
      return Boolean(item.owned?.showcased);
    default:
      return true;
  }
}

function sortItems(items: BookItem[], sort: SortKey) {
  return [...items].sort((a, b) => {
    if (sort === "rarity") return RARITY_RANK[b.collectible.rarity] - RARITY_RANK[a.collectible.rarity] || Number(Boolean(b.owned)) - Number(Boolean(a.owned));
    if (a.owned && b.owned) return b.owned.earnedAt.localeCompare(a.owned.earnedAt);
    return Number(Boolean(b.owned)) - Number(Boolean(a.owned));
  });
}

function GridTile({ item, onOpen }: { item: BookItem; onOpen: (id: string) => void }) {
  const { collectible: c, owned } = item;
  const rarity = RARITY_META[c.rarity];
  return (
    <li>
      <button
        type="button"
        onClick={() => onOpen(c.id)}
        aria-label={stickerLabel(item, rarity.label)}
        className={cn(
          "relative flex h-full w-full flex-col items-center gap-1.5 rounded-[16px] border px-2 pb-3 pt-3 text-center transition-[transform,background-color] duration-150 hover:-translate-y-0.5 active:scale-[0.98]",
          owned ? "border-line bg-cream shadow-[var(--shadow)] hover:bg-accent-soft/40" : "border-dashed border-line-strong bg-paper/50",
        )}
      >
        <Sticker collectible={c} size={64} locked={!owned} rotate={owned ? -3 : 0} peel={Boolean(owned && !owned.seen)} />
        <span className={cn("line-clamp-2 font-display text-[0.8125rem] font-bold leading-tight", owned ? "text-ink" : "text-muted")}>{c.name}</span>
        <span className="flex items-center gap-1 text-[0.6875rem] text-faint" aria-hidden>
          <span className="tracking-[-0.1em] text-accent/70">{"●".repeat(rarity.dots)}</span>
          {owned ? shortDate(owned.earnedAt) : "Locked"}
        </span>
        {(owned?.favorite || owned?.showcased || (owned && !owned.seen)) && (
          <span className="absolute right-1.5 top-1.5 flex gap-0.5" aria-hidden>
            {owned && !owned.seen && <span className="rounded-[5px] bg-accent px-1 text-[0.5625rem] font-bold uppercase tracking-wide text-on-accent">New</span>}
            {owned?.favorite && <Heart size={13} className="text-accent" fill="currentColor" />}
            {owned?.showcased && <Pin size={13} className="text-accent" />}
          </span>
        )}
      </button>
    </li>
  );
}

/** Tidy, filterable counterpart to the sticker book. */
export function CollectionGrid({ items, category, onCategory, onOpen }: { items: BookItem[]; category: CategoryFilter; onCategory: (c: CategoryFilter) => void; onOpen: (id: string) => void }) {
  const [status, setStatus] = useState<StatusFilter>("all");
  const [rarity, setRarity] = useState<Rarity | "any">("any");
  const [sort, setSort] = useState<SortKey>("recent");

  const filtered = items.filter(
    (i) => (category === "all" || i.collectible.category === category) && (rarity === "any" || i.collectible.rarity === rarity) && matchesStatus(i, status),
  );
  const groups = CATEGORY_ORDER.map((cat) => {
    const all = items.filter((i) => i.collectible.category === cat);
    return { cat, owned: all.filter((i) => i.owned).length, total: all.length, items: sortItems(filtered.filter((i) => i.collectible.category === cat), sort) };
  }).filter((g) => g.items.length);

  const clear = () => {
    onCategory("all");
    setStatus("all");
    setRarity("any");
  };

  return (
    <div className="space-y-5">
      <div className="space-y-3 rounded-[18px] border border-line bg-cream/70 p-3">
        <div className="no-scrollbar -mx-3 overflow-x-auto px-3" role="group" aria-label="Category">
          <div className="flex min-w-max gap-1.5">
            <Chip selected={category === "all"} onClick={() => onCategory("all")}>
              All
            </Chip>
            {CATEGORY_ORDER.map((cat) => (
              <Chip key={cat} selected={category === cat} onClick={() => onCategory(cat)}>
                {COLLECTIBLE_CATEGORY_META[cat].short}
              </Chip>
            ))}
          </div>
        </div>
        <div className="no-scrollbar -mx-3 overflow-x-auto px-3" role="group" aria-label="Show">
          <div className="flex min-w-max gap-1.5">
            {STATUS_OPTIONS.map((o) => (
              <Chip key={o.value} selected={status === o.value} onClick={() => setStatus(o.value)}>
                {o.label}
              </Chip>
            ))}
          </div>
        </div>
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <label className="flex min-w-0 flex-1 items-center gap-2 text-sm font-semibold text-muted">
            Rarity
            <select
              value={rarity}
              onChange={(e) => setRarity(e.target.value as Rarity | "any")}
              className="min-h-11 min-w-0 flex-1 rounded-[12px] border border-line-strong bg-cream px-3 text-[0.9375rem] font-medium text-ink focus:border-accent focus:outline-none sm:max-w-52"
            >
              <option value="any">Any rarity</option>
              {RARITIES.map((r) => (
                <option key={r} value={r}>
                  {RARITY_META[r].label}
                </option>
              ))}
            </select>
          </label>
          <Segmented
            label="Sort"
            size="sm"
            value={sort}
            onChange={setSort}
            options={[
              { value: "recent", label: "Recent" },
              { value: "rarity", label: "Rarity" },
            ]}
            className="sm:w-56"
          />
        </div>
      </div>

      <p className="sr-only" aria-live="polite">
        {filtered.length} stickers shown
      </p>

      {groups.length === 0 ? (
        <EmptyState title="Nothing matches" body="Try loosening a filter. Your stickers are still here." mood="thinking" compact action={<Chip onClick={clear}>Clear filters</Chip>} />
      ) : (
        groups.map((g) => (
          <section key={g.cat} aria-labelledby={`grid-${g.cat}`}>
            <div className="mb-2 flex items-baseline justify-between gap-3">
              <h3 id={`grid-${g.cat}`} className="font-display text-[1.0625rem] font-bold tracking-[-0.015em] text-ink">
                {COLLECTIBLE_CATEGORY_META[g.cat].label}
              </h3>
              <span className="text-sm font-semibold tabular-nums text-faint">
                {g.owned} of {g.total}
              </span>
            </div>
            <ul className="grid grid-cols-3 gap-2 sm:grid-cols-4 xl:grid-cols-5">
              {g.items.map((item) => (
                <GridTile key={item.collectible.id} item={item} onOpen={onOpen} />
              ))}
            </ul>
          </section>
        ))
      )}
    </div>
  );
}
