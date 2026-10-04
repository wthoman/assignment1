"use client";

import { Check, ChevronRight, Mail, UserPlus } from "lucide-react";
import Link from "next/link";
import { useMemo, useState } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { Page } from "@/components/shell/Page";
import {
  CheckInNoteCard,
  CheckInRow,
  ComebackItem,
  DayDivider,
  FriendQuickRow,
  NudgeBubble,
  PolaroidCheckIn,
  QuizTeaser,
  SharedHabitsStrip,
  WeeklyBoard,
} from "@/components/social/FeedItems";
import { AddFriendsSheet } from "@/components/social/AddFriendsSheet";
import { GiftSheet } from "@/components/social/GiftSheet";
import { GroupProgressCard } from "@/components/social/GroupProgressCard";
import { PredictionCard } from "@/components/social/PredictionCard";
import { ReminderComposer } from "@/components/social/ReminderComposer";
import { dayLabel, visibleCheckIn, visibleFriends } from "@/components/social/social-helpers";
import { Button, IconButton } from "@/components/ui/Button";
import { Segmented } from "@/components/ui/controls";
import { EmptyState, SectionHeading } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { addDays, toISODate } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { isComeback, isDone, isScheduled, myHabits } from "@/lib/selectors/habits";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { AppState, CheckIn, ID, ISODate, Nudge, NudgeKind } from "@/lib/types";

type Filter = "all" | "checkins" | "groups" | "nudges";

type FeedEntry =
  | { kind: "checkin"; key: string; date: ISODate; sort: string; ci: CheckIn; comeback: boolean }
  | { kind: "nudge"; key: string; date: ISODate; sort: string; nudge: Nudge };

function nudgeLocal(n: Nudge): { date: ISODate; time: string } {
  const d = new Date(n.at);
  return { date: toISODate(d), time: `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}` };
}

function buildFeed(state: AppState, today: ISODate, filter: Filter): FeedEntry[] {
  const since = addDays(today, -2);
  const out: FeedEntry[] = [];
  const myGroupIds = new Set(state.groups.filter((g) => g.memberIds.includes(state.meId)).map((g) => g.id));
  if (filter !== "nudges") {
    for (const ci of state.checkIns) {
      if (ci.date < since || ci.date > today || !visibleCheckIn(state, ci)) continue;
      if (filter === "groups") {
        const h = state.habits.find((x) => x.id === ci.habitId);
        if (!h?.groupId || !myGroupIds.has(h.groupId)) continue;
      }
      out.push({ kind: "checkin", key: ci.id, date: ci.date, sort: `${ci.date}T${ci.time}`, ci, comeback: isComeback(state, ci) });
    }
  }
  if (filter === "all" || filter === "nudges") {
    const ok = (id: ID) => id === state.meId || (state.users[state.meId].friendIds.includes(id) && !state.settings.blockedIds.includes(id));
    for (const n of state.nudges) {
      const { date, time } = nudgeLocal(n);
      if (date < since || !ok(n.fromId) || !ok(n.toId)) continue;
      out.push({ kind: "nudge", key: n.id, date, sort: `${date}T${time}`, nudge: n });
    }
  }
  return out.sort((a, b) => b.sort.localeCompare(a.sort));
}

/** Splits a day's entries into render blocks: plain check-ins are grouped into compact lists. */
function toBlocks(entries: FeedEntry[]) {
  type Block = { type: "rows"; items: CheckIn[]; key: string } | { type: "entry"; entry: FeedEntry; key: string };
  const blocks: Block[] = [];
  for (const e of entries) {
    const plain = e.kind === "checkin" && !e.comeback && !e.ci.photo && !e.ci.note && e.ci.comments.length === 0;
    const last = blocks[blocks.length - 1];
    if (plain && e.kind === "checkin") {
      if (last?.type === "rows") last.items.push(e.ci);
      else blocks.push({ type: "rows", items: [e.ci], key: `rows-${e.key}` });
    } else blocks.push({ type: "entry", entry: e, key: e.key });
  }
  return blocks;
}

