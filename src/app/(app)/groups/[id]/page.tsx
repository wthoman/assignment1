"use client";

import { Bell, BellOff, Check, LogOut, Plus, Sparkles, UserPlus } from "lucide-react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useId, useState, type FormEvent } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { IllustrationTile, TINT_SOFT } from "@/components/illustrations/Illustration";
import { Page } from "@/components/shell/Page";
import { GroupProgressCard } from "@/components/social/GroupProgressCard";
import { PredictionCard } from "@/components/social/PredictionCard";
import { dayLabel, firstName, visibleFriends } from "@/components/social/social-helpers";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button, ButtonLink, IconButton } from "@/components/ui/Button";
import { ConfirmationDialog } from "@/components/ui/ConfirmationDialog";
import { CharCount, Field, Segmented, TextInput } from "@/components/ui/controls";
import { EmptyState, HandNote, SectionHeading, Tape } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { ILLUSTRATION_LABELS } from "@/lib/data/catalog";
import { cn } from "@/lib/cn";
import { addDays, formatTime, startOfWeek } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { Group, GroupNotify, ID, IllustrationKey, User } from "@/lib/types";

export default function GroupDetailPage() {
  const { id } = useParams<{ id: string }>();
  const state = useAppState();
  const dispatch = useDispatch();
  const router = useRouter();
  const toast = useToast();
  const today = useToday();
  const [inviteOpen, setInviteOpen] = useState(false);
  const [challengeOpen, setChallengeOpen] = useState(false);
  const [predictionOpen, setPredictionOpen] = useState(false);
  const [leaveOpen, setLeaveOpen] = useState(false);

  const group = state.groups.find((g) => g.id === id);
  if (!group) {
    return (
      <Page title="Group" back="/groups">
        <EmptyState title="We couldn't find that group" body="It may have been renamed or closed. Your other groups are safe." mood="thinking" action={<ButtonLink href="/groups" size="sm" className="min-h-11" variant="secondary">Back to groups</ButtonLink>} />
      </Page>
    );
  }

  const me = state.meId;
  const isMember = group.memberIds.includes(me);
  const invited = state.groupInvites.includes(group.id);
  const members = group.memberIds
    .map((m) => state.users[m])
    .filter((u): u is User => Boolean(u) && !state.settings.blockedIds.includes(u.id))
    .sort((a, b) => (a.id === me ? -1 : b.id === me ? 1 : a.name.localeCompare(b.name)));
  const challenges = state.challenges.filter((c) => c.groupId === group.id).sort((a, b) => (a.endDate < today ? 1 : 0) - (b.endDate < today ? 1 : 0) || a.endDate.localeCompare(b.endDate));
  const predictions = state.predictions.filter((p) => p.groupId === group.id);
  const notify: GroupNotify = state.settings.groupNotify[group.id] ?? group.notify;

  const since = addDays(today, -2);
  const activity = state.checkIns
    .filter((c) => c.date >= since && group.memberIds.includes(c.userId) && !state.settings.blockedIds.includes(c.userId))
    .filter((c) => {
      const h = state.habits.find((x) => x.id === c.habitId);
      return h && (c.userId === me || h.privacy !== "private");
    })
    .sort((a, b) => `${b.date}${b.time}`.localeCompare(`${a.date}${a.time}`))
    .slice(0, 8);

  const setNotify = (v: GroupNotify) => {
    dispatch({ type: "group/update", id: group.id, patch: { notify: v } });
    dispatch({ type: "settings/update", patch: { groupNotify: { ...state.settings.groupNotify, [group.id]: v } } });
    toast({ title: v === "off" ? "Group notifications off" : v === "milestones" ? "Only milestones from this group" : "All group updates on" });
  };

  const aside = (
    <>
      <section className="card p-4" aria-labelledby="members-heading">
        <SectionHeading
          id="members-heading"
          title="Members"
          count={members.length}
          action={
            isMember ? (
              <Button size="sm" className="min-h-11" variant="ghost" icon={<UserPlus size={15} aria-hidden />} onClick={() => setInviteOpen(true)}>
                Invite
              </Button>
            ) : undefined
          }
        />
        <ul className="mt-2 space-y-1">
          {members.map((u) => (
            <li key={u.id}>
              {u.id === me ? (
                <span className="flex min-h-11 items-center gap-2.5">
                  <Avatar user={u} size={32} />
                  <span className="text-sm font-semibold text-ink">You</span>
                  {group.createdBy === u.id && <span className="text-xs text-faint">· started it</span>}
                </span>
              ) : (
                <Link href={`/friends/${u.id}`} className="flex min-h-11 items-center gap-2.5 rounded-[12px] hover:text-accent">
                  <Avatar user={u} size={32} />
                  <span className="truncate text-sm font-semibold text-ink">{u.name}</span>
                  {group.createdBy === u.id && <span className="shrink-0 text-xs text-faint">· started it</span>}
                </Link>
              )}
            </li>
          ))}
        </ul>
      </section>

      {isMember && (
        <section className="card p-4" aria-labelledby="notify-heading">
          <h2 id="notify-heading" className="flex items-center gap-2 font-display text-[1.0625rem] font-bold text-ink">
            {notify === "off" ? <BellOff size={17} aria-hidden /> : <Bell size={17} aria-hidden />} Notifications
          </h2>
          <p className="mb-3 mt-0.5 text-sm text-muted">What should this group ping you about?</p>
          <Segmented
            label="Group notifications"
            value={notify}
            onChange={setNotify}
            size="sm"
            options={[
              { value: "all", label: "All" },
              { value: "milestones", label: "Milestones" },
              { value: "off", label: "Off" },
            ]}
          />
        </section>
      )}

      {isMember && (
        <Button variant="ghost" size="sm" className="min-h-11" icon={<LogOut size={15} aria-hidden />} onClick={() => setLeaveOpen(true)}>
          Leave group
        </Button>
      )}
    </>
  );

  return (
    <Page title={group.name} back="/groups" eyebrow="Group" aside={aside} actions={isMember ? <IconButton label="Invite friends" tone="soft" onClick={() => setInviteOpen(true)}><UserPlus size={19} aria-hidden /></IconButton> : undefined}>
      <div className="space-y-7">
        <section className={cn("relative overflow-hidden rounded-[var(--radius-card)] border border-line p-5", TINT_SOFT[group.tint])} aria-label="About this group">
          <Tape className="-top-2 right-12" rotate={6} />
          <div className="flex items-start gap-4">
            <IllustrationTile kind={group.icon} tint="cream" size={64} rotate={-6} className="bg-cream" />
            <div className="min-w-0 flex-1">
              <p className="text-[0.9375rem] leading-relaxed text-ink">{group.description || "A group for doing things together."}</p>
              <p className="mt-2 flex flex-wrap items-center gap-x-2 text-sm text-muted">
                <span className="flex -space-x-2">
                  {members.slice(0, 6).map((u) => (
                    <Avatar key={u.id} user={u} size={28} ring />
                  ))}
                </span>
                {members.length} members
              </p>
            </div>
          </div>
          {!isMember && (
            <div className="mt-4 flex flex-wrap items-center gap-2 rounded-[14px] bg-cream/80 p-3">
              <p className="min-w-0 flex-1 text-sm text-ink">{invited ? "You've been invited to join." : "You're not in this group."}</p>
              <Button
                size="sm" className="min-h-11"
                onClick={() => {
                  dispatch({ type: "group/join", id: group.id });
                  toast({ title: `Welcome to ${group.name}`, motif: group.icon });
                }}
              >
                Join group
              </Button>
              {invited && (
                <Button
                  size="sm" className="min-h-11"
                  variant="secondary"
                  onClick={() => {
                    dispatch({ type: "group/declineInvite", id: group.id });
                    router.push("/groups");
                  }}
                >
                  Decline
                </Button>
              )}
            </div>
          )}
        </section>

        <section aria-labelledby="challenges-heading" className="space-y-3">
          <SectionHeading
            id="challenges-heading"
            title="Challenges"
            count={challenges.length}
            action={
              isMember ? (
                <Button size="sm" className="min-h-11" variant="soft" icon={<Plus size={15} aria-hidden />} onClick={() => setChallengeOpen(true)}>
                  New
                </Button>
              ) : undefined
            }
          />
          {challenges.length ? (
            challenges.map((c) => <GroupProgressCard key={c.id} challenge={c} variant="full" tint={group.tint} />)
          ) : (
            <EmptyState compact title="No challenges yet" body="Set a shared goal. Everyone's check-ins add up together." mood="thinking" action={isMember ? <Button size="sm" className="min-h-11" onClick={() => setChallengeOpen(true)}>Start a challenge</Button> : undefined} />
          )}
        </section>

        <section aria-labelledby="predictions-heading" className="space-y-3">
          <SectionHeading
            id="predictions-heading"
            title="Predictions"
            hand="for fun"
            action={
              isMember ? (
                <Button size="sm" className="min-h-11" variant="ghost" icon={<Sparkles size={15} aria-hidden />} onClick={() => setPredictionOpen(true)}>
                  Ask
                </Button>
              ) : undefined
            }
          />
          {predictions.length ? (
            predictions.map((p) => <PredictionCard key={p.id} prediction={p} />)
          ) : (
            <p className="rounded-[14px] border border-dashed border-line-strong p-4 text-sm text-muted">No predictions yet. Guess who hits the goal first?</p>
          )}
        </section>

        <section aria-labelledby="activity-heading" className="space-y-2">
          <SectionHeading id="activity-heading" title="Recent activity" />
          {activity.length ? (
            <ul className="card divide-y divide-line">
              {activity.map((c) => {
                const u = state.users[c.userId];
                const h = state.habits.find((x) => x.id === c.habitId)!;
                return (
                  <li key={c.id} className="flex items-center gap-3 px-3 py-2.5">
                    <Avatar user={u} size={30} />
                    <p className="min-w-0 flex-1 text-sm text-ink">
                      <span className="font-semibold">{firstName(state, c.userId)}</span> <span className="text-muted">did</span> {h.name}
                    </p>
                    <IllustrationTile kind={h.icon} tint={h.tint} size={26} />
                    <span className="shrink-0 text-right text-xs text-faint">
                      {c.date === today ? formatTime(c.time) : dayLabel(c.date, today)}
                    </span>
                  </li>
                );
              })}
            </ul>
          ) : (
            <p className="text-sm text-muted">Quiet couple of days. The first check-in sets the tone.</p>
          )}
        </section>
      </div>

      {isMember && <InviteMembersSheet open={inviteOpen} onClose={() => setInviteOpen(false)} group={group} />}
      {isMember && <NewChallengeSheet open={challengeOpen} onClose={() => setChallengeOpen(false)} group={group} />}
      {isMember && <NewPredictionSheet open={predictionOpen} onClose={() => setPredictionOpen(false)} group={group} />}
      <ConfirmationDialog
        open={leaveOpen}
        onClose={() => setLeaveOpen(false)}
        title={`Leave ${group.name}?`}
        body="You'll step out of its challenges. Everything you contributed still counts toward the group's goals, and you can rejoin if someone invites you."
        confirmLabel="Leave group"
        tone="danger"
        onConfirm={() => {
          dispatch({ type: "group/leave", id: group.id });
          toast({ title: `You left ${group.name}` });
          router.push("/groups");
        }}
      />
    </Page>
  );
}

