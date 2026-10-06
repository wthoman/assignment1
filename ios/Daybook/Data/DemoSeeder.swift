import Foundation
import SwiftData

/// Builds a realistic, deterministic demo world around today's date.
/// Everything a backend would provide (friends, their activity, groups) is generated here.
@MainActor
enum DemoSeeder {
    struct Options {
        /// Names of seeded friends the user kept during onboarding. nil keeps everyone.
        var keptFriendNames: Set<String>?
        var includeSampleHabits = true
    }

    // MARK: Friend specs

    private struct FriendSpec {
        let name: String
        let handle: String
        let pronouns: String
        let bio: String
        let avatar: AvatarConfig
        let personality: PersonalityType
        let status: FriendStatus
        let contact: String
        let mutual: Int
        let consistency: Double
        let previous: Double
        let total: Int
        let week: Int
        let comebacks: Int
        let lateNight: Int
        let weekend: Int
        let reminders: Int
        let strongest: Int
        let favorites: [String]
        let showcase: [String]
        let sinceDays: Int
    }

    private static let friendSpecs: [FriendSpec] = [
        FriendSpec(name: "Maya Okafor", handle: "mayawalks", pronouns: "she/her", bio: "6am walker. Will send you a sunrise photo whether you asked or not.",
                   avatar: AvatarConfig(head: .round, skin: 4, hair: .bun, hairColor: 0, eyes: .happy, mouth: .grin, cheeks: true, outfit: .hoodie, outfitColor: 1, accessory: .headphones, background: .sage, frame: .scallop, companion: .bird),
                   personality: .socialMotivator, status: .friend, contact: "(415) 555-0143", mutual: 4, consistency: 0.91, previous: 0.88, total: 412, week: 14, comebacks: 1, lateNight: 0, weekend: 4, reminders: 7, strongest: 2, favorites: ["Morning walk", "Sunrise stretch"], showcase: ["week-unbroken", "cheerleader", "steady-week"], sinceDays: 300),
        FriendSpec(name: "Jonah Lee", handle: "jonahreads", pronouns: "he/him", bio: "Reading 30 books this year. Currently on 19. Don't ask about 20.",
                   avatar: AvatarConfig(head: .tall, skin: 0, hair: .swoop, hairColor: 2, eyes: .dot, mouth: .grin, cheeks: false, outfit: .stripe, outfitColor: 3, accessory: .glasses, background: .sky, frame: .stamp, companion: .none),
                   personality: .deadlineSprinter, status: .friend, contact: "jonah.lee@example.com", mutual: 3, consistency: 0.81, previous: 0.52, total: 268, week: 11, comebacks: 2, lateNight: 4, weekend: 2, reminders: 2, strongest: 4, favorites: ["Read 20 pages", "Run club"], showcase: ["groove-found", "in-sync"], sinceDays: 210),
        FriendSpec(name: "Priya Raman", handle: "priya.r", pronouns: "she/her", bio: "Strength training + studying for the bar. Send snacks.",
                   avatar: AvatarConfig(head: .bean, skin: 3, hair: .long, hairColor: 0, eyes: .wink, mouth: .smile, cheeks: true, outfit: .tee, outfitColor: 2, accessory: .none, background: .gold, frame: .gold, companion: .cat),
                   personality: .quietPerfectionist, status: .friend, contact: "(415) 555-0178", mutual: 2, consistency: 0.94, previous: 0.9, total: 356, week: 15, comebacks: 0, lateNight: 1, weekend: 3, reminders: 3, strongest: 3, favorites: ["Bar prep block", "Lift"], showcase: ["long-haul", "four-good-weeks", "hundred-club"], sinceDays: 180),
        FriendSpec(name: "Theo Martins", handle: "theom", pronouns: "he/him", bio: "Comeback specialist. Hydration enthusiast (aspiring).",
                   avatar: AvatarConfig(head: .square, skin: 1, hair: .buzz, hairColor: 1, eyes: .dot, mouth: .grin, cheeks: false, outfit: .overalls, outfitColor: 4, accessory: .cap, background: .orange, frame: .none, companion: .snail),
                   personality: .varietySeeker, status: .friend, contact: "(628) 555-0112", mutual: 2, consistency: 0.58, previous: 0.41, total: 131, week: 8, comebacks: 3, lateNight: 2, weekend: 3, reminders: 1, strongest: 7, favorites: ["Drink water (seriously)", "Something outside"], showcase: ["back-again", "bounce-back"], sinceDays: 95),
        FriendSpec(name: "Sam Whitaker", handle: "samw", pronouns: "they/them", bio: "Sleep schedule: under construction.",
                   avatar: AvatarConfig(head: .round, skin: 5, hair: .none, hairColor: 0, eyes: .sleepy, mouth: .flat, cheeks: true, outfit: .hoodie, outfitColor: 5, accessory: .beanie, background: .rose, frame: .tape, companion: .sprout),
                   personality: .gentleBuilder, status: .friend, contact: "sam.w@example.com", mutual: 1, consistency: 0.67, previous: 0.6, total: 98, week: 9, comebacks: 1, lateNight: 6, weekend: 2, reminders: 0, strongest: 1, favorites: ["In bed by midnight"], showcase: ["night-owl"], sinceDays: 60),
        FriendSpec(name: "Lucía Fernández", handle: "luciaf", pronouns: "she/her", bio: "Plants, pilates, and pretending I like mornings.",
                   avatar: AvatarConfig(head: .bean, skin: 0, hair: .bob, hairColor: 4, eyes: .happy, mouth: .smile, cheeks: true, outfit: .sweater, outfitColor: 1, accessory: .flower, background: .sage, frame: .scallop, companion: .sprout),
                   personality: .gentleBuilder, status: .friend, contact: "(510) 555-0190", mutual: 2, consistency: 0.76, previous: 0.7, total: 187, week: 10, comebacks: 1, lateNight: 0, weekend: 5, reminders: 2, strongest: 7, favorites: ["Pilates", "Water the plants"], showcase: ["weekend-warrior", "steady-week"], sinceDays: 120),
        FriendSpec(name: "Dev Patel", handle: "devp", pronouns: "he/him", bio: "Climbing, coffee, and very long playlists.",
                   avatar: AvatarConfig(head: .round, skin: 3, hair: .curly, hairColor: 0, eyes: .dot, mouth: .smile, cheeks: false, outfit: .tee, outfitColor: 3, accessory: .none, background: .sky, frame: .none, companion: .none),
                   personality: .varietySeeker, status: .incoming, contact: "(415) 555-0101", mutual: 1, consistency: 0.7, previous: 0.66, total: 54, week: 6, comebacks: 1, lateNight: 1, weekend: 2, reminders: 0, strongest: 6, favorites: ["Climbing"], showcase: [], sinceDays: 0),
        FriendSpec(name: "Noor Haddad", handle: "noorh", pronouns: "she/her", bio: "Marathon training, slowly.",
                   avatar: AvatarConfig(head: .tall, skin: 2, hair: .long, hairColor: 1, eyes: .dot, mouth: .smile, cheeks: true, outfit: .hoodie, outfitColor: 0, accessory: .bandana, background: .orange, frame: .none, companion: .none),
                   personality: .deadlineSprinter, status: .suggested, contact: "noor@example.com", mutual: 1, consistency: 0.73, previous: 0.69, total: 77, week: 7, comebacks: 0, lateNight: 0, weekend: 3, reminders: 1, strongest: 1, favorites: ["Long run"], showcase: [], sinceDays: 0),
    ]

