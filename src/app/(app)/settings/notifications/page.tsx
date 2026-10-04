"use client";

import { BellOff, BellRing, Moon } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { SettingsBlock } from "@/components/settings/SettingsControls";
import { Page } from "@/components/shell/Page";
import { Segmented, TextInput, Toggle } from "@/components/ui/controls";
import { EmptyState, SettingsGroup, SettingsRow } from "@/components/ui/misc";
import { NOTIFICATION_CATEGORY_META } from "@/lib/data/catalog";
import { formatTime } from "@/lib/dates";
import { myHabits } from "@/lib/selectors/habits";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { GroupNotify, NotificationCategory, Settings, TimeOfDay } from "@/lib/types";

const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d$/;
const DEFAULT_REMINDER: Record<TimeOfDay, string> = { morning: "08:00", afternoon: "13:00", evening: "19:00", anytime: "10:00" };

function minutes(t: string) {
  const [h, m] = t.split(":").map(Number);
  return h * 60 + m;
}

function quietError(start: string, end: string): { start?: string; end?: string } {
  const e: { start?: string; end?: string } = {};
  if (!start) e.start = "Pick a start time.";
  else if (!TIME_RE.test(start)) e.start = "Use a time like 22:30.";
  if (!end) e.end = "Pick an end time.";
  else if (!TIME_RE.test(end)) e.end = "Use a time like 07:00.";
  if (!e.start && !e.end && start === end) e.end = "Quiet hours need to start and end at different times.";
  return e;
}