/* ---------- Invite more ---------- */

function InviteMembersSheet({ open, onClose, group }: { open: boolean; onClose: () => void; group: Group }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const [picked, setPicked] = useState<ID[]>([]);
  const candidates = visibleFriends(state).filter((u) => !group.memberIds.includes(u.id));
  const close = () => {
    setPicked([]);
    onClose();
  };
  return (
    <BottomSheet
      open={open}
      onClose={close}
      title="Invite friends"
      description={`Bring more people into ${group.name}.`}
      size="sm"
      footer={
        candidates.length ? (
          <Button
            block
            disabled={!picked.length}
            onClick={() => {
              dispatch({ type: "group/invite", id: group.id, userIds: picked });
              toast({ title: `Invited ${picked.length} friend${picked.length > 1 ? "s" : ""}`, motif: group.icon });
              close();
            }}
          >
            {picked.length ? `Invite ${picked.length}` : "Pick friends to invite"}
          </Button>
        ) : undefined
      }
    >
      {candidates.length ? (
        <ul className="space-y-2">
          {candidates.map((u) => {
            const on = picked.includes(u.id);
            return (
              <li key={u.id}>
                <button
                  type="button"
                  aria-pressed={on}
                  onClick={() => setPicked((xs) => (on ? xs.filter((x) => x !== u.id) : [...xs, u.id]))}
                  className={cn("flex min-h-12 w-full items-center gap-3 rounded-[14px] border px-3 py-2 text-left transition-colors", on ? "border-accent bg-accent-soft" : "border-line hover:bg-accent-soft/50")}
                >
                  <Avatar user={u} size={34} />
                  <span className="min-w-0 flex-1 truncate text-sm font-semibold text-ink">{u.name}</span>
                  <span className={cn("grid size-6 place-items-center rounded-[7px] border", on ? "border-accent bg-accent text-on-accent" : "border-line-strong")} aria-hidden>
                    {on && <Check size={14} strokeWidth={3} />}
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      ) : (
        <EmptyState compact title="Everyone's already here" body="All your friends are in this group. Add more friends to invite them." mood="happy" />
      )}
    </BottomSheet>
  );
}

/* ---------- New challenge ---------- */

const CHALLENGE_ICONS: IllustrationKey[] = ["water", "pencil", "book", "leaf", "shoe", "dumbbell", "moon", "flower"];

function NewChallengeSheet({ open, onClose, group }: { open: boolean; onClose: () => void; group: Group }) {
  return (
    <BottomSheet open={open} onClose={onClose} title="New challenge" description="A shared goal everyone chips in to." size="md">
      {open && <ChallengeForm group={group} onDone={onClose} />}
    </BottomSheet>
  );
}

function ChallengeForm({ group, onDone }: { group: Group; onDone: () => void }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const today = useToday();
  const ids = { title: useId(), unit: useId(), goal: useId(), end: useId() };
  const n = Math.max(1, group.memberIds.length);
  const weekEnd = addDays(startOfWeek(today, state.settings.weekStart), 6);
  const presets: { title: string; description: string; unit: string; goal: number; end: string; icon: IllustrationKey }[] = [
    { title: "Drink water five days this week", description: "Everyone aims for five hydrated days. We count them together.", unit: "hydrated days", goal: 5 * n, end: weekEnd, icon: "water" },
    { title: "Reach 40 collective study sessions", description: "Every focused block counts toward the jar.", unit: "sessions", goal: 40, end: addDays(today, 13), icon: "pencil" },
    { title: "One outdoor activity each day", description: "Walk, garden, bike, or sit in a park.", unit: "outdoor days", goal: 7 * n, end: addDays(today, 6), icon: "leaf" },
    { title: "Finish 20 total reading sessions", description: "Pages add up faster together.", unit: "sessions", goal: 20, end: addDays(today, 9), icon: "book" },
  ];
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [unit, setUnit] = useState("");
  const [goal, setGoal] = useState("");
  const [end, setEnd] = useState(addDays(today, 6));
  const [icon, setIcon] = useState<IllustrationKey>(group.icon);
  const [tried, setTried] = useState(false);
  const maxEnd = addDays(today, 60);

  const goalNum = Number(goal);
  const errors = {
    title: !title.trim() ? "Give it a title." : title.trim().length < 4 ? "A few more characters." : title.length > 60 ? "Keep it under 60 characters." : undefined,
    unit: !unit.trim() ? "What are you counting? e.g. sessions, days." : unit.length > 24 ? "Keep the unit short." : undefined,
    goal: !goal ? "Set a goal number." : !Number.isInteger(goalNum) || goalNum < 1 ? "Use a whole number above zero." : goalNum > 999 ? "Let's keep it under 1,000." : undefined,
    end: !end ? "Pick an end date." : end < today ? "End date can't be in the past." : end > maxEnd ? "Keep challenges under two months." : undefined,
  };
  const show = (k: keyof typeof errors) => (tried ? errors[k] : undefined);

  const submit = (e: FormEvent) => {
    e.preventDefault();
    setTried(true);
    if (Object.values(errors).some(Boolean)) return;
    dispatch({
      type: "challenge/create",
      challenge: { groupId: group.id, title: title.trim(), description: description.trim(), icon, unit: unit.trim(), goal: goalNum, startDate: today, endDate: end, participantIds: group.memberIds },
    });
    toast({ title: "Challenge started", body: `${goalNum} ${unit.trim()} together`, motif: icon });
    onDone();
  };

  return (
    <form onSubmit={submit} noValidate className="space-y-5">
      <div>
        <p className="mb-2 font-display text-sm font-semibold text-ink">Start from an idea</p>
        <ul className="grid gap-2 sm:grid-cols-2">
          {presets.map((p) => (
            <li key={p.title}>
              <button
                type="button"
                aria-pressed={title === p.title}
                onClick={() => {
                  setTitle(p.title);
                  setDescription(p.description);
                  setUnit(p.unit);
                  setGoal(String(p.goal));
                  setEnd(p.end);
                  setIcon(p.icon);
                }}
                className={cn("flex min-h-14 w-full items-center gap-2.5 rounded-[14px] border p-2.5 text-left transition-colors", title === p.title ? "border-accent bg-accent-soft" : "border-line bg-paper/40 hover:bg-accent-soft/50")}
              >
                <IllustrationTile kind={p.icon} tint={group.tint} size={34} />
                <span className="text-sm font-semibold leading-snug text-ink">{p.title}</span>
              </button>
            </li>
          ))}
        </ul>
      </div>
      <div className="hand-divider" aria-hidden />
      <Field label="Title" htmlFor={ids.title} error={show("title")}>
        <TextInput id={ids.title} value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. Ten walks this week" invalid={Boolean(show("title"))} maxLength={70} />
      </Field>
      <div className="grid grid-cols-2 gap-3">
        <Field label="Goal" htmlFor={ids.goal} error={show("goal")}>
          <TextInput id={ids.goal} type="number" inputMode="numeric" min={1} max={999} value={goal} onChange={(e) => setGoal(e.target.value)} placeholder="25" invalid={Boolean(show("goal"))} />
        </Field>
        <Field label="Counting" htmlFor={ids.unit} error={show("unit")}>
          <TextInput id={ids.unit} value={unit} onChange={(e) => setUnit(e.target.value)} placeholder="sessions" invalid={Boolean(show("unit"))} maxLength={30} />
        </Field>
      </div>
      <Field label="Ends on" htmlFor={ids.end} error={show("end")}>
        <TextInput id={ids.end} type="date" min={today} max={maxEnd} value={end} onChange={(e) => setEnd(e.target.value)} invalid={Boolean(show("end"))} />
      </Field>
      <fieldset>
        <legend className="mb-2 font-display text-sm font-semibold text-ink">Icon</legend>
        <div className="flex flex-wrap gap-1.5" role="radiogroup" aria-label="Challenge icon">
          {CHALLENGE_ICONS.map((k) => (
            <button key={k} type="button" role="radio" aria-checked={icon === k} aria-label={ILLUSTRATION_LABELS[k]} onClick={() => setIcon(k)} className={cn("grid size-12 place-items-center rounded-[13px] border-2", icon === k ? "border-accent" : "border-transparent hover:border-line-strong")}>
              <IllustrationTile kind={k} tint={icon === k ? group.tint : "cream"} size={40} />
            </button>
          ))}
        </div>
      </fieldset>
      <p className="text-xs text-muted">All {group.memberIds.length} members are added. Anyone can step out, and progress is always shown as a team total.</p>
      <Button type="submit" block>
        Start challenge
      </Button>
    </form>
  );
}

/* ---------- New prediction ---------- */

function NewPredictionSheet({ open, onClose, group }: { open: boolean; onClose: () => void; group: Group }) {
  return (
    <BottomSheet open={open} onClose={onClose} title="New prediction" description="A friendly guess. No stakes, just bragging rights." size="sm">
      {open && <PredictionForm group={group} onDone={onClose} />}
    </BottomSheet>
  );
}

const PREDICTION_IDEAS = ["Guess which friend completes the goal first", "Who logs the most sessions this week?", "Who checks in earliest tomorrow?"];

function PredictionForm({ group, onDone }: { group: Group; onDone: () => void }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const today = useToday();
  const qId = useId();
  const dateId = useId();
  const members = group.memberIds.map((m) => state.users[m]).filter((u): u is User => Boolean(u) && !state.settings.blockedIds.includes(u.id));
  const [question, setQuestion] = useState("");
  const [options, setOptions] = useState<ID[]>(members.map((u) => u.id));
  const [closes, setCloses] = useState(addDays(today, 6));
  const [tried, setTried] = useState(false);

  const qErr = !question.trim() ? "Write the question." : question.trim().length < 8 ? "A little longer, please." : question.length > 100 ? "Keep it under 100 characters." : undefined;
  const optErr = options.length < 2 ? "Pick at least two people." : undefined;
  const dateErr = !closes || closes < today ? "Pick today or later." : undefined;

  const submit = (e: FormEvent) => {
    e.preventDefault();
    setTried(true);
    if (qErr || optErr || dateErr) return;
    dispatch({ type: "prediction/create", question: question.trim(), optionIds: options, groupId: group.id, closesAt: closes });
    toast({ title: "Prediction posted", body: question.trim(), motif: "star" });
    onDone();
  };

  return (
    <form onSubmit={submit} noValidate className="space-y-4">
      <Field label="Question" htmlFor={qId} error={tried ? qErr : undefined}>
        <TextInput id={qId} value={question} onChange={(e) => setQuestion(e.target.value)} placeholder="Who will…" invalid={Boolean(tried && qErr)} maxLength={120} />
      </Field>
      <div className="-mt-2 flex items-start justify-between gap-2">
        <ul className="flex flex-wrap gap-1.5">
          {PREDICTION_IDEAS.map((s) => (
            <li key={s}>
              <button type="button" onClick={() => setQuestion(s)} className="min-h-9 rounded-[10px] border border-line-strong px-2.5 text-left text-xs text-ink hover:bg-accent-soft">
                {s}
              </button>
            </li>
          ))}
        </ul>
        <CharCount value={question} max={100} />
      </div>
      <fieldset>
        <legend className="mb-2 font-display text-sm font-semibold text-ink">Who&apos;s in the running</legend>
        <div className="flex flex-wrap gap-2">
          {members.map((u) => {
            const on = options.includes(u.id);
            return (
              <button
                key={u.id}
                type="button"
                aria-pressed={on}
                onClick={() => setOptions((xs) => (on ? xs.filter((x) => x !== u.id) : [...xs, u.id]))}
                className={cn("flex min-h-11 items-center gap-2 rounded-[12px] border py-1 pl-1 pr-3 text-sm font-semibold transition-colors", on ? "border-accent bg-accent-soft text-ink" : "border-line text-muted hover:bg-accent-soft/50")}
              >
                <Avatar user={u} size={30} />
                {firstName(state, u.id)}
              </button>
            );
          })}
        </div>
        {tried && optErr && <p role="alert" className="mt-2 text-[0.8125rem] font-medium text-[#a3301f] dark:text-[#f0a090]">{optErr}</p>}
      </fieldset>
      <Field label="Voting closes" htmlFor={dateId} error={tried ? dateErr : undefined}>
        <TextInput id={dateId} type="date" min={today} value={closes} onChange={(e) => setCloses(e.target.value)} invalid={Boolean(tried && dateErr)} />
      </Field>
      <HandNote className="text-base">winner gets eternal glory, nothing more</HandNote>
      <Button type="submit" block>
        Post prediction
      </Button>
    </form>
  );
}
