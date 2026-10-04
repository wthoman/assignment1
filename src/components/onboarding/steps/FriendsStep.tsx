"use client";

import { Check, Search, Send, UserPlus } from "lucide-react";
import { useMemo, useState, type ReactNode } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/misc";
import { BRAND } from "@/lib/brand";
import { cn } from "@/lib/cn";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { Contact } from "@/lib/types";
import { StepShell } from "../StepShell";

const INVITED = " · Invited";

const fold = (s: string) =>
  s
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase();

function initials(name: string) {
  return name
    .split(/\s+/)
    .slice(0, 2)
    .map((w) => w[0] ?? "")
    .join("")
    .toUpperCase();
}

function StatusPill({ children }: { children: ReactNode }) {
  return (
    <span className="inline-flex min-h-9 shrink-0 items-center gap-1 rounded-[10px] bg-sage-soft px-2.5 text-[0.8125rem] font-semibold text-sage-ink">
      <Check size={15} strokeWidth={2.6} aria-hidden />
      {children}
    </span>
  );
}

export function FriendsStep({ onNext }: { onNext: () => void }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const me = state.users[state.meId];
  const [query, setQuery] = useState("");
  const [added, setAdded] = useState<string[]>([]);
  const [invited, setInvited] = useState<string[]>([]);

  const { onApp, offApp } = useMemo(() => {
    const q = fold(query.trim());
    const match = (c: Contact) => !q || fold(c.name).includes(q) || fold(c.detail.replace(INVITED, "")).includes(q) || (c.userId && fold(state.users[c.userId]?.handle ?? "").includes(q));
    const list = state.contacts.filter(match);
    return { onApp: list.filter((c) => c.userId && state.users[c.userId]), offApp: list.filter((c) => !c.userId || !state.users[c.userId]) };
  }, [query, state.contacts, state.users]);

  const count = added.length + invited.length;

  const add = (userId: string) => {
    const req = state.friendRequests.find((r) => r.fromId === userId);
    dispatch(req ? { type: "friend/accept", requestId: req.id } : { type: "friend/add", userId });
    setAdded((xs) => [...xs, userId]);
  };

  const invite = (contactId: string) => {
    dispatch({ type: "contact/invite", contactId });
    setInvited((xs) => [...xs, contactId]);
  };

  const summary = [added.length > 0 && `${added.length} added`, invited.length > 0 && `${invited.length} invited`].filter(Boolean).join(" · ");

  return (
    <StepShell
      eyebrow="Friends"
      title="Bring a few people along"
      description="Habits stick better with someone cheering. We only show contacts you choose to share."
      onSubmit={onNext}
      footer={
        <div className="space-y-2">
          <p className="text-center text-sm font-semibold text-muted" role="status" aria-live="polite">
            {count > 0 ? summary : "Add or invite anyone. Or skip for now."}
          </p>
          <Button type="submit" size="lg" block>
            Continue
          </Button>
        </div>
      }
    >
      <div className="relative mb-5">
        <label htmlFor="ob-contact-search" className="sr-only">
          Search contacts
        </label>
        <Search size={18} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-faint" aria-hidden />
        <input
          id="ob-contact-search"
          type="search"
          value={query}
          placeholder="Search contacts"
          autoComplete="off"
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") e.preventDefault();
          }}
          className="min-h-12 w-full rounded-[13px] border border-line-strong bg-cream pl-10 pr-3.5 text-[0.9375rem] text-ink placeholder:text-faint focus:border-accent focus:outline-none focus:ring-3 focus:ring-accent/15"
        />
      </div>

      {onApp.length === 0 && offApp.length === 0 ? (
        <EmptyState compact mood="thinking" title={`No one matches “${query.trim()}”`} body="Try a first name, a handle or part of a number." />
      ) : (
        <div className="space-y-6">
          {onApp.length > 0 && (
            <section aria-labelledby="ob-on-app">
              <h2 id="ob-on-app" className="eyebrow mb-2 px-1">
                On {BRAND.name} · {onApp.length}
              </h2>
              <ul className="card divide-y divide-line overflow-hidden">
                {onApp.map((c) => {
                  const u = state.users[c.userId!];
                  const isFriend = me.friendIds.includes(u.id);
                  const justAdded = added.includes(u.id);
                  const requested = state.friendRequests.some((r) => r.fromId === u.id);
                  return (
                    <li key={c.id} className="flex min-h-16 items-center gap-3 px-3.5 py-2.5">
                      <Avatar user={u} size={42} />
                      <div className="min-w-0 flex-1">
                        <p className="truncate font-semibold text-ink">{c.name}</p>
                        <p className={cn("truncate text-[0.8125rem]", requested ? "font-semibold text-accent" : "text-muted")}>{requested ? "Sent you a friend request" : `@${u.handle} · On ${BRAND.name}`}</p>
                      </div>
                      {justAdded ? (
                        <StatusPill>Added</StatusPill>
                      ) : isFriend ? (
                        <StatusPill>Friends</StatusPill>
                      ) : (
                        <Button size="sm" variant={requested ? "primary" : "soft"} className="min-h-11 shrink-0" icon={<UserPlus size={16} aria-hidden />} onClick={() => add(u.id)} aria-label={`${requested ? "Accept" : "Add"} ${c.name}`}>
                          {requested ? "Accept" : "Add"}
                        </Button>
                      )}
                    </li>
                  );
                })}
              </ul>
            </section>
          )}

          {offApp.length > 0 && (
            <section aria-labelledby="ob-off-app">
              <h2 id="ob-off-app" className="eyebrow mb-2 px-1">
                Invite to {BRAND.name} · {offApp.length}
              </h2>
              <ul className="card divide-y divide-line overflow-hidden">
                {offApp.map((c) => {
                  const isInvited = c.detail.includes("Invited") || invited.includes(c.id);
                  return (
                    <li key={c.id} className="flex min-h-16 items-center gap-3 px-3.5 py-2.5">
                      <span className="grid size-[42px] shrink-0 place-items-center rounded-full border border-dashed border-line-strong bg-paper-deep/60 font-display text-sm font-bold text-muted" aria-hidden>
                        {initials(c.name)}
                      </span>
                      <div className="min-w-0 flex-1">
                        <p className="truncate font-semibold text-ink">{c.name}</p>
                        <p className="truncate text-[0.8125rem] text-muted">{c.detail.replace(INVITED, "")}</p>
                      </div>
                      {isInvited ? (
                        <StatusPill>Invited</StatusPill>
                      ) : (
                        <Button size="sm" variant="secondary" className="min-h-11 shrink-0" icon={<Send size={15} aria-hidden />} onClick={() => invite(c.id)} aria-label={`Invite ${c.name}`}>
                          Invite
                        </Button>
                      )}
                    </li>
                  );
                })}
              </ul>
            </section>
          )}
        </div>
      )}
    </StepShell>
  );
}
