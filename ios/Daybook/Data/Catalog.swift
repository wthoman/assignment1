import Foundation

/// Static content: collectibles, cosmetics, personalities, quiz prompts and templates.
enum Catalog {
    // MARK: Collectibles

    struct CollectibleSpec {
        let key: String
        let name: String
        let form: CollectibleForm
        let category: CollectibleCategory
        let rarity: Rarity
        let shape: StickerShape
        let symbol: String
        let tint: TintToken
        let blurb: String
        let howToEarn: String
    }

    static let collectibles: [CollectibleSpec] = [
        // Firsts
        .init(key: "first-stamp", name: "First Stamp", form: .stamp, category: .firsts, rarity: .common, shape: .stamp, symbol: "star.fill", tint: .burgundy, blurb: "Everything starts with one wobbly checkmark.", howToEarn: "Complete any habit for the first time."),
        .init(key: "plus-one", name: "Plus One", form: .sticker, category: .firsts, rarity: .common, shape: .circle, symbol: "heart.fill", tint: .rose, blurb: "Habits are lighter when someone else is carrying one too.", howToEarn: "Start your first shared habit."),
        .init(key: "proof-positive", name: "Proof Positive", form: .sticker, category: .firsts, rarity: .common, shape: .ticket, symbol: "camera.fill", tint: .gold, blurb: "Pics or it didn't happen. (It happened.)", howToEarn: "Attach photo proof to a check-in."),
        .init(key: "margin-notes", name: "Margin Notes", form: .sticker, category: .firsts, rarity: .common, shape: .scallop, symbol: "pencil.line", tint: .cream, blurb: "A few words about how it went.", howToEarn: "Add a note to a check-in."),
        // Consistency
        .init(key: "steady-week", name: "Steady Week", form: .badge, category: .consistency, rarity: .uncommon, shape: .badge, symbol: "figure.walk", tint: .sage, blurb: "Not perfect. Just steady. That's the trick.", howToEarn: "Reach 80% consistency across a week."),
        .init(key: "four-good-weeks", name: "Four Good Weeks", form: .badge, category: .consistency, rarity: .rare, shape: .ribbon, symbol: "rosette", tint: .burgundy, blurb: "Twenty-eight days of mostly showing up.", howToEarn: "Hold 80%+ rolling consistency for four weeks."),
        .init(key: "full-page", name: "Full Page", form: .stamp, category: .consistency, rarity: .uncommon, shape: .stamp, symbol: "checkmark.seal.fill", tint: .orange, blurb: "Every scheduled habit, stamped in one day.", howToEarn: "Complete everything scheduled for a day."),
        .init(key: "hundred-club", name: "The Hundred Club", form: .badge, category: .consistency, rarity: .rare, shape: .scallop, symbol: "crown.fill", tint: .gold, blurb: "One hundred check-ins. Each one counted.", howToEarn: "Log 100 total completions."),
        .init(key: "all-seven", name: "All Seven", form: .sticker, category: .consistency, rarity: .legendary, shape: .star, symbol: "sun.max.fill", tint: .orange, blurb: "Showed up every single day this week.", howToEarn: "Complete at least one habit on all seven days of a week."),
        // Streaks
        .init(key: "week-unbroken", name: "Week Unbroken", form: .sticker, category: .streak, rarity: .uncommon, shape: .circle, symbol: "flame.fill", tint: .orange, blurb: "Seven in a row. Nice rhythm.", howToEarn: "Reach a 7-day streak on any habit."),
        .init(key: "groove-found", name: "Groove Found", form: .badge, category: .streak, rarity: .rare, shape: .badge, symbol: "music.note", tint: .rose, blurb: "Three weeks without missing a beat.", howToEarn: "Reach a 21-day streak on any habit."),
        .init(key: "long-haul", name: "Long Haul", form: .badge, category: .streak, rarity: .legendary, shape: .ribbon, symbol: "mountain.2.fill", tint: .burgundy, blurb: "Fifty days. Tell your grandkids.", howToEarn: "Reach a 50-day streak on any habit."),
        // Comebacks
        .init(key: "back-again", name: "Back Again", form: .sticker, category: .comeback, rarity: .uncommon, shape: .heart, symbol: "arrow.uturn.up", tint: .rose, blurb: "Missing a day is normal. Coming back is the skill.", howToEarn: "Check in after missing two or more scheduled days."),
        .init(key: "bounce-back", name: "Bounce Back ×3", form: .sticker, category: .comeback, rarity: .rare, shape: .scallop, symbol: "arrow.up.heart.fill", tint: .orange, blurb: "Three comebacks. You're getting good at starting again.", howToEarn: "Make three comebacks in one month."),
        .init(key: "fresh-page", name: "Fresh Page", form: .stamp, category: .comeback, rarity: .rare, shape: .ticket, symbol: "doc.text.fill", tint: .sage, blurb: "A whole week away, then right back to it.", howToEarn: "Return to a habit after a week-long break."),
        .init(key: "sunrise-kid", name: "Sunrise Kid", form: .sticker, category: .comeback, rarity: .legendary, shape: .star, symbol: "sunrise.fill", tint: .gold, blurb: "Your best week came right after your hardest one.", howToEarn: "Beat last week's consistency by 30 points."),
        // Social
        .init(key: "in-sync", name: "In Sync", form: .sticker, category: .social, rarity: .uncommon, shape: .circle, symbol: "person.2.fill", tint: .sky, blurb: "Same habit, same day, same tiny victory.", howToEarn: "Complete a shared habit on the same day as a partner."),
        .init(key: "cheerleader", name: "Cheerleader", form: .sticker, category: .social, rarity: .uncommon, shape: .star, symbol: "megaphone.fill", tint: .rose, blurb: "Your reactions have a fan club.", howToEarn: "Send 10 reactions to friends."),
        .init(key: "gentle-nudge", name: "Gentle Nudge", form: .stamp, category: .social, rarity: .common, shape: .ticket, symbol: "bell.fill", tint: .sky, blurb: "A tiny tap on the shoulder, delivered kindly.", howToEarn: "Send a friend an encouraging reminder."),
        .init(key: "care-package", name: "Care Package", form: .badge, category: .social, rarity: .uncommon, shape: .badge, symbol: "gift.fill", tint: .orange, blurb: "Sent a little something to keep someone going.", howToEarn: "Gift a power-up or cosmetic to a friend."),
        .init(key: "welcome-committee", name: "Welcome Back Committee", form: .sticker, category: .social, rarity: .rare, shape: .heart, symbol: "party.popper.fill", tint: .gold, blurb: "First to celebrate a friend's return.", howToEarn: "Celebrate a friend's comeback."),
        .init(key: "night-owl", name: "Night Owl", form: .sticker, category: .social, rarity: .common, shape: .circle, symbol: "moon.fill", tint: .sky, blurb: "Checked in after 10pm. The day still counts.", howToEarn: "Complete a habit after 10pm."),
        .init(key: "weekend-warrior", name: "Weekend Warrior", form: .sticker, category: .social, rarity: .common, shape: .scallop, symbol: "bicycle", tint: .sage, blurb: "Saturday and Sunday showed up too.", howToEarn: "Complete habits on both weekend days."),
        // Group
        .init(key: "housewarming", name: "Housewarming", form: .stamp, category: .group, rarity: .common, shape: .scallop, symbol: "house.fill", tint: .orange, blurb: "Welcome to the group. Snacks are in the kitchen.", howToEarn: "Join or create a group."),
        .init(key: "halfway-toast", name: "Halfway Toast", form: .sticker, category: .group, rarity: .uncommon, shape: .circle, symbol: "wineglass.fill", tint: .gold, blurb: "Raised a glass at the halfway mark.", howToEarn: "React to a group milestone."),
        .init(key: "goal-reached", name: "Goal Reached", form: .badge, category: .group, rarity: .rare, shape: .ribbon, symbol: "flag.checkered", tint: .sage, blurb: "Everyone chipped in. The jar is full.", howToEarn: "Help your group hit a collective goal."),
        .init(key: "oracle", name: "The Oracle", form: .stamp, category: .group, rarity: .rare, shape: .stamp, symbol: "wand.and.stars", tint: .ink, blurb: "Called it before anyone else did.", howToEarn: "Correctly predict a challenge winner."),
        // Superlatives
        .init(key: "sup-last-minute", name: "Last-Minute Legend", form: .badge, category: .superlative, rarity: .rare, shape: .ribbon, symbol: "alarm.fill", tint: .burgundy, blurb: "Cutting it close, every time.", howToEarn: "Most check-ins after 9pm in your circle this week."),
        .init(key: "sup-weekend-mvp", name: "Weekend MVP", form: .badge, category: .superlative, rarity: .rare, shape: .star, symbol: "trophy.fill", tint: .gold, blurb: "Saturday's main character.", howToEarn: "Most weekend completions among friends."),
        .init(key: "sup-comeback-kid", name: "Comeback Kid", form: .badge, category: .superlative, rarity: .rare, shape: .heart, symbol: "arrow.uturn.up.circle.fill", tint: .orange, blurb: "Got knocked down, got back up.", howToEarn: "Most comebacks among friends this week."),
        .init(key: "sup-reminder", name: "Professional Reminder Sender", form: .badge, category: .superlative, rarity: .rare, shape: .ticket, symbol: "bell.and.waves.left.and.right.fill", tint: .sky, blurb: "Your nudges have a fan club.", howToEarn: "Send the most supportive reminders this week."),
        .init(key: "sup-surprise", name: "Surprisingly Consistent", form: .badge, category: .superlative, rarity: .legendary, shape: .badge, symbol: "sparkles", tint: .sage, blurb: "Nobody saw it coming. You did.", howToEarn: "Largest consistency jump among friends."),
        // Gifted
        .init(key: "gift-daisy", name: "Pressed Daisy", form: .sticker, category: .gifted, rarity: .uncommon, shape: .scallop, symbol: "camera.macro", tint: .cream, blurb: "Someone thought of you.", howToEarn: "Receive it as a gift from a friend."),
        .init(key: "gift-postcard", name: "Postcard From Maya", form: .stamp, category: .gifted, rarity: .rare, shape: .stamp, symbol: "envelope.fill", tint: .rose, blurb: "Wish you were here (doing your habits).", howToEarn: "Receive it as a gift from a friend."),
    ]

