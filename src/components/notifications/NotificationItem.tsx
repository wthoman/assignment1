"use client";

import { motion, useReducedMotion, type PanInfo } from "motion/react";
import { Bell, Check, Gift, Heart, MessageCircle, Sparkles, Trophy, UserPlus, Users, X, type LucideIcon } from "lucide-react";
import Link from "next/link";
import type { ReactNode } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { Button, ButtonLink } from "@/components/ui/Button";
import { useToast } from "@/components/ui/Toast";
import { cn } from "@/lib/cn";
import { relativeTime } from "@/lib/dates";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { AppNotification, AppState, IllustrationKey, NotificationKind, Tint } from "@/lib/types";

export const KIND_META: Record<NotificationKind, { label: string; icon: LucideIcon; motif: IllustrationKey; tint: Tint }> = {
  "friend-request": { label: "Friend request", icon: UserPlus, motif: "heart", tint: "rose" },
  "group-invite": { label: "Group invite", icon: Users, motif: "coffee", tint: "orange" },
  "habit-invite": { label: "Shared habit invite", icon: UserPlus, motif: "leaf", tint: "sage" },
  reminder: { label: "Reminder", icon: Bell, motif: "alarm", tint: "rose" },
  reaction: { label: "Reaction", icon: Heart, motif: "heart", tint: "rose" },
  comment: { label: "Comment", icon: MessageCircle, motif: "pencil", tint: "cream" },
  award: { label: "Award", icon: Trophy, motif: "star", tint: "gold" },
  recap: { label: "Weekly recap", icon: Sparkles, motif: "sun", tint: "gold" },
  quiz: { label: "Friend quiz", icon: Sparkles, motif: "ticket", tint: "sky" },
  feedback: { label: "Feedback", icon: MessageCircle, motif: "mascot", tint: "sage" },
  "group-goal": { label: "Group goal", icon: Users, motif: "ribbon", tint: "sage" },
  nudge: { label: "Nudge", icon: Bell, motif: "phone", tint: "sky" },
  gift: { label: "Gift", icon: Gift, motif: "ribbon", tint: "gold" },
};

/** Whether an inline invitation can still be answered. */
function actionable(state: AppState, n: AppNotification): boolean {
  if (n.resolved || !n.refId) return false;
  if (n.kind === "friend-request") return state.friendRequests.some((r) => r.id === n.refId);
  if (n.kind === "group-invite") return state.groupInvites.includes(n.refId);
  if (n.kind === "habit-invite") {
    const h = state.habits.find((x) => x.id === n.refId);
    return Boolean(h && !h.participantIds.includes(state.meId));
  }
  return false;
}

const SWIPE_DISMISS = 110;

