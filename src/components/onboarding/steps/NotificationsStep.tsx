"use client";

import { AlarmClock, BellOff, BellRing, CalendarDays, Heart, Moon, Users, UsersRound } from "lucide-react";
import { useState, type ReactNode } from "react";
import { LogoMark } from "@/components/brand/Logo";
import { Button } from "@/components/ui/Button";
import { Field, TextInput, Toggle } from "@/components/ui/controls";
import { SettingsGroup, SettingsRow } from "@/components/ui/misc";
import { BRAND } from "@/lib/brand";
import { formatTime } from "@/lib/dates";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { NotificationCategory } from "@/lib/types";
import { StepShell } from "../StepShell";

type Picked = Extract<NotificationCategory, "reminders" | "friends" | "reactions" | "groups" | "recap">;

const ROWS: { key: Picked; label: string; detail: string; icon: ReactNode }[] = [
  { key: "reminders", label: "Habit reminders", detail: "At the times you choose", icon: <AlarmClock size={18} /> },
  { key: "friends", label: "Friend activity", detail: "Requests, nudges and gifts", icon: <Users size={18} /> },
  { key: "reactions", label: "Reactions", detail: "When someone cheers a check-in", icon: <Heart size={18} /> },
  { key: "groups", label: "Groups & challenges", detail: "Invites and milestones", icon: <UsersRound size={18} /> },
  { key: "recap", label: "Weekly recap", detail: "Sunday evening, once a week", icon: <CalendarDays size={18} /> },
];

type Permission = "unasked" | "allowed" | "denied";

export function NotificationsStep({ onNext }: { onNext: () => void }) {
  const { settings } = useAppState();
  const dispatch = useDispatch();
  const [cats, setCats] = useState<Record<Picked, boolean>>(() => ({
    reminders: settings.notificationCategories.reminders,
    friends: settings.notificationCategories.friends,
    reactions: settings.notificationCategories.reactions,
    groups: settings.notificationCategories.groups,
    recap: settings.notificationCategories.recap,
  }));
  const [quiet, setQuiet] = useState(settings.quietHours);
  const [permission, setPermission] = useState<Permission>("unasked");
  const [attempted, setAttempted] = useState(false);

  const quietError = attempted && quiet.enabled && quiet.start === quiet.end ? "Start and end can't be the same time." : undefined;

  const submit = () => {
    setAttempted(true);
    if (quiet.enabled && (quiet.start === quiet.end || !quiet.start || !quiet.end)) return;
    dispatch({
      type: "settings/update",
      patch: {
        notificationsOn: permission !== "denied",
        notificationCategories: { ...settings.notificationCategories, ...cats },
        quietHours: quiet,
      },
    });
    onNext();
  };

  return (
    <StepShell
      eyebrow="Notifications"
      title="How chatty should we be?"
      description="Only the useful stuff. Every one of these can be changed later."
      onSubmit={submit}
      footer={
        <Button type="submit" size="lg" block>
          Save and continue
        </Button>
      }
    >
      <div className="space-y-6">
        {/* Mock of the OS permission prompt */}
        <div className="relative mx-auto max-w-[19rem]">
          {permission === "unasked" ? (
            <div className="overflow-hidden rounded-[18px] border border-line-strong bg-cream text-center shadow-[var(--shadow-lift)]" role="group" aria-labelledby="ob-perm-title">
              <div className="px-5 pb-4 pt-5">
                <LogoMark size={40} className="mx-auto" />
                <p id="ob-perm-title" className="mt-3 font-display text-[0.9375rem] font-bold leading-snug text-ink">
                  “{BRAND.name}” would like to send you notifications
                </p>
                <p className="mt-1.5 text-[0.8125rem] leading-relaxed text-muted">Reminders, friend cheers and your weekly recap. No marketing.</p>
              </div>
              <div className="grid grid-cols-2 border-t border-line">
                <button type="button" onClick={() => setPermission("denied")} className="min-h-12 border-r border-line text-[0.9375rem] font-semibold text-muted transition-colors hover:bg-paper-deep/60">
                  Don&rsquo;t allow
                </button>
                <button type="button" onClick={() => setPermission("allowed")} className="min-h-12 text-[0.9375rem] font-bold text-accent transition-colors hover:bg-accent-soft">
                  Allow
                </button>
              </div>
            </div>
          ) : (
            <div role="status" className="flex items-center gap-3 rounded-[16px] border border-line bg-cream px-4 py-3">
              <span className={permission === "allowed" ? "grid size-10 place-items-center rounded-[12px] bg-sage-soft text-sage-ink" : "grid size-10 place-items-center rounded-[12px] bg-paper-deep text-muted"} aria-hidden>
                {permission === "allowed" ? <BellRing size={20} /> : <BellOff size={20} />}
              </span>
              <div className="min-w-0 flex-1">
                <p className="font-semibold text-ink">{permission === "allowed" ? "Notifications allowed" : "Notifications off for now"}</p>
                <p className="text-[0.8125rem] text-muted">{permission === "allowed" ? "We'll stick to what you pick below." : "No problem. Turn them on any time in Settings."}</p>
              </div>
              <button type="button" onClick={() => setPermission("unasked")} className="min-h-11 shrink-0 px-1 text-sm font-semibold text-accent underline decoration-dashed underline-offset-4">
                Change
              </button>
            </div>
          )}
        </div>

        <SettingsGroup title="Notify me about">
          {ROWS.map((r) => (
            <SettingsRow
              key={r.key}
              icon={r.icon}
              label={r.label}
              detail={r.detail}
              control={<Toggle checked={cats[r.key]} onChange={(v) => setCats((c) => ({ ...c, [r.key]: v }))} label={r.label} disabled={permission === "denied"} />}
            />
          ))}
        </SettingsGroup>

        <SettingsGroup title="Quiet hours" footer={quiet.enabled ? `Nothing from ${formatTime(quiet.start || "00:00")} to ${formatTime(quiet.end || "00:00")}, except reminders you set yourself.` : undefined}>
          <SettingsRow
            icon={<Moon size={18} />}
            label="Quiet hours"
            detail="Hold notifications overnight"
            control={<Toggle checked={quiet.enabled} onChange={(v) => setQuiet((q) => ({ ...q, enabled: v }))} label="Quiet hours" />}
          />
          {quiet.enabled && (
            <div className="grid grid-cols-2 gap-3 px-4 py-3">
              <Field label="From" htmlFor="ob-quiet-start" error={quietError}>
                <TextInput id="ob-quiet-start" type="time" value={quiet.start} onChange={(e) => setQuiet((q) => ({ ...q, start: e.target.value }))} invalid={!!quietError} />
              </Field>
              <Field label="To" htmlFor="ob-quiet-end">
                <TextInput id="ob-quiet-end" type="time" value={quiet.end} onChange={(e) => setQuiet((q) => ({ ...q, end: e.target.value }))} invalid={!!quietError} />
              </Field>
            </div>
          )}
        </SettingsGroup>
      </div>
    </StepShell>
  );
}