    static func collectible(_ key: String) -> CollectibleSpec? { collectibles.first { $0.key == key } }

    // MARK: Cosmetics

    struct CosmeticSpec {
        let key: String
        let slot: CosmeticSlot
        let value: String
        let name: String
        let unlockHint: String
        let starter: Bool
    }

    static let cosmetics: [CosmeticSpec] = [
        .init(key: "hair-none", slot: .hair, value: "none", name: "None", unlockHint: "Starter", starter: true),
        .init(key: "hair-buzz", slot: .hair, value: "buzz", name: "Buzz", unlockHint: "Starter", starter: true),
        .init(key: "hair-bob", slot: .hair, value: "bob", name: "Bob", unlockHint: "Starter", starter: true),
        .init(key: "hair-curly", slot: .hair, value: "curly", name: "Curls", unlockHint: "Starter", starter: true),
        .init(key: "hair-bun", slot: .hair, value: "bun", name: "Top bun", unlockHint: "Starter", starter: true),
        .init(key: "hair-long", slot: .hair, value: "long", name: "Long", unlockHint: "Starter", starter: true),
        .init(key: "hair-swoop", slot: .hair, value: "swoop", name: "Swoop", unlockHint: "Log 25 check-ins", starter: false),
        .init(key: "out-tee", slot: .outfit, value: "tee", name: "Tee", unlockHint: "Starter", starter: true),
        .init(key: "out-hoodie", slot: .outfit, value: "hoodie", name: "Hoodie", unlockHint: "Starter", starter: true),
        .init(key: "out-sweater", slot: .outfit, value: "sweater", name: "Cozy sweater", unlockHint: "Starter", starter: true),
        .init(key: "out-stripe", slot: .outfit, value: "stripe", name: "Breton stripe", unlockHint: "Complete 10 shared check-ins", starter: false),
        .init(key: "out-overalls", slot: .outfit, value: "overalls", name: "Overalls", unlockHint: "Hit a group goal", starter: false),
        .init(key: "acc-none", slot: .accessory, value: "none", name: "None", unlockHint: "Starter", starter: true),
        .init(key: "acc-glasses", slot: .accessory, value: "glasses", name: "Round glasses", unlockHint: "Starter", starter: true),
        .init(key: "acc-beanie", slot: .accessory, value: "beanie", name: "Beanie", unlockHint: "Earn Weekend Warrior", starter: false),
        .init(key: "acc-flower", slot: .accessory, value: "flower", name: "Hair flower", unlockHint: "Make a comeback", starter: false),
        .init(key: "acc-headphones", slot: .accessory, value: "headphones", name: "Headphones", unlockHint: "Join a group", starter: false),
        .init(key: "acc-cap", slot: .accessory, value: "cap", name: "Ball cap", unlockHint: "Reach a 7-day streak", starter: false),
        .init(key: "acc-bandana", slot: .accessory, value: "bandana", name: "Bandana", unlockHint: "Gift from a friend", starter: false),
        .init(key: "bg-rose", slot: .background, value: "rose", name: "Dusty rose", unlockHint: "Starter", starter: true),
        .init(key: "bg-sage", slot: .background, value: "sage", name: "Sage", unlockHint: "Starter", starter: true),
        .init(key: "bg-orange", slot: .background, value: "orange", name: "Apricot", unlockHint: "Starter", starter: true),
        .init(key: "bg-cream", slot: .background, value: "cream", name: "Cream", unlockHint: "Starter", starter: true),
        .init(key: "bg-sky", slot: .background, value: "sky", name: "Pale sky", unlockHint: "Complete 5 sleep check-ins", starter: false),
        .init(key: "bg-gold", slot: .background, value: "gold", name: "Marigold", unlockHint: "Earn a Rare collectible", starter: false),
        .init(key: "frame-none", slot: .frame, value: "none", name: "No frame", unlockHint: "Starter", starter: true),
        .init(key: "frame-stamp", slot: .frame, value: "stamp", name: "Postage", unlockHint: "Starter", starter: true),
        .init(key: "frame-scallop", slot: .frame, value: "scallop", name: "Scallop", unlockHint: "Earn 5 stickers", starter: false),
        .init(key: "frame-tape", slot: .frame, value: "tape", name: "Taped photo", unlockHint: "Attach 3 photo proofs", starter: false),
        .init(key: "frame-gold", slot: .frame, value: "gold", name: "Gold leaf", unlockHint: "Earn a Legendary collectible", starter: false),
        .init(key: "comp-none", slot: .companion, value: "none", name: "Solo", unlockHint: "Starter", starter: true),
        .init(key: "comp-sprout", slot: .companion, value: "sprout", name: "Sprout", unlockHint: "Starter", starter: true),
        .init(key: "comp-cat", slot: .companion, value: "cat", name: "Biscuit the cat", unlockHint: "Reach 80% consistency", starter: false),
        .init(key: "comp-snail", slot: .companion, value: "snail", name: "Slow & Steady", unlockHint: "Make 3 comebacks", starter: false),
        .init(key: "comp-bird", slot: .companion, value: "bird", name: "Early bird", unlockHint: "10 morning check-ins", starter: false),
    ]

