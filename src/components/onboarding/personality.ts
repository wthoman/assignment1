import type { PersonalityKey, Settings } from "@/lib/types";

/** Stable order used as the final tie-breaker, so scoring is fully deterministic. */
export const PERSONALITY_ORDER: PersonalityKey[] = ["gentle-builder", "social-motivator", "deadline-sprinter", "quiet-perfectionist", "variety-seeker"];

type Weights = Partial<Record<PersonalityKey, number>>;

export interface QuizOption {
  id: string;
  label: string;
  weights: Weights;
}

export interface QuizQuestion {
  id: string;
  prompt: string;
  /** Short handwritten aside shown under the question. */
  aside: string;
  options: QuizOption[];
}

export const QUIZ_QUESTIONS: QuizQuestion[] = [
  {
    id: "walk",
    prompt: "A friend texts “walk?” at 7am. You…",
    aside: "be honest, nobody's watching",
    options: [
      { id: "yes", label: "Already lacing up. Company makes it easy.", weights: { "social-motivator": 3, "variety-seeker": 1 } },
      { id: "later", label: "Counter-offer: a short one after lunch.", weights: { "gentle-builder": 2, "variety-seeker": 1 } },
      { id: "solo", label: "I walked at 6:30. Alone. With a podcast.", weights: { "quiet-perfectionist": 2, "gentle-builder": 1 } },
      { id: "snooze", label: "Snooze. Text back at 10 with big plans for tomorrow.", weights: { "deadline-sprinter": 3 } },
    ],
  },
  {
    id: "missed",
    prompt: "You missed two days in a row. You…",
    aside: "it happens to everyone",
    options: [
      { id: "shrug", label: "Shrug and do a tiny version today.", weights: { "gentle-builder": 3 } },
      { id: "reset", label: "Feel weirdly bad about it and want to start over.", weights: { "quiet-perfectionist": 3 } },
      { id: "friend", label: "Ask a friend to keep me honest this week.", weights: { "social-motivator": 3 } },
      { id: "double", label: "Plan a big catch-up session on Sunday.", weights: { "deadline-sprinter": 2, "quiet-perfectionist": 1 } },
      { id: "swap", label: "Swap it for something that sounds more fun.", weights: { "variety-seeker": 3 } },
    ],
  },
  {
    id: "reminder",
    prompt: "Your ideal reminder is…",
    aside: "pick the one you wouldn't swipe away",
    options: [
      { id: "soft", label: "A soft nudge at the same time every day.", weights: { "gentle-builder": 2, "quiet-perfectionist": 1 } },
      { id: "friend", label: "A message from an actual friend.", weights: { "social-motivator": 3 } },
      { id: "countdown", label: "“3 hours left today.” A little urgency.", weights: { "deadline-sprinter": 3 } },
      { id: "surprise", label: "Something different each time, so I notice it.", weights: { "variety-seeker": 3 } },
    ],
  },
  {
    id: "deadline",
    prompt: "When a goal has a deadline…",
    aside: "like a race, an exam, a trip",
    options: [
      { id: "fuel", label: "Finally, I can focus. Deadlines are fuel.", weights: { "deadline-sprinter": 3 } },
      { id: "plan", label: "I build a careful plan and follow it.", weights: { "quiet-perfectionist": 3 } },
      { id: "group", label: "I recruit people to do it with me.", weights: { "social-motivator": 2, "deadline-sprinter": 1 } },
      { id: "ignore", label: "I'd rather take it slow and skip the pressure.", weights: { "gentle-builder": 3 } },
    ],
  },
  {
    id: "routine",
    prompt: "The same routine every day sounds…",
    aside: "breakfast counts as a routine",
    options: [
      { id: "cozy", label: "Cozy. Predictable is nice.", weights: { "gentle-builder": 2, "quiet-perfectionist": 1 } },
      { id: "ideal", label: "Ideal, if every detail is right.", weights: { "quiet-perfectionist": 3 } },
      { id: "boring", label: "Boring by Wednesday.", weights: { "variety-seeker": 3 } },
      { id: "shared", label: "Fine, as long as someone's in it with me.", weights: { "social-motivator": 2, "gentle-builder": 1 } },
    ],
  },
];

