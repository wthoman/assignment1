import { BRAND } from "@/lib/brand";
import { WEEKDAY_SHORT, weekday } from "@/lib/dates";
import { habitsFor } from "@/lib/selectors/habits";
import type { AppState, ID } from "@/lib/types";

/**
 * The current user's own data, safe to hand them. Other people are reduced to
 * public handles; their check-ins, notes and private settings are never included.
 */
export function buildExportJSON(state: AppState) {
  const me = state.users[state.meId];
  const handle = (id: ID) => state.users[id]?.handle ?? "unknown";
  const habits = habitsFor(state, state.meId, { includeInactive: true });
  const habitIds = new Set(habits.map((h) => h.id));
  return {
    exportedAt: new Date().toISOString(),
    app: BRAND.name,
    format: "daybook-export/v1",
    profile: { name: me.name, handle: me.handle, pronouns: me.pronouns ?? null, bio: me.bio, joinedAt: me.joinedAt, avatar: me.avatar, personality: me.personality ?? null },
    account: state.session.account ? { email: state.session.account.email, method: state.session.account.method, createdAt: state.session.account.createdAt } : null,
    goals: state.session.goals,
    friends: me.friendIds.map(handle),
    habits: habits.map((h) => ({
      id: h.id,
      name: h.name,
      description: h.description,
      category: h.category,
      frequency: h.frequency,
      days: h.days,
      timesPerWeek: h.timesPerWeek,
      timeOfDay: h.timeOfDay,
      reminders: h.remindersOn ? h.reminderTimes : [],
      optional: h.optional,
      status: h.status,
      privacy: h.privacy,
      shared: h.shared,
      sharedWithCount: h.participantIds.filter((p) => p !== state.meId).length,
      ownedByMe: h.ownerId === state.meId,
      startDate: h.startDate,
      targetDate: h.targetDate ?? null,
    })),
    checkIns: state.checkIns
      .filter((c) => c.userId === state.meId && habitIds.has(c.habitId))
      .map((c) => ({ habitId: c.habitId, date: c.date, time: c.time, note: c.note ?? null, photoCaption: c.photo?.caption ?? null, reactionsReceived: c.reactions.length, commentsReceived: c.comments.length })),
    collection: state.collection.map((o) => ({ id: o.collectibleId, earnedAt: o.earnedAt, earnedFor: o.earnedFor, favorite: o.favorite, showcased: o.showcased })),
    groups: state.groups.filter((g) => g.memberIds.includes(state.meId)).map((g) => ({ id: g.id, name: g.name, memberCount: g.memberIds.length })),
    pastRecaps: state.pastRecaps,
    settings: { ...state.settings, blockedIds: state.settings.blockedIds.map(handle) },
  };
}

function csvCell(v: string | number | boolean | null | undefined): string {
  const s = v === null || v === undefined ? "" : String(v);
  // Neutralise spreadsheet formula injection and quote when needed.
  const safe = /^[=+\-@\t\r]/.test(s) ? `'${s}` : s;
  return /[",\n\r]/.test(safe) ? `"${safe.replace(/"/g, '""')}"` : safe;
}

/** One row per check-in for the chosen habit (or all of the user's habits). */
export function buildHistoryCSV(state: AppState, habitId: ID | "all"): string {
  const habits = habitsFor(state, state.meId, { includeInactive: true });
  const byId = Object.fromEntries(habits.map((h) => [h.id, h]));
  const rows = state.checkIns
    .filter((c) => c.userId === state.meId && byId[c.habitId] && (habitId === "all" || c.habitId === habitId))
    .sort((a, b) => a.date.localeCompare(b.date) || a.time.localeCompare(b.time));
  const header = ["date", "weekday", "habit", "category", "time", "note", "photo_caption", "reactions", "comments"];
  const lines = rows.map((c) => {
    const h = byId[c.habitId];
    return [c.date, WEEKDAY_SHORT[weekday(c.date)], h.name, h.category, c.time, c.note ?? "", c.photo?.caption ?? "", c.reactions.length, c.comments.length].map(csvCell).join(",");
  });
  return [header.join(","), ...lines].join("\r\n");
}

export function downloadBlob(filename: string, content: Blob | string, type = "application/octet-stream") {
  const blob = typeof content === "string" ? new Blob([content], { type }) : content;
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

export function downloadDataURL(filename: string, dataUrl: string) {
  const a = document.createElement("a");
  a.href = dataUrl;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
}

export function downloadMyData(state: AppState) {
  const stamp = new Date().toISOString().slice(0, 10);
  downloadBlob(`${BRAND.name.toLowerCase()}-data-${stamp}.json`, JSON.stringify(buildExportJSON(state), null, 2), "application/json");
}

/** Copies text, falling back to a hidden textarea + execCommand. Resolves false on failure. */
export async function copyText(text: string): Promise<boolean> {
  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text);
      return true;
    }
  } catch {
    /* fall through to the legacy path */
  }
  try {
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.setAttribute("readonly", "");
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.select();
    const ok = document.execCommand("copy");
    ta.remove();
    return ok;
  } catch {
    return false;
  }
}