    // MARK: Personalities

    struct Personality {
        let type: PersonalityType
        let name: String
        let tagline: String
        let summary: String
        let strengths: [String]
        let watchOut: String
        let suggestedHabit: (name: String, category: HabitCategory, timeOfDay: TimeOfDay, frequency: Frequency)
        let symbol: String
        let tint: TintToken
    }

    static func personality(_ type: PersonalityType) -> Personality {
        switch type {
        case .gentleBuilder:
            Personality(type: type, name: "Gentle Builder", tagline: "Small bricks, every day.",
                        summary: "You do best with tiny, low-pressure habits that stack over time. Momentum matters more to you than intensity.",
                        strengths: ["Patient", "Low burnout", "Great at routines"],
                        watchOut: "You can under-commit. Let a habit grow once it feels easy.",
                        suggestedHabit: ("10-minute walk", .movement, .morning, .daily), symbol: "leaf.fill", tint: .sage)
        case .deadlineSprinter:
            Personality(type: type, name: "Deadline Sprinter", tagline: "Pressure makes diamonds.",
                        summary: "You thrive with a clear finish line and a bit of urgency. Short challenges keep you sharper than open-ended goals.",
                        strengths: ["Focused bursts", "Loves a challenge", "Finishes strong"],
                        watchOut: "Late-night check-ins are fine, but try one morning anchor habit.",
                        suggestedHabit: ("Two focused study blocks", .study, .afternoon, .weekdays), symbol: "alarm.fill", tint: .orange)
        case .socialMotivator:
            Personality(type: type, name: "Social Motivator", tagline: "Better together.",
                        summary: "Other people are your fuel. Shared habits and quick reactions from friends keep you showing up.",
                        strengths: ["Energizes others", "Bounces back fast", "Great teammate"],
                        watchOut: "Keep at least one habit that's just for you.",
                        suggestedHabit: ("Morning walk with a friend", .movement, .morning, .daily), symbol: "heart.fill", tint: .rose)
        case .quietPerfectionist:
            Personality(type: type, name: "Quiet Perfectionist", tagline: "Details, done well.",
                        summary: "You like doing things properly. Reflection helps — but an all-or-nothing mindset can trip you up.",
                        strengths: ["Thorough", "Self-aware", "Loves a good system"],
                        watchOut: "One missed day isn't failure. Watch your rolling consistency, not your streak.",
                        suggestedHabit: ("Journal three lines", .creative, .evening, .daily), symbol: "pencil.line", tint: .sky)
        case .varietySeeker:
            Personality(type: type, name: "Variety Seeker", tagline: "Same goal, new route.",
                        summary: "Repetition bores you. Rotating habits and flexible schedules keep things fresh enough to stick.",
                        strengths: ["Curious", "Adaptable", "Tries anything once"],
                        watchOut: "Pick one keystone habit and let the rest rotate.",
                        suggestedHabit: ("Something outdoors", .outdoors, .afternoon, .timesPerWeek), symbol: "sun.max.fill", tint: .gold)
        }
    }

