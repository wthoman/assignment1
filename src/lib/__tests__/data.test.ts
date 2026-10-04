import { describe, expect, it } from "vitest";
import { createSeedState, ME } from "../data/seed";
import { addDays, startOfWeek, weekday } from "../dates";
import { buildRecap } from "../selectors/recap";
import { checkInFor, currentStreak, dayProgress, todayEntries } from "../selectors/habits";
import { consistencyScore, windowStats } from "../selectors/stats";
import { cleanText, reducer } from "../store/reducer";

const TODAY = "2026-10-04"; // a Sunday
const fresh = () => createSeedState(TODAY);

describe("dates", () => {
  it("computes week starts for Monday and Sunday weeks", () => {
    expect(weekday(TODAY)).toBe(0);
    expect(startOfWeek(TODAY, 1)).toBe("2026-09-28");
    expect(startOfWeek(TODAY, 0)).toBe("2026-10-04");
    expect(addDays("2026-02-28", 1)).toBe("2026-03-01");
  });
});

describe("seed data", () => {
  it("is deterministic and populated", () => {
    const a = fresh();
    const b = fresh();
    expect(a.checkIns.length).toBe(b.checkIns.length);
    expect(a.checkIns.length).toBeGreaterThan(300);
    expect(Object.keys(a.users).length).toBeGreaterThanOrEqual(8);
    expect(a.session.onboarded).toBe(false);
  });

  it("sorts today's habits into sections", () => {
    const s = fresh();
    const entries = todayEntries(s, TODAY);
    const sections = new Set(entries.map((e) => e.section));
    expect(sections.has("completed")).toBe(true);
    expect(sections.has("shared")).toBe(true);
    expect(sections.has("optional")).toBe(true);
    expect(entries.every((e) => e.habit.status === "active")).toBe(true);
  });
});

describe("check-ins", () => {
  it("completes and undoes a habit", () => {
    let s = fresh();
    const before = dayProgress(s, ME, TODAY);
    s = reducer(s, { type: "checkin/complete", habitId: "h-water", date: TODAY, time: "12:00" });
    expect(checkInFor(s, "h-water", ME, TODAY)).toBeDefined();
    expect(dayProgress(s, ME, TODAY).done).toBe(before.done + 1);
    s = reducer(s, { type: "checkin/undo", habitId: "h-water", date: TODAY });
    expect(checkInFor(s, "h-water", ME, TODAY)).toBeUndefined();
  });

  it("ignores duplicate completions", () => {
    let s = fresh();
    s = reducer(s, { type: "checkin/complete", habitId: "h-water", date: TODAY });
    const n = s.checkIns.length;
    s = reducer(s, { type: "checkin/complete", habitId: "h-water", date: TODAY });
    expect(s.checkIns.length).toBe(n);
  });

  it("reveals Full House when completing a shared habit last", () => {
    let s = fresh();
    s = reducer(s, { type: "checkin/complete", habitId: "h-walk", date: TODAY, time: "08:00" });
    expect(s.pendingReveal).toBe("c-full-house");
    expect(s.notifications[0].kind).toBe("award");
  });

  it("toggles a reaction", () => {
    let s = fresh();
    const target = s.checkIns.find((c) => c.userId === "u-maya" && c.date === TODAY)!;
    s = reducer(s, { type: "checkin/react", id: target.id, kind: "heart" });
    expect(s.checkIns.find((c) => c.id === target.id)!.reactions.some((r) => r.userId === ME && r.kind === "heart")).toBe(true);
    s = reducer(s, { type: "checkin/react", id: target.id, kind: "heart" });
    expect(s.checkIns.find((c) => c.id === target.id)!.reactions.some((r) => r.userId === ME)).toBe(false);
  });
});

describe("consistency", () => {
  it("is forgiving: a single extra miss barely moves the score", () => {
    const s = fresh();
    const score = consistencyScore(s, ME, TODAY);
    expect(score.score).toBeGreaterThan(0);
    expect(score.score).toBeLessThanOrEqual(100);
    expect(score.grace).toBeLessThanOrEqual(4);
    const yesterday = addDays(TODAY, -1);
    const done = s.checkIns.find((c) => c.userId === ME && c.date === yesterday)!;
    const s2 = reducer(s, { type: "checkin/undo", habitId: done.habitId, date: yesterday });
    expect(score.score - consistencyScore(s2, ME, TODAY).score).toBeLessThanOrEqual(4);
  });

  it("computes window stats and streaks", () => {
    const s = fresh();
    const w = windowStats(s, ME, addDays(TODAY, -6), TODAY);
    expect(w.scheduled).toBeGreaterThan(0);
    expect(w.rate).toBeGreaterThanOrEqual(0);
    const walk = s.habits.find((h) => h.id === "h-walk")!;
    expect(currentStreak(s, walk, ME, TODAY)).toBeGreaterThanOrEqual(0);
  });
});

describe("recap", () => {
  it("builds superlatives with sources from real data", () => {
    const r = buildRecap(fresh(), TODAY);
    expect(r.completed).toBeGreaterThan(0);
    expect(r.superlatives.length).toBeGreaterThanOrEqual(4);
    for (const s of r.superlatives) {
      expect(["behavior", "votes", "both"]).toContain(s.source);
      expect(s.explanation.length).toBeGreaterThan(10);
    }
    expect(r.rankings[0].rate).toBeGreaterThanOrEqual(r.rankings[r.rankings.length - 1].rate);
  });
});

describe("text safety", () => {
  it("strips control characters and trims length", () => {
    expect(cleanText("  hi\u0000 there  ")).toBe("hi there");
    expect(cleanText("x".repeat(400)).length).toBe(280);
  });
  it("keeps markup as inert text", () => {
    let s = fresh();
    s = reducer(s, { type: "profile/update", patch: { bio: "<img src=x onerror=alert(1)>" } });
    expect(s.users[ME].bio).toBe("<img src=x onerror=alert(1)>");
  });
});
