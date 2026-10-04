/* Core domain types. The data layer (lib/data, lib/store) and UI only share these. */

export type ID = string;
/** Calendar day in local time, formatted YYYY-MM-DD. */
export type ISODate = string;
/** Wall-clock time, formatted HH:MM (24h). */
export type ClockTime = string;
/** Full ISO timestamp. */
export type Timestamp = string;

export type Tint = "burgundy" | "rose" | "orange" | "gold" | "sage" | "sky" | "cream";

export type IllustrationKey =
  | "shoe"
  | "water"
  | "book"
  | "alarm"
  | "flower"
  | "dumbbell"
  | "moon"
  | "pencil"
  | "fruit"
  | "mascot"
  | "leaf"
  | "bike"
  | "music"
  | "coffee"
  | "sun"
  | "heart"
  | "star"
  | "crown"
  | "ribbon"
  | "ticket"
  | "phone";

export type HabitCategory =
  | "movement"
  | "hydration"
  | "mind"
  | "sleep"
  | "study"
  | "nourish"
  | "creative"
  | "outdoors"
  | "home";

export type FrequencyPreset = "daily" | "weekdays" | "weekends" | "three-per-week" | "custom";
export type TimeOfDay = "morning" | "afternoon" | "evening" | "anytime";
export type HabitPrivacy = "private" | "friends" | "group";
export type ProofMode = "off" | "optional" | "required";
export type HabitStatus = "active" | "paused" | "archived";

export interface Habit {
  id: ID;
  ownerId: ID;
  name: string;
  description: string;
  icon: IllustrationKey;
  category: HabitCategory;
  tint: Tint;
  frequency: FrequencyPreset;
  /** Scheduled weekdays, 0 = Sunday … 6 = Saturday. */
  days: number[];
  /** Only meaningful for "three-per-week" style targets. */
  timesPerWeek: number;
  timeOfDay: TimeOfDay;
  remindersOn: boolean;
  reminderTimes: ClockTime[];
  shared: boolean;
  participantIds: ID[];
  groupId?: ID;
  proof: ProofMode;
  notesEnabled: boolean;
  showStreak: boolean;
  privacy: HabitPrivacy;
  startDate: ISODate;
  targetDate?: ISODate;
  optional: boolean;
  status: HabitStatus;
  createdAt: Timestamp;
}

export type ReactionKind = "cheer" | "fire" | "clap" | "heart" | "wow";

export interface Reaction {
  userId: ID;
  kind: ReactionKind;
  at: Timestamp;
}

export interface Comment {
  id: ID;
  userId: ID;
  text: string;
  at: Timestamp;
}

export interface PhotoProof {
  id: ID;
  caption: string;
  motif: IllustrationKey;
  tint: Tint;
}

export interface CheckIn {
  id: ID;
  habitId: ID;
  userId: ID;
  date: ISODate;
  time: ClockTime;
  note?: string;
  photo?: PhotoProof;
  reactions: Reaction[];
  comments: Comment[];
}

/* ---------- People ---------- */

export type HeadShape = "round" | "bean" | "square" | "tall";
export type HairStyle = "none" | "buzz" | "bob" | "curly" | "bun" | "long" | "swoop";
export type EyeStyle = "dot" | "happy" | "sleepy" | "wink";
export type MouthStyle = "smile" | "grin" | "flat" | "o";
export type Outfit = "tee" | "hoodie" | "stripe" | "overalls" | "sweater";
export type Accessory = "none" | "glasses" | "beanie" | "flower" | "headphones" | "cap" | "bandana";
export type AvatarFrame = "none" | "stamp" | "scallop" | "tape" | "gold";
export type Companion = "none" | "sprout" | "cat" | "snail" | "bird";

export interface AvatarConfig {
  head: HeadShape;
  skin: string;
  hair: HairStyle;
  hairColor: string;
  eyes: EyeStyle;
  mouth: MouthStyle;
  cheeks: boolean;
  outfit: Outfit;
  outfitColor: string;
  accessory: Accessory;
  background: Tint;
  frame: AvatarFrame;
  companion: Companion;
}

