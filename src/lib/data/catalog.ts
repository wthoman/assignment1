import type {
  CollectibleCategory,
  Collectible,
  Cosmetic,
  HabitCategory,
  IllustrationKey,
  NotificationCategory,
  PersonalityKey,
  Rarity,
  Tint,
} from "../types";

export const CATEGORY_META: Record<HabitCategory, { label: string; tint: Tint; icon: IllustrationKey }> = {
  movement: { label: "Movement", tint: "orange", icon: "shoe" },
  hydration: { label: "Hydration", tint: "sky", icon: "water" },
  mind: { label: "Mind", tint: "rose", icon: "flower" },
  sleep: { label: "Sleep", tint: "sky", icon: "moon" },
  study: { label: "Study", tint: "gold", icon: "book" },
  nourish: { label: "Nourish", tint: "sage", icon: "fruit" },
  creative: { label: "Creative", tint: "rose", icon: "pencil" },
  outdoors: { label: "Outdoors", tint: "sage", icon: "leaf" },
  home: { label: "Home", tint: "gold", icon: "coffee" },
};

export const ILLUSTRATION_LABELS: Record<IllustrationKey, string> = {
  shoe: "Walking shoe",
  water: "Water glass",
  book: "Book",
  alarm: "Alarm clock",
  flower: "Flower",
  dumbbell: "Dumbbell",
  moon: "Sleepy moon",
  pencil: "Pencil",
  fruit: "Pear",
  mascot: "Mascot",
  leaf: "Leaf",
  bike: "Bicycle",
  music: "Music note",
  coffee: "Mug",
  sun: "Sun",
  heart: "Heart",
  star: "Star",
  crown: "Crown",
  ribbon: "Ribbon",
  ticket: "Ticket",
  phone: "Phone",
};

/** Illustrations offered when creating a habit. */
export const HABIT_ICONS: IllustrationKey[] = [
  "shoe",
  "water",
  "book",
  "alarm",
  "flower",
  "dumbbell",
  "moon",
  "pencil",
  "fruit",
  "leaf",
  "bike",
  "music",
  "coffee",
  "sun",
  "heart",
  "phone",
];

export const COLLECTIBLE_CATEGORY_META: Record<CollectibleCategory, { label: string; short: string }> = {
  first: { label: "First steps", short: "Firsts" },
  consistency: { label: "Long-term consistency", short: "Consistency" },
  streak: { label: "Streaks", short: "Streaks" },
  comeback: { label: "Comebacks", short: "Comebacks" },
  shared: { label: "Shared habits", short: "Shared" },
  group: { label: "Group achievements", short: "Groups" },
  helping: { label: "Helping friends", short: "Helping" },
  "late-night": { label: "Late-night check-ins", short: "Late night" },
  weekend: { label: "Weekend activity", short: "Weekend" },
  superlative: { label: "Weekly superlatives", short: "Superlatives" },
};

export const RARITY_META: Record<Rarity, { label: string; dots: number }> = {
  common: { label: "Common", dots: 1 },
  uncommon: { label: "Uncommon", dots: 2 },
  rare: { label: "Rare", dots: 3 },
  legendary: { label: "Legendary", dots: 4 },
  limited: { label: "Limited · this week only", dots: 4 },
};