    struct QuizQuestion {
        let prompt: String
        let answers: [(text: String, type: PersonalityType)]
    }

    static let personalityQuiz: [QuizQuestion] = [
        QuizQuestion(prompt: "A new habit sticks best when…", answers: [
            ("I start ridiculously small", .gentleBuilder),
            ("There's a deadline", .deadlineSprinter),
            ("A friend is doing it too", .socialMotivator),
            ("I have a clear system", .quietPerfectionist),
            ("I can switch it up", .varietySeeker),
        ]),
        QuizQuestion(prompt: "You missed two days. You…", answers: [
            ("Shrug and do a tiny version today", .gentleBuilder),
            ("Plan a big catch-up session", .deadlineSprinter),
            ("Text someone to keep me honest", .socialMotivator),
            ("Feel annoyed and analyze what went wrong", .quietPerfectionist),
            ("Try a completely different approach", .varietySeeker),
        ]),
        QuizQuestion(prompt: "Your ideal check-in time is…", answers: [
            ("Same time every morning", .gentleBuilder),
            ("11:58pm, technically today", .deadlineSprinter),
            ("Whenever the group chat pings", .socialMotivator),
            ("Right after I finish, with notes", .quietPerfectionist),
            ("Depends on the day, honestly", .varietySeeker),
        ]),
        QuizQuestion(prompt: "The best reward is…", answers: [
            ("A quiet sense of progress", .gentleBuilder),
            ("Crossing the finish line", .deadlineSprinter),
            ("A friend's applause", .socialMotivator),
            ("A perfectly filled calendar", .quietPerfectionist),
            ("A new sticker I've never seen", .varietySeeker),
        ]),
        QuizQuestion(prompt: "Pick a weekend plan", answers: [
            ("Slow coffee and a short walk", .gentleBuilder),
            ("Cram everything into Sunday", .deadlineSprinter),
            ("Group hike, then brunch", .socialMotivator),
            ("Meal prep and plan the week", .quietPerfectionist),
            ("Something I've never tried", .varietySeeker),
        ]),
    ]