export type PersonalityKey =
  | "gentle-builder"
  | "deadline-sprinter"
  | "social-motivator"
  | "quiet-perfectionist"
  | "variety-seeker";

export interface User {
  id: ID;
  name: string;
  handle: string;
  pronouns?: string;
  bio: string;
  avatar: AvatarConfig;
  personality?: PersonalityKey;
  /** Ids of this user's friends (the current user's list lives on `me`). */
  friendIds: ID[];
  joinedAt: ISODate;
}

export interface Contact {
  id: ID;
  name: string;
  detail: string;
  /** Set when this contact already uses the app. */
  userId?: ID;
}

export interface FriendRequest {
  id: ID;
  fromId: ID;
  at: Timestamp;
}

/* ---------- Social ---------- */

export type NudgeKind = "nudge" | "cheer" | "comeback";

export interface Nudge {
  id: ID;
  fromId: ID;
  toId: ID;
  habitId?: ID;
  kind: NudgeKind;
  message: string;
  at: Timestamp;
}

export type GiftKind = "reminder-pass" | "comeback-boost" | "double-reaction" | "cosmetic" | "sticker";

export interface Gift {
  id: ID;
  fromId: ID;
  toId: ID;
  kind: GiftKind;
  /** Cosmetic or collectible id when kind is cosmetic/sticker. */
  itemId?: ID;
  message: string;
  at: Timestamp;
  opened: boolean;
}

export type GroupNotify = "all" | "milestones" | "off";

export interface Group {
  id: ID;
  name: string;
  description: string;
  icon: IllustrationKey;
  tint: Tint;
  memberIds: ID[];
  createdBy: ID;
  createdAt: Timestamp;
  notify: GroupNotify;
}

export interface Challenge {
  id: ID;
  groupId: ID;
  title: string;
  description: string;
  icon: IllustrationKey;
  unit: string;
  goal: number;
  startDate: ISODate;
  endDate: ISODate;
  participantIds: ID[];
  /** userId -> contributions so far. */
  contributions: Record<ID, number>;
  /** milestone percentage (25/50/75/100) -> user ids who reacted */
  milestoneReactions: Record<string, ID[]>;
}

export interface Prediction {
  id: ID;
  groupId?: ID;
  question: string;
  optionIds: ID[];
  /** voterId -> chosen user id */
  votes: Record<ID, ID>;
  closesAt: ISODate;
  winnerId?: ID;
}

export interface QuizQuestion {
  id: ID;
  prompt: string;
  /** Short tag used to connect votes to superlatives. */
  tag: string;
  /** voterId -> votedForId */
  votes: Record<ID, ID>;
  createdBy: ID;
  createdAt: Timestamp;
}

/* ---------- Collection & cosmetics ---------- */

export type CollectibleCategory =
  | "first"
  | "consistency"
  | "streak"
  | "shared"
  | "group"
  | "helping"
  | "late-night"
  | "weekend"
  | "comeback"
  | "superlative";

export type Rarity = "common" | "uncommon" | "rare" | "legendary" | "limited";
export type StickerShape = "circle" | "scallop" | "star" | "ticket" | "stamp" | "ribbon" | "heart" | "badge";

export interface Collectible {
  id: ID;
  name: string;
  category: CollectibleCategory;
  rarity: Rarity;
  shape: StickerShape;
  motif: IllustrationKey;
  tint: Tint;
  /** Flavor text printed on the back of the sticker. */
  blurb: string;
  /** Requirement copy, shown even when locked. */
  howToEarn: string;
}

export interface OwnedCollectible {
  collectibleId: ID;
  earnedAt: Timestamp;
  /** How it was earned in this specific case. */
  earnedFor: string;
  favorite: boolean;
  showcased: boolean;
  giftedBy?: ID;
  seen: boolean;
}

export type CosmeticSlot = "hair" | "accessory" | "outfit" | "background" | "frame" | "companion";

export interface Cosmetic {
  id: ID;
  slot: CosmeticSlot;
  value: string;
  name: string;
  unlock: string;
}

