"use client";

import { AnimatePresence, motion } from "motion/react";
import { Avatar } from "@/components/avatar/Avatar";
import { Page } from "@/components/shell/Page";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { useAppState, useDispatch } from "@/lib/store/provider";

export default function BlockedUsersPage() {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const blocked = state.settings.blockedIds.map((id) => ({ id, user: state.users[id] }));

  return (
    <Page title="Blocked users" back="/settings/privacy" subtitle="Blocked people can't see your profile, check-ins or recaps, and can't send you nudges or gifts. They aren't told.">
      {blocked.length === 0 ? (
        <EmptyState mood="happy" title="Nobody blocked" body="If someone makes this less fun, you can block them from their profile." />
      ) : (
        <ul className="card divide-y divide-line overflow-hidden">
          <AnimatePresence initial={false}>
            {blocked.map(({ id, user }) => (
              <motion.li key={id} layout exit={{ opacity: 0, height: 0 }} className="flex min-h-16 items-center gap-3 px-4 py-3">
                {user ? <Avatar user={user} size={40} /> : <span className="size-10 rounded-full bg-paper-deep" aria-hidden />}
                <span className="min-w-0 flex-1">
                  <span className="block truncate font-semibold text-ink">{user?.name ?? "Unknown user"}</span>
                  {user && <span className="block truncate text-sm text-muted">@{user.handle}</span>}
                </span>
                <Button
                  size="sm"
                  variant="secondary"
                  onClick={() => {
                    dispatch({ type: "settings/unblock", userId: id });
                    toast({ title: `Unblocked ${user?.name.split(" ")[0] ?? "user"}`, body: "They aren't re-added as a friend automatically." });
                  }}
                  aria-label={`Unblock ${user?.name ?? "user"}`}
                >
                  Unblock
                </Button>
              </motion.li>
            ))}
          </AnimatePresence>
        </ul>
      )}
    </Page>
  );
}
