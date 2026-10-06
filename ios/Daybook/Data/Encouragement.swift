import Foundation

/// Supportive copy. Nothing here shames a missed day.
enum Encouragement {
    static func greeting(name: String, now: Date = Date()) -> String {
        let hour = Day.calendar.component(.hour, from: now)
        let first = name.firstName
        switch hour {
        case 5..<12: return "Good morning, \(first)"
        case 12..<17: return "Good afternoon, \(first)"
        case 17..<22: return "Good evening, \(first)"
        default: return "Still up, \(first)?"
        }
    }

    static func dayMessage(style: EncouragementStyle, done: Int, total: Int) -> String {
        switch style {
        case .gentle:
            if total == 0 { return "Nothing scheduled. A rest day counts too." }
            if done == 0 { return "One small thing is plenty to start with." }
            if done >= total { return "Everything's stamped. Be proud of today." }
            return "\(done) down. Small steps still count."
        case .cheeky:
            if total == 0 { return "Day off. Don't let the couch get cocky." }
            if done == 0 { return "The day is young and so are your excuses." }
            if done >= total { return "Full sheet. Someone call the newspapers." }
            return "\(done) down. The couch is getting nervous."
        case .coach:
            if total == 0 { return "Recovery day. Recharge." }
            if done == 0 { return "First rep is the hardest. Pick one." }
            if done >= total { return "All done. Recover well — same time tomorrow." }
            return "\(done) of \(total). Keep the tempo."
        }
    }

    static func checkInMessage(style: EncouragementStyle, seed: Int) -> String {
        let list: [String]
        switch style {
        case .gentle: list = ["Nicely done.", "That counts.", "One more page in the book.", "Look at you, showing up.", "Gently stamped."]
        case .cheeky: list = ["Stamped. Smug face allowed.", "Okay, show-off.", "Another one for the scrapbook.", "Your future self says thanks (begrudgingly).", "Ink's still wet."]
        case .coach: list = ["Good rep.", "That's the standard.", "Logged. Next.", "Consistency beats intensity.", "Strong work."]
        }
        return list[abs(seed) % list.count]
    }

    static func comebackMessage(style: EncouragementStyle) -> String {
        switch style {
        case .cheeky: "Look who's back. We saved your seat."
        case .coach: "Back in the game. That's the real skill."
        case .gentle: "Welcome back. Coming back is the whole skill."
        }
    }

    static func consistencyMessage(_ value: Double?) -> String {
        guard let value else { return "Your consistency score appears after your first few check-ins." }
        switch value {
        case 0.85...: return "Wonderfully steady. Misses are forgiven — you've barely needed it."
        case 0.65..<0.85: return "Steady and real. One missed day a week never counts against you."
        case 0.4..<0.65: return "Building nicely. Every comeback moves this up."
        default: return "Every check-in counts here. Start with the smallest one."
        }
    }
}
