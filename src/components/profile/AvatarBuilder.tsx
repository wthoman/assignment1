"use client";

import { AnimatePresence, motion } from "motion/react";
import { Check, Lock, Shuffle } from "lucide-react";
import { useId, useRef, useState, type KeyboardEvent } from "react";
import { AvatarArt } from "@/components/avatar/Avatar";
import { Button } from "@/components/ui/Button";
import { Toggle } from "@/components/ui/controls";
import { HandNote, Tape } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { cn } from "@/lib/cn";
import { COSMETICS, HAIR_COLORS, OUTFIT_COLORS, SKIN_TONES } from "@/lib/data/catalog";
import { useAppState } from "@/lib/store/provider";
import type { AvatarConfig, CosmeticSlot, EyeStyle, HeadShape, MouthStyle } from "@/lib/types";

type TabKey = "face" | "hair" | "outfit" | "accessory" | "background" | "frame" | "companion";

const TABS: { key: TabKey; label: string }[] = [
  { key: "face", label: "Face" },
  { key: "hair", label: "Hair" },
  { key: "outfit", label: "Outfit" },
  { key: "accessory", label: "Accessories" },
  { key: "background", label: "Background" },
  { key: "frame", label: "Frame" },
  { key: "companion", label: "Companion" },
];

const HEADS: { value: HeadShape; name: string }[] = [
  { value: "round", name: "Round" },
  { value: "bean", name: "Bean" },
  { value: "square", name: "Soft square" },
  { value: "tall", name: "Tall" },
];
const EYES: { value: EyeStyle; name: string }[] = [
  { value: "dot", name: "Dots" },
  { value: "happy", name: "Happy" },
  { value: "sleepy", name: "Sleepy" },
  { value: "wink", name: "Wink" },
];
const MOUTHS: { value: MouthStyle; name: string }[] = [
  { value: "smile", name: "Smile" },
  { value: "grin", name: "Grin" },
  { value: "flat", name: "Neutral" },
  { value: "o", name: "Oh!" },
];

const SLOT_KEY: Record<CosmeticSlot, keyof AvatarConfig> = {
  hair: "hair",
  accessory: "accessory",
  outfit: "outfit",
  background: "background",
  frame: "frame",
  companion: "companion",
};

export interface AvatarBuilderProps {
  value: AvatarConfig;
  onChange: (next: AvatarConfig) => void;
  /** Cosmetic ids the user may pick. Defaults to the store's unlocked cosmetics. */
  unlocked?: string[] | "all";
  className?: string;
}

function pick<T>(xs: T[]): T {
  return xs[Math.floor(Math.random() * xs.length)];
}

/** Random avatar built only from unlocked cosmetics. Call from event handlers. */
export function randomAvatar(base: AvatarConfig, isUnlocked: (id: string) => boolean): AvatarConfig {
  const slotValues = (slot: CosmeticSlot) => COSMETICS.filter((c) => c.slot === slot && isUnlocked(c.id)).map((c) => c.value);
  const next: AvatarConfig = {
    ...base,
    head: pick(HEADS).value,
    skin: pick(SKIN_TONES),
    hairColor: pick(HAIR_COLORS),
    eyes: pick(EYES).value,
    mouth: pick(MOUTHS).value,
    cheeks: Math.random() > 0.35,
    outfitColor: pick(OUTFIT_COLORS),
  };
  (Object.keys(SLOT_KEY) as CosmeticSlot[]).forEach((slot) => {
    const values = slotValues(slot);
    if (values.length) (next as unknown as Record<string, string>)[SLOT_KEY[slot]] = pick(values);
  });
  return next;
}

/**
 * Avatar editor: live preview plus tabbed categories. Locked cosmetics stay visible,
 * greyed out with their (participation-only) unlock requirement.
 */
