import type {
  Account,
  AppNotification,
  AvatarConfig,
  Challenge,
  ConnectedService,
  GiftKind,
  Group,
  Habit,
  HabitStatus,
  ID,
  ISODate,
  NudgeKind,
  PersonalityKey,
  PhotoProof,
  ReactionKind,
  ServiceKey,
  Settings,
  User,
} from "../types";

export type HabitDraft = Omit<Habit, "id" | "ownerId" | "createdAt" | "status">;

export type Action =
  // Session & onboarding
  | { type: "session/account"; account: Account }
  | { type: "session/goals"; goals: string[] }
  | { type: "session/personality"; personality: PersonalityKey }
  | { type: "session/finishOnboarding" }
  | { type: "session/logout" }
  | { type: "session/reset" }
  | { type: "profile/update"; patch: Partial<Pick<User, "name" | "handle" | "bio" | "pronouns">> }
  | { type: "profile/avatar"; patch: Partial<AvatarConfig> }
  // Habits
  | { type: "habit/create"; draft: HabitDraft; id?: ID }
  | { type: "habit/update"; id: ID; patch: Partial<HabitDraft> }
  | { type: "habit/status"; id: ID; status: HabitStatus }
  | { type: "habit/delete"; id: ID }
  | { type: "habit/acceptInvite"; id: ID }
  | { type: "habit/invite"; id: ID; userIds: ID[] }
  // Check-ins
  | { type: "checkin/complete"; habitId: ID; date: ISODate; time?: string; note?: string; photo?: PhotoProof }
  | { type: "checkin/undo"; habitId: ID; date: ISODate }
  | { type: "checkin/update"; id: ID; note?: string; photo?: PhotoProof | null }
  | { type: "checkin/react"; id: ID; kind: ReactionKind }
  | { type: "checkin/comment"; id: ID; text: string }
  // Social
  | { type: "social/nudge"; toId: ID; habitId?: ID; kind: NudgeKind; message: string }
  | { type: "social/gift"; toId: ID; kind: GiftKind; itemId?: ID; message: string }
  | { type: "social/openGift"; id: ID }
  | { type: "friend/accept"; requestId: ID }
  | { type: "friend/decline"; requestId: ID }
  | { type: "friend/add"; userId: ID }
  | { type: "friend/remove"; userId: ID }
  | { type: "contact/invite"; contactId: ID }
  // Groups
  | { type: "group/create"; group: Omit<Group, "id" | "createdAt" | "createdBy">; id?: ID }
  | { type: "group/update"; id: ID; patch: Partial<Omit<Group, "id">> }
  | { type: "group/join"; id: ID }
  | { type: "group/leave"; id: ID }
  | { type: "group/declineInvite"; id: ID }
  | { type: "group/invite"; id: ID; userIds: ID[] }
  | { type: "challenge/create"; challenge: Omit<Challenge, "id" | "contributions" | "milestoneReactions">; id?: ID }
  | { type: "challenge/join"; id: ID }
  | { type: "challenge/leave"; id: ID }
  | { type: "challenge/log"; id: ID; amount?: number }
  | { type: "challenge/reactMilestone"; id: ID; milestone: number }
  | { type: "prediction/vote"; id: ID; pickId: ID }
  | { type: "prediction/create"; question: string; optionIds: ID[]; groupId?: ID; closesAt: ISODate }
  | { type: "quiz/vote"; id: ID; pickId: ID }
  | { type: "quiz/create"; prompt: string }
  // Collection & cosmetics
  | { type: "collection/favorite"; id: ID }
  | { type: "collection/showcase"; id: ID }
  | { type: "collection/seen"; id: ID }
  | { type: "collection/award"; id: ID; earnedFor: string }
  | { type: "reveal/dismiss" }
  | { type: "cosmetic/unlock"; id: ID }
  // Notifications
  | { type: "notification/read"; id: ID }
  | { type: "notification/readAll" }
  | { type: "notification/dismiss"; id: ID }
  | { type: "notification/resolve"; id: ID; resolution: NonNullable<AppNotification["resolved"]> }
  | { type: "notification/push"; notification: Omit<AppNotification, "id" | "at" | "read"> }
  // Settings
  | { type: "settings/update"; patch: Partial<Settings> }
  | { type: "settings/connection"; service: ServiceKey; value: ConnectedService }
  | { type: "settings/block"; userId: ID }
  | { type: "settings/unblock"; userId: ID };
