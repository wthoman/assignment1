"use client";

import { Ban, Bell, ChartNoAxesColumn, EyeOff, Rss } from "lucide-react";
import { SettingsBlock } from "@/components/settings/SettingsControls";
import { Page } from "@/components/shell/Page";
import { Segmented, Toggle } from "@/components/ui/controls";
import { SettingsGroup, SettingsRow } from "@/components/ui/misc";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { Settings, Visibility } from "@/lib/types";

const PROFILE_DETAIL: Record<Settings["profileVisibility"], string> = {
  private: "Only you can see your profile.",
  friends: "Friends can see your profile, favourite habits and shelf.",
  groups: "Friends and people in your groups can see your profile.",
  public: "Anyone with your link can see your profile.",
};

const RECAP_DETAIL: Record<Visibility, string> = {
  private: "Your recap is just for you.",
  friends: "Friends see your recap highlights and superlatives.",
  groups: "Friends and group members see your recap highlights.",
};

export default function PrivacySettingsPage() {
  const { settings } = useAppState();
  const dispatch = useDispatch();
  const update = (patch: Partial<Settings>) => dispatch({ type: "settings/update", patch });

  return (
    <Page title="Privacy" back="/settings" subtitle="You decide who sees what. Private habits are never shared, whatever you pick here.">
      <div className="space-y-7">
        <SettingsGroup title="Profile">
          <SettingsBlock label="Who can see your profile" detail={PROFILE_DETAIL[settings.profileVisibility]}>
            <Segmented
              size="sm"
              label="Profile visibility"
              value={settings.profileVisibility}
              onChange={(v) => update({ profileVisibility: v })}
              options={[
                { value: "private", label: "Only me" },
                { value: "friends", label: "Friends" },
                { value: "groups", label: "Groups" },
                { value: "public", label: "Public" },
              ]}
            />
          </SettingsBlock>
          <SettingsRow
            icon={<ChartNoAxesColumn size={18} />}
            label="Show consistency on profile"
            detail="Your forgiving 28-day score"
            control={<Toggle label="Show consistency on profile" checked={settings.showConsistencyOnProfile} onChange={(v) => update({ showConsistencyOnProfile: v })} />}
          />
        </SettingsGroup>

        <SettingsGroup title="Activity">
          <SettingsRow
            icon={<Rss size={18} />}
            label="Show my check-ins in Friends feed"
            detail="Turn off to check in quietly. Shared habits still show progress to partners."
            control={<Toggle label="Show my check-ins in Friends feed" checked={settings.activityInFeed} onChange={(v) => update({ activityInFeed: v })} />}
          />
          <SettingsRow
            icon={<Bell size={18} />}
            label="Friends can send me reminders"
            detail="Nudges always respect your quiet hours."
            control={<Toggle label="Friends can send me reminders" checked={settings.allowFriendReminders} onChange={(v) => update({ allowFriendReminders: v })} />}
          />
          <SettingsBlock label="Weekly recap visibility" detail={RECAP_DETAIL[settings.recapVisibility]}>
            <Segmented
              size="sm"
              label="Recap visibility"
              value={settings.recapVisibility}
              onChange={(v) => update({ recapVisibility: v })}
              options={[
                { value: "private", label: "Only me" },
                { value: "friends", label: "Friends" },
                { value: "groups", label: "Groups" },
              ]}
            />
          </SettingsBlock>
        </SettingsGroup>

        <SettingsGroup title="Sharing" footer="When on, share cards start with names, times, friends and habit names hidden. You can still reveal them per card.">
          <SettingsRow
            icon={<EyeOff size={18} />}
            label="Hide details on share cards by default"
            control={<Toggle label="Hide details on share cards by default" checked={settings.shareHidesDetails} onChange={(v) => update({ shareHidesDetails: v })} />}
          />
        </SettingsGroup>

        <SettingsGroup>
          <SettingsRow icon={<Ban size={18} />} label="Blocked users" value={settings.blockedIds.length ? String(settings.blockedIds.length) : "None"} href="/settings/blocked" />
        </SettingsGroup>
      </div>
    </Page>
  );
}
