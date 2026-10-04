"use client";

import { Check, Flame, Moon, Sun } from "lucide-react";
import { Mascot } from "@/components/illustrations/Mascot";
import { SettingsBlock } from "@/components/settings/SettingsControls";
import { Page } from "@/components/shell/Page";
import { Stamp } from "@/components/ui/Stamp";
import { Segmented, Toggle } from "@/components/ui/controls";
import { SettingsGroup, SettingsRow } from "@/components/ui/misc";
import { cn } from "@/lib/cn";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { AccentKey, EncouragementStyle, Settings } from "@/lib/types";

/** Swatch colours for the picker itself (the live app uses CSS tokens). */
const ACCENTS: { key: AccentKey; label: string; swatch: string }[] = [
  { key: "burgundy", label: "Burgundy", swatch: "#6f1725" },
  { key: "forest", label: "Forest", swatch: "#2f5d3a" },
  { key: "ink", label: "Ink blue", swatch: "#2b3a55" },
  { key: "terracotta", label: "Terracotta", swatch: "#9c4320" },
];

const ENCOURAGEMENT: Record<EncouragementStyle, { label: string; sample: string; after: string }> = {
  gentle: { label: "Gentle", sample: "Nice work today. Small steps still count.", after: "Missed yesterday? That's okay. Today's a fresh page." },
  cheeky: { label: "Cheeky", sample: "Look who showed up. The water bottle is thrilled.", after: "Yesterday ghosted you. Today's buying the coffee." },
  coach: { label: "Coach", sample: "Two down, one to go. Finish strong.", after: "One miss. No drama. Back on it at 7:30." },
};

export default function AppearanceSettingsPage() {
  const { settings } = useAppState();
  const dispatch = useDispatch();
  const update = (patch: Partial<Settings>) => dispatch({ type: "settings/update", patch });
  const enc = ENCOURAGEMENT[settings.encouragement];

  return (
    <Page title="Appearance" back="/settings" subtitle="Changes apply instantly across the app.">
      <div className="space-y-7">
        {/* Live preview */}
        <div className="card relative overflow-hidden p-4" aria-label="Preview" role="group">
          <p className="eyebrow">Preview</p>
          <div className={cn("mt-2 flex items-center gap-3 rounded-[14px] border border-line bg-paper/70", settings.density === "compact" ? "p-2" : "p-3.5")}>
            <Stamp size={settings.density === "compact" ? 34 : 42} />
            <div className="min-w-0 flex-1">
              <p className="font-display font-bold text-ink">Morning walk</p>
              <p className="text-xs text-muted">Done at 7:21am{settings.showStreaks ? " · 12 in a row" : ""}</p>
            </div>
            {settings.showStreaks && (
              <span className="inline-flex items-center gap-1 rounded-[9px] bg-accent-soft px-2 py-1 text-xs font-bold text-accent">
                <Flame size={13} aria-hidden /> 12
              </span>
            )}
          </div>
          <div className="mt-3 flex items-end gap-2">
            <Mascot mood="happy" size={52} />
            <p className="relative mb-2 rounded-[14px] rounded-bl-[4px] bg-accent px-3 py-2 text-sm text-on-accent">{enc.sample}</p>
          </div>
        </div>

        <SettingsGroup title="Theme">
          <SettingsBlock label="Theme" detail="Light is the default. Dark is easier at night.">
            <Segmented
              label="Theme"
              value={settings.theme}
              onChange={(v) => update({ theme: v })}
              options={[
                { value: "light", label: "Light", icon: <Sun size={16} aria-hidden /> },
                { value: "dark", label: "Dark", icon: <Moon size={16} aria-hidden /> },
              ]}
            />
          </SettingsBlock>
          <SettingsBlock label="Accent colour" detail="Used for buttons, stamps and highlights.">
            <div role="radiogroup" aria-label="Accent colour" className="grid grid-cols-4 gap-2">
              {ACCENTS.map((a) => {
                const active = settings.accent === a.key;
                return (
                  <button
                    key={a.key}
                    type="button"
                    role="radio"
                    aria-checked={active}
                    onClick={() => update({ accent: a.key })}
                    className={cn("flex min-h-11 flex-col items-center gap-1.5 rounded-[13px] border p-2 transition-colors", active ? "border-accent bg-accent-soft" : "border-line hover:border-line-strong")}
                  >
                    <span className="grid size-9 place-items-center rounded-full border-2 border-cream shadow-[var(--shadow)]" style={{ backgroundColor: a.swatch }}>
                      {active && <Check size={16} strokeWidth={3} className="text-[#fbf6ec]" aria-hidden />}
                    </span>
                    <span className="text-[0.75rem] font-semibold text-ink">{a.label}</span>
                  </button>
                );
              })}
            </div>
          </SettingsBlock>
        </SettingsGroup>

        <SettingsGroup title="Layout">
          <SettingsBlock label="Card density" detail={settings.density === "compact" ? "Tighter cards, more on screen." : "Roomier cards, easier to tap."}>
            <Segmented
              label="Card density"
              value={settings.density}
              onChange={(v) => update({ density: v })}
              options={[
                { value: "compact", label: "Compact" },
                { value: "comfortable", label: "Comfortable" },
              ]}
            />
          </SettingsBlock>
          <SettingsBlock label="First day of the week" detail="Used for weekly recaps, calendars and week rows.">
            <Segmented
              label="First day of the week"
              value={String(settings.weekStart) as "0" | "1"}
              onChange={(v) => update({ weekStart: v === "0" ? 0 : 1 })}
              options={[
                { value: "1", label: "Monday" },
                { value: "0", label: "Sunday" },
              ]}
            />
          </SettingsBlock>
        </SettingsGroup>

        <SettingsGroup title="Tone">
          <SettingsBlock label="Encouragement style" detail="How the app talks to you after check-ins and misses.">
            <Segmented
              label="Encouragement style"
              value={settings.encouragement}
              onChange={(v) => update({ encouragement: v })}
              options={(Object.keys(ENCOURAGEMENT) as EncouragementStyle[]).map((k) => ({ value: k, label: ENCOURAGEMENT[k].label }))}
            />
            <div className="space-y-1.5 rounded-[12px] bg-paper/70 p-3 text-sm" aria-live="polite">
              <p>
                <span className="font-semibold text-ink">After a check-in: </span>
                <span className="text-muted">“{enc.sample}”</span>
              </p>
              <p>
                <span className="font-semibold text-ink">After a miss: </span>
                <span className="text-muted">“{enc.after}”</span>
              </p>
            </div>
          </SettingsBlock>
          <SettingsRow
            label="Show streaks"
            detail="Hide them if streak counts stress you out. Your forgiving consistency score stays."
            control={<Toggle label="Show streaks" checked={settings.showStreaks} onChange={(v) => update({ showStreaks: v })} />}
          />
        </SettingsGroup>
      </div>
    </Page>
  );
}
