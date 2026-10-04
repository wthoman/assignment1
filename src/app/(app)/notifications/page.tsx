"use client";

import { AnimatePresence } from "motion/react";
import { BellOff, CheckCheck, Settings2 } from "lucide-react";
import Link from "next/link";
import { useMemo, useState } from "react";
import { NotificationItem } from "@/components/notifications/NotificationItem";
import { Page } from "@/components/shell/Page";
import { Button, ButtonLink } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { cn } from "@/lib/cn";
import { addDays, toISODate } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { AppNotification, NotificationKind } from "@/lib/types";

type Filter = "all" | "unread" | "social" | "groups" | "awards" | "reminders";

const FILTER_KINDS: Record<Exclude<Filter, "all" | "unread">, NotificationKind[]> = {
  social: ["friend-request", "habit-invite", "reaction", "comment", "nudge", "gift", "quiz"],
  groups: ["group-invite", "group-goal"],
  awards: ["award", "recap"],
  reminders: ["reminder"],
};

const FILTERS: { key: Filter; label: string }[] = [
  { key: "all", label: "All" },
  { key: "unread", label: "Unread" },
  { key: "social", label: "Social" },
  { key: "groups", label: "Groups" },
  { key: "awards", label: "Awards" },
  { key: "reminders", label: "Reminders" },
];

function matches(n: AppNotification, f: Filter) {
  if (f === "all") return true;
  if (f === "unread") return !n.read;
  return FILTER_KINDS[f].includes(n.kind);
}

const EMPTY_COPY: Record<Filter, { title: string; body: string }> = {
  all: { title: "All caught up", body: "Nothing new. Go enjoy the quiet." },
  unread: { title: "Nothing unread", body: "You've seen everything. Gold star." },
  social: { title: "No social updates", body: "Reactions, comments and friend requests land here." },
  groups: { title: "No group news", body: "Invites and group milestones will show up here." },
  awards: { title: "No awards yet", body: "New stickers and weekly recaps arrive here." },
  reminders: { title: "No reminders", body: "Habit reminders you've missed will appear here." },
};

export default function NotificationsPage() {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const today = useToday();
  const [filter, setFilter] = useState<Filter>("all");
  const { notifications, settings } = state;
  const unreadCount = notifications.filter((n) => !n.read).length;

  const groups = useMemo(() => {
    const weekAgo = addDays(today, -6);
    const sorted = notifications.filter((n) => matches(n, filter)).sort((a, b) => b.at.localeCompare(a.at));
    const out: { key: string; label: string; items: AppNotification[] }[] = [
      { key: "today", label: "Today", items: [] },
      { key: "week", label: "Earlier this week", items: [] },
      { key: "older", label: "Older", items: [] },
    ];
    for (const n of sorted) {
      const d = toISODate(new Date(n.at));
      if (d >= today) out[0].items.push(n);
      else if (d >= weekAgo) out[1].items.push(n);
      else out[2].items.push(n);
    }
    return out.filter((g) => g.items.length);
  }, [notifications, filter, today]);

  const counts = useMemo(() => Object.fromEntries(FILTERS.map((f) => [f.key, notifications.filter((n) => matches(n, f.key) && !n.read).length])) as Record<Filter, number>, [notifications]);

  return (
    <Page
      title="Notifications"
      subtitle={unreadCount ? `${unreadCount} unread` : "You're all caught up."}
      hideHeaderActions
      actions={
        <Link href="/settings/notifications" aria-label="Notification preferences" title="Notification preferences" className="grid size-11 place-items-center rounded-[13px] text-ink transition-colors hover:bg-accent-soft">
          <Settings2 size={21} aria-hidden />
        </Link>
      }
    >
      {!settings.notificationsOn && (
        <div className="mb-4 flex items-center gap-3 rounded-[16px] border border-dashed border-line-strong bg-gold-soft/60 p-3">
          <BellOff size={20} className="shrink-0 text-accent" aria-hidden />
          <p className="min-w-0 flex-1 text-sm text-ink">Notifications are turned off. You&apos;ll still find everything here.</p>
          <ButtonLink href="/settings/notifications" size="sm" variant="secondary">
            Change
          </ButtonLink>
        </div>
      )}

      <div className="flex items-center gap-2">
        <div role="toolbar" aria-label="Filter notifications" className="no-scrollbar -mx-4 flex min-w-0 flex-1 gap-1.5 overflow-x-auto px-4 py-1 sm:mx-0 sm:px-0">
          {FILTERS.map((f) => {
            const active = filter === f.key;
            return (
              <button
                key={f.key}
                type="button"
                aria-pressed={active}
                onClick={() => setFilter(f.key)}
                className={cn(
                  "inline-flex min-h-10 shrink-0 items-center gap-1.5 rounded-[11px] border px-3 text-sm font-semibold transition-colors",
                  active ? "border-accent bg-accent text-on-accent" : "border-line-strong bg-cream text-ink hover:bg-accent-soft",
                )}
              >
                {f.label}
                {counts[f.key] > 0 && f.key !== "unread" && (
                  <span className={cn("grid min-w-5 place-items-center rounded-full px-1 text-[0.6875rem] font-bold", active ? "bg-cream text-accent" : "bg-accent-soft text-accent")}>{counts[f.key]}</span>
                )}
              </button>
            );
          })}
        </div>
      </div>
      <div className="mt-2 flex justify-end">
        <Button
          variant="ghost"
          size="sm"
          icon={<CheckCheck size={16} aria-hidden />}
          disabled={!unreadCount}
          onClick={() => {
            dispatch({ type: "notification/readAll" });
            toast({ title: "All marked as read" });
          }}
        >
          Mark all read
        </Button>
      </div>

      <div className="mt-2 space-y-6" aria-live="polite">
        {groups.length === 0 ? (
          <EmptyState mood={filter === "all" || filter === "unread" ? "happy" : "thinking"} title={EMPTY_COPY[filter].title} body={EMPTY_COPY[filter].body} />
        ) : (
          groups.map((g) => (
            <section key={g.key} aria-labelledby={`ng-${g.key}`}>
              <h2 id={`ng-${g.key}`} className="eyebrow mb-2 px-1">
                {g.label}
              </h2>
              <ul className="space-y-2">
                <AnimatePresence initial={false}>
                  {g.items.map((n) => (
                    <NotificationItem key={n.id} notification={n} />
                  ))}
                </AnimatePresence>
              </ul>
            </section>
          ))
        )}
      </div>
      <p className="mt-6 text-center text-xs text-faint">
        Tip: swipe a notification sideways to dismiss it.
      </p>
    </Page>
  );
}