/** question id -> option id */
export type QuizAnswers = Record<string, string>;

/** How strongly each goal hints at a personality. Only used to break ties. */
const GOAL_AFFINITY: Record<string, Weights> = {
  move: { "variety-seeker": 1, "social-motivator": 1 },
  sleep: { "gentle-builder": 1 },
  read: { "quiet-perfectionist": 1 },
  hydrate: { "gentle-builder": 1 },
  focus: { "deadline-sprinter": 2 },
  calm: { "gentle-builder": 2 },
  eat: { "variety-seeker": 1 },
  outside: { "variety-seeker": 2 },
  strength: { "deadline-sprinter": 1 },
  create: { "variety-seeker": 1, "quiet-perfectionist": 1 },
  mornings: { "quiet-perfectionist": 1, "gentle-builder": 1 },
  friends: { "social-motivator": 2 },
};

function emptyScores(): Record<PersonalityKey, number> {
  return { "gentle-builder": 0, "deadline-sprinter": 0, "social-motivator": 0, "quiet-perfectionist": 0, "variety-seeker": 0 };
}

/** Sums weighted points for every answered question. Unknown ids are ignored. */
export function personalityScores(answers: QuizAnswers): Record<PersonalityKey, number> {
  const scores = emptyScores();
  for (const q of QUIZ_QUESTIONS) {
    const opt = q.options.find((o) => o.id === answers[q.id]);
    if (!opt) continue;
    for (const [key, pts] of Object.entries(opt.weights) as [PersonalityKey, number][]) scores[key] += pts;
  }
  return scores;
}

/**
 * Picks the personality with the most points. Ties are broken first by how well
 * the chosen goals fit each tied personality, then by PERSONALITY_ORDER.
 */
export function scorePersonality(answers: QuizAnswers, goals: string[] = []): PersonalityKey {
  const scores = personalityScores(answers);
  const top = Math.max(...Object.values(scores));
  const tied = PERSONALITY_ORDER.filter((k) => scores[k] === top);
  if (tied.length === 1) return tied[0];
  const affinity = emptyScores();
  for (const g of goals) for (const [key, pts] of Object.entries(GOAL_AFFINITY[g] ?? {}) as [PersonalityKey, number][]) affinity[key] += pts;
  // `tied` is already in PERSONALITY_ORDER, so a stable "first max" keeps the final fallback.
  return tied.reduce((best, k) => (affinity[k] > affinity[best] ? k : best), tied[0]);
}

/** Settings applied by "Use these settings" on the result screen. */
export const PERSONALITY_SETTINGS: Record<PersonalityKey, Partial<Settings>> = {
  "gentle-builder": { encouragement: "gentle", showStreaks: false, allowFriendReminders: true },
  "deadline-sprinter": { encouragement: "coach", showStreaks: true, allowFriendReminders: true },
  "social-motivator": { encouragement: "cheeky", showStreaks: true, allowFriendReminders: true, recapVisibility: "friends", activityInFeed: true },
  "quiet-perfectionist": { encouragement: "gentle", showStreaks: false, allowFriendReminders: false, recapVisibility: "private" },
  "variety-seeker": { encouragement: "cheeky", showStreaks: true, allowFriendReminders: true },
};

const ENCOURAGEMENT_LABEL: Record<Settings["encouragement"], string> = { gentle: "Gentle encouragement", cheeky: "Cheeky encouragement", coach: "Coach-style encouragement" };

/** Human-readable list of what PERSONALITY_SETTINGS will change. */
export function describeSettings(patch: Partial<Settings>): string[] {
  const out: string[] = [];
  if (patch.encouragement) out.push(ENCOURAGEMENT_LABEL[patch.encouragement]);
  if (patch.showStreaks !== undefined) out.push(patch.showStreaks ? "Streaks visible" : "Streaks hidden");
  if (patch.allowFriendReminders !== undefined) out.push(patch.allowFriendReminders ? "Friends can nudge you" : "No friend nudges");
  if (patch.recapVisibility) out.push(patch.recapVisibility === "private" ? "Weekly recap kept private" : "Weekly recap shared with friends");
  return out;
}