export default function NotificationSettingsPage() {
  const state = useAppState();
  const dispatch = useDispatch();
  const { settings } = state;
  const update = (patch: Partial<Settings>) => dispatch({ type: "settings/update", patch });
  const off = !settings.notificationsOn;

  const [start, setStart] = useState(settings.quietHours.start);
  const [end, setEnd] = useState(settings.quietHours.end);
  const errors = quietError(start, end);
  const commitQuiet = (s: string, e: string) => {
    const err = quietError(s, e);
    if (!err.start && !err.end) update({ quietHours: { ...settings.quietHours, start: s, end: e } });
  };
  const quietLen = !errors.start && !errors.end ? (minutes(end) - minutes(start) + 1440) % 1440 : 0;

  const habits = myHabits(state);
  const groups = state.groups.filter((g) => g.memberIds.includes(state.meId));

  return (
    <Page title="Notification preferences" back="/notifications" subtitle="Choose what reaches you, and when. Everything still lands in your inbox.">
      <div className="space-y-7">
        <SettingsGroup>
          <SettingsRow
            icon={off ? <BellOff size={18} /> : <BellRing size={18} />}
            label="Allow notifications"
            detail={off ? "All notifications are off. Turn back on any time." : "Turn off to pause everything at once."}
            control={<Toggle label="Allow notifications" checked={settings.notificationsOn} onChange={(v) => update({ notificationsOn: v })} />}
          />
        </SettingsGroup>

        <fieldset disabled={off} className="space-y-7 disabled:opacity-60">
          <legend className="sr-only">Notification details</legend>
          <SettingsGroup title="Quiet hours" footer="During quiet hours reminders wait silently in your inbox. Friends' nudges are held until morning.">
            <SettingsRow
              icon={<Moon size={18} />}
              label="Quiet hours"
              detail={settings.quietHours.enabled && quietLen ? `On · ${formatTime(settings.quietHours.start)} to ${formatTime(settings.quietHours.end)} (${Math.floor(quietLen / 60)}h${quietLen % 60 ? ` ${quietLen % 60}m` : ""})` : "Off"}
              control={<Toggle label="Quiet hours" disabled={off} checked={settings.quietHours.enabled} onChange={(v) => update({ quietHours: { ...settings.quietHours, enabled: v } })} />}
            />
            {settings.quietHours.enabled && (
              <div className="grid grid-cols-2 gap-3 px-4 py-3.5">
                <div className="space-y-1.5">
                  <label htmlFor="quiet-start" className="font-display text-sm font-semibold text-ink">
                    From
                  </label>
                  <TextInput
                    id="quiet-start"
                    type="time"
                    value={start}
                    invalid={Boolean(errors.start)}
                    onChange={(e) => {
                      setStart(e.target.value);
                      commitQuiet(e.target.value, end);
                    }}
                    required
                  />
                  {errors.start && (
                    <p id="quiet-start-error" role="alert" className="text-[0.8125rem] font-medium text-[#a3301f] dark:text-[#f0a090]">
                      {errors.start}
                    </p>
                  )}
                </div>
                <div className="space-y-1.5">
                  <label htmlFor="quiet-end" className="font-display text-sm font-semibold text-ink">
                    Until
                  </label>
                  <TextInput
                    id="quiet-end"
                    type="time"
                    value={end}
                    invalid={Boolean(errors.end)}
                    onChange={(e) => {
                      setEnd(e.target.value);
                      commitQuiet(start, e.target.value);
                    }}
                    required
                  />
                  {errors.end && (
                    <p id="quiet-end-error" role="alert" className="text-[0.8125rem] font-medium text-[#a3301f] dark:text-[#f0a090]">
                      {errors.end}
                    </p>
                  )}
                </div>
              </div>
            )}
          </SettingsGroup>

          <SettingsGroup title="What to notify me about">
            {(Object.keys(NOTIFICATION_CATEGORY_META) as NotificationCategory[]).map((k) => (
              <SettingsRow
                key={k}
                label={NOTIFICATION_CATEGORY_META[k].label}
                detail={NOTIFICATION_CATEGORY_META[k].detail}
                control={
                  <Toggle
                    label={NOTIFICATION_CATEGORY_META[k].label}
                    disabled={off}
                    checked={settings.notificationCategories[k]}
                    onChange={(v) => update({ notificationCategories: { ...settings.notificationCategories, [k]: v } })}
                  />
                }
              />
            ))}
          </SettingsGroup>

          <section id="habit-reminders" className="scroll-mt-6 space-y-2">
            <h3 className="eyebrow px-1">Habit reminders</h3>
            {habits.length === 0 ? (
              <EmptyState compact title="No active habits" body="Reminders appear here once you add a habit." />
            ) : (
              <div className="card divide-y divide-line overflow-hidden">
                {habits.map((h) => (
                  <div key={h.id} className="flex min-h-14 items-center gap-3 px-4 py-2.5">
                    <IllustrationTile kind={h.icon} tint={h.tint} size={36} />
                    <span className="min-w-0 flex-1">
                      <Link href={`/habits/${h.id}`} className="block truncate text-[0.9375rem] font-semibold text-ink hover:underline">
                        {h.name}
                      </Link>
                      <span className="block text-[0.8125rem] text-muted">{h.remindersOn && h.reminderTimes.length ? h.reminderTimes.map(formatTime).join(", ") : "No reminder"}</span>
                    </span>
                    <Toggle
                      label={`Reminders for ${h.name}`}
                      disabled={off || !settings.notificationCategories.reminders}
                      checked={h.remindersOn}
                      onChange={(v) => dispatch({ type: "habit/update", id: h.id, patch: { remindersOn: v, reminderTimes: v && !h.reminderTimes.length ? [DEFAULT_REMINDER[h.timeOfDay]] : h.reminderTimes } })}
                    />
                  </div>
                ))}
              </div>
            )}
            {!settings.notificationCategories.reminders && !off && <p className="px-1 text-[0.8125rem] text-muted">Habit reminders are switched off above, so these are paused.</p>}
            <p className="px-1 text-[0.8125rem] text-muted">Change reminder times from each habit&apos;s edit screen.</p>
          </section>

          <section id="group-notifications" className="scroll-mt-6 space-y-2">
            <h3 className="eyebrow px-1">Group notifications</h3>
            {groups.length === 0 ? (
              <EmptyState compact title="No groups yet" body="Join a group to tune its notifications." />
            ) : (
              <div className="card divide-y divide-line overflow-hidden">
                {groups.map((g) => {
                  const value = settings.groupNotify[g.id] ?? g.notify;
                  return (
                    <SettingsBlock key={g.id} label={g.name} detail={value === "all" ? "Every check-in, milestone and finished goal" : value === "milestones" ? "Only milestones and finished goals" : "Nothing from this group"}>
                      <Segmented<GroupNotify>
                        size="sm"
                        label={`Notifications for ${g.name}`}
                        value={value}
                        onChange={(v) => {
                          dispatch({ type: "group/update", id: g.id, patch: { notify: v } });
                          update({ groupNotify: { ...settings.groupNotify, [g.id]: v } });
                        }}
                        options={[
                          { value: "all", label: "All" },
                          { value: "milestones", label: "Milestones" },
                          { value: "off", label: "Off" },
                        ]}
                      />
                    </SettingsBlock>
                  );
                })}
              </div>
            )}
          </section>
        </fieldset>
      </div>
    </Page>
  );
}
