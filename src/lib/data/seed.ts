import { addDays, rangeDates, stamp, weekday } from "../dates";
import { mulberry32 } from "../random";
import type {
  AppNotification,
  AppState,
  AvatarConfig,
  Challenge,
  CheckIn,
  Comment,
  Contact,
  Gift,
  Group,
  Habit,
  ISODate,
  Nudge,
  OwnedCollectible,
  PastRecap,
  Prediction,
  QuizQuestion,
  Reaction,
  ReactionKind,
  Settings,
  User,
} from "../types";

export const STATE_VERSION = 3;
export const ME = "u-me";

const avatar = (a: Partial<AvatarConfig>): AvatarConfig => ({
  head: "round",
  skin: "#EBC09C",
  hair: "bob",
  hairColor: "#271C1B",
  eyes: "dot",
  mouth: "smile",
  cheeks: true,
  outfit: "tee",
  outfitColor: "#6F1725",
  accessory: "none",
  background: "cream",
  frame: "none",
  companion: "none",
  ...a,
});

function buildUsers(today: ISODate): Record<string, User> {
  const joined = addDays(today, -140);
  const list: User[] = [
    {
      id: ME,
      name: "Riley",
      handle: "riley",
      pronouns: "they/them",
      bio: "Trying to walk more and doomscroll less.",
      avatar: avatar({ hair: "curly", hairColor: "#5B3424", skin: "#D29F76", outfit: "sweater", outfitColor: "#6F1725", background: "rose", companion: "sprout" }),
      friendIds: ["u-maya", "u-jonah", "u-priya", "u-theo", "u-sam", "u-lucia"],
      joinedAt: joined,
    },
    { id: "u-maya", name: "Maya Okafor", handle: "mayawalks", pronouns: "she/her", bio: "6am walker. Will send you a sunrise photo whether you asked or not.", avatar: avatar({ hair: "bun", skin: "#8A5A3B", outfit: "hoodie", outfitColor: "#8FA382", background: "sage", accessory: "headphones", eyes: "happy" }), personality: "social-motivator", friendIds: [ME, "u-jonah", "u-priya", "u-sam"], joinedAt: addDays(today, -300) },
    { id: "u-jonah", name: "Jonah Lee", handle: "jonahreads", pronouns: "he/him", bio: "Reading 30 books this year. Currently on 19. Don't ask about 20.", avatar: avatar({ hair: "swoop", skin: "#F6D5B8", outfit: "stripe", outfitColor: "#A9C3D4", accessory: "glasses", background: "sky", mouth: "grin" }), personality: "deadline-sprinter", friendIds: [ME, "u-maya", "u-theo"], joinedAt: addDays(today, -210) },
    { id: "u-priya", name: "Priya Raman", handle: "priya.r", pronouns: "she/her", bio: "Strength training + studying for the bar. Send snacks.", avatar: avatar({ hair: "long", skin: "#B07B53", outfit: "tee", outfitColor: "#E09A5F", background: "gold", eyes: "wink" }), personality: "quiet-perfectionist", friendIds: [ME, "u-maya", "u-lucia"], joinedAt: addDays(today, -180) },
    { id: "u-theo", name: "Theo Martins", handle: "theom", pronouns: "he/him", bio: "Comeback specialist. Hydration enthusiast (aspiring).", avatar: avatar({ hair: "buzz", skin: "#EBC09C", outfit: "overalls", outfitColor: "#C9A24A", accessory: "cap", background: "orange", mouth: "grin" }), personality: "variety-seeker", friendIds: [ME, "u-jonah"], joinedAt: addDays(today, -95) },
    { id: "u-sam", name: "Sam Whitaker", handle: "samw", pronouns: "they/them", bio: "Sleep schedule: under construction.", avatar: avatar({ hair: "none", skin: "#5E3B27", outfit: "hoodie", outfitColor: "#D9A3A0", accessory: "beanie", background: "rose", eyes: "sleepy" }), personality: "gentle-builder", friendIds: [ME, "u-maya"], joinedAt: addDays(today, -60) },
    { id: "u-lucia", name: "Lucía Fernández", handle: "luciaf", pronouns: "she/her", bio: "Plants, pilates, and pretending I like mornings.", avatar: avatar({ hair: "bob", hairColor: "#B4473A", skin: "#F6D5B8", outfit: "sweater", outfitColor: "#8FA382", accessory: "flower", background: "sage" }), personality: "gentle-builder", friendIds: [ME, "u-priya"], joinedAt: addDays(today, -120) },
    { id: "u-dev", name: "Dev Patel", handle: "devp", pronouns: "he/him", bio: "Climbing, coffee, and very long playlists.", avatar: avatar({ hair: "curly", hairColor: "#271C1B", skin: "#B07B53", outfit: "tee", outfitColor: "#A9C3D4", background: "sky" }), friendIds: ["u-jonah"], joinedAt: addDays(today, -40) },
    { id: "u-noor", name: "Noor Haddad", handle: "noorh", pronouns: "she/her", bio: "Marathon training, slowly.", avatar: avatar({ hair: "long", hairColor: "#5B3424", skin: "#D29F76", outfit: "hoodie", outfitColor: "#6F1725", background: "orange", accessory: "bandana" }), friendIds: ["u-maya"], joinedAt: addDays(today, -30) },
  ];
  return Object.fromEntries(list.map((u) => [u.id, u]));
}