export const COLLECTIBLES: Collectible[] = [
  // First steps
  { id: "c-first-stamp", name: "First Stamp", category: "first", rarity: "common", shape: "stamp", motif: "star", tint: "burgundy", blurb: "Everything starts with one wobbly checkmark.", howToEarn: "Complete any habit for the first time." },
  { id: "c-first-share", name: "Plus One", category: "first", rarity: "common", shape: "circle", motif: "heart", tint: "rose", blurb: "Habits are lighter when someone else is carrying one too.", howToEarn: "Start your first shared habit." },
  { id: "c-first-photo", name: "Proof Positive", category: "first", rarity: "common", shape: "ticket", motif: "sun", tint: "gold", blurb: "Pics or it didn't happen. (It happened.)", howToEarn: "Attach photo proof to a check-in." },
  { id: "c-first-note", name: "Margin Notes", category: "first", rarity: "common", shape: "scallop", motif: "pencil", tint: "cream", blurb: "A few words about how it went.", howToEarn: "Add a note to a check-in." },
  // Consistency
  { id: "c-steady-week", name: "Steady Week", category: "consistency", rarity: "uncommon", shape: "badge", motif: "shoe", tint: "sage", blurb: "Not perfect. Just steady. That's the trick.", howToEarn: "Reach 80% consistency across a week." },
  { id: "c-month-80", name: "Four Good Weeks", category: "consistency", rarity: "rare", shape: "ribbon", motif: "ribbon", tint: "burgundy", blurb: "Twenty-eight days of mostly showing up.", howToEarn: "Hold 80%+ rolling consistency for four weeks." },
  { id: "c-hundred", name: "The Hundred Club", category: "consistency", rarity: "rare", shape: "scallop", motif: "crown", tint: "gold", blurb: "One hundred check-ins. Each one counted.", howToEarn: "Log 100 total completions." },
  { id: "c-every-day", name: "All Seven", category: "consistency", rarity: "legendary", shape: "star", motif: "sun", tint: "orange", blurb: "Showed up every single day this week.", howToEarn: "Complete at least one habit on all seven days of a week." },
  // Streaks
  { id: "c-streak-7", name: "Week Unbroken", category: "streak", rarity: "uncommon", shape: "circle", motif: "star", tint: "orange", blurb: "Seven in a row. Nice rhythm.", howToEarn: "Reach a 7-day streak on any habit." },
  { id: "c-streak-21", name: "Groove Found", category: "streak", rarity: "rare", shape: "badge", motif: "music", tint: "rose", blurb: "Three weeks without missing a beat.", howToEarn: "Reach a 21-day streak on any habit." },
  { id: "c-streak-50", name: "Long Haul", category: "streak", rarity: "legendary", shape: "ribbon", motif: "crown", tint: "burgundy", blurb: "Fifty days. Tell your grandkids.", howToEarn: "Reach a 50-day streak on any habit." },
  // Comebacks
  { id: "c-comeback", name: "Back Again", category: "comeback", rarity: "uncommon", shape: "heart", motif: "heart", tint: "rose", blurb: "Missing a day is normal. Coming back is the skill.", howToEarn: "Check in after missing two or more scheduled days." },
  { id: "c-comeback-3", name: "Bounce Back x3", category: "comeback", rarity: "rare", shape: "scallop", motif: "sun", tint: "orange", blurb: "Three comebacks. You're getting good at starting again.", howToEarn: "Make three comebacks in one month." },
  { id: "c-comeback-week", name: "Fresh Page", category: "comeback", rarity: "rare", shape: "ticket", motif: "pencil", tint: "sage", blurb: "A whole week away, then right back to it.", howToEarn: "Return to a habit after a week-long break." },
  { id: "c-phoenix", name: "Sunrise Kid", category: "comeback", rarity: "legendary", shape: "star", motif: "sun", tint: "gold", blurb: "Your best week came right after your hardest one.", howToEarn: "Beat your previous week's consistency by 30 points." },
  // Shared
  { id: "c-in-sync", name: "In Sync", category: "shared", rarity: "uncommon", shape: "circle", motif: "shoe", tint: "sky", blurb: "Same habit, same day, same tiny victory.", howToEarn: "Complete a shared habit on the same day as a partner." },
  { id: "c-duet", name: "Duet Week", category: "shared", rarity: "rare", shape: "badge", motif: "music", tint: "sage", blurb: "You and a friend matched every day this week.", howToEarn: "Match a friend on a shared habit for 5 days in a week." },
  { id: "c-full-house", name: "Full House", category: "shared", rarity: "uncommon", shape: "scallop", motif: "mascot", tint: "orange", blurb: "Everybody showed up. Even you, eventually.", howToEarn: "Be the last person to check in on a shared habit, completing it for everyone that day." },
  { id: "c-book-club", name: "Book Club", category: "shared", rarity: "uncommon", shape: "stamp", motif: "book", tint: "gold", blurb: "Three readers, one chapter at a time.", howToEarn: "Join a shared habit with three or more people." },
  // Group
  { id: "c-group-goal", name: "Goal Reached", category: "group", rarity: "rare", shape: "ribbon", motif: "ribbon", tint: "sage", blurb: "Everyone chipped in. The jar is full.", howToEarn: "Help your group hit a collective goal." },
  { id: "c-first-group", name: "Housewarming", category: "group", rarity: "common", shape: "scallop", motif: "coffee", tint: "orange", blurb: "Welcome to the group. Snacks are in the kitchen.", howToEarn: "Join or create a group." },
  { id: "c-milestone", name: "Halfway Toast", category: "group", rarity: "uncommon", shape: "circle", motif: "star", tint: "gold", blurb: "Raised a glass at the halfway mark.", howToEarn: "React to a group milestone." },
  // Helping
  { id: "c-cheerleader", name: "Cheerleader", category: "helping", rarity: "uncommon", shape: "star", motif: "heart", tint: "rose", blurb: "Twenty-five reactions sent. Friends noticed.", howToEarn: "Send 25 reactions to friends." },
  { id: "c-nudger", name: "Gentle Nudge", category: "helping", rarity: "common", shape: "ticket", motif: "alarm", tint: "sky", blurb: "A tiny tap on the shoulder, delivered kindly.", howToEarn: "Send a friend an encouraging reminder." },
  { id: "c-gifter", name: "Care Package", category: "helping", rarity: "uncommon", shape: "badge", motif: "ribbon", tint: "orange", blurb: "Sent a little something to keep someone going.", howToEarn: "Gift a power-up or cosmetic to a friend." },
  { id: "c-comeback-cheer", name: "Welcome Back Committee", category: "helping", rarity: "rare", shape: "heart", motif: "sun", tint: "gold", blurb: "First to celebrate a friend's return.", howToEarn: "Celebrate a friend's comeback." },
  // Late night
  { id: "c-night-owl", name: "Night Owl", category: "late-night", rarity: "common", shape: "circle", motif: "moon", tint: "sky", blurb: "Checked in after 10pm. The day still counts.", howToEarn: "Complete a habit after 10pm." },
  { id: "c-1159", name: "11:59 Club", category: "late-night", rarity: "rare", shape: "stamp", motif: "alarm", tint: "burgundy", blurb: "Technically still today.", howToEarn: "Check in between 11:50pm and midnight." },
  // Weekend
  { id: "c-weekend", name: "Weekend Warrior", category: "weekend", rarity: "common", shape: "scallop", motif: "bike", tint: "sage", blurb: "Saturday and Sunday showed up too.", howToEarn: "Complete habits on both weekend days." },
  { id: "c-sunday-reset", name: "Sunday Reset", category: "weekend", rarity: "uncommon", shape: "ticket", motif: "flower", tint: "rose", blurb: "Set the week up right.", howToEarn: "Complete three habits on a Sunday." },
  // Superlatives (limited weekly)
  { id: "c-sup-last-minute", name: "Last-Minute Legend", category: "superlative", rarity: "limited", shape: "ribbon", motif: "alarm", tint: "burgundy", blurb: "Weekly superlative. Cutting it close, every time.", howToEarn: "Have the most check-ins after 9pm in your circle this week." },
  { id: "c-sup-weekend-mvp", name: "Weekend MVP", category: "superlative", rarity: "limited", shape: "star", motif: "crown", tint: "gold", blurb: "Weekly superlative. Saturday's main character.", howToEarn: "Most weekend completions among friends." },
  { id: "c-sup-comeback-kid", name: "Comeback Kid", category: "superlative", rarity: "limited", shape: "heart", motif: "sun", tint: "orange", blurb: "Weekly superlative. Got knocked down, got back up.", howToEarn: "Most comebacks among friends this week." },
  { id: "c-sup-reminder", name: "Pro Reminder Sender", category: "superlative", rarity: "limited", shape: "ticket", motif: "phone", tint: "sky", blurb: "Weekly superlative. Your nudges have a fan club.", howToEarn: "Send the most nudges that led to a check-in." },
  { id: "c-sup-surprise", name: "Surprisingly Consistent", category: "superlative", rarity: "limited", shape: "badge", motif: "star", tint: "sage", blurb: "Weekly superlative. Nobody saw it coming. You did.", howToEarn: "Largest consistency jump among friends." },
];

