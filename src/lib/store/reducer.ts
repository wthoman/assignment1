import { COLLECTIBLE_BY_ID } from "../data/catalog";
import { createSeedState } from "../data/seed";
import { addDays, formatDate, nowClock, startOfWeek, todayISO, weekday } from "../dates";
import { uid } from "../random";
import { currentStreak, habitById, isDone, missedBefore } from "../selectors/habits";
import { comebackCount, totalCompletions } from "../selectors/stats";
import type { AppNotification, AppState, CheckIn, ID, OwnedCollectible } from "../types";
import type { Action } from "./actions";

const MAX_TEXT = 280;
/** User text is stored as plain text and always rendered through React (never as HTML). */
export function cleanText(s: string, max = MAX_TEXT): string {
  return s.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, "").trim().slice(0, max);
}

const nowTs = () => new Date().toISOString();

function notify(state: AppState, n: Omit<AppNotification, "id" | "at" | "read">): AppState {
  return { ...state, notifications: [{ ...n, id: uid("n"), at: nowTs(), read: false }, ...state.notifications] };
}

function owns(state: AppState, id: ID) {
  return state.collection.some((c) => c.collectibleId === id);
}

function award(state: AppState, collectibleId: ID, earnedFor: string, opts: { reveal?: boolean; giftedBy?: ID } = {}): AppState {
  if (owns(state, collectibleId) || !COLLECTIBLE_BY_ID[collectibleId]) return state;
  const owned: OwnedCollectible = { collectibleId, earnedAt: nowTs(), earnedFor, favorite: false, showcased: false, seen: false, giftedBy: opts.giftedBy };
  const next = { ...state, collection: [owned, ...state.collection], pendingReveal: opts.reveal === false ? state.pendingReveal : state.pendingReveal ?? collectibleId };
  return notify(next, { kind: "award", title: `New sticker: ${COLLECTIBLE_BY_ID[collectibleId].name}`, body: earnedFor, href: "/collection" });
}

/** Checks which collectibles a fresh check-in unlocks. At most one reveal per check-in. */
function evaluateCheckInAwards(state: AppState, ci: CheckIn): AppState {
  const h = habitById(state, ci.habitId);
  if (!h) return state;
  const me = state.meId;
  const candidates: [ID, string][] = [];
  const mine = state.checkIns.filter((c) => c.userId === me);

  if (mine.length === 1) candidates.push(["c-first-stamp", `First check-in: ${h.name}`]);
  if (ci.note) candidates.push(["c-first-note", `Noted on ${h.name}`]);
  if (ci.photo) candidates.push(["c-first-photo", `Photo proof on ${h.name}`]);
  if (ci.time >= "23:50") candidates.push(["c-1159", `${h.name} at ${ci.time}. Technically still today.`]);
  if (ci.time >= "22:00") candidates.push(["c-night-owl", `${h.name} after 10pm`]);

  if (h.shared && h.participantIds.length > 1) {
    const others = h.participantIds.filter((p) => p !== me);
    if (others.every((p) => isDone(state, h.id, p, ci.date))) candidates.push(["c-full-house", `Completed “${h.name}” for everyone on ${formatDate(ci.date, { weekday: "long", month: "short", day: "numeric" })}`]);
    if (others.some((p) => isDone(state, h.id, p, ci.date))) candidates.push(["c-in-sync", `Matched a friend on ${h.name}`]);
  }

  const { missed, hadPrior } = missedBefore({ ...state, checkIns: state.checkIns.filter((c) => c.id !== ci.id) }, h, me, ci.date);
  if (hadPrior && missed >= 2) {
    candidates.push(["c-comeback", `Came back to ${h.name} after ${missed} missed days`]);
    const comebacks = comebackCount(state, me, addDays(ci.date, -30), ci.date);
    if (missed >= 7) candidates.push(["c-comeback-week", `Returned to ${h.name} after ${missed} missed days`]);
    else if (comebacks > 2) candidates.push(["c-comeback-3", `Another comeback on ${h.name}`]);
  }

  const streak = currentStreak(state, h, me, ci.date);
  if (streak >= 50) candidates.push(["c-streak-50", `${streak} in a row on ${h.name}`]);
  if (streak >= 21) candidates.push(["c-streak-21", `${streak} in a row on ${h.name}`]);
  if (streak >= 7) candidates.push(["c-streak-7", `${streak} in a row on ${h.name}`]);

  const wd = weekday(ci.date);
  if (wd === 0 || wd === 6) {
    const other = wd === 0 ? addDays(ci.date, -1) : addDays(ci.date, 1);
    if (mine.some((c) => c.date === other)) candidates.push(["c-weekend", "Checked in on Saturday and Sunday"]);
    if (wd === 0 && mine.filter((c) => c.date === ci.date).length >= 3) candidates.push(["c-sunday-reset", "Three habits done on a Sunday"]);
  }
  const ws = startOfWeek(ci.date, state.settings.weekStart);
  const activeDays = new Set(mine.filter((c) => c.date >= ws && c.date <= addDays(ws, 6)).map((c) => c.date));
  if (activeDays.size === 7) candidates.push(["c-every-day", "Checked in on all seven days of the week"]);
  if (totalCompletions(state, me) >= 100) candidates.push(["c-hundred", `Your ${totalCompletions(state, me)}th check-in`]);

  const fresh = candidates.find(([id]) => !owns(state, id));
  return fresh ? award(state, fresh[0], fresh[1]) : state;
}

