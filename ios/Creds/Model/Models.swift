import Foundation

/// Insertion-ordered dictionary (the mock-up relies on JS object key order).
struct Ordered<V> {
    private(set) var keys: [String] = []
    private var store: [String: V] = [:]

    init() {}
    init(_ pairs: [(String, V)]) { for (k, v) in pairs { self[k] = v } }

    subscript(key: String) -> V? {
        get { store[key] }
        set {
            if let newValue {
                if store[key] == nil { keys.append(key) }
                store[key] = newValue
            } else if store[key] != nil {
                store[key] = nil
                keys.removeAll { $0 == key }
            }
        }
    }
    var values: [V] { keys.compactMap { store[$0] } }
    var entries: [(String, V)] { keys.compactMap { k in store[k].map { (k, $0) } } }
}

struct Person {
    var name, full, handle, av, bio: String
    var mutual: Int? = nil
    var since: String? = nil
    var strong: String? = nil
}

/// A person's record on a habit: `hist` = the 6 days before today (oldest→newest),
/// `s` = streak as of yesterday, `done` = today's check-in time.
/// `proof` = a real photo was captured and saved; `sample` = a demo photo variant (seed data only, never proof).
struct Member {
    var s: Int
    var hist: [Int]
    var done: String?
    var proof = false
    var caption: String? = nil
    var sample: Int? = nil
}

func mem(_ s: Int, _ hist: [Int], _ done: String? = nil, caption: String? = nil, sample: Int? = nil) -> Member {
    Member(s: s, hist: hist, done: done, caption: caption, sample: sample)
}

struct Habit: Identifiable {
    let id: String
    var name, ic, time, tod, freq: String
    var group: String?
    var optional = false
    var mem: Ordered<Member>
}

struct Challenge {
    var title, detail, unit: String
    var goal: Int
    var left: Int
    var c: Ordered<Int>
    var others: Int? = nil
}

struct Finished { var t, r: String; var ok: Bool }

/// Who may add tasks to a group.
enum TaskPerm: String { case admins, members }

/// A group can hold several tasks: every habit whose `group` is this id. `habit` is the one it started with.
struct HabitGroup: Identifiable {
    let id: String
    var name, ic, type: String
    var habit: String?
    var notif: String
    var size: Int? = nil
    var desc: String
    var members: [String]
    var ch: Challenge?
    var fin: [Finished]
    /// The creator and anyone they've made an admin.
    var admins: [String] = []
    var taskPerm: TaskPerm = .members
}

struct Invite: Identifiable {
    let id: String
    var name, ic, from, desc: String
    var members: [String]
    var ch: Challenge
}

struct Community: Identifiable {
    let id: String
    var look: PosterLook
    var name, ic: String
    var size, pct: Int
    var cat, desc: String
    var friends: [String]
    var habit: String? = nil
}

struct FeedEvent {
    let id, kind: String
    var who: String? = nil
    var group: String? = nil
    var habit: String? = nil
    var ic: String? = nil
    var title: String? = nil
    var when: String
    var text: String
}

struct Notif: Identifiable {
    let id, kind: String
    var who: String? = nil
    var title, body, time: String
    var unread: Bool
    var act = false
    var group: String? = nil
    var earlier = false
    var res: String? = nil
}

struct TrophyPage { let id, name, note: String }

struct Trophy: Identifiable {
    let id, pg, kind, tier, name, how, blurb: String
    var got: String? = nil
    var fresh = false
}

struct Comment { let p, t: String }

struct Reaction { let k, l: String; let ic: UIIcon }
