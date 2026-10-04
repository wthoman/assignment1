"use client";

import { Shuffle } from "lucide-react";
import { motion } from "motion/react";
import { useId, useState, type ReactNode } from "react";
import { AvatarArt } from "@/components/avatar/Avatar";
import { TINT_HEX } from "@/components/illustrations/Illustration";
import { Button } from "@/components/ui/Button";
import { Segmented, Toggle } from "@/components/ui/controls";
import { Tape } from "@/components/ui/misc";
import { cn } from "@/lib/cn";
import { HAIR_COLORS, OUTFIT_COLORS, SKIN_TONES } from "@/lib/data/catalog";
import type { Accessory, AvatarConfig, EyeStyle, HairStyle, HeadShape, MouthStyle, Outfit, Tint } from "@/lib/types";

/* Starter options only: unlockable cosmetics live in the full avatar builder. */
const HEADS: { value: HeadShape; label: string }[] = [
  { value: "round", label: "Round" },
  { value: "bean", label: "Bean" },
  { value: "square", label: "Soft square" },
  { value: "tall", label: "Oval" },
];
const HAIR: { value: HairStyle; label: string }[] = [
  { value: "buzz", label: "Buzz" },
  { value: "bob", label: "Bob" },
  { value: "curly", label: "Curls" },
  { value: "bun", label: "Top bun" },
  { value: "long", label: "Long" },
  { value: "none", label: "None" },
];
const EYES: { value: EyeStyle; label: string }[] = [
  { value: "dot", label: "Dots" },
  { value: "happy", label: "Happy" },
  { value: "sleepy", label: "Sleepy" },
  { value: "wink", label: "Wink" },
];
const MOUTHS: { value: MouthStyle; label: string }[] = [
  { value: "smile", label: "Smile" },
  { value: "grin", label: "Grin" },
  { value: "flat", label: "Neutral" },
  { value: "o", label: "Ooh" },
];
const OUTFITS: { value: Outfit; label: string }[] = [
  { value: "tee", label: "Tee" },
  { value: "hoodie", label: "Hoodie" },
  { value: "sweater", label: "Sweater" },
];
const ACCESSORIES: { value: Accessory; label: string }[] = [
  { value: "none", label: "None" },
  { value: "glasses", label: "Glasses" },
];
const BACKGROUNDS: { value: Tint; label: string }[] = [
  { value: "cream", label: "Cream" },
  { value: "rose", label: "Dusty rose" },
  { value: "sage", label: "Sage" },
  { value: "orange", label: "Apricot" },
];
const COLOR_NAMES: Record<string, string> = {
  "#F6D5B8": "Light",
  "#EBC09C": "Light medium",
  "#D29F76": "Medium",
  "#B07B53": "Medium deep",
  "#8A5A3B": "Deep",
  "#5E3B27": "Very deep",
  "#271C1B": "Black",
  "#5B3424": "Dark brown",
  "#9A5B32": "Auburn",
  "#D9A95B": "Blond",
  "#B4473A": "Copper",
  "#8E8A84": "Grey",
  "#6F1725": "Burgundy",
  "#8FA382": "Sage",
  "#E09A5F": "Apricot",
  "#A9C3D4": "Sky",
  "#C9A24A": "Mustard",
  "#D9A3A0": "Rose",
};

type Tab = "face" | "hair" | "outfit" | "extras";

const pick = <T,>(xs: readonly T[]): T => xs[Math.floor(Math.random() * xs.length)];

export function randomAvatar(base: AvatarConfig): AvatarConfig {
  return {
    ...base,
    head: pick(HEADS).value,
    skin: pick(SKIN_TONES),
    hair: pick(HAIR).value,
    hairColor: pick(HAIR_COLORS),
    eyes: pick(EYES).value,
    mouth: pick(MOUTHS).value,
    outfit: pick(OUTFITS).value,
    outfitColor: pick(OUTFIT_COLORS),
    background: pick(BACKGROUNDS).value,
    accessory: Math.random() < 0.3 ? "glasses" : "none",
    cheeks: Math.random() < 0.7,
  };
}

function OptionGroup({ label, children }: { label: string; children: ReactNode }) {
  const id = useId();
  return (
    <div className="space-y-2">
      <p id={id} className="font-display text-sm font-semibold text-ink">
        {label}
      </p>
      <div role="radiogroup" aria-labelledby={id} className="flex flex-wrap gap-2">
        {children}
      </div>
    </div>
  );
}

/** A style option rendered as a small avatar preview with that option applied. */
function StyleOption({ config, selected, label, onSelect }: { config: AvatarConfig; selected: boolean; label: string; onSelect: () => void }) {
  return (
    <button
      type="button"
      role="radio"
      aria-checked={selected}
      onClick={onSelect}
      className={cn(
        "flex w-16 flex-col items-center gap-1 rounded-[13px] border px-1 pb-1.5 pt-2 transition-[background-color,border-color,transform] duration-150 active:scale-[0.96]",
        selected ? "border-accent bg-accent-soft" : "border-line bg-cream hover:bg-accent-soft/50",
      )}
    >
      <AvatarArt config={{ ...config, companion: "none", frame: "none" }} size={44} />
      <span className={cn("text-[0.6875rem] font-semibold leading-tight", selected ? "text-accent" : "text-muted")}>{label}</span>
    </button>
  );
}

