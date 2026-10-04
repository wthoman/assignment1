"use client";

import { ChevronRight, Plus } from "lucide-react";
import Link from "next/link";
import { FriendAvatarStack } from "@/components/avatar/FriendAvatarStack";
import { IllustrationTile, TINT_SOFT } from "@/components/illustrations/Illustration";
import { Page } from "@/components/shell/Page";
import { CollectiveBar } from "@/components/social/GroupProgressCard";
import { challengeTotal, firstName } from "@/components/social/social-helpers";
import { Button, ButtonLink } from "@/components/ui/Button";
import { EmptyState, HandNote, SectionHeading, Tape } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { cn } from "@/lib/cn";
import { useToday } from "@/lib/hooks";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { Group, User } from "@/lib/types";

export default function GroupsPage() {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const today = useToday();
  const mine = state.groups.filter((g) => g.memberIds.includes(state.meId));
  const invites = state.groupInvites.map((id) => state.groups.find((g) => g.id === id)).filter((g): g is Group => Boolean(g) && !g!.memberIds.includes(state.meId));
  const members = (g: Group) => g.memberIds.map((id) => state.users[id]).filter((u): u is User => Boolean(u) && !state.settings.blockedIds.includes(u.id));

  return (
    <Page
      title="Groups"
      subtitle="Small crews, shared goals. Everyone's progress adds up together."
      actions={
        <ButtonLink href="/groups/new" size="sm" variant="soft" icon={<Plus size={16} aria-hidden />} className="min-h-11 hidden sm:inline-flex">
          New group
        </ButtonLink>
      }
    >
      <div className="space-y-7">
        {invites.length > 0 && (
          <section aria-labelledby="invites-heading" className="space-y-2">
            <SectionHeading id="invites-heading" title="Invitations" count={invites.length} />
            {invites.map((g) => {
              const inviter = g.createdBy !== state.meId ? state.users[g.createdBy] : undefined;
              return (
                <article key={g.id} className="relative rounded-[var(--radius-card)] border border-accent/25 bg-accent-soft p-4" aria-label={`Invitation to ${g.name}`}>
                  <Tape className="-top-2 left-8" rotate={-5} />
                  <div className="flex items-start gap-3">
                    <IllustrationTile kind={g.icon} tint={g.tint} size={48} rotate={-5} />
                    <div className="min-w-0 flex-1">
                      <p className="font-display text-[1.0625rem] font-bold text-ink">{g.name}</p>
                      <p className="text-sm text-muted">{g.description}</p>
                      <p className="mt-1.5 flex items-center gap-2 text-xs text-muted">
                        <FriendAvatarStack users={members(g)} size={22} />
                        {inviter ? `${firstName(state, inviter.id)} invited you` : `${g.memberIds.length} members`}
                      </p>
                    </div>
                  </div>
                  <div className="mt-3 flex gap-2">
                    <Button
                      size="sm" className="min-h-11"
                      onClick={() => {
                        dispatch({ type: "group/join", id: g.id });
                        toast({ title: `Welcome to ${g.name}`, motif: g.icon });
                      }}
                    >
                      Join group
                    </Button>
                    <Button size="sm" className="min-h-11" variant="secondary" onClick={() => dispatch({ type: "group/declineInvite", id: g.id })} aria-label={`Decline invitation to ${g.name}`}>
                      Not now
                    </Button>
                    <Link href={`/groups/${g.id}`} className="ml-auto inline-flex min-h-9 items-center text-sm font-semibold text-accent hover:underline">
                      Peek
                    </Link>
                  </div>
                </article>
              );
            })}
          </section>
        )}

        <section aria-labelledby="mine-heading" className="space-y-3">
          <SectionHeading id="mine-heading" title="Your groups" count={mine.length} />
          {mine.length ? (
            <ul className="space-y-3">
              {mine.map((g, i) => {
                const active = state.challenges.filter((c) => c.groupId === g.id && c.endDate >= today);
                const lead = active[0];
                return (
                  <li key={g.id}>
                    <Link href={`/groups/${g.id}`} className="card group relative block overflow-hidden p-4 transition-transform hover:-translate-y-0.5">
                      <span aria-hidden className={cn("absolute inset-y-0 left-0 w-1.5", TINT_SOFT[g.tint])} />
                      <div className="flex items-start gap-3 pl-1">
                        <IllustrationTile kind={g.icon} tint={g.tint} size={52} rotate={i % 2 ? 4 : -4} />
                        <div className="min-w-0 flex-1">
                          <p className="font-display text-[1.0625rem] font-bold text-ink">{g.name}</p>
                          <p className="line-clamp-2 text-sm text-muted">{g.description}</p>
                          <p className="mt-2 flex items-center gap-2 text-xs text-muted">
                            <FriendAvatarStack users={members(g)} size={22} max={5} />
                            {g.memberIds.length} members
                          </p>
                        </div>
                        <ChevronRight size={18} className="mt-1 shrink-0 text-faint transition-transform group-hover:translate-x-0.5" aria-hidden />
                      </div>
                      {lead ? (
                        <div className="mt-3 rounded-[12px] bg-paper/60 p-3 pl-4">
                          <div className="mb-1.5 flex items-baseline justify-between gap-2 text-sm">
                            <span className="truncate font-semibold text-ink">{lead.title}</span>
                            <span className="shrink-0 text-xs tabular-nums text-muted">
                              {challengeTotal(lead)}/{lead.goal} {lead.unit}
                            </span>
                          </div>
                          <CollectiveBar total={challengeTotal(lead)} goal={lead.goal} tint={g.tint} label={`${lead.title} progress`} size="sm" />
                          {active.length > 1 && <p className="mt-1.5 text-xs text-muted">+{active.length - 1} more challenge{active.length > 2 ? "s" : ""}</p>}
                        </div>
                      ) : (
                        <p className="mt-3 pl-1 text-sm text-muted">No challenge running. Start one inside.</p>
                      )}
                    </Link>
                  </li>
                );
              })}
            </ul>
          ) : (
            <EmptyState title="No groups yet" body="Groups are for shared goals, like drinking water five days this week together." mood="wave" action={<ButtonLink href="/groups/new" size="sm" className="min-h-11">Start a group</ButtonLink>} />
          )}
        </section>

        <section className="relative overflow-hidden rounded-[var(--radius-card)] border border-dashed border-line-strong bg-cream/60 p-5" aria-labelledby="create-heading">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
            <div className="flex -space-x-2" aria-hidden>
              <IllustrationTile kind="water" tint="sky" size={44} rotate={-8} />
              <IllustrationTile kind="book" tint="gold" size={44} rotate={4} />
              <IllustrationTile kind="leaf" tint="sage" size={44} rotate={-3} />
            </div>
            <div className="min-w-0 flex-1">
              <h2 id="create-heading" className="font-display text-[1.0625rem] font-bold text-ink">
                Start something together
              </h2>
              <p className="text-sm text-muted">A study crew, a hydration pact, a walking club. Invite friends and set a shared goal.</p>
            </div>
            <ButtonLink href="/groups/new" icon={<Plus size={17} aria-hidden />}>
              New group
            </ButtonLink>
          </div>
          <HandNote className="absolute -bottom-0.5 right-4 hidden text-base sm:inline-block" rotate={-4}>
            snacks optional
          </HandNote>
        </section>
      </div>
    </Page>
  );
}