type HabitSeed = Omit<Habit, "createdAt" | "startDate" | "status" | "privacy" | "proof" | "notesEnabled" | "showStreak" | "remindersOn" | "timesPerWeek" | "optional" | "shared" | "participantIds" | "description"> &
  Partial<Habit> & { ageDays: number };

function buildHabits(today: ISODate): Habit[] {
  const ALL = [0, 1, 2, 3, 4, 5, 6];
  const WEEKDAYS = [1, 2, 3, 4, 5];
  const seeds: HabitSeed[] = [
    { id: "h-walk", ownerId: ME, name: "Morning walk", description: "Around the block, or further if the sun's out.", icon: "shoe", category: "movement", tint: "orange", frequency: "daily", days: ALL, timeOfDay: "morning", reminderTimes: ["07:30"], shared: true, participantIds: [ME, "u-maya"], proof: "optional", ageDays: 70 },
    { id: "h-water", ownerId: ME, name: "Six glasses of water", description: "Refill the big bottle twice.", icon: "water", category: "hydration", tint: "sky", frequency: "daily", days: ALL, timeOfDay: "anytime", reminderTimes: ["11:00", "15:00"], ageDays: 60 },
    { id: "h-read", ownerId: "u-jonah", name: "Read 20 pages", description: "Book club pick: The Remains of the Day.", icon: "book", category: "study", tint: "gold", frequency: "weekdays", days: WEEKDAYS, timeOfDay: "evening", reminderTimes: ["21:00"], shared: true, participantIds: ["u-jonah", ME, "u-priya"], ageDays: 45 },
    { id: "h-wake", ownerId: ME, name: "Up by 7:30", description: "Feet on the floor, phone across the room.", icon: "alarm", category: "sleep", tint: "rose", frequency: "weekdays", days: WEEKDAYS, timeOfDay: "morning", reminderTimes: ["07:25"], ageDays: 56 },
    { id: "h-strength", ownerId: ME, name: "Strength session", description: "20 minutes. Bodyweight counts.", icon: "dumbbell", category: "movement", tint: "burgundy", frequency: "three-per-week", days: [1, 3, 5], timesPerWeek: 3, timeOfDay: "afternoon", reminderTimes: ["17:30"], ageDays: 40 },
    { id: "h-lights", ownerId: ME, name: "Lights out by 11", description: "Book instead of phone for the last 20 minutes.", icon: "moon", category: "sleep", tint: "sky", frequency: "daily", days: ALL, timeOfDay: "evening", reminderTimes: ["22:30"], showStreak: false, ageDays: 35 },
    { id: "h-plants", ownerId: ME, name: "Water the plants", description: "Fern is dramatic. Check her first.", icon: "flower", category: "home", tint: "sage", frequency: "custom", days: [0, 3], timeOfDay: "anytime", reminderTimes: [], optional: true, remindersOn: false, ageDays: 50 },
    { id: "h-journal", ownerId: ME, name: "Journal three lines", description: "What happened, how it felt, one good thing.", icon: "pencil", category: "creative", tint: "rose", frequency: "daily", days: ALL, timeOfDay: "evening", reminderTimes: ["22:00"], optional: true, privacy: "private", ageDays: 28 },
    { id: "h-fruit", ownerId: ME, name: "A piece of fruit", description: "Pears count double. (They don't.)", icon: "fruit", category: "nourish", tint: "sage", frequency: "daily", days: ALL, timeOfDay: "anytime", reminderTimes: [], optional: true, remindersOn: false, ageDays: 21 },
    { id: "h-guitar", ownerId: ME, name: "Guitar practice", description: "Paused until the new strings arrive.", icon: "music", category: "creative", tint: "gold", frequency: "three-per-week", days: [2, 4, 6], timesPerWeek: 3, timeOfDay: "evening", reminderTimes: [], status: "paused", ageDays: 90 },
    // Friends' own habits (for the feed)
    { id: "h-maya-yoga", ownerId: "u-maya", name: "Sunrise stretch", description: "", icon: "sun", category: "mind", tint: "gold", frequency: "daily", days: ALL, timeOfDay: "morning", reminderTimes: [], ageDays: 120 },
    { id: "h-priya-study", ownerId: "u-priya", name: "Bar prep block", description: "", icon: "pencil", category: "study", tint: "gold", frequency: "weekdays", days: WEEKDAYS, timeOfDay: "afternoon", reminderTimes: [], ageDays: 80 },
    { id: "h-priya-lift", ownerId: "u-priya", name: "Lift", description: "", icon: "dumbbell", category: "movement", tint: "burgundy", frequency: "three-per-week", days: [1, 3, 5], timesPerWeek: 3, timeOfDay: "morning", reminderTimes: [], ageDays: 80 },
    { id: "h-theo-water", ownerId: "u-theo", name: "Drink water (seriously)", description: "", icon: "water", category: "hydration", tint: "sky", frequency: "daily", days: ALL, timeOfDay: "anytime", reminderTimes: [], groupId: "g-hydro", ageDays: 50 },
    { id: "h-theo-outside", ownerId: "u-theo", name: "Something outside", description: "", icon: "leaf", category: "outdoors", tint: "sage", frequency: "three-per-week", days: [0, 3, 6], timesPerWeek: 3, timeOfDay: "afternoon", reminderTimes: [], ageDays: 50 },
    { id: "h-sam-sleep", ownerId: "u-sam", name: "In bed by midnight", description: "", icon: "moon", category: "sleep", tint: "sky", frequency: "daily", days: ALL, timeOfDay: "evening", reminderTimes: [], ageDays: 40 },
    { id: "h-lucia-plants", ownerId: "u-lucia", name: "Pilates", description: "", icon: "flower", category: "movement", tint: "rose", frequency: "three-per-week", days: [2, 4, 6], timesPerWeek: 3, timeOfDay: "morning", reminderTimes: [], ageDays: 70 },
    { id: "h-jonah-run", ownerId: "u-jonah", name: "Run club", description: "", icon: "shoe", category: "movement", tint: "orange", frequency: "custom", days: [2, 6], timeOfDay: "morning", reminderTimes: [], ageDays: 60 },
  ];
  return seeds.map(({ ageDays, ...h }) => ({
    timesPerWeek: 7,
    optional: false,
    shared: false,
    participantIds: [h.ownerId],
    privacy: h.shared ? "friends" : "friends",
    proof: "optional",
    notesEnabled: true,
    showStreak: true,
    remindersOn: true,
    status: "active",
    ...h,
    description: h.description ?? "",
    startDate: addDays(today, -ageDays),
    createdAt: stamp(addDays(today, -ageDays), "09:00"),
  })) as Habit[];
}

