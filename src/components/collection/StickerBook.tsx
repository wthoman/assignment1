"use client";

import { motion } from "motion/react";
import { TINT_SOFT } from "@/components/illustrations/Illustration";
import { HandNote, Tape } from "@/components/ui/misc";
import { Stamp } from "@/components/ui/Stamp";
import { COLLECTIBLE_CATEGORY_META, RARITY_META } from "@/lib/data/catalog";
import { cn } from "@/lib/cn";
import { useAppState } from "@/lib/store/provider";
import { CATEGORY_ORDER, CATEGORY_TINT, scatter, shortDate, stickerLabel, type BookItem, type CategoryFilter } from "./bookUtils";
import { Sticker } from "./Sticker";

interface Section {
  key: string;
  title: string;
  items: BookItem[];
  note?: string;
}

const SECTION_NOTES: Partial<Record<string, string>> = {
  comeback: "comeback counts double",
  superlative: "this week only!",
  "late-night": "technically still today",
};

function buildSections(items: BookItem[], category: CategoryFilter): Section[] {
  if (category === "all") {
    return CATEGORY_ORDER.map((cat) => ({
      key: cat,
      title: COLLECTIBLE_CATEGORY_META[cat].label,
      items: items.filter((i) => i.collectible.category === cat),
      note: SECTION_NOTES[cat],
    })).filter((s) => s.items.length);
  }
  const inCat = items.filter((i) => i.collectible.category === category);
  const owned = inCat.filter((i) => i.owned).sort((a, b) => a.owned!.earnedAt.localeCompare(b.owned!.earnedAt));
  const locked = inCat.filter((i) => !i.owned);
  const out: Section[] = [];
  if (owned.length) out.push({ key: "owned", title: "Collected", items: owned, note: SECTION_NOTES[category] });
  if (locked.length) out.push({ key: "locked", title: "Still to find", items: locked });
  return out;
}

/** Splits sections across two facing pages, keeping their order and balancing sticker counts. */
function paginate(sections: Section[]): [Section[], Section[]] {
  if (sections.length === 1) {
    const s = sections[0];
    const half = Math.ceil(s.items.length / 2);
    if (s.items.length < 4) return [[s], []];
    return [[{ ...s, items: s.items.slice(0, half) }], [{ ...s, key: `${s.key}-2`, title: `${s.title}, cont.`, note: undefined, items: s.items.slice(half) }]];
  }
  const total = sections.reduce((n, s) => n + s.items.length, 0);
  const left: Section[] = [];
  const right: Section[] = [];
  let count = 0;
  for (const s of sections) {
    if (count < total / 2 && (count + s.items.length / 2 <= total / 2 || !left.length)) {
      left.push(s);
      count += s.items.length;
    } else right.push(s);
  }
  return [left, right];
}

