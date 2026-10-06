import Foundation

/// How a superlative was decided. Shown on every award card.
enum SuperlativeSource: String {
    case activity = "From activity"
    case votes = "Voted by friends"
    case both = "Activity + votes"
}

struct Superlative: Identifiable, Hashable {
    let id: String
    let title: String
    let winnerID: UUID
    let winnerName: String
    let avatar: AvatarConfig
    let isMe: Bool
    let explanation: String
    let source: SuperlativeSource
    let symbol: String
    let tint: TintToken
}

/// A person's numbers for the week, from real data (you) or seeded stats (friends).
struct RecapPerson {
    let id: UUID
    let name: String
    let avatar: AvatarConfig
    let isMe: Bool
    var completions: Int
    var lateNight: Int
    var weekend: Int
    var comebacks: Int
    var remindersSent: Int
    var consistency: Double
    var previousConsistency: Double
    /// Quiz tag → votes received.
    var votes: [String: Int] = [:]
}

struct RecapData {
    struct HabitLine: Hashable { let name: String; let symbol: String; let tint: TintToken; let value: Double; let detail: String }
    struct GoalLine: Hashable { let group: String; let title: String; let progress: Double; let tint: TintToken; let total: Int; let goal: Int }
    struct RankLine: Hashable { let name: String; let avatar: AvatarConfig; let count: Int; let isMe: Bool; let label: String }

    var weekStart: Date
    var weekEnd: Date
    var totalCompletions = 0
    var previousCompletions = 0
    var consistency: Double?
    var previousConsistency: Double?
    var dailyCounts: [(day: Date, count: Int)] = []
    var strongestWeekday = 2
    var strongestCount = 0
    var mostConsistent: HabitLine?
    var mostImproved: HabitLine?
    var reactionsSent = 0
    var reactionsReceived = 0
    var commentsSent = 0
    var remindersSent = 0
    var comebacks = 0
    var goals: [GoalLine] = []
    var pattern: (title: String, detail: String, symbol: String) = ("", "", "sparkles")
    var collectibleKey: String?
    var predictions: [String] = []
    var ranking: [RankLine] = []
    var superlatives: [Superlative] = []

    var headline: String {
        if comebacks >= 2 { return "A week of comebacks." }
        if let consistency, consistency >= 0.85 { return "Your steadiest week yet." }
        if totalCompletions > previousCompletions { return "More stamps than last week." }
        return "Small steps, still counted."
    }
}

/// Builds the weekly recap from plain values so it can be unit tested.
enum RecapEngine {
    struct HabitInput {
        let name: String
        let symbol: String
        let tint: TintToken
        let rule: ScheduleRule
        let start: Date
        let completions: [Date: Date]  // day -> completedAt
        let countsToward: Bool
    }

    struct Inputs {
        var me: RecapPerson
        var friends: [RecapPerson]
        var habits: [HabitInput]
        var reactionsSent: Int
        var reactionsReceived: Int
        var commentsSent: Int
        var remindersSent: Int
        var goals: [RecapData.GoalLine]
        var newestCollectibleKey: String?
        var predictions: [String]
        var end: Date = Day.today
    }