export const COLLECTIBLE_BY_ID: Record<string, Collectible> = Object.fromEntries(COLLECTIBLES.map((c) => [c.id, c]));

export const COSMETICS: Cosmetic[] = [
  { id: "hair-buzz", slot: "hair", value: "buzz", name: "Buzz", unlock: "Starter" },
  { id: "hair-bob", slot: "hair", value: "bob", name: "Bob", unlock: "Starter" },
  { id: "hair-curly", slot: "hair", value: "curly", name: "Curls", unlock: "Starter" },
  { id: "hair-bun", slot: "hair", value: "bun", name: "Top bun", unlock: "Starter" },
  { id: "hair-long", slot: "hair", value: "long", name: "Long", unlock: "Starter" },
  { id: "hair-swoop", slot: "hair", value: "swoop", name: "Swoop", unlock: "Complete 25 check-ins" },
  { id: "hair-none", slot: "hair", value: "none", name: "None", unlock: "Starter" },
  { id: "acc-none", slot: "accessory", value: "none", name: "None", unlock: "Starter" },
  { id: "acc-glasses", slot: "accessory", value: "glasses", name: "Round glasses", unlock: "Starter" },
  { id: "acc-beanie", slot: "accessory", value: "beanie", name: "Beanie", unlock: "Earn a Weekend award" },
  { id: "acc-flower", slot: "accessory", value: "flower", name: "Hair flower", unlock: "Make a comeback" },
  { id: "acc-headphones", slot: "accessory", value: "headphones", name: "Headphones", unlock: "Join a group" },
  { id: "acc-cap", slot: "accessory", value: "cap", name: "Ball cap", unlock: "Reach a 7-day streak" },
  { id: "acc-bandana", slot: "accessory", value: "bandana", name: "Bandana", unlock: "Gift from a friend" },
  { id: "out-tee", slot: "outfit", value: "tee", name: "Tee", unlock: "Starter" },
  { id: "out-hoodie", slot: "outfit", value: "hoodie", name: "Hoodie", unlock: "Starter" },
  { id: "out-stripe", slot: "outfit", value: "stripe", name: "Breton stripe", unlock: "Complete 10 shared check-ins" },
  { id: "out-overalls", slot: "outfit", value: "overalls", name: "Overalls", unlock: "Hit a group goal" },
  { id: "out-sweater", slot: "outfit", value: "sweater", name: "Cozy sweater", unlock: "Starter" },
  { id: "bg-cream", slot: "background", value: "cream", name: "Cream", unlock: "Starter" },
  { id: "bg-rose", slot: "background", value: "rose", name: "Dusty rose", unlock: "Starter" },
  { id: "bg-sage", slot: "background", value: "sage", name: "Sage", unlock: "Starter" },
  { id: "bg-sky", slot: "background", value: "sky", name: "Pale sky", unlock: "Complete 5 sleep check-ins" },
  { id: "bg-gold", slot: "background", value: "gold", name: "Marigold", unlock: "Earn a Rare collectible" },
  { id: "bg-orange", slot: "background", value: "orange", name: "Apricot", unlock: "Starter" },
  { id: "frame-none", slot: "frame", value: "none", name: "No frame", unlock: "Starter" },
  { id: "frame-stamp", slot: "frame", value: "stamp", name: "Postage", unlock: "Starter" },
  { id: "frame-scallop", slot: "frame", value: "scallop", name: "Scallop", unlock: "Earn 5 stickers" },
  { id: "frame-tape", slot: "frame", value: "tape", name: "Taped photo", unlock: "Attach 3 photo proofs" },
  { id: "frame-gold", slot: "frame", value: "gold", name: "Gold leaf", unlock: "Earn a Legendary collectible" },
  { id: "comp-none", slot: "companion", value: "none", name: "Solo", unlock: "Starter" },
  { id: "comp-sprout", slot: "companion", value: "sprout", name: "Sprout", unlock: "Starter" },
  { id: "comp-cat", slot: "companion", value: "cat", name: "Biscuit the cat", unlock: "Reach 80% consistency" },
  { id: "comp-snail", slot: "companion", value: "snail", name: "Slow & Steady", unlock: "Make 3 comebacks" },
  { id: "comp-bird", slot: "companion", value: "bird", name: "Early bird", unlock: "10 morning check-ins" },
];

