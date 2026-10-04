"use client";

import { Accessibility, Ban, Bell, BellRing, Download, FileDown, Info, LogOut, Palette, Plug, RotateCcw, Shield, Smartphone, UserRound, UsersRound, Volume2, Vibrate, KeyRound } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { LogoMark } from "@/components/brand/Logo";
import { downloadMyData } from "@/components/share/exportData";
import { Page } from "@/components/shell/Page";
import { ConfirmationDialog } from "@/components/ui/ConfirmationDialog";
import { Toggle } from "@/components/ui/controls";
import { SettingsGroup, SettingsRow } from "@/components/ui/misc";
import { haptic, useToast } from "@/components/ui/Toast";
import { BRAND } from "@/lib/brand";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { Settings } from "@/lib/types";
import { VISIBILITY_LABEL } from "@/components/profile/ProfileHeader";

const APP_VERSION = "0.1.0";

export default function SettingsPage() {
  const state = useAppState();
  const dispatch = useDispatch();
  const router = useRouter();
  const toast = useToast();
  const { settings, session } = state;
  const [confirmReset, setConfirmReset] = useState(false);
  const [confirmLogout, setConfirmLogout] = useState(false);
  const update = (patch: Partial<Settings>) => dispatch({ type: "settings/update", patch });
  const connectedCount = Object.values(settings.connected).filter((c) => c.status === "connected").length;

  return (
    <Page title="Settings" subtitle="Everything saves as you go.">
      <div className="space-y-7">
        <SettingsGroup title="Account">
          <SettingsRow icon={<KeyRound size={18} />} label="Account" detail={session.account?.email ?? "Not signed in"} href="/settings/account" />
          <SettingsRow icon={<UserRound size={18} />} label="Profile" detail="Name, handle, bio and pronouns" href="/profile" />
          <SettingsRow icon={<Palette size={18} />} label="Avatar & cosmetics" href="/profile/avatar" />
        </SettingsGroup>

        <SettingsGroup title="Privacy & safety">
          <SettingsRow icon={<Shield size={18} />} label="Privacy" detail={`Profile visible to ${VISIBILITY_LABEL[settings.profileVisibility].toLowerCase()}`} href="/settings/privacy" />
          <SettingsRow icon={<Ban size={18} />} label="Blocked users" value={settings.blockedIds.length ? String(settings.blockedIds.length) : "None"} href="/settings/blocked" />
        </SettingsGroup>

        <SettingsGroup title="Notifications">
          <SettingsRow icon={<Bell size={18} />} label="Notifications" detail={settings.notificationsOn ? (settings.quietHours.enabled ? "On · quiet hours set" : "On") : "Off"} href="/settings/notifications" />
          <SettingsRow icon={<BellRing size={18} />} label="Habit reminders" href="/settings/notifications#habit-reminders" />
          <SettingsRow icon={<UsersRound size={18} />} label="Group notifications" href="/settings/notifications#group-notifications" />
        </SettingsGroup>

        <SettingsGroup title="Look & feel">
          <SettingsRow icon={<Palette size={18} />} label="Appearance" detail="Theme, accent colour, density, week start, tone" href="/settings/appearance" />
          <SettingsRow icon={<Accessibility size={18} />} label="Accessibility" detail="Motion, text size, contrast" href="/settings/accessibility" />
        </SettingsGroup>

        <SettingsGroup title="Sounds & haptics">
          <SettingsRow icon={<Volume2 size={18} />} label="Sounds" detail="A soft stamp sound on check-in" control={<Toggle label="Sounds" checked={settings.sound} onChange={(v) => update({ sound: v })} />} />
          <SettingsRow
            icon={<Vibrate size={18} />}
            label="Haptics"
            detail="A gentle tap when you check in (on supported phones)"
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

        <SettingsGroup title="Connected services" footer="Preview only: integrations aren't live yet.">
          <SettingsRow icon={<Plug size={18} />} label="Connected services" detail="Apple Health, Screen Time, Calendars, Weather" value={connectedCount ? `${connectedCount} on` : undefined} href="/settings/connected" />
        </SettingsGroup>

        <SettingsGroup title="Your data">
          <SettingsRow
            icon={<Download size={18} />}
            label="Download my data (JSON)"
            detail="Your habits, check-ins and settings"
            onClick={() => {
              downloadMyData(state);
              toast({ title: "Export started", body: "Check your downloads.", motif: "book" });
            }}
          />
          <SettingsRow icon={<FileDown size={18} />} label="Share & export studio" detail="Share cards and CSV history" href="/share#export" />
          <SettingsRow icon={<RotateCcw size={18} />} label="Reset demo data" detail="Start over with fresh sample data" tone="danger" onClick={() => setConfirmReset(true)} />
        </SettingsGroup>

        <SettingsGroup>
          <SettingsRow icon={<LogOut size={18} />} label="Log out" tone="danger" onClick={() => setConfirmLogout(true)} />
        </SettingsGroup>

        <section aria-labelledby="about-h" className="flex items-center gap-3 rounded-[16px] border border-dashed border-line-strong px-4 py-4">
          <LogoMark size={36} />
          <div className="min-w-0 text-sm">
            <h2 id="about-h" className="font-display font-bold text-ink">
              {BRAND.name} <span className="font-sans font-normal text-muted">v{APP_VERSION} · prototype</span>
            </h2>
            <p className="text-muted">{BRAND.tagline} Data stays on this device.</p>
          </div>
          <Info size={18} className="ml-auto shrink-0 text-faint" aria-hidden />
        </section>
        <p className="flex items-center justify-center gap-1.5 text-xs text-faint">
          <Smartphone size={13} aria-hidden /> Made for small screens first.
        </p>
      </div>

      <ConfirmationDialog
        open={confirmReset}
        onClose={() => setConfirmReset(false)}
        title="Reset demo data?"
        body="This replaces everything on this device with fresh sample data and takes you back to onboarding. It can't be undone."
        confirmLabel="Reset everything"
        tone="danger"
        onConfirm={() => {
          dispatch({ type: "session/reset" });
          router.replace("/onboarding");
        }}
      />
      <ConfirmationDialog
        open={confirmLogout}
        onClose={() => setConfirmLogout(false)}
        title="Log out?"
        body="Your habits stay saved on this device. You'll go back to the welcome screen."
        confirmLabel="Log out"
        onConfirm={() => {
          dispatch({ type: "session/logout" });
          router.replace("/onboarding");
        }}
      />
    </Page>
  );
}