    static func build(_ input: Inputs) -> RecapData {
        let end = Day.start(input.end)
        let start = Day.add(-6, to: end)
        let prevEnd = Day.add(-1, to: start)
        let prevStart = Day.add(-6, to: prevEnd)
        var data = RecapData(weekStart: start, weekEnd: end)
        let days = (0..<7).map { Day.add($0, to: start) }

        // Totals
        var counts = Array(repeating: 0, count: 7)
        var lateNight = 0
        var weekend = 0
        var hours: [Int: Int] = [:]
        for habit in input.habits {
            for (index, day) in days.enumerated() {
                if let at = habit.completions[day] {
                    counts[index] += 1
                    let hour = Day.calendar.component(.hour, from: at)
                    hours[hour, default: 0] += 1
                    if hour >= 21 { lateNight += 1 }
                    if Day.isWeekend(day) { weekend += 1 }
                }
            }
            data.previousCompletions += habit.completions.keys.filter { $0 >= prevStart && $0 <= prevEnd }.count
            data.comebacks += Stats.comebacks(rule: habit.rule, start: habit.start, completions: Set(habit.completions.keys), from: start, to: end)
        }
        data.dailyCounts = zip(days, counts).map { ($0, $1) }
        data.totalCompletions = counts.reduce(0, +)
        if let best = data.dailyCounts.max(by: { $0.count < $1.count }) {
            data.strongestWeekday = Day.weekday(best.day)
            data.strongestCount = best.count
        }

        // Consistency this week vs last
        let counting = input.habits.filter(\.countsToward)
        func tally(_ from: Date, _ to: Date) -> Tally {
            counting.map { Stats.tally(rule: $0.rule, start: $0.start, completions: Set($0.completions.keys), from: from, to: to, today: input.end) }
                .reduce(Tally.zero, +)
        }
        data.consistency = tally(start, end).consistency
        data.previousConsistency = tally(prevStart, prevEnd).consistency

        // Habit highlights
        var lines: [(RecapEngine.HabitInput, Double, Double)] = []
        for habit in counting {
            let set = Set(habit.completions.keys)
            let now = Stats.tally(rule: habit.rule, start: habit.start, completions: set, from: start, to: end, today: input.end).consistency
            let before = Stats.tally(rule: habit.rule, start: habit.start, completions: set, from: prevStart, to: prevEnd, today: input.end).consistency
            if let now { lines.append((habit, now, before ?? 0)) }
        }
        if let top = lines.max(by: { $0.1 < $1.1 }) {
            let done = days.filter { top.0.completions[$0] != nil }.count
            data.mostConsistent = .init(name: top.0.name, symbol: top.0.symbol, tint: top.0.tint, value: top.1, detail: "\(done) check-ins in 7 days")
        }
        if let improved = lines.max(by: { ($0.1 - $0.2) < ($1.1 - $1.2) }), improved.1 - improved.2 > 0.05 {
            data.mostImproved = .init(name: improved.0.name, symbol: improved.0.symbol, tint: improved.0.tint, value: improved.1 - improved.2,
                                      detail: "\(improved.2.percentText) → \(improved.1.percentText)")
        }

        // Social
        data.reactionsSent = input.reactionsSent
        data.reactionsReceived = input.reactionsReceived
        data.commentsSent = input.commentsSent
        data.remindersSent = input.remindersSent
        data.goals = input.goals
        data.collectibleKey = input.newestCollectibleKey
        data.predictions = input.predictions

        // Funniest pattern
        let total = max(1, data.totalCompletions)
        if Double(lateNight) / Double(total) >= 0.2 {
            data.pattern = ("Night shift", "\(lateNight) of your check-ins happened after 9pm. The moon has seen things.", "moon.stars.fill")
        } else if Double(weekend) / Double(total) >= 0.4 {
            data.pattern = ("Weekend energy", "\(weekend) check-ins landed on Saturday or Sunday. Weekdays, take notes.", "sun.max.fill")
        } else if let peak = hours.max(by: { $0.value < $1.value }) {
            let label = Day.timeText(minutes: peak.key * 60)
            data.pattern = ("Creature of habit", "Your favorite check-in time was around \(label). \(peak.value) stamps in that hour alone.", "clock.fill")
        } else {
            data.pattern = ("Fresh start", "A quiet week. Quiet weeks count too.", "leaf.fill")
        }

        // Ranking (supportive labels for everyone)
        var me = input.me
        me.completions = data.totalCompletions
        me.lateNight = lateNight
        me.weekend = weekend
        me.comebacks = data.comebacks
        me.remindersSent = input.remindersSent
        me.consistency = data.consistency ?? 0
        me.previousConsistency = data.previousConsistency ?? 0
        let people = [me] + input.friends
        let labels = ["Pace setter", "Right behind", "Steady hands", "Showing up", "On the board", "Warming up", "In the mix"]
        data.ranking = people.sorted { $0.completions > $1.completions }.enumerated().map { index, person in
            .init(name: person.isMe ? "You" : person.name.firstName, avatar: person.avatar, count: person.completions, isMe: person.isMe, label: labels[safe: index] ?? "Showing up")
        }

        data.superlatives = assignSuperlatives(people)
        return data
    }