    /// Tallies answers; ties go to the earliest personality in declaration order.
    static func scorePersonality(_ answers: [PersonalityType]) -> PersonalityType {
        var best = PersonalityType.gentleBuilder
        var bestCount = -1
        for type in PersonalityType.allCases {
            let count = answers.filter { $0 == type }.count
            if count > bestCount {
                best = type
                bestCount = count
            }
        }
        return best
    }

    // MARK: Onboarding

    struct Interest: Identifiable {
        let id: String
        let label: String
        let symbol: String
        let category: HabitCategory
        let suggestion: String
    }

    static let interests: [Interest] = [
        Interest(id: "move", label: "Move more", symbol: "figure.walk", category: .movement, suggestion: "10-minute walk"),
        Interest(id: "sleep", label: "Sleep better", symbol: "moon.stars.fill", category: .sleep, suggestion: "Lights out by 11"),
        Interest(id: "read", label: "Read more", symbol: "book.fill", category: .study, suggestion: "Read 10 pages"),
        Interest(id: "hydrate", label: "Drink water", symbol: "drop.fill", category: .hydration, suggestion: "Six glasses of water"),
        Interest(id: "focus", label: "Study & focus", symbol: "pencil.and.ruler.fill", category: .study, suggestion: "One focused study block"),
        Interest(id: "calm", label: "Feel calmer", symbol: "leaf.fill", category: .mind, suggestion: "Five quiet minutes"),
        Interest(id: "eat", label: "Eat well", symbol: "carrot.fill", category: .nourish, suggestion: "A piece of fruit"),
        Interest(id: "outside", label: "Get outside", symbol: "tree.fill", category: .outdoors, suggestion: "Step outside for 15 minutes"),
        Interest(id: "strength", label: "Get stronger", symbol: "dumbbell.fill", category: .movement, suggestion: "Strength session"),
        Interest(id: "create", label: "Make things", symbol: "paintbrush.pointed.fill", category: .creative, suggestion: "Sketch for 10 minutes"),
        Interest(id: "mornings", label: "Better mornings", symbol: "sunrise.fill", category: .sleep, suggestion: "Up by 7:30"),
        Interest(id: "friends", label: "Stay close to friends", symbol: "heart.fill", category: .social, suggestion: "Call someone you love"),
    ]