export const SKIN_TONES = ["#F6D5B8", "#EBC09C", "#D29F76", "#B07B53", "#8A5A3B", "#5E3B27"];
export const HAIR_COLORS = ["#271C1B", "#5B3424", "#9A5B32", "#D9A95B", "#B4473A", "#8E8A84"];
export const OUTFIT_COLORS = ["#6F1725", "#8FA382", "#E09A5F", "#A9C3D4", "#C9A24A", "#D9A3A0"];

export const PERSONALITIES: Record<
  PersonalityKey,
  {
    name: string;
    tagline: string;
    summary: string;
    strengths: string[];
    watchOut: string;
    habits: { name: string; icon: IllustrationKey; schedule: string }[];
    schedule: string;
    accountability: string[];
    tint: Tint;
    motif: IllustrationKey;
  }
> = {
  "gentle-builder": {
    name: "Gentle Builder",
    tagline: "Small bricks, every day.",
    summary: "You do best with tiny, low-pressure habits that stack over time. Momentum matters more to you than intensity.",
    strengths: ["Patient", "Low burnout", "Great at routines"],
    watchOut: "You can under-commit. Let a habit grow once it feels easy.",
    habits: [
      { name: "Drink a glass of water on waking", icon: "water", schedule: "Daily · morning" },
      { name: "10-minute walk", icon: "shoe", schedule: "Daily · anytime" },
      { name: "Read 5 pages", icon: "book", schedule: "Weekdays · evening" },
    ],
    schedule: "Daily, at a consistent time, with one optional habit for good days.",
    accountability: ["One accountability partner", "Gentle encouragement tone", "Streaks hidden"],
    tint: "sage",
    motif: "leaf",
  },
  "deadline-sprinter": {
    name: "Deadline Sprinter",
    tagline: "Pressure makes diamonds.",
    summary: "You thrive with a clear finish line and a bit of urgency. Short challenges keep you sharper than open-ended goals.",
    strengths: ["Focused bursts", "Loves a challenge", "Finishes strong"],
    watchOut: "Late-night check-ins are fine, but try one morning anchor habit.",
    habits: [
      { name: "Two focused study blocks", icon: "pencil", schedule: "Weekdays · afternoon" },
      { name: "Strength session", icon: "dumbbell", schedule: "3× per week" },
      { name: "Lights out by 11:30", icon: "moon", schedule: "Daily · evening" },
    ],
    schedule: "Three-times-a-week targets with a weekly finish line.",
    accountability: ["Join a time-boxed group challenge", "Evening reminder", "Coach-style encouragement"],
    tint: "orange",
    motif: "alarm",
  },
  "social-motivator": {
    name: "Social Motivator",
    tagline: "Better together.",
    summary: "Other people are your fuel. Shared habits and quick reactions from friends keep you showing up.",
    strengths: ["Energizes others", "Bounces back fast", "Great teammate"],
    watchOut: "Keep at least one habit that's just for you.",
    habits: [
      { name: "Morning walk with a friend", icon: "shoe", schedule: "Daily · morning" },
      { name: "Shared reading", icon: "book", schedule: "Weekdays · evening" },
      { name: "Call someone you love", icon: "phone", schedule: "Weekends" },
    ],
    schedule: "Shared daily habits, plus a weekly group challenge.",
    accountability: ["Shared habits on by default", "Friends can send reminders", "Weekly recap shared with friends"],
    tint: "rose",
    motif: "heart",
  },
  "quiet-perfectionist": {
    name: "Quiet Perfectionist",
    tagline: "Details, done well.",
    summary: "You like doing things properly. Data and reflection help — but an all-or-nothing mindset can trip you up.",
    strengths: ["Thorough", "Self-aware", "Loves a good system"],
    watchOut: "One missed day isn't failure. Watch your rolling consistency, not your streak.",
    habits: [
      { name: "Journal three lines", icon: "pencil", schedule: "Daily · evening" },
      { name: "Stretch for 10 minutes", icon: "flower", schedule: "Daily · morning" },
      { name: "Plan tomorrow", icon: "book", schedule: "Weekdays · evening" },
    ],
    schedule: "Daily habits with notes enabled and private by default.",
    accountability: ["Streaks hidden", "Notes on every check-in", "Private by default"],
    tint: "sky",
    motif: "pencil",
  },
  "variety-seeker": {
    name: "Variety Seeker",
    tagline: "Same goal, new route.",
    summary: "Repetition bores you. Rotating habits and flexible schedules keep things fresh enough to stick.",
    strengths: ["Curious", "Adaptable", "Tries anything once"],
    watchOut: "Pick one keystone habit and let the rest rotate.",
    habits: [
      { name: "Something outdoors", icon: "leaf", schedule: "3× per week" },
      { name: "Try a new recipe", icon: "fruit", schedule: "Weekends" },
      { name: "Move your body (any way)", icon: "bike", schedule: "Daily · anytime" },
    ],
    schedule: "Flexible 3×-per-week targets instead of fixed days.",
    accountability: ["Rotating group challenges", "Photo proof for fun", "Cheeky encouragement"],
    tint: "gold",
    motif: "sun",
  },
};