function Swatch({ color, selected, label, onSelect }: { color: string; selected: boolean; label: string; onSelect: () => void }) {
  return (
    <button
      type="button"
      role="radio"
      aria-checked={selected}
      aria-label={label}
      title={label}
      onClick={onSelect}
      className={cn("grid size-11 place-items-center rounded-full transition-transform duration-150 active:scale-[0.92]", selected ? "ring-2 ring-accent ring-offset-2 ring-offset-cream" : "hover:scale-105")}
    >
      <span className="size-9 rounded-full border border-[#2e1b1a]/40" style={{ backgroundColor: color }} />
    </button>
  );
}

/** Compact avatar customizer used during onboarding: big live preview, tabs, starter options only. */
export function AvatarCustomizer({ value, onChange, reduce }: { value: AvatarConfig; onChange: (v: AvatarConfig) => void; reduce: boolean }) {
  const [tab, setTab] = useState<Tab>("face");
  const [spins, setSpins] = useState(0);
  const set = (patch: Partial<AvatarConfig>) => onChange({ ...value, ...patch });

  return (
    <div className="space-y-5">
      <div className="relative flex flex-col items-center rounded-[var(--radius-card)] border border-line bg-paper-deep/50 px-4 pb-4 pt-6">
        <Tape className="-top-2 left-6" rotate={-8} />
        <Tape className="-top-2 right-6" rotate={7} />
        <motion.div key={spins} initial={reduce || spins === 0 ? false : { scale: 0.86, rotate: -6 }} animate={{ scale: 1, rotate: 0 }} transition={{ type: "spring", stiffness: 380, damping: 18 }}>
          <AvatarArt config={value} size={168} title="Your avatar preview" />
        </motion.div>
        <Button
          variant="secondary"
          size="sm"
          className="mt-4 min-h-11"
          icon={<Shuffle size={16} aria-hidden />}
          onClick={() => {
            onChange(randomAvatar(value));
            setSpins((n) => n + 1);
          }}
        >
          Surprise me
        </Button>
      </div>

      <Segmented<Tab>
        label="Avatar part"
        value={tab}
        onChange={setTab}
        size="sm"
        options={[
          { value: "face", label: "Face" },
          { value: "hair", label: "Hair" },
          { value: "outfit", label: "Outfit" },
          { value: "extras", label: "Extras" },
        ]}
      />

      <div className="space-y-5">
        {tab === "face" && (
          <>
            <OptionGroup label="Skin tone">
              {SKIN_TONES.map((c) => (
                <Swatch key={c} color={c} label={COLOR_NAMES[c] ?? c} selected={value.skin === c} onSelect={() => set({ skin: c })} />
              ))}
            </OptionGroup>
            <OptionGroup label="Face shape">
              {HEADS.map((o) => (
                <StyleOption key={o.value} config={{ ...value, head: o.value }} label={o.label} selected={value.head === o.value} onSelect={() => set({ head: o.value })} />
              ))}
            </OptionGroup>
            <OptionGroup label="Eyes">
              {EYES.map((o) => (
                <StyleOption key={o.value} config={{ ...value, eyes: o.value }} label={o.label} selected={value.eyes === o.value} onSelect={() => set({ eyes: o.value })} />
              ))}
            </OptionGroup>
            <OptionGroup label="Mouth">
              {MOUTHS.map((o) => (
                <StyleOption key={o.value} config={{ ...value, mouth: o.value }} label={o.label} selected={value.mouth === o.value} onSelect={() => set({ mouth: o.value })} />
              ))}
            </OptionGroup>
          </>
        )}
        {tab === "hair" && (
          <>
            <OptionGroup label="Hair style">
              {HAIR.map((o) => (
                <StyleOption key={o.value} config={{ ...value, hair: o.value }} label={o.label} selected={value.hair === o.value} onSelect={() => set({ hair: o.value })} />
              ))}
            </OptionGroup>
            <OptionGroup label="Hair color">
              {HAIR_COLORS.map((c) => (
                <Swatch key={c} color={c} label={COLOR_NAMES[c] ?? c} selected={value.hairColor === c} onSelect={() => set({ hairColor: c })} />
              ))}
            </OptionGroup>
          </>
        )}
        {tab === "outfit" && (
          <>
            <OptionGroup label="Top">
              {OUTFITS.map((o) => (
                <StyleOption key={o.value} config={{ ...value, outfit: o.value }} label={o.label} selected={value.outfit === o.value} onSelect={() => set({ outfit: o.value })} />
              ))}
            </OptionGroup>
            <OptionGroup label="Color">
              {OUTFIT_COLORS.map((c) => (
                <Swatch key={c} color={c} label={COLOR_NAMES[c] ?? c} selected={value.outfitColor === c} onSelect={() => set({ outfitColor: c })} />
              ))}
            </OptionGroup>
          </>
        )}
        {tab === "extras" && (
          <>
            <OptionGroup label="Background">
              {BACKGROUNDS.map((o) => (
                <Swatch key={o.value} color={TINT_HEX[o.value]} label={o.label} selected={value.background === o.value} onSelect={() => set({ background: o.value })} />
              ))}
            </OptionGroup>
            <OptionGroup label="Accessory">
              {ACCESSORIES.map((o) => (
                <StyleOption key={o.value} config={{ ...value, accessory: o.value }} label={o.label} selected={value.accessory === o.value} onSelect={() => set({ accessory: o.value })} />
              ))}
            </OptionGroup>
            <div className="flex min-h-11 items-center justify-between gap-3">
              <span className="font-display text-sm font-semibold text-ink">Rosy cheeks</span>
              <Toggle checked={value.cheeks} onChange={(v) => set({ cheeks: v })} label="Rosy cheeks" />
            </div>
            <p className="text-[0.8125rem] leading-relaxed text-muted">More hats, frames and companions unlock as you collect stickers.</p>
          </>
        )}
      </div>
    </div>
  );
}