    // MARK: Contacts (mock address book)

    struct Contact {
        let name: String
        let detail: String
        let usesApp: Bool
    }

    static let extraContacts: [Contact] = [
        Contact(name: "Grandma June", detail: "(707) 555-0166", usesApp: false),
        Contact(name: "Ben Carter", detail: "(415) 555-0124", usesApp: false),
        Contact(name: "Aisha Bello", detail: "aisha.b@example.com", usesApp: false),
    ]

    // MARK: Friend quizzes

    static let quizPrompts: [(prompt: String, tag: String)] = [
        ("Who is most likely to finish early?", "early"),
        ("Who always checks in at the last minute?", "last-minute"),
        ("Who gives the best reminders?", "reminders"),
        ("Who would survive a no-phone weekend?", "no-phone"),
        ("Who is secretly the most competitive?", "competitive"),
        ("Who would you trust with your wallet the least?", "wallet"),
        ("Who is the group chat personal trainer?", "trainer"),
    ]

    // MARK: Challenge templates

    struct ChallengeTemplate: Identifiable {
        var id: String { title }
        let title: String
        let detail: String
        let symbol: String
        let unit: String
        let goal: Int
        let days: Int
        let kind: ChallengeKind
    }

    static let challengeTemplates: [ChallengeTemplate] = [
        ChallengeTemplate(title: "Drink water five days this week", detail: "Everyone logs a water day. Five each fills the jar.", symbol: "drop.fill", unit: "water days", goal: 25, days: 7, kind: .collective),
        ChallengeTemplate(title: "Reach 40 collective study sessions", detail: "Any focused block of 25+ minutes counts.", symbol: "book.fill", unit: "sessions", goal: 40, days: 14, kind: .collective),
        ChallengeTemplate(title: "One outdoor activity each day", detail: "Walks, bikes, puddles. Outside is outside.", symbol: "tree.fill", unit: "outings", goal: 28, days: 7, kind: .collective),
        ChallengeTemplate(title: "Finish 20 reading sessions together", detail: "Twenty pages or twenty minutes, your call.", symbol: "text.book.closed.fill", unit: "reading sessions", goal: 20, days: 10, kind: .collective),
        ChallengeTemplate(title: "Predict which friend will finish first", detail: "Place your guess. Bragging rights only.", symbol: "wand.and.stars", unit: "votes", goal: 1, days: 7, kind: .prediction),
    ]

    // MARK: Reminder templates

    static let reminderTemplates = [
        "No pressure — just a friendly wave from me.",
        "Tiny version counts! Even two minutes.",
        "Doing mine now, want to join?",
        "You've got this. I believe in you.",
        "Future you is going to be so smug.",
    ]

    static let commentStarters = ["Proud of you!", "Love this.", "Same time tomorrow?", "Okay, show-off.", "You make it look easy."]
}