function updateCheckIn(state: AppState, id: ID, fn: (c: CheckIn) => CheckIn): AppState {
  return { ...state, checkIns: state.checkIns.map((c) => (c.id === id ? fn(c) : c)) };
}

export function reducer(state: AppState, action: Action): AppState {
  const me = state.meId;
  switch (action.type) {
    /* ---------- Session ---------- */
    case "session/account":
      return { ...state, session: { ...state.session, account: action.account } };
    case "session/goals":
      return { ...state, session: { ...state.session, goals: action.goals } };
    case "session/personality":
      return {
        ...state,
        session: { ...state.session, personality: action.personality },
        users: { ...state.users, [me]: { ...state.users[me], personality: action.personality } },
      };
    case "session/finishOnboarding":
      return { ...state, session: { ...state.session, onboarded: true } };
    case "session/logout":
      return { ...state, session: { ...state.session, onboarded: false, account: null } };
    case "session/reset":
      return createSeedState(todayISO());
    case "profile/update": {
      const patch = { ...action.patch };
      if (patch.name !== undefined) patch.name = cleanText(patch.name, 40);
      if (patch.bio !== undefined) patch.bio = cleanText(patch.bio, 160);
      if (patch.handle !== undefined) patch.handle = cleanText(patch.handle, 24).toLowerCase().replace(/[^a-z0-9._]/g, "");
      if (patch.pronouns !== undefined) patch.pronouns = cleanText(patch.pronouns, 24);
      return { ...state, users: { ...state.users, [me]: { ...state.users[me], ...patch } } };
    }
    case "profile/avatar":
      return { ...state, users: { ...state.users, [me]: { ...state.users[me], avatar: { ...state.users[me].avatar, ...action.patch } } } };

    /* ---------- Habits ---------- */
    case "habit/create": {
      const d = action.draft;
      const habit = {
        ...d,
        name: cleanText(d.name, 60),
        description: cleanText(d.description, 140),
        participantIds: Array.from(new Set([me, ...d.participantIds])),
        id: action.id ?? uid("h"),
        ownerId: me,
        createdAt: nowTs(),
        status: "active" as const,
      };
      let next: AppState = { ...state, habits: [habit, ...state.habits] };
      if (habit.shared && habit.participantIds.length > 1) next = award(next, "c-first-share", `Started “${habit.name}” with friends`, { reveal: false });
      return next;
    }
    case "habit/update": {
      const patch = { ...action.patch };
      if (patch.name !== undefined) patch.name = cleanText(patch.name, 60);
      if (patch.description !== undefined) patch.description = cleanText(patch.description, 140);
      if (patch.participantIds) patch.participantIds = Array.from(new Set([me, ...patch.participantIds]));
      return { ...state, habits: state.habits.map((h) => (h.id === action.id ? { ...h, ...patch } : h)) };
    }
    case "habit/status":
      return { ...state, habits: state.habits.map((h) => (h.id === action.id ? { ...h, status: action.status } : h)) };
    case "habit/delete":
      return { ...state, habits: state.habits.filter((h) => h.id !== action.id), checkIns: state.checkIns.filter((c) => c.habitId !== action.id) };
    case "habit/acceptInvite":
      return {
        ...state,
        habits: state.habits.map((h) => (h.id === action.id ? { ...h, shared: true, participantIds: Array.from(new Set([...h.participantIds, me])) } : h)),
      };
    case "habit/invite":
      return {
        ...state,
        habits: state.habits.map((h) => (h.id === action.id ? { ...h, shared: true, participantIds: Array.from(new Set([...h.participantIds, ...action.userIds])) } : h)),
      };

    /* ---------- Check-ins ---------- */
    case "checkin/complete": {
      if (isDone(state, action.habitId, me, action.date)) return state;
      const ci: CheckIn = {
        id: uid("ci"),
        habitId: action.habitId,
        userId: me,
        date: action.date,
        time: action.time ?? (action.date === todayISO() ? nowClock() : "20:00"),
        note: action.note ? cleanText(action.note) : undefined,
        photo: action.photo,
        reactions: [],
        comments: [],
      };
      const next = { ...state, checkIns: [...state.checkIns, ci] };
      return evaluateCheckInAwards(next, ci);
    }
    case "checkin/undo":
      return { ...state, checkIns: state.checkIns.filter((c) => !(c.habitId === action.habitId && c.userId === me && c.date === action.date)) };
    case "checkin/update": {
      let next = updateCheckIn(state, action.id, (c) => ({
        ...c,
        note: action.note !== undefined ? cleanText(action.note) || undefined : c.note,
        photo: action.photo === null ? undefined : action.photo ?? c.photo,
      }));
      const ci = next.checkIns.find((c) => c.id === action.id);
      const h = ci && habitById(next, ci.habitId);
      if (ci?.note && h) next = award(next, "c-first-note", `Noted on ${h.name}`);
      if (ci?.photo && h) next = award(next, "c-first-photo", `Photo proof on ${h.name}`);
      return next;
    }
    case "checkin/react": {
      let next = updateCheckIn(state, action.id, (c) => {
        const mineIdx = c.reactions.findIndex((r) => r.userId === me);
        const existing = c.reactions[mineIdx];
        const without = c.reactions.filter((r) => r.userId !== me);
        if (existing && existing.kind === action.kind) return { ...c, reactions: without };
        return { ...c, reactions: [...without, { userId: me, kind: action.kind, at: nowTs() }] };
      });
      const sent = next.checkIns.reduce((n, c) => n + c.reactions.filter((r) => r.userId === me).length, 0);
      if (sent >= 25) next = award(next, "c-cheerleader", `${sent} reactions sent`, { reveal: false });
      return next;
    }
    case "checkin/comment": {
      const text = cleanText(action.text, 200);
      if (!text) return state;
      return updateCheckIn(state, action.id, (c) => ({ ...c, comments: [...c.comments, { id: uid("cm"), userId: me, text, at: nowTs() }] }));
    }

    /* ---------- Social ---------- */
    case "social/nudge": {
      const message = cleanText(action.message, 120);
      if (!message) return state;
      let next: AppState = { ...state, nudges: [{ id: uid("nd"), fromId: me, toId: action.toId, habitId: action.habitId, kind: action.kind, message, at: nowTs() }, ...state.nudges] };
      next = award(next, action.kind === "comeback" ? "c-comeback-cheer" : "c-nudger", action.kind === "comeback" ? `Celebrated ${state.users[action.toId]?.name.split(" ")[0]}'s comeback` : `Nudged ${state.users[action.toId]?.name.split(" ")[0]}`);
      return next;
    }
    case "social/gift": {
      const next: AppState = { ...state, gifts: [{ id: uid("gf"), fromId: me, toId: action.toId, kind: action.kind, itemId: action.itemId, message: cleanText(action.message, 120), at: nowTs(), opened: false }, ...state.gifts] };
      return award(next, "c-gifter", `Sent a gift to ${state.users[action.toId]?.name.split(" ")[0]}`);
    }
    case "social/openGift": {
      const gift = state.gifts.find((g) => g.id === action.id);
      if (!gift || gift.opened) return state;
      let next: AppState = { ...state, gifts: state.gifts.map((g) => (g.id === action.id ? { ...g, opened: true } : g)) };
      if (gift.kind === "cosmetic" && gift.itemId && !next.unlockedCosmetics.includes(gift.itemId)) next = { ...next, unlockedCosmetics: [...next.unlockedCosmetics, gift.itemId] };
      if (gift.kind === "sticker" && gift.itemId) next = award(next, gift.itemId, `Gift from ${state.users[gift.fromId]?.name.split(" ")[0]}`, { giftedBy: gift.fromId });
      return next;
    }
    case "friend/accept": {
      const req = state.friendRequests.find((r) => r.id === action.requestId);
      if (!req) return state;
      const next = { ...state, friendRequests: state.friendRequests.filter((r) => r.id !== action.requestId) };
      return reducer(next, { type: "friend/add", userId: req.fromId });
    }
    case "friend/decline":
      return { ...state, friendRequests: state.friendRequests.filter((r) => r.id !== action.requestId) };
    case "friend/add": {
      const u = state.users[action.userId];
      if (!u) return state;
      const meUser = state.users[me];
      return {
        ...state,
        users: {
          ...state.users,
          [me]: { ...meUser, friendIds: Array.from(new Set([...meUser.friendIds, action.userId])) },
          [action.userId]: { ...u, friendIds: Array.from(new Set([...u.friendIds, me])) },
        },
      };
    }
    case "friend/remove": {
      const meUser = state.users[me];
      return { ...state, users: { ...state.users, [me]: { ...meUser, friendIds: meUser.friendIds.filter((f) => f !== action.userId) } } };
    }
    case "contact/invite":
      return { ...state, contacts: state.contacts.map((c) => (c.id === action.contactId ? { ...c, detail: c.detail.includes("Invited") ? c.detail : `${c.detail} · Invited` } : c)) };

    /* ---------- Groups ---------- */
    case "group/create": {
      const g = { ...action.group, name: cleanText(action.group.name, 40), description: cleanText(action.group.description, 140), id: action.id ?? uid("g"), createdAt: nowTs(), createdBy: me, memberIds: Array.from(new Set([me, ...action.group.memberIds])) };
      return award({ ...state, groups: [g, ...state.groups] }, "c-first-group", `Started ${g.name}`);
    }
    case "group/update":
      return { ...state, groups: state.groups.map((g) => (g.id === action.id ? { ...g, ...action.patch, name: action.patch.name !== undefined ? cleanText(action.patch.name, 40) : g.name } : g)) };
    case "group/join": {
      const next = {
        ...state,
        groupInvites: state.groupInvites.filter((id) => id !== action.id),
        groups: state.groups.map((g) => (g.id === action.id ? { ...g, memberIds: Array.from(new Set([...g.memberIds, me])) } : g)),
      };
      return award(next, "c-first-group", `Joined ${state.groups.find((g) => g.id === action.id)?.name}`);
    }
    case "group/leave":
      return {
        ...state,
        groups: state.groups.map((g) => (g.id === action.id ? { ...g, memberIds: g.memberIds.filter((m) => m !== me) } : g)),
        challenges: state.challenges.map((c) => (c.groupId === action.id ? { ...c, participantIds: c.participantIds.filter((p) => p !== me) } : c)),
      };
    case "group/declineInvite":
      return { ...state, groupInvites: state.groupInvites.filter((id) => id !== action.id) };
    case "group/invite":
      return { ...state, groups: state.groups.map((g) => (g.id === action.id ? { ...g, memberIds: Array.from(new Set([...g.memberIds, ...action.userIds])) } : g)) };
    case "challenge/create": {
      const c = { ...action.challenge, title: cleanText(action.challenge.title, 60), description: cleanText(action.challenge.description, 160), id: action.id ?? uid("ch"), contributions: {}, milestoneReactions: {} };
      return { ...state, challenges: [c, ...state.challenges] };
    }
    case "challenge/join":
      return { ...state, challenges: state.challenges.map((c) => (c.id === action.id ? { ...c, participantIds: Array.from(new Set([...c.participantIds, me])) } : c)) };
    case "challenge/leave":
      return { ...state, challenges: state.challenges.map((c) => (c.id === action.id ? { ...c, participantIds: c.participantIds.filter((p) => p !== me) } : c)) };
    case "challenge/log": {
      const ch = state.challenges.find((c) => c.id === action.id);
      if (!ch) return state;
      const before = Object.values(ch.contributions).reduce((a, b) => a + b, 0);
      const amount = action.amount ?? 1;
      let next: AppState = {
        ...state,
        challenges: state.challenges.map((c) => (c.id === action.id ? { ...c, contributions: { ...c.contributions, [me]: Math.max(0, (c.contributions[me] ?? 0) + amount) } } : c)),
      };
      if (before < ch.goal && before + amount >= ch.goal) {
        next = notify(next, { kind: "group-goal", title: `${ch.title}: goal reached!`, body: `Your group hit ${ch.goal} ${ch.unit}. Everyone chipped in.`, href: `/groups/${ch.groupId}` });
        next = award(next, "c-group-goal", `Finished “${ch.title}” together`);
      }
      return next;
    }
    case "challenge/reactMilestone": {
      const key = String(action.milestone);
      let next: AppState = {
        ...state,
        challenges: state.challenges.map((c) => {
          if (c.id !== action.id) return c;
          const list = c.milestoneReactions[key] ?? [];
          return { ...c, milestoneReactions: { ...c.milestoneReactions, [key]: list.includes(me) ? list.filter((x) => x !== me) : [...list, me] } };
        }),
      };
      next = award(next, "c-milestone", "Toasted a group milestone", { reveal: false });
      return next;
    }
    case "prediction/vote":
      return { ...state, predictions: state.predictions.map((p) => (p.id === action.id && !p.winnerId ? { ...p, votes: { ...p.votes, [me]: action.pickId } } : p)) };
    case "prediction/create": {
      const question = cleanText(action.question, 100);
      if (!question) return state;
      return { ...state, predictions: [{ id: uid("pr"), question, optionIds: action.optionIds, groupId: action.groupId, votes: {}, closesAt: action.closesAt }, ...state.predictions] };
    }
    case "quiz/vote":
      return { ...state, quizzes: state.quizzes.map((q) => (q.id === action.id ? { ...q, votes: { ...q.votes, [me]: action.pickId } } : q)) };
    case "quiz/create": {
      const prompt = cleanText(action.prompt, 100);
      if (!prompt) return state;
      return { ...state, quizzes: [{ id: uid("q"), prompt, tag: `custom-${Date.now()}`, votes: {}, createdBy: me, createdAt: nowTs() }, ...state.quizzes] };
    }

    /* ---------- Collection ---------- */
    case "collection/favorite":
      return { ...state, collection: state.collection.map((c) => (c.collectibleId === action.id ? { ...c, favorite: !c.favorite } : c)) };
    case "collection/showcase": {
      const showcasedCount = state.collection.filter((c) => c.showcased).length;
      return {
        ...state,
        collection: state.collection.map((c) => {
          if (c.collectibleId !== action.id) return c;
          if (!c.showcased && showcasedCount >= 6) return c;
          return { ...c, showcased: !c.showcased };
        }),
      };
    }
    case "collection/seen":
      return { ...state, collection: state.collection.map((c) => (c.collectibleId === action.id ? { ...c, seen: true } : c)) };
    case "collection/award":
      return award(state, action.id, action.earnedFor);
    case "reveal/dismiss":
      return {
        ...state,
        collection: state.collection.map((c) => (c.collectibleId === state.pendingReveal ? { ...c, seen: true } : c)),
        pendingReveal: null,
      };
    case "cosmetic/unlock":
      return state.unlockedCosmetics.includes(action.id) ? state : { ...state, unlockedCosmetics: [...state.unlockedCosmetics, action.id] };

    /* ---------- Notifications ---------- */
    case "notification/read":
      return { ...state, notifications: state.notifications.map((n) => (n.id === action.id ? { ...n, read: true } : n)) };
    case "notification/readAll":
      return { ...state, notifications: state.notifications.map((n) => ({ ...n, read: true })) };
    case "notification/dismiss":
      return { ...state, notifications: state.notifications.filter((n) => n.id !== action.id) };
    case "notification/resolve":
      return { ...state, notifications: state.notifications.map((n) => (n.id === action.id ? { ...n, resolved: action.resolution, read: true } : n)) };
    case "notification/push":
      return notify(state, action.notification);

    /* ---------- Settings ---------- */
    case "settings/update":
      return { ...state, settings: { ...state.settings, ...action.patch } };
    case "settings/connection":
      return { ...state, settings: { ...state.settings, connected: { ...state.settings.connected, [action.service]: action.value } } };
    case "settings/block":
      return {
        ...state,
        settings: { ...state.settings, blockedIds: Array.from(new Set([...state.settings.blockedIds, action.userId])) },
        users: { ...state.users, [me]: { ...state.users[me], friendIds: state.users[me].friendIds.filter((f) => f !== action.userId) } },
      };
    case "settings/unblock":
      return { ...state, settings: { ...state.settings, blockedIds: state.settings.blockedIds.filter((b) => b !== action.userId) } };
    default: {
      const exhaustive: never = action;
      return exhaustive;
    }
  }
}
