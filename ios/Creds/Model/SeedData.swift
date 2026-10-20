import Foundation

/// Demo data, laid out around the real current date.
enum Seed {
    static var today: Date { Calendar.current.startOfDay(for: Date()) }
    /// The current time, "6:12 PM".
    static var now: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US"); f.dateFormat = "h:mm a"
        return f.string(from: Date())
    }

    static func people() -> [String: Person] { [
        "me": Person(name: "Shannon", full: "Shannon Sutiono", handle: "shannon", av: "a1", bio: "Trying to drink more water than coffee."),
        "mina": Person(name: "Mina", full: "Mina Sun", handle: "minasun", av: "a2", bio: "Lo-fi prototypes and hi-fi lattes.", mutual: 4, since: "Aug 2026", strong: "Monday"),
        "preston": Person(name: "Preston", full: "Preston Hale", handle: "prestonruns", av: "a3", bio: "6AM club president (self-appointed).", mutual: 5, since: "Jan 2026", strong: "Tuesday"),
        "caitlyn": Person(name: "Caitlyn", full: "Caitlyn Park", handle: "caitlynreads", av: "a4", bio: "Reading 40 books this year. Currently on 31.", mutual: 3, since: "Sep 2025", strong: "Sunday"),
        "ava": Person(name: "Ava", full: "Ava Moreno", handle: "avam", av: "a5", bio: "Gym, water, sleep. Repeat.", mutual: 3, since: "Mar 2026", strong: "Wednesday"),
        "jordan": Person(name: "Jordan", full: "Jordan Lee", handle: "jordanlee", av: "a6", bio: "Comeback specialist.", mutual: 2, since: "May 2026", strong: "Saturday"),
        "leo": Person(name: "Leo", full: "Leo Okafor", handle: "leo.o", av: "a7", bio: "Sunrise miles and sunset playlists.", mutual: 4, since: "Feb 2026", strong: "Monday"),
        "theo": Person(name: "Theo", full: "Theo Martins", handle: "theom", av: "a8", bio: "Trying everything once. Meditation twice.", mutual: 1, since: "Jul 2026", strong: "Friday"),
        "noah": Person(name: "Noah", full: "Noah Haddad", handle: "noahh", av: "a10", bio: "Marathon training, slowly.", mutual: 2, since: "Jun 2026", strong: "Thursday"),
        "sofia": Person(name: "Sofia", full: "Sofia Reyes", handle: "sofiar", av: "a9", bio: "Plants, pilates and pretending I like mornings.")
    ] }

    static let friends = ["mina", "preston", "caitlyn", "ava", "jordan", "leo", "theo", "noah"]

    static func habits() -> [Habit] { [
        Habit(id: "water", name: "Drink 5L of water", ic: "water", time: "Anytime", tod: "anytime", freq: "Every day", group: "hydration",
              mem: Ordered([("me", mem(6, [1, 1, 1, 1, 1, 1])), ("mina", mem(13, [1, 1, 1, 1, 1, 1], "8:12 AM", sample: 0)), ("preston", mem(2, [1, 1, 1, 0, 1, 1])),
                            ("ava", mem(8, [1, 1, 1, 1, 1, 1], "10:40 AM", sample: 1)), ("jordan", mem(1, [0, 1, 1, 0, 0, 1]))])),
        Habit(id: "run", name: "Morning run", ic: "run", time: "6:30 AM", tod: "morning", freq: "Weekdays", group: "run",
              mem: Ordered([("me", mem(3, [1, 1, 0, 1, 1, 1], "6:31 AM", caption: "Slow, but done.", sample: 0)), ("preston", mem(11, [1, 1, 1, 1, 1, 1], "6:04 AM", sample: 1)),
                            ("leo", mem(5, [0, 1, 1, 1, 1, 1], "6:20 AM", sample: 2)), ("theo", mem(1, [1, 0, 1, 0, 0, 1]))])),
        Habit(id: "study", name: "Study 2 hours", ic: "study", time: "8:00 PM", tod: "evening", freq: "Every day", group: "idsn",
              mem: Ordered([("me", mem(4, [1, 0, 1, 1, 1, 1])), ("mina", mem(9, [1, 1, 1, 1, 1, 1], "1:15 PM", sample: 0)),
                            ("preston", mem(0, [1, 1, 1, 1, 1, 0])), ("caitlyn", mem(7, [1, 1, 1, 1, 1, 1], "4:20 PM", sample: 1))])),
        Habit(id: "read", name: "Read 20 pages", ic: "read", time: "9:30 PM", tod: "evening", freq: "Every day", group: "pageturners",
              mem: Ordered([("me", mem(2, [1, 1, 0, 0, 1, 1])), ("caitlyn", mem(15, [1, 1, 1, 1, 1, 1], "7:02 AM", sample: 0)), ("noah", mem(0, [1, 0, 1, 0, 0, 0]))])),
        Habit(id: "calm", name: "Meditate 10 min", ic: "calm", time: "7:00 AM", tod: "morning", freq: "Every day", group: "calm",
              mem: Ordered([("me", mem(5, [0, 1, 1, 1, 1, 1])), ("ava", mem(12, [1, 1, 1, 1, 1, 1], "7:30 AM", sample: 2)), ("theo", mem(0, [0, 0, 1, 0, 1, 0]))])),
        Habit(id: "phone", name: "No phone after 11pm", ic: "phone", time: "10:45 PM", tod: "evening", freq: "Every day", group: nil,
              mem: Ordered([("me", mem(4, [1, 0, 1, 1, 1, 1]))])),
        Habit(id: "journal", name: "Journal three lines", ic: "create", time: "Anytime", tod: "anytime", freq: "Every day", group: nil, optional: true,
              mem: Ordered([("me", mem(2, [0, 1, 0, 1, 1, 1]))]))
    ] }

    static func groups() -> [HabitGroup] { [
        HabitGroup(id: "hydration", name: "Hydration Station", ic: "water", type: "friends", habit: "water", notif: "Everything",
              desc: "Five friends, many water bottles, zero excuses.", members: ["me", "mina", "preston", "ava", "jordan"],
              ch: Challenge(title: "Drink water five days this week", detail: "Everyone logs a water day. Five each fills the jar.", unit: "water days", goal: 25, left: 4,
                            c: Ordered([("me", 3), ("mina", 6), ("preston", 5), ("ava", 5), ("jordan", 4)])),
              fin: [Finished(t: "Hit 100 water days in September", r: "Goal reached · 112 water days", ok: true)]),
        HabitGroup(id: "run", name: "6AM Run Club", ic: "run", type: "friends", habit: "run", notif: "Milestones",
              desc: "Sunrise miles, slow and steady. Walking breaks count.", members: ["me", "preston", "leo", "theo"],
              ch: Challenge(title: "Run 40 miles together this week", detail: "Every run counts, however short.", unit: "miles", goal: 40, left: 4,
                            c: Ordered([("me", 6), ("preston", 12), ("leo", 9), ("theo", 4)])),
              fin: [Finished(t: "Run 120 miles in September", r: "98 of 120 · still counts", ok: false)]),
        HabitGroup(id: "idsn", name: "IDSN 533 crew", ic: "study", type: "friends", habit: "study", notif: "Everything",
              desc: "Midterm mode. Two focused hours a day, then we rest.", members: ["me", "mina", "preston", "caitlyn"],
              ch: Challenge(title: "20 study blocks before the midterm", detail: "One block = two focused hours.", unit: "study blocks", goal: 20, left: 6,
                            c: Ordered([("me", 3), ("mina", 5), ("preston", 2), ("caitlyn", 4)])),
              fin: []),
        HabitGroup(id: "pageturners", name: "Page Turners", ic: "read", type: "community", habit: "read", notif: "Milestones", size: 1284,
              desc: "Read 20 pages of anything, every day. Snap your page number as proof.", members: ["me", "caitlyn", "noah"],
              ch: Challenge(title: "1,000 pages this week", detail: "Every page anyone reads adds to the pile.", unit: "pages", goal: 1000, left: 4,
                            c: Ordered([("me", 60), ("caitlyn", 140), ("noah", 20)]), others: 592),
              fin: [Finished(t: "Read 3,000 pages in September", r: "Goal reached · 3,240 pages", ok: true)]),
        HabitGroup(id: "calm", name: "Calm Collective", ic: "calm", type: "community", habit: "calm", notif: "Off", size: 862,
              desc: "Ten quiet minutes a day. Any app, any method. Just sit.", members: ["me", "ava", "theo"],
              ch: Challenge(title: "500 quiet sessions this week", detail: "Ten minutes each. Breathe.", unit: "sessions", goal: 500, left: 4,
                            c: Ordered([("me", 5), ("ava", 6), ("theo", 2)]), others: 301),
              fin: [])
    ] }

    static func invites() -> [Invite] { [
        Invite(id: "touchgrass", name: "Touch Grass Club", ic: "eat", from: "caitlyn", desc: "One outdoor thing a day. Puddles count.", members: ["caitlyn", "mina", "leo", "noah"],
               ch: Challenge(title: "One outdoor activity each day", detail: "Walks, bikes, puddles. Outside is outside.", unit: "outings", goal: 28, left: 5,
                             c: Ordered([("caitlyn", 4), ("mina", 3), ("leo", 3), ("noah", 2)])))
    ] }

    static func communities() -> [Community] { [
        Community(id: "pageturners", look: .paper, name: "Page Turners", ic: "read", size: 1284, pct: 64, cat: "Learning", desc: "Read 20 pages of anything, every day. Snap your page number as proof.", friends: ["caitlyn", "noah"]),
        Community(id: "calm", look: .ink, name: "Calm Collective", ic: "calm", size: 862, pct: 71, cat: "Mind", desc: "Ten quiet minutes a day. Any app, any method. Just sit.", friends: ["ava", "theo"]),
        Community(id: "steps", look: .wine, name: "10k Steps Daily", ic: "run", size: 3420, pct: 58, cat: "Fitness", desc: "Hit 10,000 steps before bed. Screenshot your step count as proof.", friends: ["jordan", "leo"], habit: "10k steps"),
        Community(id: "early", look: .paper, name: "Early Risers", ic: "sunrise", size: 2108, pct: 49, cat: "Mind", desc: "Out of bed before 6:30 AM. A photo of the sunrise (or your coffee) counts.", friends: ["preston"], habit: "Up before 6:30 AM"),
        Community(id: "gym", look: .ink, name: "Gym Rats", ic: "strength", size: 2876, pct: 62, cat: "Fitness", desc: "Any workout, 30+ minutes. Gym selfie or a screenshot of your workout as proof.", friends: ["theo", "noah"], habit: "Work out 30 min"),
        Community(id: "lang", look: .curtain, name: "Language Sprint", ic: "talk", size: 1560, pct: 66, cat: "Learning", desc: "Fifteen minutes of any language you are learning.", friends: ["caitlyn"], habit: "Practice a language"),
        Community(id: "sketch", look: .paper, name: "Sketch a Day", ic: "create", size: 774, pct: 53, cat: "Creative", desc: "One drawing a day. Doodles absolutely count.", friends: ["mina"], habit: "Sketch something"),
        Community(id: "pray", look: .ink, name: "Morning Prayer", ic: "pray", size: 1205, pct: 74, cat: "Faith", desc: "Start the day in prayer or reflection, before you check your phone.", friends: [], habit: "Morning prayer"),
        Community(id: "sugar", look: .wine, name: "Sugar-Free Squad", ic: "clean", size: 940, pct: 57, cat: "Health", desc: "No added sugar today. Honest check-ins only.", friends: ["ava"], habit: "No added sugar"),
        Community(id: "plants", look: .paper, name: "Plant-based Plates", ic: "eat", size: 655, pct: 60, cat: "Health", desc: "At least one fully plant-based meal a day. Share the plate.", friends: [], habit: "One plant-based meal")
    ] }
    static let cats = ["All", "Health", "Fitness", "Mind", "Learning", "Creative", "Faith"]

    static let captions: [String: String] = [
        "water:mina": "Bottle number four. Almost there.", "water:ava": "Refilled at the gym, twice.", "run:preston": "5K before sunrise. Again.",
        "study:caitlyn": "Library corner secured.", "read:caitlyn": "Chapter nine, finally.", "run:leo": "Cold one today. Still went.",
        "study:mina": "Two blocks, one very long coffee.", "calm:ava": "Ten minutes of nothing. Needed it."
    ]

    /// Things that happened earlier this week (recap highlights).
    static let events: [FeedEvent] = [
        FeedEvent(id: "e1", kind: "started", who: "mina", habit: "Morning pages", ic: "create", when: "Tue", text: "Three pages before coffee. Day two!"),
        FeedEvent(id: "e2", kind: "comeback", who: "jordan", habit: "Drink 5L of water", ic: "water", when: "Mon", text: "Back after four days off. Big bottle refilled."),
        FeedEvent(id: "e3", kind: "trophy", who: "caitlyn", title: "Week Unbroken", when: "Sun", text: "7 days in a row on Read 20 pages."),
        FeedEvent(id: "e4", kind: "milestone", group: "hydration", title: "Hydration Station hit 75%", when: "Mon", text: "18 of 25 water days logged. Two days to go."),
        FeedEvent(id: "e5", kind: "joined", who: "theo", group: "calm", title: "Calm Collective", when: "Sun", text: "Ten quiet minutes a day. Join him?")
    ]

    static func notifs() -> [Notif] { [
        Notif(id: "n1", kind: "friend", who: "sofia", title: "Sofia Reyes wants to be friends", body: "1 mutual friend: Caitlyn.", time: "1h", unread: true, act: true),
        Notif(id: "n2", kind: "invite", who: "caitlyn", title: "Join Touch Grass Club?", body: "Caitlyn invited you. One outdoor thing a day — puddles count.", time: "2h", unread: true, act: true, group: "touchgrass"),
        Notif(id: "n3", kind: "reaction", who: "mina", title: "Mina loved your Morning run photo", body: "“Slow, but done.”", time: "3h", unread: true),
        Notif(id: "n4", kind: "comment", who: "preston", title: "Preston commented", body: "“See you at 6 tomorrow?”", time: "4h", unread: false),
        Notif(id: "n5", kind: "milestone", title: "Hydration Station hit 75%", body: "Two more water days fill the jar.", time: "5h", unread: false),
        Notif(id: "n6", kind: "recap", title: "Your weekly recap is ready", body: "Week 40 · Sep 28 – Oct 4", time: "Mon", unread: false, earlier: true),
        Notif(id: "n7", kind: "award", title: "New medal: Week Unbroken", body: "7 days in a row on Drink 5L of water.", time: "Sat", unread: false, earlier: true)
    ] }

    static let pages: [TrophyPage] = [
        TrophyPage(id: "firsts", name: "Firsts", note: "where it all started"),
        TrophyPage(id: "streaks", name: "Streaks", note: "no skipping!"),
        TrophyPage(id: "groups", name: "Groups", note: "team effort"),
        TrophyPage(id: "photos", name: "Photos", note: "pics or it didn’t happen"),
        TrophyPage(id: "weekly", name: "Weekly awards", note: "and the award goes to…")
    ]

    static func trophies() -> [Trophy] { [
        Trophy(id: "t1", pg: "firsts", kind: "medal", tier: "bronze", name: "First Stamp", how: "Check in for the first time", blurb: "Every streak starts with one.", got: "Aug 14"),
        Trophy(id: "t2", pg: "firsts", kind: "medal", tier: "bronze", name: "Proof Positive", how: "Post your first photo", blurb: "Pics, or it didn’t happen.", got: "Aug 15"),
        Trophy(id: "t3", pg: "firsts", kind: "medal", tier: "bronze", name: "New Friend", how: "Add your first friend", blurb: "Habits are easier with an audience.", got: "Aug 14"),
        Trophy(id: "t4", pg: "firsts", kind: "medal", tier: "bronze", name: "Newcomer", how: "Join a community", blurb: "Strangers, but make it supportive.", got: "Aug 20"),
        Trophy(id: "t5", pg: "streaks", kind: "trophy", tier: "silver", name: "Week Unbroken", how: "7 days in a row on one habit", blurb: "A whole week. Not one skip.", got: "Oct 3", fresh: true),
        Trophy(id: "t6", pg: "streaks", kind: "trophy", tier: "gold", name: "Groove Found", how: "21 days in a row on one habit", blurb: "This is just who you are now."),
        Trophy(id: "t7", pg: "streaks", kind: "trophy", tier: "platinum", name: "Long Haul", how: "50 days in a row on one habit", blurb: "Legend status."),
        Trophy(id: "t8", pg: "streaks", kind: "medal", tier: "bronze", name: "Back Again", how: "Check in after missing 2+ days", blurb: "Missing a day is normal. Coming back is the skill.", got: "Sep 9"),
        Trophy(id: "t9", pg: "groups", kind: "medal", tier: "bronze", name: "Housewarming", how: "Start a group", blurb: "Put the kettle on.", got: "Aug 22"),
        Trophy(id: "t10", pg: "groups", kind: "medal", tier: "silver", name: "Halfway There", how: "A group challenge hits 50%", blurb: "The jar is half full.", got: "Sep 18"),
        Trophy(id: "t11", pg: "groups", kind: "trophy", tier: "gold", name: "Goal Reached", how: "Finish a group challenge", blurb: "Done together.", got: "Sep 30"),
        Trophy(id: "t12", pg: "groups", kind: "medal", tier: "silver", name: "Team Player", how: "Add 25 to group challenges", blurb: "You carried, quietly."),
        Trophy(id: "t13", pg: "photos", kind: "medal", tier: "bronze", name: "Five Frames", how: "Post 5 photos", blurb: "Building a little gallery.", got: "Aug 29"),
        Trophy(id: "t14", pg: "photos", kind: "medal", tier: "silver", name: "Gallery Night", how: "Post 25 photos", blurb: "Curated. Iconic."),
        Trophy(id: "t15", pg: "photos", kind: "trophy", tier: "gold", name: "Front Row", how: "A photo gets 10 reactions", blurb: "Everyone saw that."),
        Trophy(id: "t16", pg: "weekly", kind: "trophy", tier: "gold", name: "Most Consistent", how: "Weekly award", blurb: "Checked in on every habit, every day.", got: "Wk 36"),
        Trophy(id: "t17", pg: "weekly", kind: "trophy", tier: "silver", name: "Early Bird", how: "Weekly award", blurb: "The sun was not up yet.", got: "Wk 37"),
        Trophy(id: "t18", pg: "weekly", kind: "medal", tier: "bronze", name: "Comeback Kid", how: "Weekly award", blurb: "Broke a streak Monday, back by Friday.", got: "Wk 38"),
        Trophy(id: "t19", pg: "weekly", kind: "medal", tier: "silver", name: "Steady Week", how: "Weekly award: 5+ days on 3 habits", blurb: "Quietly, reliably there."),
        Trophy(id: "t20", pg: "weekly", kind: "trophy", tier: "platinum", name: "Perfect Week", how: "Weekly award: every habit, every day", blurb: "Not one empty box.")
    ] }

    static let voice = ["Nicely done.", "That counts.", "One more page in the book.", "Look at you, showing up.", "Gently stamped."]

    static let reactions = [Reaction(k: "cheer", l: "Cheer", ic: .spark), Reaction(k: "fire", l: "On fire", ic: .flame), Reaction(k: "clap", l: "Applause", ic: .clap),
                            Reaction(k: "love", l: "Love", ic: .heart), Reaction(k: "star", l: "Gold star", ic: .star)]

    static let onboardingGoals: [(id: String, l: String, ic: String)] = [
        ("water", "Hydrate", "water"), ("move", "Move more", "run"), ("read", "Read", "read"), ("sleep", "Sleep early", "sleep"),
        ("mind", "Be mindful", "calm"), ("study", "Study", "study"), ("eat", "Eat well", "eat"), ("screen", "Less screen", "phone"),
        ("faith", "Faith", "pray"), ("create", "Create", "create")
    ]

    static let contacts: [(n: String, s: String, av: String)] = [
        ("Dev Patel", "(415) 555-0124", "a6"), ("Lucía Fernández", "lucia@example.com", "a9"), ("Grandma June", "(707) 555-0166", "a7")
    ]

    static let prevWeekPct = 71   // mock: the week before
}