    private struct Definition {
        let key: String
        let title: String
        let symbol: String
        let tint: TintToken
        let source: SuperlativeSource
        let score: (RecapPerson) -> Double
        let explain: (RecapPerson) -> String
    }

    private static let definitions: [Definition] = [
        Definition(key: "sup-last-minute", title: "Last-Minute Legend", symbol: "alarm.fill", tint: .burgundy, source: .activity,
                   score: { Double($0.lateNight) },
                   explain: { "\($0.lateNight) check-ins after 9pm. Cutting it close is an art form." }),
        Definition(key: "sup-weekend-mvp", title: "Weekend MVP", symbol: "trophy.fill", tint: .gold, source: .activity,
                   score: { Double($0.weekend) },
                   explain: { "\($0.weekend) weekend check-ins. Saturday's main character." }),
        Definition(key: "sup-comeback-kid", title: "Comeback Kid", symbol: "arrow.uturn.up.circle.fill", tint: .orange, source: .activity,
                   score: { Double($0.comebacks) },
                   explain: { "\($0.comebacks) comeback\($0.comebacks == 1 ? "" : "s") this week. Got knocked down, got back up." }),
        Definition(key: "sup-reminder", title: "Professional Reminder Sender", symbol: "bell.and.waves.left.and.right.fill", tint: .sky, source: .activity,
                   score: { Double($0.remindersSent) },
                   explain: { "\($0.remindersSent) supportive nudges sent. Friends noticed." }),
        Definition(key: "sup-surprise", title: "Surprisingly Consistent", symbol: "sparkles", tint: .sage, source: .activity,
                   score: { $0.consistency - $0.previousConsistency },
                   explain: { "Up from \($0.previousConsistency.percentText) to \($0.consistency.percentText). Nobody saw it coming." }),
        Definition(key: "sup-1159", title: "Most Likely to Check In at 11:59", symbol: "clock.badge.exclamationmark.fill", tint: .rose, source: .votes,
                   score: { Double($0.votes["last-minute"] ?? 0) },
                   explain: { "\($0.votes["last-minute"] ?? 0) friend votes. Midnight is merely a suggestion." }),
        Definition(key: "sup-wallet", title: "Wouldn't Give My Wallet To", symbol: "wallet.pass.fill", tint: .orange, source: .votes,
                   score: { Double($0.votes["wallet"] ?? 0) },
                   explain: { "\($0.votes["wallet"] ?? 0) votes in the friend quiz. Lovingly, of course." }),
        Definition(key: "sup-trainer", title: "Group Chat Personal Trainer", symbol: "figure.strengthtraining.traditional", tint: .burgundy, source: .both,
                   score: { Double($0.votes["trainer"] ?? 0) * 2 + Double($0.remindersSent) * 0.5 },
                   explain: { person in
                       let votes = person.votes["trainer"] ?? 0
                       let reminders = "\(person.remindersSent) pep-talk reminder\(person.remindersSent == 1 ? "" : "s")"
                       return votes > 0 ? "\(votes) vote\(votes == 1 ? "" : "s") plus \(reminders). Drop and give us ten." : "\(reminders) this week. Drop and give us ten."
                   }),
    ]

    /// Each person wins at most one award, so the whole circle gets celebrated.
    static func assignSuperlatives(_ people: [RecapPerson]) -> [Superlative] {
        var winners = Set<UUID>()
        var results: [Superlative] = []
        // Friend-voted awards go first so the people friends picked actually receive them.
        let ordered = definitions.filter { $0.source != .activity } + definitions.filter { $0.source == .activity }
        for definition in ordered {
            let ranked = people.sorted { definition.score($0) > definition.score($1) }
            guard let pick = ranked.first(where: { !winners.contains($0.id) && definition.score($0) > 0 }) else { continue }
            winners.insert(pick.id)
            results.append(Superlative(id: definition.key, title: definition.title, winnerID: pick.id,
                                       winnerName: pick.isMe ? "You" : pick.name.firstName, avatar: pick.avatar, isMe: pick.isMe,
                                       explanation: definition.explain(pick), source: definition.source, symbol: definition.symbol, tint: definition.tint))
        }
        // Save the user's own award for last: it's the headline act.
        return results.filter { !$0.isMe } + results.filter(\.isMe)
    }
}
