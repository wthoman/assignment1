"use client";

import { Check, Search, X } from "lucide-react";
import { useState } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button } from "@/components/ui/Button";
import { TextInput } from "@/components/ui/controls";
import { useToast } from "@/components/ui/Toast";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { ID } from "@/lib/types";

/** Search people on the app and invite contacts. */
export function AddFriendsSheet({ open, onClose }: { open: boolean; onClose: () => void }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const [q, setQ] = useState("");
  const me = state.users[state.meId];
  const query = q.trim().toLowerCase();
  const people = Object.values(state.users).filter(
    (u) => u.id !== state.meId && !me.friendIds.includes(u.id) && !state.settings.blockedIds.includes(u.id) && (!query || u.name.toLowerCase().includes(query) || u.handle.toLowerCase().includes(query)),
  );
  const contacts = state.contacts.filter((c) => !query || c.name.toLowerCase().includes(query) || c.detail.toLowerCase().includes(query));

  const add = (userId: ID) => {
    const req = state.friendRequests.find((r) => r.fromId === userId);
    dispatch(req ? { type: "friend/accept", requestId: req.id } : { type: "friend/add", userId });
    toast({ title: `You and ${state.users[userId]?.name.split(" ")[0]} are friends`, motif: "heart" });
  };

  return (
    <BottomSheet open={open} onClose={onClose} title="Add friends" description="Find people on Daybook or invite contacts." size="md">
      <div className="space-y-5">
        <div className="relative">
          <label htmlFor="friend-search" className="sr-only">
            Search by name or handle
          </label>
          <Search size={18} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-faint" aria-hidden />
          <TextInput id="friend-search" type="search" value={q} onChange={(e) => setQ(e.target.value)} placeholder="Name or @handle" className="pl-10" autoComplete="off" data-autofocus />
          {q && (
            <button type="button" onClick={() => setQ("")} aria-label="Clear search" className="absolute right-1 top-1/2 grid size-10 -translate-y-1/2 place-items-center rounded-[10px] text-muted hover:text-accent">
              <X size={16} aria-hidden />
            </button>
          )}
        </div>

        <section aria-labelledby="people-heading">
          <h3 id="people-heading" className="eyebrow mb-2">
            {query ? "On Daybook" : "People you may know"}
          </h3>
          {people.length ? (
            <ul className="space-y-1">
              {people.map((u) => {
                const mutual = u.friendIds.filter((f) => me.friendIds.includes(f)).length;
                const requested = state.friendRequests.some((r) => r.fromId === u.id);
                return (
                  <li key={u.id} className="flex items-center gap-3 py-1">
                    <Avatar user={u} size={40} />
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-sm font-semibold text-ink">{u.name}</span>
                      <span className="block truncate text-xs text-muted">
                        @{u.handle}
                        {mutual ? ` · ${mutual} mutual` : ""}
                        {requested ? " · wants to be friends" : ""}
                      </span>
                    </span>
                    <Button size="sm" className="min-h-11" variant={requested ? "primary" : "soft"} onClick={() => add(u.id)} aria-label={`${requested ? "Accept" : "Add"} ${u.name}`}>
                      {requested ? "Accept" : "Add"}
                    </Button>
                  </li>
                );
              })}
            </ul>
          ) : (
            <p className="text-sm text-muted">{query ? "No one by that name yet. Try inviting them below." : "You're friends with everyone we know about."}</p>
          )}
        </section>

        <section aria-labelledby="contacts-heading">
          <h3 id="contacts-heading" className="eyebrow mb-2">
            From your contacts
          </h3>
          <ul className="card-flat divide-y divide-line overflow-hidden">
            {contacts.map((c) => {
              const onApp = c.userId && state.users[c.userId];
              const friend = c.userId ? me.friendIds.includes(c.userId) : false;
              const invited = c.detail.includes("Invited");
              return (
                <li key={c.id} className="flex items-center gap-3 px-3 py-2">
                  {onApp ? (
                    <Avatar user={state.users[c.userId!]} size={34} />
                  ) : (
                    <span className="grid size-[34px] shrink-0 place-items-center rounded-full bg-paper-deep font-display text-sm font-bold text-muted" aria-hidden>
                      {c.name.charAt(0)}
                    </span>
                  )}
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-semibold text-ink">{c.name}</span>
                    <span className="block truncate text-xs text-muted">{onApp ? "On Daybook" : c.detail.replace(" · Invited", "")}</span>
                  </span>
                  {friend ? (
                    <span className="inline-flex min-h-9 items-center gap-1 text-xs font-semibold text-sage-ink">
                      <Check size={14} aria-hidden /> Friends
                    </span>
                  ) : onApp ? (
                    <Button size="sm" className="min-h-11" variant="soft" onClick={() => add(c.userId!)} aria-label={`Add ${c.name}`}>
                      Add
                    </Button>
                  ) : invited ? (
                    <span className="inline-flex min-h-9 items-center gap-1 text-xs font-semibold text-muted">
                      <Check size={14} aria-hidden /> Invited
                    </span>
                  ) : (
                    <Button
                      size="sm" className="min-h-11"
                      variant="secondary"
                      onClick={() => {
                        dispatch({ type: "contact/invite", contactId: c.id });
                        toast({ title: `Invite sent to ${c.name.split(" ")[0]}`});
                      }}
                      aria-label={`Invite ${c.name}`}
                    >
                      Invite
                    </Button>
                  )}
                </li>
              );
            })}
            {contacts.length === 0 && <li className="px-3 py-3 text-sm text-muted">No contacts match “{q}”.</li>}
          </ul>
        </section>
      </div>
    </BottomSheet>
  );
}