export function AvatarBuilder({ value, onChange, unlocked, className }: AvatarBuilderProps) {
  const state = useAppState();
  const toast = useToast();
  const [tab, setTab] = useState<TabKey>("face");
  const [spin, setSpin] = useState(0);
  const baseId = useId();
  const tabRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const list = unlocked ?? state.unlockedCosmetics;
  const isUnlocked = (id: string) => list === "all" || list.includes(id);
  const set = <K extends keyof AvatarConfig>(k: K, v: AvatarConfig[K]) => onChange({ ...value, [k]: v });

  const onTabKey = (e: KeyboardEvent, i: number) => {
    let next = -1;
    if (e.key === "ArrowRight") next = (i + 1) % TABS.length;
    else if (e.key === "ArrowLeft") next = (i - 1 + TABS.length) % TABS.length;
    else if (e.key === "Home") next = 0;
    else if (e.key === "End") next = TABS.length - 1;
    if (next < 0) return;
    e.preventDefault();
    setTab(TABS[next].key);
    tabRefs.current[next]?.focus();
  };

  const randomize = () => {
    onChange(randomAvatar(value, isUnlocked));
    setSpin((s) => s + 1);
  };

  const cosmeticOptions = (slot: CosmeticSlot) =>
    COSMETICS.filter((c) => c.slot === slot).map((c) => ({
      value: c.value,
      name: c.name,
      locked: !isUnlocked(c.id),
      unlock: c.unlock,
      preview: { ...value, [SLOT_KEY[slot]]: c.value } as AvatarConfig,
    }));

  const onLocked = (name: string, unlock: string) => toast({ title: `${name} is locked`, body: `Unlock: ${unlock}. Earned by taking part, never bought.`, motif: "ribbon" });

  const unlockedCount = list === "all" ? COSMETICS.length : COSMETICS.filter((c) => list.includes(c.id)).length;

  return (
    <div className={cn("space-y-4", className)}>
      {/* Preview */}
      <div className="card relative flex flex-col items-center px-4 pb-4 pt-6">
        <Tape className="-top-2 left-1/2 -ml-7" rotate={-3} />
        <motion.div key={spin} initial={spin ? { rotate: -8, scale: 0.9 } : false} animate={{ rotate: 0, scale: 1 }} transition={{ type: "spring", stiffness: 380, damping: 18 }} className="pb-2 pr-4">
          <AvatarArt config={value} size={168} title="Avatar preview" />
        </motion.div>
        <HandNote className="mt-1 text-base" rotate={-2}>
          looking good
        </HandNote>
        <div className="mt-3 flex w-full items-center justify-between gap-2">
          <p className="text-xs text-muted">
            <span className="font-semibold text-ink">{unlockedCount}</span> of {COSMETICS.length} cosmetics unlocked
          </p>
          <Button variant="secondary" size="sm" icon={<Shuffle size={15} aria-hidden />} onClick={randomize}>
            Randomize
          </Button>
        </div>
      </div>

      {/* Tabs */}
      <div role="tablist" aria-label="Avatar categories" className="no-scrollbar -mx-4 flex gap-1.5 overflow-x-auto px-4 pb-1 sm:mx-0 sm:flex-wrap sm:px-0">
        {TABS.map((t, i) => {
          const active = t.key === tab;
          return (
            <button
              key={t.key}
              ref={(el) => {
                tabRefs.current[i] = el;
              }}
              type="button"
              role="tab"
              id={`${baseId}-tab-${t.key}`}
              aria-selected={active}
              aria-controls={`${baseId}-panel`}
              tabIndex={active ? 0 : -1}
              onClick={() => setTab(t.key)}
              onKeyDown={(e) => onTabKey(e, i)}
              className={cn(
                "min-h-11 shrink-0 rounded-[11px] border px-3.5 font-display text-sm font-semibold transition-colors",
                active ? "border-accent bg-accent text-on-accent" : "border-line-strong bg-cream text-ink hover:bg-accent-soft",
              )}
            >
              {t.label}
            </button>
          );
        })}
      </div>

      <div role="tabpanel" id={`${baseId}-panel`} aria-labelledby={`${baseId}-tab-${tab}`} className="card-flat p-4">
        <AnimatePresence mode="wait" initial={false}>
          <motion.div key={tab} initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -4 }} transition={{ duration: 0.16 }} className="space-y-5">
            {tab === "face" && (
              <>
                <OptionGroup label="Head shape" options={HEADS.map((h) => ({ value: h.value, name: h.name, preview: { ...value, head: h.value } }))} selected={value.head} onSelect={(v) => set("head", v as HeadShape)} onLocked={onLocked} />
                <SwatchGroup label="Skin tone" colors={SKIN_TONES} selected={value.skin} onSelect={(c) => set("skin", c)} />
                <OptionGroup label="Eyes" options={EYES.map((o) => ({ value: o.value, name: o.name, preview: { ...value, eyes: o.value } }))} selected={value.eyes} onSelect={(v) => set("eyes", v as EyeStyle)} onLocked={onLocked} zoom />
                <OptionGroup label="Mouth" options={MOUTHS.map((o) => ({ value: o.value, name: o.name, preview: { ...value, mouth: o.value } }))} selected={value.mouth} onSelect={(v) => set("mouth", v as MouthStyle)} onLocked={onLocked} zoom />
                <div className="flex min-h-11 items-center justify-between gap-3 rounded-[12px] bg-paper/60 px-3">
                  <span className="text-sm font-semibold text-ink">Rosy cheeks</span>
                  <Toggle label="Rosy cheeks" checked={value.cheeks} onChange={(v) => set("cheeks", v)} />
                </div>
              </>
            )}
            {tab === "hair" && (
              <>
                <OptionGroup label="Hair style" options={cosmeticOptions("hair")} selected={value.hair} onSelect={(v) => set("hair", v as AvatarConfig["hair"])} onLocked={onLocked} />
                <SwatchGroup label="Hair colour" colors={HAIR_COLORS} selected={value.hairColor} onSelect={(c) => set("hairColor", c)} />
              </>
            )}
            {tab === "outfit" && (
              <>
                <OptionGroup label="Outfit" options={cosmeticOptions("outfit")} selected={value.outfit} onSelect={(v) => set("outfit", v as AvatarConfig["outfit"])} onLocked={onLocked} />
                <SwatchGroup label="Outfit colour" colors={OUTFIT_COLORS} selected={value.outfitColor} onSelect={(c) => set("outfitColor", c)} />
              </>
            )}
            {tab === "accessory" && <OptionGroup label="Accessories" options={cosmeticOptions("accessory")} selected={value.accessory} onSelect={(v) => set("accessory", v as AvatarConfig["accessory"])} onLocked={onLocked} />}
            {tab === "background" && <OptionGroup label="Background" options={cosmeticOptions("background")} selected={value.background} onSelect={(v) => set("background", v as AvatarConfig["background"])} onLocked={onLocked} />}
            {tab === "frame" && <OptionGroup label="Frame" options={cosmeticOptions("frame")} selected={value.frame} onSelect={(v) => set("frame", v as AvatarConfig["frame"])} onLocked={onLocked} />}
            {tab === "companion" && <OptionGroup label="Companion" options={cosmeticOptions("companion")} selected={value.companion} onSelect={(v) => set("companion", v as AvatarConfig["companion"])} onLocked={onLocked} wide />}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}

