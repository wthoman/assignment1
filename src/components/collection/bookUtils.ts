import { COLLECTIBLE_CATEGORY_META, COLLECTIBLES } from "@/lib/data/catalog";
import { hashString, mulberry32 } from "@/lib/random";
import type { Collectible, CollectibleCategory, OwnedCollectible, Rarity, Tint } from "@/lib/types";

export type CategoryFilter = "all" | CollectibleCategory;

export const CATEGORY_ORDER = Object.keys(COLLECTIBLE_CATEGORY_META) as CollectibleCategory[];

/** Tab colours for the sticker-book page tabs. Kept soft so the stickers stay the stars. */
export const CATEGORY_TINT: Record<CollectibleCategory, Tint> = {
  first: "gold",
  consistency: "sage",
  streak: "orange",
  comeback: "rose",
  shared: "sky",
  group: "sage",
  helping: "rose",
  "late-night": "sky",
  weekend: "gold",
  superlative: "burgundy",
};

export const RARITY_RANK: Record<Rarity, number> = { common: 0, uncommon: 1, rare: 2, legendary: 3, limited: 4 };

export interface BookItem {
  collectible: Collectible;
  owned?: OwnedCollectible;
}

export function bookItems(collection: OwnedCollectible[]): BookItem[] {
  const byId = new Map(collection.map((o) => [o.collectibleId, o]));
  return COLLECTIBLES.map((c) => ({ collectible: c, owned: byId.get(c.id) }));
}

/**
 * Deterministic "imperfect placement" for a sticker, seeded by its id so the
 * page never reshuffles between renders or reloads.
 */
export function scatter(id: string) {
  const rnd = mulberry32(hashString(id));
  const rotate = Math.round((rnd() * 2 - 1) * 11 * 10) / 10;
  const dx = Math.round((rnd() * 2 - 1) * 6);
  const dy = Math.round((rnd() * 2 - 1) * 9);
  const overlap = rnd() < 0.45;
  const dateTilt = Math.round((rnd() * 2 - 1) * 6);
  const showDate = rnd() < 0.7;
  return { rotate, dx, dy, overlap, dateTilt, showDate };
}

export function shortDate(ts: string) {
  return new Date(ts).toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

export function stickerLabel(item: BookItem, rarityLabel: string) {
  const { collectible: c, owned } = item;
  const status = owned ? `earned ${new Date(owned.earnedAt).toLocaleDateString("en-US", { month: "long", day: "numeric" })}` : "locked";
  return `${c.name}, ${rarityLabel}, ${status}${owned && !owned.seen ? ", new" : ""}`;
}

/** Locked collectibles that look closest to being earned: common first, in categories you've started. */
export function nearestLocked(items: BookItem[], n = 3): BookItem[] {
  const startedCats = new Set(items.filter((i) => i.owned).map((i) => i.collectible.category));
  return items
    .filter((i) => !i.owned && i.collectible.rarity !== "limited")
    .sort((a, b) => {
      const ra = RARITY_RANK[a.collectible.rarity] - (startedCats.has(a.collectible.category) ? 0.5 : 0);
      const rb = RARITY_RANK[b.collectible.rarity] - (startedCats.has(b.collectible.category) ? 0.5 : 0);
      return ra - rb;
    })
    .slice(0, n);
}

export const VIEW_KEY = "daybook:collection-view";
export type CollectionView = "book" | "grid";

export function readView(): CollectionView {
  try {
    return window.localStorage.getItem(VIEW_KEY) === "grid" ? "grid" : "book";
  } catch {
    return "book";
  }
}

export function writeView(v: CollectionView) {
  try {
    window.localStorage.setItem(VIEW_KEY, v);
  } catch {
    /* storage unavailable: the choice just won't stick */
  }
}
