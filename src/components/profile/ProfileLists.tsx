"use client";

import { ChevronRight } from "lucide-react";
import Link from "next/link";
import { useMemo } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { FriendAvatarStack } from "@/components/avatar/FriendAvatarStack";
import { Sticker } from "@/components/collection/Sticker";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { ButtonLink } from "@/components/ui/Button";
import { ProgressBar, Segmented, Toggle } from "@/components/ui/controls";
import { Badge, EmptyState, SectionHeading } from "@/components/ui/misc";
import { cn } from "@/lib/cn";
import { COLLECTIBLE_BY_ID } from "@/lib/data/catalog";
import { addDays, formatDate } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { currentStreak, myHabits, scheduleLabel } from "@/lib/selectors/habits";
import { habitRate } from "@/lib/selectors/stats";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { Settings, User } from "@/lib/types";

const linkCls = "inline-flex min-h-11 items-center px-1 text-sm font-semibold text-accent hover:underline";

export function FriendsPreview() {
  const state = useAppState();
  const me = state.users[state.meId];
  const friends = me.friendIds.map((id) => state.users[id]).filter((u): u is User => Boolean(u) && !state.settings.blockedIds.includes(u.id));
  const withMutual = friends
    .map((f) => ({ user: f, mutual: f.friendIds.filter((id) => id !== me.id && me.friendIds.includes(id)) }))
    .sort((a, b) => b.mutual.length - a.mutual.length);

  return (
    <section aria-labelledby="friends-h" className="space-y-3">
      <SectionHeading id="friends-h" title="Friends" count={friends.length} action={<Link href="/friends" className={linkCls}>All friends</Link>} />
      {friends.length === 0 ? (
        <EmptyState compact mood="wave" title="No friends here yet" body="Habits are lighter with company." action={<ButtonLink href="/friends" size="sm" variant="soft">Find friends</ButtonLink>} />
      ) : (
        <div className="card-flat p-4">
          <div className="flex items-center gap-3">
            <FriendAvatarStack users={friends} size={34} max={6} />
            <p className="min-w-0 text-sm text-muted">
              <span className="font-semibold text-ink">{friends.length} friends</span> cheering you on
            </p>
          </div>
          <ul className="mt-3 grid gap-1 sm:grid-cols-2">
            {withMutual.slice(0, 4).map(({ user, mutual }) => (
              <li key={user.id}>
                <Link href={`/friends/${user.id}`} className="flex min-h-12 items-center gap-2.5 rounded-[12px] px-2 py-1.5 transition-colors hover:bg-accent-soft/60">
                  <Avatar user={user} size={34} />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-semibold text-ink">{user.name}</span>
                    <span className="block truncate text-xs text-muted">
                      {mutual.length ? `${mutual.length} mutual · ${mutual.map((id) => state.users[id]?.name.split(" ")[0]).slice(0, 2).join(", ")}` : `@${user.handle}`}
                    </span>
                  </span>
                  <ChevronRight size={16} className="shrink-0 text-faint" aria-hidden />
                </Link>
              </li>
            ))}
          </ul>
        </div>
      )}
    </section>
  );
}

/** Top three active habits by completion rate over the last 28 days. */
export function FavoriteHabits() {
  const state = useAppState();
  const today = useToday();
  const top = useMemo(() => {
    const from = addDays(today, -27);
    return myHabits(state)
      .map((h) => ({ h, ...habitRate(state, h, state.meId, from, today), streak: currentStreak(state, h, state.meId, today) }))
      .filter((r) => r.scheduled > 0)
      .sort((a, b) => b.rate - a.rate || b.done - a.done)
      .slice(0, 3);
  }, [state, today]);
  const showStreaks = state.settings.showStreaks;

  return (
    <section aria-labelledby="fav-h" className="space-y-3">
      <SectionHeading id="fav-h" title="Favourite habits" hand="most kept" />
      {top.length === 0 ? (
        <EmptyState compact title="No habits yet" body="Start one and it'll show up here." action={<ButtonLink href="/habits/new" size="sm">New habit</ButtonLink>} />
      ) : (
        <ol className="space-y-2">
          {top.map(({ h, rate, done, scheduled, streak }, i) => (
            <li key={h.id}>
              <Link href={`/habits/${h.id}`} className="card-flat flex items-center gap-3 p-3 transition-colors hover:bg-accent-soft/40">
                <span className="w-5 shrink-0 text-center font-display text-lg font-extrabold text-faint" aria-hidden>
                  {i + 1}
                </span>
                <IllustrationTile kind={h.icon} tint={h.tint} size={44} rotate={i % 2 ? 3 : -3} />
                <span className="min-w-0 flex-1">
                  <span className="block truncate font-display text-[0.9375rem] font-bold text-ink">{h.name}</span>
                  <span className="mt-1 flex items-center gap-2">
                    <ProgressBar value={rate} size="sm" label={`${h.name} completion rate`} className="max-w-40" />
                    <span className="shrink-0 text-xs tabular-nums text-muted">
                      {done}/{scheduled}
                    </span>
                  </span>
                </span>
                <span className="shrink-0 text-right">
                  <span className="block font-display text-lg font-extrabold text-accent">{Math.round(rate * 100)}%</span>
                  {showStreaks && h.showStreak && streak > 1 && <span className="block text-[0.6875rem] text-muted">{streak} in a row</span>}
                </span>
              </Link>
            </li>
          ))}
        </ol>
      )}
    </section>
  );
}