export default function FriendsPage() {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const today = useToday();
  const [filter, setFilter] = useState<Filter>("all");
  const [addOpen, setAddOpen] = useState(false);
  const [showEarlier, setShowEarlier] = useState(false);
  const [composer, setComposer] = useState<{ open: boolean; toId: ID; habitId?: ID; kind?: NudgeKind }>({ open: false, toId: "" });
  const [gift, setGift] = useState<{ open: boolean; toId: ID }>({ open: false, toId: "" });

  const encourage = (toId: ID, habitId?: ID, kind: NudgeKind = "nudge") => setComposer({ open: true, toId, habitId, kind });
  const openGift = (toId: ID) => setGift({ open: true, toId });

  const friends = visibleFriends(state);
  const requests = state.friendRequests.filter((r) => state.users[r.fromId] && !state.settings.blockedIds.includes(r.fromId));
  const myGroups = state.groups.filter((g) => g.memberIds.includes(state.meId));

  const feed = useMemo(() => buildFeed(state, today, filter), [state, today, filter]);
  const days = useMemo(() => {
    const map = new Map<ISODate, FeedEntry[]>();
    for (const e of feed) map.set(e.date, [...(map.get(e.date) ?? []), e]);
    return [...map.entries()];
  }, [feed]);

  const together = useMemo(
    () =>
      myHabits(state).filter(
        (h) =>
          h.shared &&
          isScheduled(h, today) &&
          !isDone(state, h.id, state.meId, today) &&
          h.participantIds.some((p) => p !== state.meId && !state.settings.blockedIds.includes(p) && isDone(state, h.id, p, today)),
      ),
    [state, today],
  );

  const challenges = state.challenges.filter((c) => c.participantIds.includes(state.meId) && c.endDate >= today);
  const predictions = state.predictions.filter((p) => !p.groupId || myGroups.some((g) => g.id === p.groupId));
  const openPredictions = predictions.filter((p) => !p.winnerId && p.closesAt >= today);

  const visibleDays = showEarlier ? days : days.slice(0, 2);
  const showGroupsBlock = filter === "all" || filter === "groups";
  const nothing = feed.length === 0 && !(showGroupsBlock && (challenges.length || predictions.length)) && !((filter === "all" || filter === "checkins") && together.length);

  const renderDay = ([date, entries]: [ISODate, FeedEntry[]]) => (
    <section key={date} aria-label={dayLabel(date, today)} className="space-y-3">
      <DayDivider>{dayLabel(date, today)}</DayDivider>
      {toBlocks(entries).map((b, i) => {
        if (b.type === "rows")
          return (
            <ul key={b.key} className="card divide-y divide-line overflow-visible py-1" aria-label="Check-ins">
              {b.items.map((ci) => (
                <CheckInRow key={ci.id} checkIn={ci} />
              ))}
            </ul>
          );
        const e = b.entry;
        if (e.kind === "nudge") return <NudgeBubble key={b.key} nudge={e.nudge} />;
        if (e.comeback) return <ComebackItem key={b.key} checkIn={e.ci} onCelebrate={encourage} />;
        if (e.ci.photo) return <PolaroidCheckIn key={b.key} checkIn={e.ci} tilt={i % 2 ? 1.5 : -1.5} />;
        return <CheckInNoteCard key={b.key} checkIn={e.ci} />;
      })}
    </section>
  );

  const aside = (
    <>
      <section className="card p-4" aria-labelledby="aside-friends">
        <SectionHeading id="aside-friends" title="Your friends" count={friends.length} />
        {friends.length ? (
          <ul className="mt-1 divide-y divide-line">
            {friends.map((u) => (
              <FriendQuickRow key={u.id} user={u} onNudge={() => encourage(u.id)} onGift={() => openGift(u.id)} />
            ))}
          </ul>
        ) : (
          <p className="mt-2 text-sm text-muted">No friends yet. Add a few to fill this space.</p>
        )}
      </section>
      {myGroups.length > 0 && (
        <section className="card p-4" aria-labelledby="aside-groups">
          <SectionHeading id="aside-groups" title="Your groups" action={<Link href="/groups" className="inline-flex min-h-11 items-center text-sm font-semibold text-accent hover:underline">All</Link>} />
          <ul className="mt-1 space-y-1">
            {myGroups.map((g) => (
              <li key={g.id}>
                <Link href={`/groups/${g.id}`} className="flex min-h-12 items-center gap-3 rounded-[12px] px-1 hover:bg-accent-soft/50">
                  <IllustrationTile kind={g.icon} tint={g.tint} size={34} rotate={-4} />
                  <span className="min-w-0 flex-1 truncate text-sm font-semibold text-ink">{g.name}</span>
                  <ChevronRight size={16} className="text-faint" aria-hidden />
                </Link>
              </li>
            ))}
          </ul>
        </section>
      )}
      <InviteCard onOpen={() => setAddOpen(true)} />
    </>
  );

  return (
    <Page
      title="Friends"
      subtitle="What your people are up to. Cheer loudly, nudge gently."
      actions={<IconButton label="Add friends" tone="soft" onClick={() => setAddOpen(true)}><UserPlus size={19} aria-hidden /></IconButton>}
      aside={aside}
      asideOnMobile={false}
    >
      <div className="space-y-5">
        {requests.map((r) => {
          const u = state.users[r.fromId];
          const mutual = u.friendIds.filter((f) => state.users[state.meId].friendIds.includes(f)).map((f) => state.users[f]?.name.split(" ")[0]).filter(Boolean);
          return (
            <div key={r.id} className="flex flex-wrap items-center gap-3 rounded-[var(--radius-card)] border border-accent/25 bg-accent-soft p-3.5" role="region" aria-label={`Friend request from ${u.name}`}>
              <Link href={`/friends/${u.id}`} className="flex min-w-0 flex-1 items-center gap-3">
                <Avatar user={u} size={44} />
                <span className="min-w-0">
                  <span className="block font-display font-bold text-ink">{u.name} wants to be friends</span>
                  <span className="block truncate text-sm text-muted">{mutual.length ? `${mutual.length} mutual: ${mutual.join(", ")}` : `@${u.handle}`}</span>
                </span>
              </Link>
              <div className="flex gap-2">
                <Button size="sm" className="min-h-11" variant="secondary" onClick={() => dispatch({ type: "friend/decline", requestId: r.id })} aria-label={`Decline request from ${u.name}`}>
                  Not now
                </Button>
                <Button
                  size="sm" className="min-h-11"
                  icon={<Check size={16} aria-hidden />}
                  onClick={() => {
                    dispatch({ type: "friend/accept", requestId: r.id });
                    toast({ title: `You and ${u.name.split(" ")[0]} are friends`, motif: "heart" });
                  }}
                >
                  Accept
                </Button>
              </div>
            </div>
          );
        })}

        {/* Mobile friend strip (desktop shows the full list in the aside) */}
        {friends.length > 0 && (
          <ul className="no-scrollbar -mx-4 flex gap-3 overflow-x-auto px-4 lg:hidden" aria-label="Your friends">
            {friends.map((u) => (
              <li key={u.id} className="shrink-0">
                <Link href={`/friends/${u.id}`} className="flex w-16 flex-col items-center gap-1 rounded-[12px] py-1">
                  <Avatar user={u} size={48} />
                  <span className="w-full truncate text-center text-xs font-semibold text-ink">{u.name.split(" ")[0]}</span>
                </Link>
              </li>
            ))}
            <li className="shrink-0">
              <button type="button" onClick={() => setAddOpen(true)} className="flex w-16 flex-col items-center gap-1 rounded-[12px] py-1">
                <span className="grid size-12 place-items-center rounded-full border-2 border-dashed border-line-strong text-accent">
                  <UserPlus size={19} aria-hidden />
                </span>
                <span className="text-xs font-semibold text-muted">Add</span>
              </button>
            </li>
          </ul>
        )}

        <Segmented
          label="Filter feed"
          value={filter}
          onChange={setFilter}
          size="sm"
          options={[
            { value: "all", label: "All" },
            { value: "checkins", label: "Check-ins" },
            { value: "groups", label: "Groups" },
            { value: "nudges", label: "Nudges" },
          ]}
        />

        {(filter === "all" || filter === "checkins") && <SharedHabitsStrip habits={together} />}

        {nothing ? (
          <EmptyState
            title={filter === "nudges" ? "No nudges lately" : filter === "groups" ? "Quiet in the groups" : "Nothing new yet"}
            body={filter === "nudges" ? "Send someone a kind word. It might be exactly what they need." : filter === "groups" ? "Start a challenge or join a group to see it here." : "When friends check in, it shows up here."}
            mood="sleepy"
            action={
              filter === "nudges" && friends[0] ? (
                <Button size="sm" className="min-h-11" onClick={() => encourage(friends[0].id)}>
                  Send a nudge
                </Button>
              ) : filter === "groups" ? (
                <Link href="/groups" className="text-sm font-semibold text-accent hover:underline">
                  Go to groups
                </Link>
              ) : (
                <Button size="sm" className="min-h-11" variant="secondary" onClick={() => setAddOpen(true)}>
                  Add friends
                </Button>
              )
            }
          />
        ) : (
          <>
            {visibleDays.slice(0, 1).map(renderDay)}

            {showGroupsBlock && challenges.length > 0 && (
              <section aria-labelledby="challenges-heading" className="space-y-3">
                <SectionHeading id="challenges-heading" title="Group challenges" count={challenges.length} action={<Link href="/groups" className="inline-flex min-h-11 items-center text-sm font-semibold text-accent hover:underline">Groups</Link>} />
                {challenges.slice(0, filter === "groups" ? undefined : 2).map((c) => (
                  <GroupProgressCard key={c.id} challenge={c} />
                ))}
              </section>
            )}

            {filter === "all" && <WeeklyBoard />}

            {visibleDays.slice(1).map(renderDay)}

            {!showEarlier && days.length > 2 && (
              <Button variant="secondary" block onClick={() => setShowEarlier(true)}>
                Show {dayLabel(days[2][0], today)}
              </Button>
            )}

            {showGroupsBlock && (filter === "groups" ? predictions : openPredictions).length > 0 && (
              <section aria-labelledby="predictions-heading" className="space-y-3">
                <SectionHeading id="predictions-heading" title="Predictions" hand="just for fun" />
                {(filter === "groups" ? predictions : openPredictions.slice(0, 2)).map((p) => (
                  <PredictionCard key={p.id} prediction={p} showGroup />
                ))}
              </section>
            )}

            {filter === "all" && <QuizTeaser />}
          </>
        )}
      </div>

      <AddFriendsSheet open={addOpen} onClose={() => setAddOpen(false)} />
      {composer.toId && <ReminderComposer open={composer.open} onClose={() => setComposer((c) => ({ ...c, open: false }))} toId={composer.toId} habitId={composer.habitId} kind={composer.kind} />}
      {gift.toId && <GiftSheet open={gift.open} onClose={() => setGift((g) => ({ ...g, open: false }))} toId={gift.toId} />}
    </Page>
  );
}

function InviteCard({ onOpen }: { onOpen: () => void }) {
  return (
    <section className="relative overflow-hidden rounded-[var(--radius-card)] border border-line bg-gold-soft p-4" aria-labelledby="invite-heading">
      <h2 id="invite-heading" className="font-display text-[1.0625rem] font-bold text-ink">
        Habits are easier in pairs
      </h2>
      <p className="mt-1 text-sm leading-relaxed text-muted">Invite someone from your contacts. They&apos;ll get a link, nothing else.</p>
      <Button size="sm" className="min-h-11 mt-3" icon={<Mail size={16} aria-hidden />} onClick={onOpen}>
        Invite friends
      </Button>
    </section>
  );
}
