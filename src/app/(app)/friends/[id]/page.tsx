"use client";

import { Ban, BellRing, Check, Gift, Plus, UserMinus, UserPlus } from "lucide-react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useState } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { FriendAvatarStack } from "@/components/avatar/FriendAvatarStack";
import { Sticker } from "@/components/collection/Sticker";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { Page } from "@/components/shell/Page";
import { GiftSheet } from "@/components/social/GiftSheet";
import { ReminderComposer } from "@/components/social/ReminderComposer";
import { firstName, isFriend } from "@/components/social/social-helpers";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button, ButtonLink } from "@/components/ui/Button";
import { ConfirmationDialog } from "@/components/ui/ConfirmationDialog";
import { EmptyState, HandNote, SectionHeading, Tape } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { PERSONALITIES } from "@/lib/data/catalog";
import { cn } from "@/lib/cn";
import { addDays, formatDate, orderedWeekdays, startOfWeek, WEEKDAY_LETTER } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { isDone, scheduleLabel } from "@/lib/selectors/habits";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { User } from "@/lib/types";

export default function FriendProfilePage() {
  const params = useParams<{ id: string }>();
  const id = params.id;
  const state = useAppState();
  const dispatch = useDispatch();
  const router = useRouter();
  const toast = useToast();
  const today = useToday();
  const [nudgeOpen, setNudgeOpen] = useState(false);
  const [giftOpen, setGiftOpen] = useState(false);
  const [inviteOpen, setInviteOpen] = useState(false);
  const [confirm, setConfirm] = useState<"remove" | "block" | null>(null);

  const user = state.users[id];
  const blocked = state.settings.blockedIds.includes(id);

  if (!user || id === state.meId || blocked) {
    return (
      <Page title="Friend" back="/friends">
        <EmptyState
          title={blocked ? "You've blocked this person" : id === state.meId ? "That's you!" : "We couldn't find that person"}
          body={blocked ? "Unblock them in Settings if you'd like to see their profile again." : id === state.meId ? "Your own profile lives on the Profile page." : "They may have left, or the link is out of date."}
          mood="thinking"
          action={<ButtonLink href={id === state.meId ? "/profile" : blocked ? "/settings" : "/friends"} variant="secondary" size="sm" className="min-h-11">{id === state.meId ? "Go to profile" : blocked ? "Open settings" : "Back to friends"}</ButtonLink>}
        />
      </Page>
    );
  }

  const name = user.name.split(" ")[0];
  const friend = isFriend(state, id);
  const me = state.users[state.meId];
  const mutual = user.friendIds.filter((f) => f !== state.meId && me.friendIds.includes(f)).map((f) => state.users[f]).filter((u): u is User => Boolean(u));
  const shared = state.habits.filter((h) => h.status === "active" && h.participantIds.includes(id) && h.participantIds.includes(state.meId));
  const theirPublic = state.habits.filter((h) => h.status === "active" && h.participantIds.includes(id) && h.privacy !== "private");
  const weekStart = startOfWeek(today, state.settings.weekStart);
  const week = orderedWeekdays(state.settings.weekStart).map((wd, i) => {
    const date = addDays(weekStart, i);
    const count = theirPublic.filter((h) => isDone(state, h.id, id, date)).length;
    return { date, wd, count, future: date > today };
  });
  const weekTotal = week.reduce((n, d) => n + d.count, 0);
  const personality = user.personality ? PERSONALITIES[user.personality] : undefined;
  const request = state.friendRequests.find((r) => r.fromId === id);
  // Seed friends have no sticker data of their own; this is where showcased stickers would render.
  const showcase: { id: string; collectible: Parameters<typeof Sticker>[0]["collectible"] }[] = [];
  const invitable = state.habits.filter((h) => h.ownerId === state.meId && h.status === "active" && h.privacy !== "private");

  return (
    <Page title={user.name} back="/friends" eyebrow={friend ? "Friend" : "On Daybook"}>
      <div className="space-y-6">
        <section className="card relative overflow-hidden p-5" aria-label="Profile">
          <Tape className="-top-2 right-10" rotate={8} />
          <div className="flex flex-col items-center gap-4 text-center sm:flex-row sm:items-start sm:text-left">
            <Avatar user={user} size={104} />
            <div className="min-w-0 flex-1">
              <p className="font-display text-2xl font-extrabold tracking-[-0.02em] text-ink">{user.name}</p>
              <p className="text-sm text-muted">
                @{user.handle}
                {user.pronouns && <> · {user.pronouns}</>}
              </p>
              {user.bio && <p className="mt-2 text-[0.9375rem] leading-relaxed text-ink">{user.bio}</p>}
              {personality && (
                <p className="mt-2 inline-flex items-center gap-2 rounded-[10px] bg-paper/70 px-2.5 py-1 text-xs font-semibold text-muted">
                  <IllustrationTile kind={personality.motif} tint={personality.tint} size={20} className="rounded-[6px]" />
                  {personality.name}
                </p>
              )}
              {mutual.length > 0 && (
                <p className="mt-3 flex items-center justify-center gap-2 text-sm text-muted sm:justify-start">
                  <FriendAvatarStack users={mutual} size={24} />
                  {mutual.length} mutual: {mutual.map((u) => u.name.split(" ")[0]).join(", ")}
                </p>
              )}
            </div>
          </div>

          <div className="mt-5 grid grid-cols-2 gap-2 sm:flex sm:flex-wrap">
            {friend ? (
              <>
                <Button onClick={() => setNudgeOpen(true)} icon={<BellRing size={17} aria-hidden />}>
                  Nudge
                </Button>
                <Button variant="secondary" onClick={() => setGiftOpen(true)} icon={<Gift size={17} aria-hidden />}>
                  Gift
                </Button>
                <Button variant="soft" className="col-span-2" onClick={() => setInviteOpen(true)} icon={<Plus size={17} aria-hidden />}>
                  Invite to a habit
                </Button>
              </>
            ) : (
              <Button
                className="col-span-2"
                icon={<UserPlus size={17} aria-hidden />}
                onClick={() => {
                  dispatch(request ? { type: "friend/accept", requestId: request.id } : { type: "friend/add", userId: id });
                  toast({ title: `You and ${name} are friends`, motif: "heart" });
                }}
              >
                {request ? "Accept friend request" : "Add friend"}
              </Button>
            )}
          </div>
        </section>

        {friend && (
          <section aria-labelledby="week-heading" className="card p-4">
            <SectionHeading id="week-heading" title={`${name}'s week`} hand={weekTotal ? `${weekTotal} check-ins` : undefined} />
            <ol className="mt-3 grid grid-cols-7 gap-1.5">
              {week.map((d) => (
                <li key={d.date} className="flex flex-col items-center gap-1.5">
                  <span className={cn("text-xs font-semibold", d.date === today ? "text-accent" : "text-faint")}>{WEEKDAY_LETTER[d.wd]}</span>
                  <span
                    className={cn(
                      "grid size-9 place-items-center rounded-full border text-xs font-bold tabular-nums",
                      d.count > 0 ? "border-accent bg-accent text-on-accent" : d.future ? "border-dashed border-line text-faint" : "border-line bg-paper/60 text-faint",
                      d.date === today && "ring-2 ring-accent/30 ring-offset-2 ring-offset-cream",
                    )}
                    aria-label={`${formatDate(d.date, { weekday: "long" })}: ${d.future ? "upcoming" : d.count ? `${d.count} check-in${d.count > 1 ? "s" : ""}` : "rest day"}`}
                    role="img"
                  >
                    {d.count > 0 ? d.count : ""}
                  </span>
                </li>
              ))}
            </ol>
            <p className="mt-3 text-xs text-muted">Only habits {name} shares with friends are shown.</p>
          </section>
        )}

        <section aria-labelledby="shared-heading">
          <SectionHeading id="shared-heading" title="Habits you share" count={shared.length} />
          {shared.length ? (
            <ul className="mt-2 space-y-2">
              {shared.map((h) => {
                const theirs = isDone(state, h.id, id, today);
                const mine = isDone(state, h.id, state.meId, today);
                return (
                  <li key={h.id}>
                    <Link href={`/habits/${h.id}`} className="card flex min-h-16 items-center gap-3 p-3 transition-colors hover:bg-accent-soft/40">
                      <IllustrationTile kind={h.icon} tint={h.tint} size={42} rotate={-4} />
                      <span className="min-w-0 flex-1">
                        <span className="block truncate font-display font-bold text-ink">{h.name}</span>
                        <span className="block text-xs text-muted">{scheduleLabel(h)}</span>
                      </span>
                      <span className="flex shrink-0 flex-col items-end gap-0.5 text-xs">
                        <span className={cn("inline-flex items-center gap-1", theirs ? "text-sage-ink" : "text-faint")}>
                          {theirs && <Check size={12} aria-hidden />} {name} {theirs ? "done" : "not yet"}
                        </span>
                        <span className={cn("inline-flex items-center gap-1", mine ? "text-sage-ink" : "text-faint")}>
                          {mine && <Check size={12} aria-hidden />} You {mine ? "done" : "not yet"}
                        </span>
                      </span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          ) : (
            <p className="mt-2 rounded-[14px] border border-dashed border-line-strong p-4 text-sm text-muted">
              Nothing shared yet.{" "}
              {friend && (
                <button type="button" onClick={() => setInviteOpen(true)} className="font-semibold text-accent underline-offset-2 hover:underline">
                  Invite {name} to one of yours
                </button>
              )}
            </p>
          )}
        </section>

        <section aria-labelledby="showcase-heading">
          <SectionHeading id="showcase-heading" title="Sticker showcase" />
          {showcase.length ? (
            <ul className="mt-2 flex flex-wrap gap-3">
              {showcase.map((s, i) => (
                <li key={s.id}>
                  <Sticker collectible={s.collectible} size={72} rotate={i % 2 ? 6 : -6} />
                </li>
              ))}
            </ul>
          ) : (
            <div className="mt-2 flex items-center gap-4 rounded-[var(--radius-card)] border border-dashed border-line-strong bg-cream/60 p-4">
              <div className="flex shrink-0 -space-x-3" aria-hidden>
                {[-8, 4, -2].map((r, i) => (
                  <span key={i} className="block size-12 rounded-full border-2 border-dashed border-line-strong bg-paper-deep/60" style={{ transform: `rotate(${r}deg)` }} />
                ))}
              </div>
              <p className="text-sm leading-relaxed text-muted">
                {name} hasn&apos;t pinned any stickers yet.
                <HandNote className="ml-1 text-base">space saved for something good</HandNote>
              </p>
            </div>
          )}
        </section>

        {friend && (
          <section aria-label="Manage friendship" className="flex flex-col gap-2 border-t border-line pt-5 sm:flex-row">
            <Button variant="ghost" size="sm" className="min-h-11" icon={<UserMinus size={16} aria-hidden />} onClick={() => setConfirm("remove")}>
              Remove friend
            </Button>
            <Button variant="ghost" size="sm" className="min-h-11" icon={<Ban size={16} aria-hidden />} onClick={() => setConfirm("block")}>
              Block {name}
            </Button>
          </section>
        )}
      </div>

      <ReminderComposer open={nudgeOpen} onClose={() => setNudgeOpen(false)} toId={id} habitId={shared.find((h) => !isDone(state, h.id, id, today))?.id} />
      <GiftSheet open={giftOpen} onClose={() => setGiftOpen(false)} toId={id} />

      <BottomSheet open={inviteOpen} onClose={() => setInviteOpen(false)} title={`Invite ${name} to a habit`} description="They'll get an invite and can join if they like." size="sm">
        {invitable.length ? (
          <ul className="space-y-2">
            {invitable.map((h) => {
              const already = h.participantIds.includes(id);
              return (
                <li key={h.id} className="flex items-center gap-3 rounded-[14px] border border-line p-2.5">
                  <IllustrationTile kind={h.icon} tint={h.tint} size={38} />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-semibold text-ink">{h.name}</span>
                    <span className="block text-xs text-muted">{scheduleLabel(h)}</span>
                  </span>
                  {already ? (
                    <span className="inline-flex min-h-9 items-center gap-1 text-xs font-semibold text-sage-ink">
                      <Check size={14} aria-hidden /> Together
                    </span>
                  ) : (
                    <Button
                      size="sm" className="min-h-11"
                      variant="soft"
                      aria-label={`Invite ${name} to ${h.name}`}
                      onClick={() => {
                        dispatch({ type: "habit/invite", id: h.id, userIds: [id] });
                        toast({ title: `Invited ${name} to “${h.name}”`, motif: h.icon });
                      }}
                    >
                      Invite
                    </Button>
                  )}
                </li>
              );
            })}
          </ul>
        ) : (
          <EmptyState compact title="No habits to share yet" body="Create a habit that isn't private, then invite friends to it." action={<ButtonLink href="/habits/new" size="sm" className="min-h-11">New habit</ButtonLink>} />
        )}
      </BottomSheet>

      <ConfirmationDialog
        open={confirm === "remove"}
        onClose={() => setConfirm(null)}
        title={`Remove ${name}?`}
        body={`You'll stop seeing each other's check-ins. Shared habits stay as they are, and ${name} won't be notified.`}
        confirmLabel="Remove friend"
        tone="danger"
        onConfirm={() => {
          dispatch({ type: "friend/remove", userId: id });
          toast({ title: `Removed ${name} from friends` });
        }}
      />
      <ConfirmationDialog
        open={confirm === "block"}
        onClose={() => setConfirm(null)}
        title={`Block ${firstName(state, id)}?`}
        body={`${name} won't be able to see your activity, send you nudges, or find you. You can unblock them in Settings.`}
        confirmLabel="Block"
        tone="danger"
        onConfirm={() => {
          dispatch({ type: "settings/block", userId: id });
          toast({ title: `Blocked ${name}` });
          router.push("/friends");
        }}
      />
    </Page>
  );
}