interface Option {
  value: string;
  name: string;
  preview: AvatarConfig;
  locked?: boolean;
  unlock?: string;
}

function OptionGroup({
  label,
  options,
  selected,
  onSelect,
  onLocked,
  zoom,
  wide,
}: {
  label: string;
  options: Option[];
  selected: string;
  onSelect: (v: string) => void;
  onLocked: (name: string, unlock: string) => void;
  zoom?: boolean;
  wide?: boolean;
}) {
  const id = useId();
  return (
    <fieldset>
      <legend id={id} className="mb-2 font-display text-sm font-bold text-ink">
        {label}
      </legend>
      <div role="radiogroup" aria-labelledby={id} className={cn("grid gap-2", wide ? "grid-cols-2 sm:grid-cols-3" : "grid-cols-3 sm:grid-cols-4")}>
        {options.map((o) => {
          const active = o.value === selected;
          return (
            <button
              key={o.value}
              type="button"
              role="radio"
              aria-checked={active}
              aria-disabled={o.locked || undefined}
              aria-label={o.locked ? `${o.name}, locked. ${o.unlock}` : o.name}
              onClick={() => (o.locked ? onLocked(o.name, o.unlock ?? "Keep going") : onSelect(o.value))}
              className={cn(
                "relative flex min-h-11 flex-col items-center gap-1 rounded-[13px] border p-2 text-center transition-[background-color,border-color,transform] active:scale-[0.97]",
                active ? "border-accent bg-accent-soft" : "border-line bg-cream hover:border-line-strong",
                o.locked && "border-dashed bg-paper-deep/50",
              )}
            >
              <span className={cn("grid place-items-center overflow-hidden rounded-full", zoom && "[&>svg]:scale-[1.7] [&>svg]:translate-y-[2px]", o.locked && "opacity-45 grayscale")}>
                <AvatarArt config={o.preview} size={wide ? 64 : 52} />
              </span>
              <span className={cn("text-[0.75rem] font-semibold leading-tight", o.locked ? "text-faint" : "text-ink")}>{o.name}</span>
              {o.locked && (
                <>
                  <span className="text-[0.625rem] leading-tight text-muted">{o.unlock}</span>
                  <span className="absolute right-1.5 top-1.5 grid size-5 place-items-center rounded-full bg-cream text-muted shadow-[var(--shadow)]">
                    <Lock size={11} aria-hidden />
                  </span>
                </>
              )}
              {active && !o.locked && (
                <span className="absolute right-1.5 top-1.5 grid size-5 place-items-center rounded-full bg-accent text-on-accent">
                  <Check size={12} strokeWidth={3} aria-hidden />
                </span>
              )}
            </button>
          );
        })}
      </div>
    </fieldset>
  );
}

function SwatchGroup({ label, colors, selected, onSelect }: { label: string; colors: string[]; selected: string; onSelect: (c: string) => void }) {
  const id = useId();
  return (
    <fieldset>
      <legend id={id} className="mb-2 font-display text-sm font-bold text-ink">
        {label}
      </legend>
      <div role="radiogroup" aria-labelledby={id} className="flex flex-wrap gap-2">
        {colors.map((c, i) => {
          const active = c.toLowerCase() === selected.toLowerCase();
          return (
            <button
              key={c}
              type="button"
              role="radio"
              aria-checked={active}
              aria-label={`${label} ${i + 1} of ${colors.length}`}
              onClick={() => onSelect(c)}
              className={cn("grid size-11 place-items-center rounded-full border-2 transition-transform active:scale-95", active ? "border-accent" : "border-transparent hover:border-line-strong")}
            >
              <span className="grid size-8 place-items-center rounded-full border border-[#2e1b1a]/40" style={{ backgroundColor: c }}>
                {active && <Check size={14} strokeWidth={3} className="text-[#fbf6ec] drop-shadow-[0_1px_1px_rgb(0_0_0/0.5)]" aria-hidden />}
              </span>
            </button>
          );
        })}
      </div>
    </fieldset>
  );
}