export function NotificationItem({ notification: n }: { notification: AppNotification }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const reduce = useReducedMotion();
  const actor = n.actorId ? state.users[n.actorId] : undefined;
  const meta = KIND_META[n.kind];
  const Icon = meta.icon;
  const unread = !n.read;

  const markRead = () => {
    if (!n.read) dispatch({ type: "notification/read", id: n.id });
  };
  const dismiss = () => dispatch({ type: "notification/dismiss", id: n.id });
  const resolve = (resolution: "accepted" | "declined") => dispatch({ type: "notification/resolve", id: n.id, resolution });

  const onDragEnd = (_: unknown, info: PanInfo) => {
    if (Math.abs(info.offset.x) > SWIPE_DISMISS || Math.abs(info.velocity.x) > 700) dismiss();
  };

  let actions: ReactNode = null;
  if (actionable(state, n)) {
    if (n.kind === "friend-request") {
      const name = actor?.name.split(" ")[0] ?? "them";
      actions = (
        <>
          <Button size="sm" icon={<Check size={15} aria-hidden />} onClick={() => { dispatch({ type: "friend/accept", requestId: n.refId! }); resolve("accepted"); toast({ title: `You and ${name} are friends`, motif: "heart" }); }}>
            Accept
          </Button>
          <Button size="sm" variant="secondary" onClick={() => { dispatch({ type: "friend/decline", requestId: n.refId! }); resolve("declined"); toast({ title: "Request declined", body: "They won't be told." }); }}>
            Decline
          </Button>
        </>
      );
    } else if (n.kind === "group-invite") {
      const g = state.groups.find((x) => x.id === n.refId);
      actions = (
        <>
          <Button size="sm" icon={<Check size={15} aria-hidden />} onClick={() => { dispatch({ type: "group/join", id: n.refId! }); resolve("accepted"); toast({ title: `Joined ${g?.name ?? "the group"}`, motif: "coffee" }); }}>
            Join
          </Button>
          <Button size="sm" variant="secondary" onClick={() => { dispatch({ type: "group/declineInvite", id: n.refId! }); resolve("declined"); }}>
            Decline
          </Button>
        </>
      );
    } else if (n.kind === "habit-invite") {
      const h = state.habits.find((x) => x.id === n.refId);
      actions = (
        <>
          <Button size="sm" icon={<Check size={15} aria-hidden />} onClick={() => { dispatch({ type: "habit/acceptInvite", id: n.refId! }); resolve("accepted"); toast({ title: `Joined “${h?.name ?? "the habit"}”`, body: "It's on your Today list now.", motif: h?.icon ?? "leaf" }); }}>
            Join habit
          </Button>
          <Button size="sm" variant="secondary" onClick={() => resolve("declined")}>
            Not now
          </Button>
        </>
      );
    }
  } else if (n.kind === "feedback" && !n.resolved) {
    actions = (
      <>
        <Button size="sm" variant="soft" onClick={() => { resolve("accepted"); toast({ title: "Thanks for the feedback!", body: "Glad it's working for you.", motif: "mascot" }); }}>
          Loving it
        </Button>
        <Button size="sm" variant="secondary" onClick={() => { resolve("declined"); toast({ title: "Thanks, noted", body: "We'll keep tuning it.", motif: "mascot" }); }}>
          Needs work
        </Button>
      </>
    );
  } else if (n.kind === "gift") {
    actions = (
      <ButtonLink href="/profile/avatar" size="sm" variant="soft" icon={<Gift size={15} aria-hidden />} onClick={markRead}>
        Open in Cosmetics
      </ButtonLink>
    );
  }

  const resolvedNote = n.resolved ? (
    <p className="mt-1.5 inline-flex items-center gap-1 text-xs font-semibold text-muted">
      {n.resolved === "accepted" ? <Check size={13} aria-hidden /> : <X size={13} aria-hidden />}
      {n.kind === "feedback" ? "Thanks for answering" : n.resolved === "accepted" ? "Accepted" : "Declined"}
    </p>
  ) : null;

  const body = (
    <>
      <span className="relative shrink-0">
        {actor ? <Avatar user={actor} size={44} /> : <IllustrationTile kind={meta.motif} tint={meta.tint} size={44} rotate={-3} />}
        <span className="absolute -bottom-1 -right-1 grid size-5 place-items-center rounded-full border-2 border-cream bg-accent text-on-accent">
          <Icon size={10} strokeWidth={2.6} aria-hidden />
        </span>
      </span>
      <span className="min-w-0 flex-1">
        <span className={cn("block text-[0.9375rem] leading-snug", unread ? "font-bold text-ink" : "font-medium text-ink/85")}>{n.title}</span>
        <span className="mt-0.5 block text-[0.8125rem] leading-snug text-muted">{n.body}</span>
        <span className="mt-1 block text-xs text-faint">
          <span className="sr-only">{meta.label}. </span>
          {relativeTime(n.at)}
          {unread && <span className="sr-only">. Unread</span>}
        </span>
      </span>
    </>
  );

  return (
    <motion.li
      layout={!reduce}
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, x: -60, height: 0, marginTop: 0, marginBottom: 0, transition: { duration: 0.22 } }}
      className="relative overflow-hidden"
    >
      <motion.div
        drag={reduce ? false : "x"}
        dragDirectionLock
        dragConstraints={{ left: 0, right: 0 }}
        dragElastic={0.6}
        onDragEnd={onDragEnd}
        className={cn("relative flex gap-2 rounded-[16px] border p-3 pr-1 transition-colors", unread ? "border-line-strong bg-cream shadow-[var(--shadow)]" : "border-line bg-cream/55")}
      >
        {unread && <span className="absolute left-1.5 top-1/2 size-2 -translate-y-1/2 rounded-full bg-accent" aria-hidden />}
        <div className="min-w-0 flex-1 pl-2">
          {n.href ? (
            <Link href={n.href} onClick={markRead} className="flex items-start gap-3 rounded-[12px]">
              {body}
            </Link>
          ) : (
            <button type="button" onClick={markRead} className="flex w-full items-start gap-3 rounded-[12px] text-left" aria-label={unread ? `${n.title}. Mark as read` : n.title}>
              {body}
            </button>
          )}
          {actions && <div className="mt-2.5 flex flex-wrap gap-2 pl-14">{actions}</div>}
          {resolvedNote && <div className="pl-14">{resolvedNote}</div>}
        </div>
        <button type="button" onClick={dismiss} aria-label={`Dismiss: ${n.title}`} className="grid size-11 shrink-0 place-items-center self-start rounded-[12px] text-faint transition-colors hover:bg-accent-soft hover:text-accent">
          <X size={18} aria-hidden />
        </button>
      </motion.div>
    </motion.li>
  );
}