    static var seededFriendNames: [String] {
        friendSpecs.filter { $0.status == .friend }.map(\.name)
    }

    /// The demo circle shown on the onboarding "add friends" step.
    static var circlePreview: [(name: String, avatar: AvatarConfig, detail: String)] {
        friendSpecs.filter { $0.status == .friend }.map { ($0.name, $0.avatar, $0.contact) }
    }

    // MARK: Entry point

    static func seed(into context: ModelContext, me: UserProfile, firstHabit: Habit?, options: Options = Options()) {
        var rng = SeededGenerator(seed: 20_261_006)
        let today = Day.today
        let now = Date()

        if me.modelContext == nil { context.insert(me) }

        // Friends
        var friends: [String: Friend] = [:]
        for spec in friendSpecs {
            var status = spec.status
            if status == .friend, let kept = options.keptFriendNames, !kept.contains(spec.name) { status = .suggested }
            let friend = Friend(name: spec.name, handle: spec.handle, bio: spec.bio, pronouns: spec.pronouns, avatar: spec.avatar,
                                personality: spec.personality, status: status, contactDetail: spec.contact, mutualFriendCount: spec.mutual)
            friend.consistency = spec.consistency
            friend.previousConsistency = spec.previous
            friend.totalCompletions = spec.total
            friend.weekCompletions = spec.week
            friend.comebackCount = spec.comebacks
            friend.lateNightCheckIns = spec.lateNight
            friend.weekendCheckIns = spec.weekend
            friend.remindersSent = spec.reminders
            friend.strongestWeekday = spec.strongest
            friend.favoriteHabits = spec.favorites
            friend.showcaseKeys = spec.showcase
            friend.since = Day.add(-spec.sinceDays, to: today)
            friend.lastActive = now.addingTimeInterval(-Double(Int.random(in: 600...30_000, using: &rng)))
            context.insert(friend)
            friends[spec.name.firstName] = friend
        }
        func fid(_ first: String) -> UUID? { friends[first]?.id }
        func isFriend(_ first: String) -> Bool { friends[first]?.status == .friend }
        let maya = friends["Maya"], jonah = friends["Jonah"], priya = friends["Priya"], theo = friends["Theo"]
        let sam = friends["Sam"], lucia = friends["Lucía"], dev = friends["Dev"], noor = friends["Noor"]

        // Habits
        var habits: [Habit] = []
        var order = 0
        if let firstHabit {
            firstHabit.sortOrder = order
            order += 1
            if firstHabit.modelContext == nil { context.insert(firstHabit) }
            habits.append(firstHabit)
        }

        if options.includeSampleHabits {
            struct HabitSpec {
                let name: String; let category: HabitCategory; let symbol: String; let tint: TintToken
                let rule: ScheduleRule; let time: TimeOfDay; let minutes: Int; let reminder: Bool
                let shared: [String]; let notes: String; let age: Int; let rate: Double; let lastWeekRate: Double?
                var optional = false; var showStreak = true; var privacy: Visibility = .friends; var status: HabitStatus = .active
                var lateNight = false; var doneToday = false; var gap: ClosedRange<Int>? = nil
            }
            let specs: [HabitSpec] = [
                HabitSpec(name: "Morning walk", category: .movement, symbol: "figure.walk", tint: .orange, rule: .init(frequency: .daily), time: .morning, minutes: 7 * 60 + 30, reminder: true, shared: ["Maya"], notes: "Around the block, or further if the sun's out.", age: 70, rate: 0.86, lastWeekRate: nil, doneToday: true, gap: 11...13),
                HabitSpec(name: "Six glasses of water", category: .hydration, symbol: "waterbottle.fill", tint: .sky, rule: .init(frequency: .daily), time: .anytime, minutes: 11 * 60, reminder: true, shared: [], notes: "Refill the big bottle twice.", age: 60, rate: 0.74, lastWeekRate: nil),
                HabitSpec(name: "Read 20 pages", category: .study, symbol: "book.fill", tint: .gold, rule: .init(frequency: .weekdays), time: .evening, minutes: 21 * 60, reminder: true, shared: ["Jonah", "Priya"], notes: "Book club pick: The Remains of the Day.", age: 45, rate: 0.72, lastWeekRate: nil),
                HabitSpec(name: "Up by 7:30", category: .sleep, symbol: "alarm.fill", tint: .rose, rule: .init(frequency: .weekdays), time: .morning, minutes: 7 * 60 + 25, reminder: false, shared: [], notes: "Feet on the floor, phone across the room.", age: 56, rate: 0.8, lastWeekRate: nil, doneToday: true),
                HabitSpec(name: "Strength session", category: .movement, symbol: "dumbbell.fill", tint: .burgundy, rule: .init(frequency: .timesPerWeek, timesPerWeek: 3), time: .afternoon, minutes: 17 * 60 + 30, reminder: true, shared: [], notes: "20 minutes. Bodyweight counts.", age: 40, rate: 0.45, lastWeekRate: nil, gap: 18...24),
                HabitSpec(name: "Lights out by 11", category: .sleep, symbol: "moon.stars.fill", tint: .sky, rule: .init(frequency: .daily), time: .evening, minutes: 22 * 60 + 30, reminder: true, shared: [], notes: "Book instead of phone for the last 20 minutes.", age: 35, rate: 0.86, lastWeekRate: 0.3, showStreak: false, lateNight: true),
                HabitSpec(name: "Water the plants", category: .home, symbol: "camera.macro", tint: .sage, rule: .init(frequency: .custom, weekdays: [1, 4]), time: .anytime, minutes: 10 * 60, reminder: false, shared: [], notes: "Fern is dramatic. Check her first.", age: 50, rate: 0.75, lastWeekRate: nil, optional: true),
                HabitSpec(name: "Journal three lines", category: .creative, symbol: "pencil.line", tint: .rose, rule: .init(frequency: .daily), time: .evening, minutes: 22 * 60, reminder: false, shared: [], notes: "What happened, how it felt, one good thing.", age: 28, rate: 0.5, lastWeekRate: nil, optional: true, privacy: .onlyMe),
                HabitSpec(name: "Guitar practice", category: .creative, symbol: "guitars.fill", tint: .gold, rule: .init(frequency: .custom, weekdays: [3, 5, 7]), time: .evening, minutes: 19 * 60, reminder: false, shared: [], notes: "Paused until the new strings arrive.", age: 90, rate: 0.6, lastWeekRate: nil, status: .paused),
            ]
            let noteBank = ["Felt good today.", "Short one, still counts.", "Rained — did it anyway.", "Sunrise was unreal.", "Chapter 7. Stevens, my guy.", "Slow start, strong finish.", "Did the tiny version.", "Brought a friend!"]
            let weekStart = Day.startOfWeek(today)
            let lastWeekStart = Day.add(-7, to: weekStart)

            for spec in specs {
                let participantIDs = spec.shared.compactMap { isFriend($0) ? fid($0) : nil }
                let habit = Habit(
                    name: spec.name, category: spec.category, symbol: spec.symbol, tint: spec.tint,
                    schedule: HabitSchedule(rule: spec.rule), timeOfDay: spec.time, scheduledMinutes: spec.minutes,
                    reminderEnabled: spec.reminder, reminderMinutes: spec.minutes, isShared: !participantIDs.isEmpty,
                    participantIDs: participantIDs, notes: spec.notes, proof: .optional, privacy: spec.privacy,
                    startDate: Day.add(-spec.age, to: today), showStreak: spec.showStreak, isOptional: spec.optional,
                    status: spec.status, createdAt: Day.add(-spec.age, to: today), sortOrder: order)
                order += 1
                context.insert(habit)
                habits.append(habit)

                // History
                var weekCount = 0
                var currentWeek = Day.startOfWeek(Day.add(-spec.age, to: today))
                for offset in stride(from: spec.age, through: 1, by: -1) {
                    let day = Day.add(-offset, to: today)
                    let ws = Day.startOfWeek(day)
                    if ws != currentWeek { currentWeek = ws; weekCount = 0 }
                    if spec.status == .paused, offset < 12 { continue }
                    if let gap = spec.gap, gap.contains(offset) { continue }
                    var rate = spec.rate
                    if let last = spec.lastWeekRate, ws == lastWeekStart || ws < lastWeekStart { rate = last }
                    if ws == weekStart, spec.lastWeekRate != nil { rate = spec.rate }
                    let scheduled: Bool
                    if spec.rule.isFlexible {
                        scheduled = weekCount < spec.rule.timesPerWeek && [2, 4, 6, 7].contains(Day.weekday(day))
                    } else {
                        scheduled = spec.rule.isScheduled(on: day)
                    }
                    let bonus = !scheduled && spec.optional && rng.chance(0.15)
                    guard (scheduled && rng.chance(rate)) || bonus else { continue }
                    weekCount += 1
                    var minutes = spec.minutes + Int.random(in: -40...50, using: &rng)
                    if spec.lateNight, rng.chance(0.45) { minutes = 23 * 60 + Int.random(in: 30...58, using: &rng) }
                    minutes = min(max(minutes, 5 * 60), 23 * 60 + 59)
                    let checkIn = CheckIn(habit: nil, day: day, completedAt: Day.date(day, atMinutes: minutes),
                                          note: rng.chance(0.18) ? (noteBank.randomElement(using: &rng) ?? "") : "")
                    context.insert(checkIn)
                    habit.checkIns.append(checkIn)
                }
                // Mark comebacks in history so stats and feed agree.
                let days = habit.myCompletionDays
                for checkIn in habit.checkIns where Stats.isComeback(day: checkIn.day, rule: spec.rule, start: habit.startDate, completions: days) {
                    checkIn.isComeback = true
                }
                if spec.doneToday {
                    let checkIn = CheckIn(habit: nil, day: today, completedAt: min(now, Day.date(today, atMinutes: spec.minutes)), note: spec.name == "Morning walk" ? "Sunrise was unreal." : "")
                    context.insert(checkIn)
                    habit.checkIns.append(checkIn)
                }

                // Friends' check-ins on shared habits.
                for friendID in participantIDs {
                    let friendRate = friendID == maya?.id ? 0.92 : (friendID == jonah?.id ? 0.8 : 0.74)
                    for offset in stride(from: min(spec.age, 42), through: 0, by: -1) {
                        let day = Day.add(-offset, to: today)
                        guard spec.rule.isScheduled(on: day), rng.chance(friendRate) else { continue }
                        if offset == 0, friendID != maya?.id { continue }
                        let minutes = spec.minutes + Int.random(in: -30...45, using: &rng)
                        let checkIn = CheckIn(habit: nil, friendID: friendID, day: day,
                                              completedAt: offset == 0 ? min(now, Day.date(day, atMinutes: minutes)) : Day.date(day, atMinutes: minutes))
                        context.insert(checkIn)
                        habit.checkIns.append(checkIn)
                    }
                }
            }
        }

        // Groups and challenges
        let weekStart = Day.startOfWeek(today)
        func members(_ names: [String]) -> [UUID] { names.compactMap { fid($0) } }

        let hydration = HabitGroup(name: "Hydration Station", detail: "Five friends, many water bottles, zero excuses.", symbol: "drop.fill", tint: .sky,
                                   memberIDs: members(["Theo", "Maya", "Sam", "Jonah"]), createdAt: Day.add(-50, to: today), notify: .all)
        let library = HabitGroup(name: "Library Goblins", detail: "Quiet hours, loud progress. Bar prep + book club.", symbol: "book.fill", tint: .gold,
                                 memberIDs: members(["Priya", "Jonah", "Lucía"]), createdAt: Day.add(-35, to: today), notify: .milestones)
        let outside = HabitGroup(name: "Touch Grass Club", detail: "One outdoor thing a day. Puddles count.", symbol: "tree.fill", tint: .sage,
                                 memberIDs: members(["Maya", "Lucía", "Noor", "Theo"]), isMember: false, isInvited: true, createdAt: Day.add(-20, to: today), notify: .all)
        outside.invitedByID = lucia?.id
        [hydration, library, outside].forEach { context.insert($0) }
        habits.first { $0.name == "Six glasses of water" }?.groupID = hydration.id
        habits.first { $0.name == "Read 20 pages" }?.groupID = library.id

        let water = Challenge(title: "Drink water five days this week", detail: "Everyone logs a water day. Five each fills the jar.", symbol: "drop.fill", unit: "water days", goal: 25,
                              startDate: weekStart, endDate: Day.add(6, to: weekStart))
        water.add(3, for: me.id)
        for (name, count) in [("Theo", 5), ("Maya", 6), ("Sam", 4), ("Jonah", 5)] { if let id = fid(name) { water.add(count, for: id) } }
        water.reactedMilestones = [25]
        hydration.challenges.append(water)

        let study = Challenge(title: "Reach 40 collective study sessions", detail: "Any focused block of 25+ minutes counts.", symbol: "book.fill", unit: "sessions", goal: 40,
                              startDate: Day.add(-9, to: today), endDate: Day.add(5, to: today))
        study.add(7, for: me.id)
        for (name, count) in [("Priya", 12), ("Jonah", 8), ("Lucía", 4)] { if let id = fid(name) { study.add(count, for: id) } }
        study.reactedMilestones = [25, 50]
        library.challenges.append(study)

        let reading = Challenge(title: "Finish 20 reading sessions together", detail: "Twenty pages or twenty minutes, your call.", symbol: "text.book.closed.fill", unit: "reading sessions", goal: 20,
                                startDate: Day.add(-24, to: today), endDate: Day.add(-14, to: today))
        reading.add(6, for: me.id)
        for (name, count) in [("Priya", 6), ("Jonah", 7), ("Lucía", 3)] { if let id = fid(name) { reading.add(count, for: id) } }
        reading.completedAt = Day.add(-15, to: today)
        reading.celebrated = true
        reading.reactedMilestones = [25, 50, 75, 100]
        library.challenges.append(reading)

        let predict = Challenge(title: "Who finishes the book first?", detail: "The Remains of the Day. Place your guess — bragging rights only.", symbol: "wand.and.stars", unit: "votes", goal: 1,
                                startDate: Day.add(-3, to: today), endDate: Day.add(4, to: today), kind: .prediction)
        if let p = priya?.id, let j = jonah?.id, let l = lucia?.id {
            predict.votes = [PredictionVote(voterID: j, choiceID: p), PredictionVote(voterID: l, choiceID: p), PredictionVote(voterID: p, choiceID: j)]
        }
        library.challenges.append(predict)

        let grass = Challenge(title: "One outdoor activity each day", detail: "Walks, bikes, puddles. Outside is outside.", symbol: "tree.fill", unit: "outings", goal: 28,
                              startDate: weekStart, endDate: Day.add(6, to: weekStart))
        for (name, count) in [("Maya", 4), ("Lucía", 3), ("Noor", 3), ("Theo", 2)] { if let id = fid(name) { grass.add(count, for: id) } }
        outside.challenges.append(grass)

        // Collectibles
        let favorites: Set<String> = ["back-again", "sup-last-minute"]
        let unlocked: [String: (daysAgo: Int, reason: String)] = [
            "first-stamp": (68, "First check-in: Morning walk"),
            "margin-notes": (60, "Noted on Morning walk"),
            "plus-one": (66, "Started Morning walk with Maya"),
            "steady-week": (20, "86% consistency the week of \(Day.add(-27, to: today).formatted(.dateTime.month().day()))"),
            "week-unbroken": (30, "7 in a row on Morning walk"),
            "back-again": (10, "Came back to Morning walk after 3 missed days"),
            "in-sync": (25, "Matched Maya on Morning walk"),
            "night-owl": (8, "Lights out by 11, checked in at 11:41pm"),
            "housewarming": (50, "Joined Hydration Station"),
            "halfway-toast": (5, "Toasted Library Goblins at 50%"),
            "gentle-nudge": (12, "Nudged Theo about water"),
            "sup-last-minute": (7, "Most check-ins after 9pm last week"),
            "gift-daisy": (3, "A gift from Maya"),
        ]
        for (index, spec) in Catalog.collectibles.enumerated() {
            let item = Collectible(key: spec.key, name: spec.name, form: spec.form, category: spec.category, rarity: spec.rarity, shape: spec.shape,
                                   symbol: spec.symbol, tint: spec.tint, blurb: spec.blurb, howToEarn: spec.howToEarn, sortIndex: index)
            if let info = unlocked[spec.key] {
                item.isUnlocked = true
                item.isFavorite = favorites.contains(spec.key)
                item.earnedAt = Day.add(-info.daysAgo, to: today).addingTimeInterval(14 * 3600)
                item.earnedFor = info.reason
                item.isSeen = true
                if spec.key == "gift-daisy" { item.giftedByID = maya?.id }
            }
            context.insert(item)
        }
        me.showcaseKeys = ["week-unbroken", "back-again", "sup-last-minute"]

        // Cosmetics
        let unlockedCosmetics: Set<String> = ["acc-headphones", "acc-flower", "acc-cap"]
        for spec in Catalog.cosmetics {
            context.insert(CosmeticItem(key: spec.key, slot: spec.slot, value: spec.value, name: spec.name, unlockHint: spec.unlockHint,
                                        isUnlocked: spec.starter || unlockedCosmetics.contains(spec.key)))
        }

        // Activity feed
        func activity(_ kind: ActivityKind, _ actor: Friend?, _ title: String, _ detail: String = "", symbol: String? = nil, tint: TintToken = .burgundy,
                      hoursAgo: Double, habitID: UUID? = nil, groupID: UUID? = nil, reactions: [(Friend?, ReactionKind)] = [], comments: [(Friend?, String)] = [],
                      mine: ReactionKind? = nil, myComment: String? = nil) {
            if let actor, actor.status != .friend { return }
            let item = ActivityItem(kind: kind, actorID: actor?.id, title: title, detail: detail, symbol: symbol, tint: tint, habitID: habitID, groupID: groupID,
                                    createdAt: now.addingTimeInterval(-hoursAgo * 3600))
            context.insert(item)
            for (author, kind) in reactions {
                guard let author, author.status == .friend else { continue }
                let reaction = Reaction(kind: kind, authorID: author.id, createdAt: item.createdAt.addingTimeInterval(600))
                context.insert(reaction)
                item.reactions.append(reaction)
            }
            if let mine {
                let reaction = Reaction(kind: mine, authorID: nil, createdAt: item.createdAt.addingTimeInterval(900))
                context.insert(reaction)
                item.reactions.append(reaction)
            }
            if let myComment {
                let comment = Comment(authorID: nil, text: myComment, createdAt: item.createdAt.addingTimeInterval(1500))
                context.insert(comment)
                item.comments.append(comment)
            }
            for (author, text) in comments {
                guard let author, author.status == .friend else { continue }
                let comment = Comment(authorID: author.id, text: text, createdAt: item.createdAt.addingTimeInterval(1200))
                context.insert(comment)
                item.comments.append(comment)
            }
        }
        let walk = habits.first { $0.name == "Morning walk" }
        let read = habits.first { $0.name == "Read 20 pages" }

        activity(.sharedHabit, maya, "Morning walk", "Sunrise loop with the dog. Your turn!", symbol: "figure.walk", tint: .orange, hoursAgo: 1.5, habitID: walk?.id,
                 reactions: [(jonah, .cheer), (lucia, .heart)], comments: [(lucia, "That dog is the real MVP.")])
        if walk?.isCompleted(on: today) == true {
            activity(.checkIn, nil, "Morning walk", "Sunrise was unreal.", symbol: "figure.walk", tint: .orange, hoursAgo: 1.2, habitID: walk?.id,
                     reactions: [(maya, .heart), (jonah, .clap)], comments: [(maya, "Same time tomorrow?")])
        }
        activity(.comeback, theo, "Drink water (seriously)", "Back after four days off. Big bottle refilled.", symbol: "drop.fill", tint: .sky, hoursAgo: 3,
                 reactions: [(maya, .fire), (sam, .cheer)], mine: .heart, myComment: "Welcome back!!")
        activity(.groupMilestone, nil, "Hydration Station hit 75%", "18 of 25 water days logged. Two days to go.", symbol: "flag.checkered", tint: .sage, hoursAgo: 5, groupID: hydration.id,
                 reactions: [(theo, .cheer), (maya, .clap)])
        activity(.checkIn, priya, "Bar prep block", "Fifth focused block this week. Snacks were consumed.", symbol: "pencil.and.ruler.fill", tint: .gold, hoursAgo: 7,
                 reactions: [(jonah, .wow)], mine: .clap)
        activity(.sharedHabit, jonah, "Read 20 pages", "Chapter 7. Stevens, my guy.", symbol: "book.fill", tint: .gold, hoursAgo: 14, habitID: read?.id,
                 reactions: [(priya, .heart)], comments: [(priya, "No spoilers!!")])
        activity(.prediction, nil, "Prediction result", "Library Goblins guessed Priya would finish the bar prep set first — she did, by two days.", symbol: "wand.and.stars", tint: .ink, hoursAgo: 20, groupID: library.id)
        activity(.checkIn, sam, "In bed by midnight", "11:58pm. Technically counts.", symbol: "moon.stars.fill", tint: .sky, hoursAgo: 22,
                 reactions: [(maya, .clap), (theo, .fire)], comments: [(theo, "Living on the edge.")], mine: .wow)
        activity(.ranking, nil, "Most check-ins this week", "Priya, Maya and Jonah are setting the pace. Everyone's on the board.", symbol: "list.number", tint: .burgundy, hoursAgo: 26)
        activity(.checkIn, lucia, "Pilates", "Wobbly but present.", symbol: "figure.yoga", tint: .rose, hoursAgo: 30, reactions: [(priya, .heart), (maya, .cheer)], mine: .cheer)
        activity(.collectible, priya, "Earned Groove Found", "21 days in a row on Lift.", symbol: "music.note", tint: .rose, hoursAgo: 34, reactions: [(jonah, .wow)])
        activity(.comeback, sam, "In bed by midnight", "Back on track after a rough week.", symbol: "moon.stars.fill", tint: .sky, hoursAgo: 46)
        activity(.checkIn, jonah, "Run club", "5k, mostly jogging, partly walking, fully counted.", symbol: "figure.run", tint: .orange, hoursAgo: 52, reactions: [(maya, .fire)], mine: .fire, myComment: "Fully counted!")
        activity(.gift, maya, "Sent you a sticker", "Pressed Daisy — for your book.", symbol: "gift.fill", tint: .gold, hoursAgo: 72)
        activity(.joinedGroup, lucia, "Started Touch Grass Club", "One outdoor thing a day. You're invited.", symbol: "tree.fill", tint: .sage, hoursAgo: 80, groupID: outside.id)

        // Reminders
        if let maya { context.insert(Reminder(fromID: maya.id, toID: nil, habitName: "Read 20 pages", message: "Doing mine now, want to join?", createdAt: now.addingTimeInterval(-26 * 3600))) }
        if let theo { context.insert(Reminder(fromID: nil, toID: theo.id, habitName: "Drink water (seriously)", message: "Tiny version counts! Even two minutes.", createdAt: now.addingTimeInterval(-50 * 3600))) }
        if let sam { context.insert(Reminder(fromID: nil, toID: sam.id, habitName: "In bed by midnight", message: "You've got this. I believe in you.", createdAt: now.addingTimeInterval(-30 * 3600))) }

        // Gifts
        if let jonah { context.insert(Gift(kind: .reminderPass, fromID: jonah.id, toID: nil, message: "For the busy week. Use it wisely.", createdAt: now.addingTimeInterval(-90 * 3600), opened: true)) }
        me.reminderPasses = 1
        if let theo { context.insert(Gift(kind: .cosmetic, fromID: theo.id, toID: nil, itemKey: "acc-bandana", message: "Matching bandanas for the hydration crew.", createdAt: now.addingTimeInterval(-4 * 3600))) }
        if let maya { context.insert(Gift(kind: .comebackBoost, fromID: maya.id, toID: nil, message: "Just in case. No pressure!", createdAt: now.addingTimeInterval(-28 * 3600))) }

        // Quizzes
        let circle = [maya, jonah, priya, theo, sam, lucia].compactMap { $0 }.filter { $0.status == .friend }
        let optionIDs = Array(circle.prefix(4).map(\.id)) + [me.id]
        let voters = circle.map(\.id)
        let quizPlan: [(Int, UUID?, Bool)] = [ // (prompt index, favored person, I've voted)
            (0, priya?.id, true), (1, sam?.id, false), (2, maya?.id, true), (4, priya?.id, false), (5, theo?.id, false), (6, maya?.id, true),
        ]
        for (index, (promptIndex, favored, iVoted)) in quizPlan.enumerated() {
            let prompt = Catalog.quizPrompts[promptIndex]
            var options = optionIDs
            if let favored, !options.contains(favored) { options[0] = favored }
            let quiz = Quiz(prompt: prompt.prompt, tag: prompt.tag, optionIDs: options, createdByID: voters[safe: index % max(voters.count, 1)],
                            createdAt: now.addingTimeInterval(-Double(index + 1) * 20 * 3600))
            context.insert(quiz)
            for voter in voters {
                let choice = rng.chance(0.65) ? (favored ?? options[0]) : (options.filter { $0 != voter }.randomElement(using: &rng) ?? options[0])
                guard choice != voter else { continue }
                let response = QuizResponse(voterID: voter, choiceID: choice)
                context.insert(response)
                quiz.responses.append(response)
            }
            if iVoted, let favored {
                let response = QuizResponse(voterID: nil, choiceID: favored)
                context.insert(response)
                quiz.responses.append(response)
            }
        }

        // Past recaps
        let pastTitles = ["Last-Minute Legend", "Comeback Kid", "Surprisingly Consistent", "Weekend MVP"]
        let pastHeadlines = ["A late-night kind of week.", "Two comebacks and a full Sunday.", "Your steadiest week yet.", "Saturday carried the team."]
        for weeksAgo in 1...4 {
            context.insert(WeeklyRecap(weekStart: Day.add(-7 * weeksAgo, to: weekStart), completions: [31, 27, 34, 24][weeksAgo - 1],
                                       consistency: [0.78, 0.71, 0.86, 0.64][weeksAgo - 1], strongestWeekday: [3, 1, 4, 7][weeksAgo - 1],
                                       headline: pastHeadlines[weeksAgo - 1], superlativeTitle: pastTitles[weeksAgo - 1],
                                       topHabitName: ["Morning walk", "Up by 7:30", "Six glasses of water", "Morning walk"][weeksAgo - 1]))
        }

        // Notifications
        func note(_ kind: NotificationKind, _ actor: Friend?, _ title: String, _ body: String, hoursAgo: Double, read: Bool = false, ref: UUID? = nil) {
            context.insert(NotificationItem(kind: kind, actorID: actor?.id, title: title, body: body, createdAt: now.addingTimeInterval(-hoursAgo * 3600), isRead: read, refID: ref))
        }
        if let dev, dev.status == .incoming { note(.friendRequest, dev, "Dev Patel wants to be friends", "You have 1 mutual friend: Jonah.", hoursAgo: 2, ref: dev.id) }
        note(.groupInvite, lucia, "Join Touch Grass Club?", "Lucía invited you. One outdoor thing a day — puddles count.", hoursAgo: 4, ref: outside.id)
        if let maya, maya.status == .friend { note(.habitInvite, maya, "Maya invited you to “Sunrise stretch”", "Daily · morning. She'll stretch with you.", hoursAgo: 6, ref: maya.id) }
        note(.reaction, jonah, "Jonah applauded your Morning walk", "Your check-in from this morning.", hoursAgo: 1)
        note(.comment, maya, "Maya commented", "“Same time tomorrow?”", hoursAgo: 1.1)
        note(.gift, theo, "Theo sent you a gift", "Open it from your profile.", hoursAgo: 4)
        note(.groupMilestone, nil, "Hydration Station hit 75%", "Two more water days fills the jar.", hoursAgo: 5)
        note(.quiz, priya, "New friend quiz", "Priya asked: Who is secretly the most competitive?", hoursAgo: 9)
        note(.reminder, maya, "A nudge from Maya", "“Doing mine now, want to join?” — Read 20 pages", hoursAgo: 26, read: true)
        note(.recap, nil, "Your weekly recap is ready", "See who won Last-Minute Legend this week.", hoursAgo: 30, read: true)
        note(.award, nil, "New sticker: Back Again", "Came back to Morning walk after 3 missed days.", hoursAgo: 240, read: true)
        _ = noor

        try? context.save()
    }

    /// Creates the demo account holder used by "Explore with demo data".
    static func makeDemoProfile() -> UserProfile {
        let profile = UserProfile(
            name: "Riley Chen", handle: "riley", bio: "Trying to be a morning person. Mostly succeeding on Tuesdays.", pronouns: "",
            avatar: AvatarConfig(head: .round, skin: 1, hair: .bob, hairColor: 1, eyes: .happy, mouth: .smile, cheeks: true, outfit: .sweater, outfitColor: 0,
                                 accessory: .glasses, background: .rose, frame: .stamp, companion: .sprout),
            personality: .socialMotivator, interests: ["move", "read", "sleep", "friends"], joinedAt: Day.add(-70, to: Day.today), isDemo: true)
        return profile
    }
}