/** Per-person completion personality used to generate believable history. */
const PROFILES: Record<string, { base: number; lateNight: number; weekendBoost: number; slumpWeek?: number }> = {
  [ME]: { base: 0.74, lateNight: 0.15, weekendBoost: -0.05, slumpWeek: 3 },
  "u-maya": { base: 0.9, lateNight: 0.02, weekendBoost: 0.05 },
  "u-jonah": { base: 0.72, lateNight: 0.55, weekendBoost: -0.1 },
  "u-priya": { base: 0.86, lateNight: 0.1, weekendBoost: 0 },
  "u-theo": { base: 0.62, lateNight: 0.2, weekendBoost: 0.2, slumpWeek: 2 },
  "u-sam": { base: 0.58, lateNight: 0.6, weekendBoost: 0.1, slumpWeek: 1 },
  "u-lucia": { base: 0.8, lateNight: 0.05, weekendBoost: 0.15 },
};

const NOTES = [
  "Felt slow but did it anyway.",
  "Took the long way past the bakery.",
  "Easier than yesterday.",
  "Raining. Still counts.",
  "Did it with a podcast on, 10/10.",
  "Short one today, but I showed up.",
  "Brought a friend along!",
];

const COMMENTS = [
  "Look at you go",
  "This is the energy I needed today",
  "Okay, that view though",
  "Proud of you!",
  "Saving this as motivation",
  "Same time tomorrow?",
  "Back at it, love to see it",
];