/* ---------- Notifications ---------- */

export type NotificationKind =
  | "friend-request"
  | "group-invite"
  | "habit-invite"
  | "reminder"
  | "reaction"
  | "comment"
  | "award"
  | "recap"
  | "quiz"
  | "feedback"
  | "group-goal"
  | "nudge"
  | "gift";

export interface AppNotification {
  id: ID;
  kind: NotificationKind;
  actorId?: ID;
  title: string;
  body: string;
  at: Timestamp;
  read: boolean;
  href?: string;
  /** Some invitations can be answered inline. */
  refId?: ID;
  resolved?: "accepted" | "declined";
}

/* ---------- Recaps ---------- */

export interface PastRecap {
  id: ID;
  weekStart: ISODate;
  completions: number;
  consistency: number;
  headline: string;
  superlative: string;
}

export type SuperlativeSource = "behavior" | "votes" | "both";

export interface Superlative {
  id: ID;
  title: string;
  userId: ID;
  explanation: string;
  source: SuperlativeSource;
  motif: IllustrationKey;
  tint: Tint;
}

/* ---------- Settings & session ---------- */

export type ThemeSetting = "light" | "dark";
export type AccentKey = "burgundy" | "forest" | "ink" | "terracotta";
export type Density = "compact" | "comfortable";
export type EncouragementStyle = "gentle" | "cheeky" | "coach";
export type Visibility = "private" | "friends" | "groups";
export type MotionPref = "system" | "reduced" | "full";
export type ServiceKey = "apple-health" | "screen-time" | "calendar" | "weather";
export type ConnectionStatus = "connected" | "disconnected" | "syncing" | "error";

export type NotificationCategory =
  | "reminders"
  | "friends"
  | "reactions"
  | "comments"
  | "groups"
  | "awards"
  | "recap"
  | "quizzes"
  | "product";

export interface ConnectedService {
  status: ConnectionStatus;
  lastSync?: Timestamp;
  /** Mock settings, e.g. which metric is mapped to which habit. */
  mappedHabitId?: ID;
}

export interface Settings {
  theme: ThemeSetting;
  accent: AccentKey;
  density: Density;
  weekStart: 0 | 1;
  encouragement: EncouragementStyle;
  recapVisibility: Visibility;
  showStreaks: boolean;
  allowFriendReminders: boolean;
  activityInFeed: boolean;
  sound: boolean;
  haptics: boolean;
  motion: MotionPref;
  largeText: boolean;
  highContrast: boolean;
  notificationsOn: boolean;
  notificationCategories: Record<NotificationCategory, boolean>;
  quietHours: { enabled: boolean; start: ClockTime; end: ClockTime };
  groupNotify: Record<ID, GroupNotify>;
  profileVisibility: Visibility | "public";
  showConsistencyOnProfile: boolean;
  shareHidesDetails: boolean;
  blockedIds: ID[];
  connected: Record<ServiceKey, ConnectedService>;
}

export interface Account {
  email: string;
  method: "email" | "apple" | "google";
  createdAt: Timestamp;
}

export interface Session {
  onboarded: boolean;
  account: Account | null;
  goals: string[];
  personality?: PersonalityKey;
}

export interface AppState {
  version: number;
  /** The day the seed data was generated around. */
  seededFor: ISODate;
  session: Session;
  meId: ID;
  users: Record<ID, User>;
  contacts: Contact[];
  friendRequests: FriendRequest[];
  habits: Habit[];
  checkIns: CheckIn[];
  nudges: Nudge[];
  gifts: Gift[];
  groups: Group[];
  /** Groups the current user was invited to but has not joined. */
  groupInvites: ID[];
  challenges: Challenge[];
  predictions: Prediction[];
  quizzes: QuizQuestion[];
  collection: OwnedCollectible[];
  unlockedCosmetics: ID[];
  pastRecaps: PastRecap[];
  notifications: AppNotification[];
  settings: Settings;
  /** Collectible to reveal with a celebratory sheet, if any. */
  pendingReveal: ID | null;
}