export const NOTIFICATION_CATEGORY_META: Record<NotificationCategory, { label: string; detail: string }> = {
  reminders: { label: "Habit reminders", detail: "Scheduled reminders for your own habits" },
  friends: { label: "Friend activity", detail: "Requests, nudges and gifts from friends" },
  reactions: { label: "Reactions", detail: "When someone reacts to a check-in" },
  comments: { label: "Comments", detail: "Replies on your check-ins" },
  groups: { label: "Groups & challenges", detail: "Invites, milestones and finished goals" },
  awards: { label: "Awards", detail: "New stickers and collectibles" },
  recap: { label: "Weekly recap", detail: "When your recap is ready on Sunday" },
  quizzes: { label: "Friend quizzes", detail: "New questions from your circle" },
  product: { label: "Feedback & tips", detail: "Occasional feedback prompts" },
};

export const GOAL_OPTIONS: { key: string; label: string; icon: IllustrationKey }[] = [
  { key: "move", label: "Move more", icon: "shoe" },
  { key: "sleep", label: "Sleep better", icon: "moon" },
  { key: "read", label: "Read more", icon: "book" },
  { key: "hydrate", label: "Drink water", icon: "water" },
  { key: "focus", label: "Study & focus", icon: "pencil" },
  { key: "calm", label: "Feel calmer", icon: "flower" },
  { key: "eat", label: "Eat well", icon: "fruit" },
  { key: "outside", label: "Get outside", icon: "leaf" },
  { key: "strength", label: "Get stronger", icon: "dumbbell" },
  { key: "create", label: "Make things", icon: "music" },
  { key: "mornings", label: "Better mornings", icon: "alarm" },
  { key: "friends", label: "Stay close to friends", icon: "heart" },
];