const PHOTO_CAPTIONS: Record<string, string> = {
  shoe: "Park loop at golden hour",
  water: "Bottle #2, refilled",
  book: "Chapter 7 done",
  dumbbell: "Living room gym",
  flower: "Fern is thriving",
  sun: "Sunrise from the bridge",
  leaf: "Trail behind the library",
  fruit: "Pear supremacy",
};

const REACTION_KINDS: ReactionKind[] = ["cheer", "fire", "clap", "heart", "wow"];

function scheduledOn(h: Habit, date: ISODate) {
  return h.days.includes(weekday(date));
}

function buildCheckIns(today: ISODate, habits: Habit[], users: Record<string, User>): CheckIn[] {
  const rand = mulberry32(20241004);
  const out: CheckIn[] = [];
  let n = 0;
  for (const h of habits) {
    if (h.status === "archived") continue;
    for (const userId of h.participantIds) {
      const p = PROFILES[userId] ?? { base: 0.7, lateNight: 0.1, weekendBoost: 0 };
      const end = h.status === "paused" ? addDays(today, -12) : addDays(today, -1);
      for (const date of rangeDates(h.startDate, end)) {
        if (!scheduledOn(h, date)) continue;
        const wd = weekday(date);
        const weeksAgo = Math.floor((Date.parse(today) - Date.parse(date)) / (7 * 86_400_000));
        let chance = p.base + (wd === 0 || wd === 6 ? p.weekendBoost : 0);
        if (p.slumpWeek !== undefined && weeksAgo === p.slumpWeek) chance -= 0.45;
        // Recent weeks trend a little better: improvement is part of the story.
        chance += Math.max(0, 3 - weeksAgo) * 0.03;
        if (h.optional) chance -= 0.25;
        if (rand() > chance) continue;

        const late = rand() < p.lateNight;
        const base = h.timeOfDay === "morning" ? 7 : h.timeOfDay === "afternoon" ? 14 : h.timeOfDay === "evening" ? 20 : 10 + Math.floor(rand() * 8);
        const hour = late ? 22 + Math.floor(rand() * 2) : base + Math.floor(rand() * 2);
        const minute = late && rand() < 0.3 ? 50 + Math.floor(rand() * 9) : Math.floor(rand() * 60);
        const time = `${String(Math.min(hour, 23)).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;

        const recent = weeksAgo < 2;
        const reactions: Reaction[] = [];
        const comments: Comment[] = [];
        if (recent) {
          const friends = (users[userId]?.friendIds ?? []).filter((f) => users[f]);
          for (const f of friends) {
            if (rand() < 0.28) reactions.push({ userId: f, kind: REACTION_KINDS[Math.floor(rand() * REACTION_KINDS.length)], at: stamp(date, time) });
          }
          if (rand() < 0.12 && friends.length) {
            comments.push({ id: `cm-${n}`, userId: friends[Math.floor(rand() * friends.length)], text: COMMENTS[Math.floor(rand() * COMMENTS.length)], at: stamp(date, time) });
          }
        }
        const withPhoto = recent && h.proof !== "off" && rand() < 0.18;
        const withNote = recent && h.notesEnabled && rand() < 0.2;
        out.push({
          id: `ci-${n++}`,
          habitId: h.id,
          userId,
          date,
          time,
          note: withNote ? NOTES[Math.floor(rand() * NOTES.length)] : undefined,
          photo: withPhoto ? { id: `ph-${n}`, caption: PHOTO_CAPTIONS[h.icon] ?? "Proof!", motif: h.icon, tint: h.tint } : undefined,
          reactions,
          comments,
        });
      }
    }
  }

  // Today: a believable half-finished day.
  const todayDone: [string, string, string][] = [
    ["h-wake", ME, "07:21"],
    ["h-fruit", ME, "08:30"],
    ["h-walk", "u-maya", "06:58"],
    ["h-maya-yoga", "u-maya", "06:30"],
    ["h-priya-lift", "u-priya", "08:15"],
    ["h-theo-water", "u-theo", "10:05"],
    ["h-lucia-plants", "u-lucia", "09:10"],
    ["h-read", "u-jonah", "08:40"],
    ["h-read", "u-priya", "09:05"],
  ];
  for (const [habitId, userId, time] of todayDone) {
    const h = habits.find((x) => x.id === habitId);
    if (!h || !scheduledOn(h, today)) continue;
    out.push({
      id: `ci-${n++}`,
      habitId,
      userId,
      date: today,
      time,
      note: habitId === "h-fruit" && userId === ME ? "Pear, obviously." : undefined,
      photo: habitId === "h-walk" && userId === "u-maya" ? { id: "ph-today", caption: "Fog on the reservoir", motif: "sun", tint: "gold" } : undefined,
      reactions:
        userId === "u-maya"
          ? [{ userId: "u-sam", kind: "heart", at: stamp(today, "07:10") }]
          : userId === ME && habitId === "h-wake"
            ? [{ userId: "u-maya", kind: "fire", at: stamp(today, "07:50") }, { userId: "u-lucia", kind: "clap", at: stamp(today, "08:02") }]
            : [],
      comments: userId === "u-maya" ? [{ id: "cm-today", userId: "u-jonah", text: "How are you this awake", at: stamp(today, "07:30") }] : [],
    });
  }
  return out;
}

function buildGroups(today: ISODate): { groups: Group[]; challenges: Challenge[]; predictions: Prediction[] } {
  const groups: Group[] = [
    { id: "g-hydro", name: "Hydration Station", description: "Five friends, many water bottles, zero excuses.", icon: "water", tint: "sky", memberIds: [ME, "u-theo", "u-maya", "u-sam", "u-jonah"], createdBy: "u-theo", createdAt: stamp(addDays(today, -50), "12:00"), notify: "all" },
    { id: "g-study", name: "Library Goblins", description: "Quiet hours, loud progress. Bar prep + book club.", icon: "book", tint: "gold", memberIds: [ME, "u-priya", "u-jonah", "u-lucia"], createdBy: "u-priya", createdAt: stamp(addDays(today, -35), "12:00"), notify: "milestones" },
    { id: "g-outside", name: "Touch Grass Club", description: "One outdoor thing a day. Puddles count.", icon: "leaf", tint: "sage", memberIds: ["u-maya", "u-lucia", "u-noor", "u-theo"], createdBy: "u-lucia", createdAt: stamp(addDays(today, -20), "12:00"), notify: "all" },
  ];
  const weekStart = addDays(today, -((weekday(today) + 6) % 7));
  const challenges: Challenge[] = [
    { id: "ch-water", groupId: "g-hydro", title: "Water five days this week", description: "Everyone aims for five hydrated days. We count them together.", icon: "water", unit: "hydrated days", goal: 25, startDate: weekStart, endDate: addDays(weekStart, 6), participantIds: [ME, "u-theo", "u-maya", "u-sam", "u-jonah"], contributions: { [ME]: 4, "u-theo": 5, "u-maya": 5, "u-sam": 2, "u-jonah": 3 }, milestoneReactions: { "25": ["u-theo", "u-maya"], "50": ["u-theo", "u-maya", "u-sam", ME], "75": ["u-maya"] } },
    { id: "ch-study", groupId: "g-study", title: "40 study sessions", description: "Bar prep, book club pages, problem sets — every focused block counts.", icon: "pencil", unit: "sessions", goal: 40, startDate: addDays(today, -10), endDate: addDays(today, 4), participantIds: [ME, "u-priya", "u-jonah", "u-lucia"], contributions: { [ME]: 7, "u-priya": 12, "u-jonah": 6, "u-lucia": 4 }, milestoneReactions: { "25": ["u-priya", "u-jonah"], "50": ["u-priya"] } },
    { id: "ch-reading", groupId: "g-study", title: "20 reading sessions", description: "Shared book club pages. Finish the novel by Friday.", icon: "book", unit: "sessions", goal: 20, startDate: addDays(today, -6), endDate: addDays(today, 3), participantIds: [ME, "u-jonah", "u-priya"], contributions: { [ME]: 4, "u-jonah": 6, "u-priya": 4 }, milestoneReactions: { "25": ["u-jonah"], "50": [] } },
    { id: "ch-outside", groupId: "g-outside", title: "One outdoor thing a day", description: "Walk, garden, bike, sit in a park. Seven days.", icon: "leaf", unit: "outdoor days", goal: 28, startDate: weekStart, endDate: addDays(weekStart, 6), participantIds: ["u-maya", "u-lucia", "u-noor", "u-theo"], contributions: { "u-maya": 6, "u-lucia": 5, "u-noor": 4, "u-theo": 3 }, milestoneReactions: { "25": ["u-lucia"], "50": ["u-maya"] } },
  ];
  const predictions: Prediction[] = [
    { id: "pr-1", groupId: "g-hydro", question: "Who'll hit five water days first?", optionIds: ["u-theo", "u-maya", ME, "u-sam"], votes: { "u-theo": "u-maya", "u-sam": "u-maya", "u-jonah": "u-theo" }, closesAt: addDays(weekStart, 6) },
    { id: "pr-2", groupId: "g-study", question: "Who finishes the book club novel first?", optionIds: ["u-jonah", "u-priya", ME], votes: { "u-priya": "u-jonah", "u-lucia": "u-priya", [ME]: "u-jonah" }, closesAt: addDays(today, 3) },
    { id: "pr-3", question: "Who logs the most walks this week?", optionIds: ["u-maya", ME, "u-noor"], votes: { "u-maya": "u-noor", "u-theo": "u-maya", [ME]: "u-maya", "u-sam": "u-maya" }, closesAt: addDays(today, -1), winnerId: "u-maya" },
  ];
  return { groups, challenges, predictions };
}

function buildQuizzes(today: ISODate): QuizQuestion[] {
  const at = stamp(addDays(today, -3), "18:00");
  return [
    { id: "q-early", prompt: "Who is most likely to finish a habit before 8am?", tag: "early", votes: { "u-jonah": "u-maya", "u-priya": "u-maya", "u-sam": "u-maya", "u-theo": "u-priya" }, createdBy: "u-jonah", createdAt: at },
    { id: "q-lastminute", prompt: "Who always checks in at the last minute?", tag: "last-minute", votes: { "u-maya": "u-sam", "u-priya": "u-jonah", "u-theo": "u-sam", "u-lucia": "u-sam" }, createdBy: "u-maya", createdAt: at },
    { id: "q-reminders", prompt: "Who sends the best reminders?", tag: "reminders", votes: { "u-sam": "u-maya", "u-jonah": ME, "u-theo": ME, "u-lucia": "u-maya" }, createdBy: "u-theo", createdAt: at },
    { id: "q-nophone", prompt: "Who would survive a no-phone weekend?", tag: "no-phone", votes: { "u-maya": "u-lucia", "u-priya": "u-lucia", "u-jonah": "u-priya" }, createdBy: "u-lucia", createdAt: at },
    { id: "q-competitive", prompt: "Who is secretly the most competitive?", tag: "competitive", votes: { "u-maya": "u-priya", "u-sam": "u-priya", "u-lucia": "u-theo" }, createdBy: "u-sam", createdAt: at },
    { id: "q-wallet", prompt: "Who would you not trust with your wallet?", tag: "wallet", votes: { "u-maya": "u-theo", "u-priya": "u-theo", "u-jonah": "u-theo", "u-sam": "u-jonah" }, createdBy: "u-priya", createdAt: at },
  ];
}

function buildCollection(today: ISODate): OwnedCollectible[] {
  const own = (collectibleId: string, daysAgo: number, earnedFor: string, extra: Partial<OwnedCollectible> = {}): OwnedCollectible => ({
    collectibleId,
    earnedAt: stamp(addDays(today, -daysAgo), "19:30"),
    earnedFor,
    favorite: false,
    showcased: false,
    seen: true,
    ...extra,
  });
  return [
    own("c-first-stamp", 70, "First check-in: Morning walk", { showcased: true }),
    own("c-first-share", 70, "Started “Morning walk” with Maya"),
    own("c-first-note", 64, "Noted: “Took the long way past the bakery.”"),
    own("c-first-photo", 12, "Photo proof on Strength session"),
    own("c-first-group", 50, "Joined Hydration Station"),
    own("c-streak-7", 41, "7 mornings in a row on Morning walk", { favorite: true }),
    own("c-comeback", 18, "Came back to Morning walk after 3 missed days", { favorite: true, showcased: true }),
    own("c-steady-week", 9, "84% consistency, week of " + addDays(today, -13)),
    own("c-in-sync", 6, "Walked on the same morning as Maya"),
    own("c-book-club", 44, "Joined Read 20 pages with Jonah and Priya"),
    own("c-nudger", 15, "Nudged Sam about In bed by midnight"),
    own("c-night-owl", 22, "Lights out by 11 at 10:47pm"),
    own("c-weekend", 8, "Checked in Saturday and Sunday"),
    own("c-milestone", 5, "Toasted Hydration Station's halfway mark"),
    own("c-sup-comeback-kid", 7, "Weekly superlative: 3 comebacks last week", { showcased: true }),
    own("c-gifter", 4, "Gifted Sam a comeback boost"),
    own("c-sunday-reset", 13, "Three habits done on a Sunday", { giftedBy: undefined }),
    own("c-hundred", 16, "Your 100th check-in: Six glasses of water"),
    own("c-cheerleader", 3, "25 reactions sent this month", { seen: false }),
  ];
}

function buildNotifications(today: ISODate): AppNotification[] {
  const t = (daysAgo: number, time: string) => stamp(addDays(today, -daysAgo), time);
  return [
    { id: "n-1", kind: "reaction", actorId: "u-maya", title: "Maya reacted to your check-in", body: "Sent a flame to “Up by 7:30”.", at: t(1, "07:50"), read: false, href: "/habits/h-wake" },
    { id: "n-2", kind: "friend-request", actorId: "u-dev", title: "Dev Patel wants to be friends", body: "You have 1 mutual friend: Jonah.", at: t(0, "09:12"), read: false, refId: "fr-dev" },
    { id: "n-3", kind: "group-invite", actorId: "u-lucia", title: "Lucía invited you to Touch Grass Club", body: "One outdoor thing a day. Puddles count.", at: t(0, "08:30"), read: false, refId: "g-outside" },
    { id: "n-4", kind: "comment", actorId: "u-lucia", title: "Lucía commented", body: "“Same time tomorrow?” on Morning walk", at: t(1, "08:10"), read: false, href: "/habits/h-walk" },
    { id: "n-5", kind: "award", title: "New sticker: Cheerleader", body: "25 reactions sent this month. Your friends noticed.", at: t(3, "20:00"), read: false, href: "/collection" },
    { id: "n-6", kind: "recap", title: "Your weekly recap is ready", body: "Spoiler: you had a very good Thursday.", at: t(1, "18:00"), read: true, href: "/recap" },
    { id: "n-7", kind: "quiz", actorId: "u-priya", title: "Priya asked your circle a question", body: "“Who would you not trust with your wallet?”", at: t(2, "12:40"), read: true, href: "/friends/quizzes" },
    { id: "n-8", kind: "habit-invite", actorId: "u-theo", title: "Theo invited you to a shared habit", body: "“Something outside” · 3× per week", at: t(2, "16:05"), read: false, refId: "h-theo-outside" },
    { id: "n-9", kind: "group-goal", title: "Hydration Station passed 75%", body: "19 of 25 hydrated days. Two days to go.", at: t(1, "21:00"), read: true, href: "/groups/g-hydro" },
    { id: "n-10", kind: "reminder", title: "Strength session at 5:30", body: "20 minutes. Bodyweight counts.", at: t(2, "17:30"), read: true, href: "/today" },
    { id: "n-11", kind: "nudge", actorId: "u-sam", title: "Sam sent you a nudge", body: "“Lights out buddy, we said 11!”", at: t(3, "22:41"), read: true },
    { id: "n-12", kind: "gift", actorId: "u-maya", title: "Maya sent you a gift", body: "A Bandana for your avatar. Open it in Cosmetics.", at: t(4, "13:00"), read: true, href: "/profile/avatar" },
    { id: "n-13", kind: "feedback", title: "How's the new Friends feed?", body: "Two quick taps help us tune it.", at: t(5, "10:00"), read: true },
  ];
}

function buildPastRecaps(today: ISODate): PastRecap[] {
  const lastMonday = addDays(today, -((weekday(today) + 6) % 7) - 7);
  return [
    { id: "r-1", weekStart: lastMonday, completions: 34, consistency: 81, headline: "A very good Thursday", superlative: "Comeback Kid" },
    { id: "r-2", weekStart: addDays(lastMonday, -7), completions: 29, consistency: 72, headline: "Quietly consistent", superlative: "Surprisingly Consistent" },
    { id: "r-3", weekStart: addDays(lastMonday, -14), completions: 18, consistency: 44, headline: "The rainy week", superlative: "Most Likely to Check In at 11:59" },
    { id: "r-4", weekStart: addDays(lastMonday, -21), completions: 31, consistency: 77, headline: "Weekend mode: on", superlative: "Weekend MVP" },
  ];
}

export function defaultSettings(): Settings {
  return {
    theme: "light",
    accent: "burgundy",
    density: "comfortable",
    weekStart: 1,
    encouragement: "gentle",
    recapVisibility: "friends",
    showStreaks: true,
    allowFriendReminders: true,
    activityInFeed: true,
    sound: false,
    haptics: true,
    motion: "system",
    largeText: false,
    highContrast: false,
    notificationsOn: true,
    notificationCategories: { reminders: true, friends: true, reactions: true, comments: true, groups: true, awards: true, recap: true, quizzes: true, product: false },
    quietHours: { enabled: true, start: "22:30", end: "07:00" },
    groupNotify: {},
    profileVisibility: "friends",
    showConsistencyOnProfile: true,
    shareHidesDetails: true,
    blockedIds: [],
    connected: {
      "apple-health": { status: "disconnected" },
      "screen-time": { status: "disconnected" },
      calendar: { status: "disconnected" },
      weather: { status: "disconnected" },
    },
  };
}

export function createSeedState(today: ISODate): AppState {
  const users = buildUsers(today);
  const habits = buildHabits(today);
  const { groups, challenges, predictions } = buildGroups(today);
  const contacts: Contact[] = [
    { id: "ct-1", name: "Maya Okafor", detail: "(415) 555-0143", userId: "u-maya" },
    { id: "ct-2", name: "Jonah Lee", detail: "jonah.lee@example.com", userId: "u-jonah" },
    { id: "ct-3", name: "Priya Raman", detail: "(415) 555-0178", userId: "u-priya" },
    { id: "ct-4", name: "Theo Martins", detail: "(628) 555-0112", userId: "u-theo" },
    { id: "ct-5", name: "Sam Whitaker", detail: "sam.w@example.com", userId: "u-sam" },
    { id: "ct-6", name: "Lucía Fernández", detail: "(510) 555-0190", userId: "u-lucia" },
    { id: "ct-7", name: "Dev Patel", detail: "(415) 555-0101", userId: "u-dev" },
    { id: "ct-8", name: "Noor Haddad", detail: "noor@example.com", userId: "u-noor" },
    { id: "ct-9", name: "Grandma June", detail: "(707) 555-0166" },
    { id: "ct-10", name: "Ben Carter", detail: "(415) 555-0124" },
    { id: "ct-11", name: "Alex Kim", detail: "alex.kim@example.com" },
  ];
  const t = (daysAgo: number, time: string) => stamp(addDays(today, -daysAgo), time);
  const nudges: Nudge[] = [
    { id: "nd-1", fromId: "u-sam", toId: ME, habitId: "h-lights", kind: "nudge", message: "Lights out buddy, we said 11!", at: t(3, "22:41") },
    { id: "nd-2", fromId: ME, toId: "u-sam", habitId: "h-sam-sleep", kind: "nudge", message: "Phone down, pillow up.", at: t(2, "23:05") },
    { id: "nd-3", fromId: "u-maya", toId: "u-theo", kind: "comeback", message: "Welcome back to water world!", at: t(1, "10:30") },
    { id: "nd-4", fromId: ME, toId: "u-theo", habitId: "h-theo-water", kind: "cheer", message: "Big bottle energy today", at: t(0, "10:20") },
    { id: "nd-5", fromId: "u-priya", toId: "u-jonah", habitId: "h-read", kind: "nudge", message: "Chapter 8 waits for no one", at: t(1, "20:50") },
  ];
  const gifts: Gift[] = [
    { id: "gf-1", fromId: "u-maya", toId: ME, kind: "cosmetic", itemId: "acc-bandana", message: "Saw this and thought of you", at: t(4, "13:00"), opened: false },
    { id: "gf-2", fromId: ME, toId: "u-sam", kind: "comeback-boost", message: "For your next first day back", at: t(4, "19:00"), opened: true },
    { id: "gf-3", fromId: "u-jonah", toId: ME, kind: "double-reaction", message: "Use it wisely", at: t(6, "21:10"), opened: true },
  ];
  return {
    version: STATE_VERSION,
    seededFor: today,
    session: { onboarded: false, account: null, goals: [] },
    meId: ME,
    users,
    contacts,
    friendRequests: [{ id: "fr-dev", fromId: "u-dev", at: t(0, "09:12") }],
    habits,
    checkIns: buildCheckIns(today, habits, users),
    nudges,
    gifts,
    groups: groups.filter((g) => g.memberIds.includes(ME)).concat(groups.filter((g) => !g.memberIds.includes(ME))),
    groupInvites: ["g-outside"],
    challenges,
    predictions,
    quizzes: buildQuizzes(today),
    collection: buildCollection(today),
    unlockedCosmetics: [
      "hair-buzz", "hair-bob", "hair-curly", "hair-bun", "hair-long", "hair-none", "hair-swoop",
      "acc-none", "acc-glasses", "acc-beanie", "acc-flower", "acc-headphones",
      "out-tee", "out-hoodie", "out-sweater", "out-stripe",
      "bg-cream", "bg-rose", "bg-sage", "bg-orange", "bg-sky",
      "frame-none", "frame-stamp", "frame-scallop",
      "comp-none", "comp-sprout", "comp-snail",
    ],
    pastRecaps: buildPastRecaps(today),
    notifications: buildNotifications(today),
    settings: defaultSettings(),
    pendingReveal: null,
  };
}
