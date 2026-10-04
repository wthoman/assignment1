import { describe, expect, it } from "vitest";
import { PERSONALITIES } from "@/lib/data/catalog";
import { buildHabitDraft, parseSchedule } from "./habitDraft";
import { personalityScores, QUIZ_QUESTIONS, scorePersonality, type QuizAnswers } from "./personality";

const pick = (ids: string[]): QuizAnswers => Object.fromEntries(QUIZ_QUESTIONS.map((q, i) => [q.id, ids[i]]));

describe("scorePersonality", () => {
  it("has five questions with three to five options each", () => {
    expect(QUIZ_QUESTIONS).toHaveLength(5);
    for (const q of QUIZ_QUESTIONS) {
      expect(q.options.length).toBeGreaterThanOrEqual(3);
      expect(q.options.length).toBeLessThanOrEqual(5);
    }
  });

  it("picks the clear winner for consistent answers", () => {
    expect(scorePersonality(pick(["yes", "friend", "friend", "group", "shared"]))).toBe("social-motivator");
    expect(scorePersonality(pick(["snooze", "double", "countdown", "fuel", "boring"]))).toBe("deadline-sprinter");
    expect(scorePersonality(pick(["solo", "reset", "soft", "plan", "ideal"]))).toBe("quiet-perfectionist");
    expect(scorePersonality(pick(["later", "swap", "surprise", "group", "boring"]))).toBe("variety-seeker");
    expect(scorePersonality(pick(["later", "shrug", "soft", "ignore", "cozy"]))).toBe("gentle-builder");
  });

  it("is deterministic", () => {
    const a = pick(["yes", "reset", "countdown", "ignore", "boring"]);
    expect(scorePersonality(a, ["move"])).toBe(scorePersonality(a, ["move"]));
  });

  it("breaks ties using goals, then a fixed order", () => {
    // social-motivator 3 vs deadline-sprinter 3
    const tie: QuizAnswers = { walk: "yes", reminder: "countdown" };
    const s = personalityScores(tie);
    expect(s["social-motivator"]).toBe(s["deadline-sprinter"]);
    expect(scorePersonality(tie, ["focus"])).toBe("deadline-sprinter");
    expect(scorePersonality(tie, ["friends"])).toBe("social-motivator");
    // No goals: fixed order puts social-motivator before deadline-sprinter.
    expect(scorePersonality(tie)).toBe("social-motivator");
  });

  it("falls back gracefully with no answers", () => {
    expect(scorePersonality({})).toBe("gentle-builder");
    expect(scorePersonality({}, ["outside"])).toBe("variety-seeker");
  });
});

describe("first-habit helpers", () => {
  it("parses every catalog schedule into a quick preset", () => {
    for (const p of Object.values(PERSONALITIES)) for (const h of p.habits) expect(parseSchedule(h.schedule).frequency).toMatch(/daily|weekdays|weekends|three-per-week/);
    expect(parseSchedule("Weekdays · evening")).toEqual({ frequency: "weekdays", timeOfDay: "evening" });
    expect(parseSchedule("3× per week")).toEqual({ frequency: "three-per-week", timeOfDay: "anytime" });
  });

  it("builds a complete draft", () => {
    const d = buildHabitDraft({ name: "  Read 5 pages ", icon: "book", frequency: "weekends", timeOfDay: "evening", remindersOn: true, reminderTime: "20:00" }, "2026-10-04");
    expect(d).toMatchObject({ name: "Read 5 pages", category: "study", tint: "gold", days: [0, 6], timesPerWeek: 2, reminderTimes: ["20:00"], privacy: "friends", proof: "optional", shared: false });
  });
});