const STATUS_TONE = { active: "sage", paused: "gold", archived: "muted" } as const;

export function HabitHistory() {
  const state = useAppState();
  const habits = myHabits(state, { includeInactive: true });
  const order = { active: 0, paused: 1, archived: 2 };
  const sorted = [...habits].sort((a, b) => order[a.status] - order[b.status] || a.startDate.localeCompare(b.startDate));
  const counts = useMemo(() => {
    const m: Record<string, number> = {};
    for (const c of state.checkIns) if (c.userId === state.meId) m[c.habitId] = (m[c.habitId] ?? 0) + 1;
    return m;
  }, [state.checkIns, state.meId]);

  return (
    <section aria-labelledby="history-h" className="space-y-3">
      <SectionHeading id="history-h" title="Habit history" count={habits.length} />
      {sorted.length === 0 ? (
        <EmptyState compact title="Nothing logged yet" />
      ) : (
        <ul className="card divide-y divide-line overflow-hidden">
          {sorted.map((h) => (
            <li key={h.id}>
              <Link href={`/habits/${h.id}`} className={cn("flex min-h-14 items-center gap-3 px-4 py-2.5 transition-colors hover:bg-accent-soft/40", h.status !== "active" && "opacity-80")}>
                <IllustrationTile kind={h.icon} tint={h.tint} size={36} muted={h.status !== "active"} />
                <span className="min-w-0 flex-1">
                  <span className="block truncate text-[0.9375rem] font-semibold text-ink">{h.name}</span>
                  <span className="block truncate text-xs text-muted">
                    {scheduleLabel(h)} · since {formatDate(h.startDate)} · {counts[h.id] ?? 0} check-ins
                  </span>
                </span>
                {h.status !== "active" && <Badge tone={STATUS_TONE[h.status]}>{h.status}</Badge>}
                <ChevronRight size={16} className="shrink-0 text-faint" aria-hidden />
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

export function PastRecaps() {
  const { pastRecaps } = useAppState();
  return (
    <section aria-labelledby="recaps-h" className="space-y-3">
      <SectionHeading id="recaps-h" title="Past recaps" action={<Link href="/recap" className={linkCls}>Recap hub</Link>} />
      {pastRecaps.length === 0 ? (
        <EmptyState compact mood="sleepy" title="No recaps yet" body="Your first one arrives on Sunday." />
      ) : (
        <ul className="no-scrollbar -mx-4 flex snap-x gap-3 overflow-x-auto px-4 pb-2 sm:mx-0 sm:grid sm:grid-cols-2 sm:overflow-visible sm:px-0">
          {pastRecaps.map((r, i) => (
            <li key={r.id} className="w-[220px] shrink-0 snap-start sm:w-auto">
              <Link href="/recap" className="paper-panel relative block h-full rounded-[16px] border border-line p-4 transition-transform hover:-translate-y-0.5" style={{ transform: `rotate(${i % 2 ? 0.6 : -0.6}deg)` }}>
                <p className="eyebrow">Week of {formatDate(r.weekStart)}</p>
                <p className="mt-1 font-display text-base font-bold leading-snug text-ink">{r.headline}</p>
                <p className="mt-2 flex items-baseline gap-3 text-sm text-muted">
                  <span>
                    <strong className="font-display text-xl text-accent">{r.consistency}%</strong> consistent
                  </span>
                  <span className="tabular-nums">{r.completions} done</span>
                </p>
                <p className="mt-1 text-xs text-muted">Superlative: {r.superlative}</p>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

export function EarnedSuperlatives() {
  const { collection } = useAppState();
  const sups = collection.filter((o) => COLLECTIBLE_BY_ID[o.collectibleId]?.category === "superlative");
  return (
    <section aria-labelledby="sup-h" className="space-y-3">
      <SectionHeading id="sup-h" title="Earned superlatives" count={sups.length} />
      {sups.length === 0 ? (
        <p className="card-flat p-4 text-sm text-muted">Weekly superlatives are handed out in your recap. Late-night check-ins and comebacks are a good place to start.</p>
      ) : (
        <ul className="grid gap-2 sm:grid-cols-2">
          {sups.map((o) => {
            const c = COLLECTIBLE_BY_ID[o.collectibleId];
            return (
              <li key={o.collectibleId} className="card-flat flex items-center gap-3 p-3">
                <Sticker collectible={c} size={52} rotate={-5} />
                <div className="min-w-0">
                  <p className="font-display text-[0.9375rem] font-bold text-ink">{c.name}</p>
                  <p className="text-xs leading-snug text-muted">{o.earnedFor}</p>
                  <p className="mt-0.5 text-[0.6875rem] text-faint">{new Date(o.earnedAt).toLocaleDateString("en-US", { month: "short", day: "numeric" })}</p>
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );
}

export function GroupsList() {
  const state = useAppState();
  const groups = state.groups.filter((g) => g.memberIds.includes(state.meId));
  return (
    <section aria-labelledby="groups-h" className="card p-4">
      <div className="flex items-center justify-between">
        <h2 id="groups-h" className="eyebrow">
          Groups · {groups.length}
        </h2>
        <Link href="/groups" className="inline-flex min-h-11 items-center text-sm font-semibold text-accent hover:underline">
          All
        </Link>
      </div>
      {groups.length === 0 ? (
        <p className="text-sm text-muted">Not in any groups yet.</p>
      ) : (
        <ul className="-mx-2 mt-1 space-y-0.5">
          {groups.map((g) => (
            <li key={g.id}>
              <Link href={`/groups/${g.id}`} className="flex min-h-12 items-center gap-3 rounded-[12px] px-2 py-1.5 transition-colors hover:bg-accent-soft/60">
                <IllustrationTile kind={g.icon} tint={g.tint} size={36} />
                <span className="min-w-0 flex-1">
                  <span className="block truncate text-sm font-semibold text-ink">{g.name}</span>
                  <span className="block text-xs text-muted">{g.memberIds.length} members</span>
                </span>
                <ChevronRight size={16} className="shrink-0 text-faint" aria-hidden />
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

export function PrivacyShortcut() {
  const { settings } = useAppState();
  const dispatch = useDispatch();
  const update = (patch: Partial<Settings>) => dispatch({ type: "settings/update", patch });
  return (
    <section aria-labelledby="privacy-h" className="card p-4">
      <h2 id="privacy-h" className="eyebrow">
        Privacy
      </h2>
      <p className="mt-2 text-sm font-semibold text-ink">Who can see your profile</p>
      <Segmented
        className="mt-2"
        size="sm"
        label="Profile visibility"
        value={settings.profileVisibility}
        onChange={(v) => update({ profileVisibility: v })}
        options={[
          { value: "private", label: "Me" },
          { value: "friends", label: "Friends" },
          { value: "groups", label: "Groups" },
          { value: "public", label: "All" },
        ]}
      />
      <div className="mt-3 flex items-center justify-between gap-3">
        <span id="privacy-consistency" className="text-sm text-ink">
          Show consistency score
        </span>
        <Toggle label="Show consistency score on profile" checked={settings.showConsistencyOnProfile} onChange={(v) => update({ showConsistencyOnProfile: v })} />
      </div>
      <Link href="/settings/privacy" className="mt-1 inline-flex min-h-11 items-center text-sm font-semibold text-accent hover:underline">
        More privacy settings
      </Link>
    </section>
  );
}
