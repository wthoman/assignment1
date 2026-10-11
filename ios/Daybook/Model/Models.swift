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
struct Member {
    var s: Int
    var hist: [Int]
    var done: String?
    var proof = false
    var caption: String? = nil
    var nophoto = false
}

func mem(_ s: Int, _ hist: [Int], _ done: String? = nil, proof: Bool = false, caption: String? = nil, nophoto: Bool = false) -> Member {
    Member(s: s, hist: hist, done: done, proof: proof, caption: caption, nophoto: nophoto)
}

struct Habit: Identifiable {
    let id: String
    var name, ic, time, tod, freq: String
    var group: String?
    var proof: Bool
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