/** Category tabs that stick up from the top edge of the book. They filter the pages. */
function BookTabs({ category, onCategory, items }: { category: CategoryFilter; onCategory: (c: CategoryFilter) => void; items: BookItem[] }) {
  const tabs: { value: CategoryFilter; label: string; tint: keyof typeof TINT_SOFT; count: number }[] = [
    { value: "all", label: "All", tint: "cream", count: items.filter((i) => i.owned).length },
    ...CATEGORY_ORDER.map((cat) => ({
      value: cat as CategoryFilter,
      label: COLLECTIBLE_CATEGORY_META[cat].short,
      tint: CATEGORY_TINT[cat],
      count: items.filter((i) => i.collectible.category === cat && i.owned).length,
    })),
  ];
  return (
    <div className="no-scrollbar -mx-4 overflow-x-auto px-4 sm:mx-0 sm:px-0" role="group" aria-label="Filter pages by category">
      <ul className="flex min-w-max items-end gap-1 pl-3 pr-3 sm:min-w-0 sm:flex-wrap">
        {tabs.map((t, i) => {
          const active = t.value === category;
          return (
            <li key={t.value} className="relative" style={{ zIndex: active ? 5 : 1 }}>
              <button
                type="button"
                aria-pressed={active}
                onClick={() => onCategory(t.value)}
                className={cn(
                  "relative flex min-h-11 items-center gap-1.5 rounded-t-[12px] border border-b-0 px-3 font-display text-[0.8125rem] font-semibold transition-[transform,background-color,color] duration-200",
                  active ? "translate-y-px border-line-strong bg-cream text-accent" : cn("translate-y-1.5 border-line text-muted hover:translate-y-0.5 hover:text-ink", TINT_SOFT[t.tint]),
                )}
                style={{ rotate: `${(i % 3) - 1}deg` }}
              >
                {t.label}
                <span className={cn("text-[0.6875rem] tabular-nums", active ? "text-accent/70" : "text-faint")}>{t.count}</span>
              </button>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

function BookSticker({ item, order, note, onOpen }: { item: BookItem; order: number; note?: string; onOpen: (id: string) => void }) {
  const state = useAppState();
  const { collectible: c, owned } = item;
  const s = scatter(c.id);
  const isNew = Boolean(owned && !owned.seen);
  const gifter = owned?.giftedBy ? state.users[owned.giftedBy]?.name.split(" ")[0] : undefined;
  const handNote = note ?? (gifter ? `from ${gifter}` : undefined);

  return (
    <motion.button
      type="button"
      onClick={() => onOpen(c.id)}
      aria-label={stickerLabel(item, RARITY_META[c.rarity].label)}
      className="group relative grid w-[88px] shrink-0 place-items-center rounded-[20px] pb-6 pt-1 hover:z-20 focus-visible:z-20"
      style={{ marginLeft: s.overlap && order > 0 ? -16 : 0, x: s.dx }}
      initial={isNew ? { opacity: 0, scale: 1.35, rotate: -24, y: s.dy - 26 } : false}
      animate={{ opacity: 1, scale: 1, rotate: 0, y: s.dy }}
      transition={isNew ? { type: "spring", stiffness: 260, damping: 15, delay: 0.25 + order * 0.04 } : { duration: 0 }}
      whileHover={{ scale: 1.07, y: s.dy - 3 }}
      whileTap={{ scale: 0.96 }}
    >
      <Sticker collectible={c} size={78} locked={!owned} rotate={s.rotate} peel={isNew} />
      {!owned && (
        <span aria-hidden className="pointer-events-none absolute inset-x-0 bottom-0.5 text-center font-hand text-lg leading-none text-faint">
          ?
        </span>
      )}
      {owned && s.showDate && (
        <span aria-hidden className="pointer-events-none absolute inset-x-0 bottom-0.5 text-center font-hand text-[0.95rem] leading-none text-muted" style={{ rotate: `${s.dateTilt}deg` }}>
          {shortDate(owned.earnedAt)}
        </span>
      )}
      {isNew && (
        <span className="pointer-events-none absolute -right-1 top-0" aria-hidden>
          <Stamp variant="label" text="new" rotate={12} animate className="bg-cream/80 text-[0.625rem]!" />
        </span>
      )}
      {handNote && (
        <span aria-hidden className="pointer-events-none absolute -top-3 left-1/2 whitespace-nowrap">
          <HandNote rotate={-8} className="text-base">
            {handNote}
          </HandNote>
        </span>
      )}
    </motion.button>
  );
}

function BookPage({ sections, side, firstId, onOpen, stamp }: { sections: Section[]; side: "left" | "right"; firstId?: string; onOpen: (id: string) => void; stamp?: string }) {
  return (
    <div className={cn("relative min-w-0 px-3 pb-8 pt-6 sm:px-5", side === "right" && "max-md:pt-2")}>
      {/* faint fold lines */}
      <span aria-hidden className="pointer-events-none absolute inset-x-0 top-1/3 h-px bg-[linear-gradient(90deg,transparent,var(--line)_15%,var(--line)_85%,transparent)] opacity-70" />
      <span aria-hidden className="pointer-events-none absolute inset-x-0 top-2/3 h-px bg-[linear-gradient(90deg,transparent,var(--line)_15%,var(--line)_85%,transparent)] opacity-50" />
      {side === "left" ? <Tape className="-left-3 top-3" rotate={-32} /> : <Tape className="-right-3 top-3 max-md:hidden" rotate={30} />}
      {stamp && (
        <span className="pointer-events-none absolute right-3 top-2 opacity-80 max-md:hidden" aria-hidden>
          <Stamp variant="date" text={stamp} size={58} rotate={14} />
        </span>
      )}
      <div className="relative space-y-6">
        {sections.map((sec) => (
          <section key={sec.key} aria-label={sec.title}>
            <div className="mb-1 flex flex-wrap items-baseline gap-x-2 pl-1">
              <h3 className="font-hand text-[1.6rem] font-bold leading-none text-accent">{sec.title}</h3>
              <span className="font-display text-xs font-semibold tabular-nums text-faint">
                {sec.items.filter((i) => i.owned).length}/{sec.items.length}
              </span>
              {sec.note && (
                <HandNote rotate={-2} className="ml-auto text-base text-muted">
                  ← {sec.note}
                </HandNote>
              )}
            </div>
            <div className="flex flex-wrap items-start pl-1 pt-2">
              {sec.items.map((item, i) => (
                <BookSticker key={item.collectible.id} item={item} order={i} onOpen={onOpen} note={item.collectible.id === firstId ? "first one!" : undefined} />
              ))}
            </div>
          </section>
        ))}
      </div>
    </div>
  );
}

/**
 * The open scrapbook: facing pages with a centre fold on wider screens, one long page on phones.
 * Placement is deliberately imperfect but deterministic (seeded by collectible id).
 */
export function StickerBook({ items, category, onCategory, onOpen }: { items: BookItem[]; category: CategoryFilter; onCategory: (c: CategoryFilter) => void; onOpen: (id: string) => void }) {
  const sections = buildSections(items, category);
  const [left, right] = paginate(sections);
  const ownedAll = items.filter((i) => i.owned);
  const firstId = [...ownedAll].sort((a, b) => a.owned!.earnedAt.localeCompare(b.owned!.earnedAt))[0]?.collectible.id;
  const inView = category === "all" ? items : items.filter((i) => i.collectible.category === category);
  const stampText = `${inView.filter((i) => i.owned).length}/${inView.length}`;

  return (
    <div className="relative">
      <BookTabs category={category} onCategory={onCategory} items={items} />
      <div className="relative">
        {/* page edges peeking out underneath */}
        <span aria-hidden className="absolute inset-x-2 -bottom-2 h-full rounded-[10px_10px_20px_20px] border border-line bg-paper-deep" />
        <span aria-hidden className="absolute inset-x-1 -bottom-1 h-full rounded-[10px_10px_20px_20px] border border-line bg-cream" />
        <div
          className="relative overflow-hidden rounded-[8px_8px_18px_18px] border border-line-strong bg-cream shadow-[var(--shadow-lift)] md:grid md:grid-cols-2"
          style={{
            backgroundImage: "radial-gradient(rgb(111 23 37 / 0.07) 1px, transparent 1.3px), radial-gradient(ellipse at 50% 0%, rgb(255 255 255 / 0.35), transparent 70%)",
            backgroundSize: "18px 18px, 100% 100%",
          }}
        >
          {/* centre gutter shadow */}
          <span
            aria-hidden
            className="pointer-events-none absolute inset-y-0 left-1/2 z-[1] hidden w-16 -translate-x-1/2 md:block"
            style={{ background: "linear-gradient(90deg, transparent, rgb(70 30 20 / 0.07) 38%, rgb(70 30 20 / 0.2) 50%, rgb(70 30 20 / 0.07) 62%, transparent)" }}
          />
          <BookPage sections={left} side="left" firstId={firstId} onOpen={onOpen} />
          {right.length > 0 && <BookPage sections={right} side="right" firstId={firstId} onOpen={onOpen} stamp={stampText} />}
          {right.length === 0 && (
            <div className="relative hidden place-items-center p-8 md:grid" aria-hidden>
              <HandNote rotate={-4} className="text-center text-xl text-muted">
                room for more…
              </HandNote>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
