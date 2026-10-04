"use client";

import { Contrast, Type, Vibrate, Volume2 } from "lucide-react";
import { SettingsBlock } from "@/components/settings/SettingsControls";
import { Page } from "@/components/shell/Page";
import { Segmented, Toggle } from "@/components/ui/controls";
import { SettingsGroup, SettingsRow } from "@/components/ui/misc";
import { haptic } from "@/components/ui/Toast";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { MotionPref, Settings } from "@/lib/types";

const MOTION_DETAIL: Record<MotionPref, string> = {
  system: "Follows your device's reduce-motion setting.",
  reduced: "Stamps, sheets and transitions appear instantly.",
  full: "All animations on, even if your device asks for less.",
};

export default function AccessibilitySettingsPage() {
  const { settings } = useAppState();
  const dispatch = useDispatch();
  const update = (patch: Partial<Settings>) => dispatch({ type: "settings/update", patch });

  return (
    <Page title="Accessibility" back="/settings">
      <div className="space-y-7">
        <SettingsGroup title="Motion">
          <SettingsBlock label="Animations" detail={MOTION_DETAIL[settings.motion]}>
            <Segmented
              label="Animations"
              value={settings.motion}
              onChange={(v) => update({ motion: v })}
              options={[
                { value: "system", label: "System" },
                { value: "reduced", label: "Reduced" },
                { value: "full", label: "Full" },
              ]}
            />
          </SettingsBlock>
        </SettingsGroup>

        <SettingsGroup title="Reading">
          <SettingsRow icon={<Type size={18} />} label="Larger text" detail="Bumps all text up a size." control={<Toggle label="Larger text" checked={settings.largeText} onChange={(v) => update({ largeText: v })} />} />
          <SettingsRow icon={<Contrast size={18} />} label="Higher contrast" detail="Darker secondary text and stronger outlines." control={<Toggle label="Higher contrast" checked={settings.highContrast} onChange={(v) => update({ highContrast: v })} />} />
        </SettingsGroup>

        <SettingsGroup title="Sounds & haptics">
          <SettingsRow icon={<Volume2 size={18} />} label="Sounds" control={<Toggle label="Sounds" checked={settings.sound} onChange={(v) => update({ sound: v })} />} />
          <SettingsRow
            icon={<Vibrate size={18} />}
            label="Haptics"
            detail="Gentle taps on check-in, where supported"
            control={
              <Toggle
                label="Haptics"
                checked={settings.haptics}
                onChange={(v) => {
                  update({ haptics: v });
                  haptic(v);
                }}
              />
            }
          />
        </SettingsGroup>
        <p className="px-1 text-[0.8125rem] leading-relaxed text-muted">Every action in the app works with a keyboard and screen reader. Colour is never the only way something is shown.</p>
      </div>
    </Page>
  );
}
