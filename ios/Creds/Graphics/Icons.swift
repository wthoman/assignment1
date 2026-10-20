import SwiftUI

/// Habit icons (24×24 stroke drawings).
enum HabitIcon {
    static let all = ["water", "run", "read", "calm", "study", "phone", "sleep", "eat", "pray", "create", "strength", "sunrise", "talk", "music", "clean", "pill"]
    static let markup: [String: String] = [
        "water": #"<path d="M12 3.2c3.2 4.3 5.8 7.6 5.8 10.8a5.8 5.8 0 0 1-11.6 0c0-3.2 2.6-6.5 5.8-10.8z"/>"#,
        "run": #"<path d="M3 15.5V7.8a1 1 0 0 1 1.1-1l2.4.3c.4 1.9 1.6 3 3.3 3 1.3 0 2.2-.7 2.6-1.9l5.4 2.7c1.9.9 3.2 2.4 3.2 4.1v.5z"/><path d="M3 15.5h18v1.3a1.7 1.7 0 0 1-1.7 1.7H4.7A1.7 1.7 0 0 1 3 16.8zM13.6 10.6l-1 1.6M16.3 12l-1 1.6"/>"#,
        "read": #"<path d="M3 5.5c3.2-1.1 6.2-.9 9 1.2 2.8-2.1 5.8-2.3 9-1.2v13c-3.2-1.1-6.2-.9-9 1.2-2.8-2.1-5.8-2.3-9-1.2z"/><path d="M12 6.7v13"/>"#,
        "calm": #"<path d="M3 9h11.5a2.75 2.75 0 1 0-2.75-2.75M3 15h15a3 3 0 1 1-3 3M3 12h7"/>"#,
        "study": #"<path d="M2.5 9.5 12 5l9.5 4.5L12 14z"/><path d="M6.5 11.6v4.2c1.5 1.4 3.4 2.1 5.5 2.1s4-.7 5.5-2.1v-4.2M21.5 9.5v5"/>"#,
        "phone": #"<rect x="7" y="3" width="10" height="18" rx="2"/><path d="M4 4l16 16M11 18h2"/>"#,
        "sleep": #"<path d="M19.5 14.5A7.8 7.8 0 1 1 9.5 4.5a6.2 6.2 0 0 0 10 10z"/>"#,
        "eat": #"<path d="M5 19c0-8.5 5.5-13.5 15-14 0 9-5.5 14-15 14z"/><path d="M5 19l7.5-7.5"/>"#,
        "pray": #"<path d="M12 3.2c1.6 1.9 1.6 3.5 0 4.6-1.6-1.1-1.6-2.7 0-4.6z"/><rect x="9" y="10" width="6" height="11" rx="1"/>"#,
        "create": #"<path d="M12 21l-6-8 6-10 6 10z"/><circle cx="12" cy="13" r="1.6"/><path d="M12 3v8.4"/>"#,
        "strength": #"<path d="M6.5 7v10M17.5 7v10M3.5 9.5v5M20.5 9.5v5M6.5 12h11"/>"#,
        "sunrise": #"<path d="M3 18h18M6.5 18a5.5 5.5 0 0 1 11 0M12 5.5v3M5.3 10.3l2 2M18.7 10.3l-2 2M8 21h8"/>"#,
        "talk": #"<path d="M4 5.5h16v10.5H10l-4.5 3.5V16H4z"/><path d="M8 10h8M8 13h5"/>"#,
        "music": #"<path d="M9 18V5.5l11-2v12.5"/><circle cx="6.5" cy="18" r="2.5"/><circle cx="17.5" cy="16" r="2.5"/>"#,
        "clean": #"<circle cx="12" cy="12" r="8.5"/><path d="M6 6l12 12"/>"#,
        "pill": #"<rect x="2.8" y="8.5" width="18.4" height="7" rx="3.5" transform="rotate(-45 12 12)"/><path d="M9.5 9.5l5 5"/>"#
    ]
}

/// UI icons: markup + default stroke width.
enum UIIcon: String {
    case sun, groups, trophy, film, user, bell, plus, chev, back, right, left, x, check, search, more, lock, globe, camera, invite,
         person, flame, clock, moon, sunr, info, cal, gear, share, edit, leave, heart, spark, clap, star, comment, link, story,
         chat, video, save, grid, book, palette, sound, vib, eye, refresh

    var def: (String, CGFloat) {
        switch self {
        case .sun: return (#"<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"/>"#, 2)
        case .groups: return (#"<circle cx="9" cy="8.5" r="3.2"/><path d="M3 19.5c.6-3.2 3-5.2 6-5.2s5.4 2 6 5.2"/><circle cx="17" cy="9.5" r="2.5"/><path d="M16.4 14.4c2.5-.1 4.3 1.5 4.7 4.1"/>"#, 2)
        case .trophy: return (#"<path d="M8 4h8v5a4 4 0 0 1-8 0zM8 6H5a3 3 0 0 0 3 4M16 6h3a3 3 0 0 1-3 4M12 13v4M8.5 20h7M10 17h4"/>"#, 2)
        case .film: return (#"<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M7 4v16M17 4v16M3 9h4M3 15h4M17 9h4M17 15h4"/>"#, 2)
        case .user: return (#"<circle cx="12" cy="8.5" r="3.8"/><path d="M4.5 20.5c.9-3.9 3.9-6.2 7.5-6.2s6.6 2.3 7.5 6.2"/>"#, 2)
        case .bell: return (#"<path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15zM10 20.5h4"/>"#, 2)
        case .plus: return (#"<path d="M12 5v14M5 12h14"/>"#, 2)
        case .chev: return (#"<path d="m6 9 6 6 6-6"/>"#, 2)
        case .back: return (#"<path d="m15 5-7 7 7 7"/>"#, 2)
        case .right: return (#"<path d="m9 5 7 7-7 7"/>"#, 2)
        case .left: return (#"<path d="m15 5-7 7 7 7"/>"#, 2)
        case .x: return (#"<path d="M6 6l12 12M18 6 6 18"/>"#, 2)
        case .check: return (#"<path d="m5 12.5 4.5 4.5L19 7.5"/>"#, 2.8)
        case .search: return (#"<circle cx="11" cy="11" r="6.5"/><path d="m20 20-4.2-4.2"/>"#, 2)
        case .more: return (#"<circle cx="5" cy="12" r="1.7"/><circle cx="12" cy="12" r="1.7"/><circle cx="19" cy="12" r="1.7"/>"#, 0)
        case .lock: return (#"<rect x="5" y="11" width="14" height="9.5" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>"#, 2)
        case .globe: return (#"<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.5 2.6 2.5 14.4 0 17M12 3.5c-2.5 2.6-2.5 14.4 0 17"/>"#, 2)
        case .camera: return (#"<path d="M4 8.5A1.5 1.5 0 0 1 5.5 7h2l1.5-2h6l1.5 2h2A1.5 1.5 0 0 1 20 8.5v9a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 17.5z"/><circle cx="12" cy="12.8" r="3.3"/>"#, 2)
        case .invite: return (#"<circle cx="9.5" cy="8.5" r="3.5"/><path d="M3 19.5c.7-3.4 3.3-5.4 6.5-5.4 1.4 0 2.6.4 3.6 1M18 13v6M15 16h6"/>"#, 2)
        case .person: return (#"<circle cx="12" cy="8" r="3.6"/><path d="M5 20c.8-3.6 3.6-5.8 7-5.8s6.2 2.2 7 5.8"/>"#, 2)
        case .flame: return (#"<path d="M12 3c.7 3.6 5 5.2 5 10.2A5 5 0 0 1 12 18.5a5 5 0 0 1-5-5.3c0-2.4 1.2-3.7 2-5.2.7 1.4 1.3 2 2.1 2.4-.4-3 .1-5.6.9-7.4z"/>"#, 2)
        case .clock: return (#"<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>"#, 2)
        case .moon: return (#"<path d="M19.5 14.5A7.8 7.8 0 1 1 9.5 4.5a6.2 6.2 0 0 0 10 10z"/>"#, 2)
        case .sunr: return (#"<path d="M3 18h18M6.5 18a5.5 5.5 0 0 1 11 0M12 6v3"/>"#, 2)
        case .info: return (#"<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5M12 8h.01"/>"#, 2)
        case .cal: return (#"<rect x="3.5" y="5" width="17" height="15" rx="2.5"/><path d="M3.5 10h17M8 3v4M16 3v4"/>"#, 2)
        case .gear: return (#"<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1V21a2 2 0 1 1-4 0v-.1a1.6 1.6 0 0 0-2.7-1.1l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1A1.6 1.6 0 0 0 3.5 15H3a2 2 0 1 1 0-4h.1a1.6 1.6 0 0 0 1.1-2.7l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.6 1.6 0 0 0 9.7 4.3V4a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 2.7 1.1l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0 1.1 2.7H21a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.5 1z"/>"#, 2)
        case .share: return (#"<path d="M12 15V3.5M7.5 8 12 3.5 16.5 8M5 12v7a1.5 1.5 0 0 0 1.5 1.5h11A1.5 1.5 0 0 0 19 19v-7"/>"#, 2)
        case .edit: return (#"<path d="M4 20l1.2-4.6L15.8 4.8a2 2 0 0 1 2.8 0l.6.6a2 2 0 0 1 0 2.8L8.6 18.8z"/>"#, 2)
        case .leave: return (#"<path d="M14 4h4.5A1.5 1.5 0 0 1 20 5.5v13a1.5 1.5 0 0 1-1.5 1.5H14M10 16l-4-4 4-4M6 12h10"/>"#, 2)
        case .heart: return (#"<path d="M12 20s-7.5-4.6-7.5-10A4.3 4.3 0 0 1 12 7.3 4.3 4.3 0 0 1 19.5 10c0 5.4-7.5 10-7.5 10z"/>"#, 2)
        case .spark: return (#"<path d="M12 3l1.9 5.6 5.6 1.9-5.6 1.9L12 18l-1.9-5.6-5.6-1.9 5.6-1.9z"/><path d="M19 16.5v4M17 18.5h4"/>"#, 2)
        case .clap: return (#"<path d="M8.5 12.5 6.6 7.4a1.4 1.4 0 0 1 2.6-1l2.3 5M11.4 10.5 10 6.2a1.4 1.4 0 0 1 2.7-.8l2 5.5M14.4 10.4l-.7-2.2a1.4 1.4 0 0 1 2.7-.8l1.7 5c1.3 3.7-.8 7.3-4.4 8.2-3 .8-6-.8-7.2-3.6L5 13.7a1.3 1.3 0 0 1 2.3-1.3l1.6 2.4"/>"#, 2)
        case .star: return (#"<path d="M12 3.3l2.6 5.6 6.1.7-4.5 4.2 1.2 6L12 16.8 6.6 19.8l1.2-6-4.5-4.2 6.1-.7z"/>"#, 2)
        case .comment: return (#"<path d="M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H9l-5 4z"/>"#, 2)
        case .link: return (#"<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>"#, 2)
        case .story: return (#"<rect x="5" y="3" width="14" height="18" rx="3"/><circle cx="12" cy="12" r="3"/>"#, 2)
        case .chat: return (#"<path d="M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H9l-5 4z"/>"#, 2)
        case .video: return (#"<rect x="3" y="6" width="13" height="12" rx="2"/><path d="M16 10.5 21 7.5v9l-5-3"/>"#, 2)
        case .save: return (#"<path d="M12 4v11M7 10l5 5 5-5M5 20h14"/>"#, 2)
        case .grid: return (#"<rect x="4" y="4" width="6" height="6" rx="1.5"/><rect x="14" y="4" width="6" height="6" rx="1.5"/><rect x="4" y="14" width="6" height="6" rx="1.5"/><rect x="14" y="14" width="6" height="6" rx="1.5"/>"#, 2)
        case .book: return (#"<path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v15H6.5A2.5 2.5 0 0 0 4 20.5zM4 20.5A2.5 2.5 0 0 0 6.5 23H20v-5"/>"#, 2)
        case .palette: return (#"<path d="M12 3a9 9 0 1 0 0 18c1 0 1.5-.8 1.5-1.6 0-1.2-1-1.6-1-2.6 0-.9.7-1.6 1.6-1.6H17a4 4 0 0 0 4-4C21 6.6 17 3 12 3z"/><circle cx="7.5" cy="11" r="1"/><circle cx="10" cy="7" r="1"/><circle cx="15" cy="7" r="1"/>"#, 2)
        case .sound: return (#"<path d="M4 9.5h3.5L12 5.5v13l-4.5-4H4zM16 9a4 4 0 0 1 0 6M18.5 6.5a7.5 7.5 0 0 1 0 11"/>"#, 2)
        case .vib: return (#"<rect x="8" y="4" width="8" height="16" rx="2"/><path d="M4 9v6M20 9v6"/>"#, 2)
        case .eye: return (#"<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="3"/>"#, 2)
        case .refresh: return (#"<path d="M20 11a8 8 0 1 0-2.3 5.7M20 4v7h-7"/>"#, 2)
        }
    }

    /// The JS defaults for the icon size when called with no width.
    var defaultSize: CGFloat {
        switch self {
        case .sun, .groups, .trophy, .film, .user: return 22
        case .bell: return 19
        case .plus, .back: return 20
        case .chev, .x, .check, .info, .cal, .camera, .comment, .link, .palette, .sound, .vib, .eye, .refresh: return 16
        case .right, .left: return 14
        case .search, .more, .gear, .heart, .spark, .clap, .star: return 18
        case .lock, .person, .flame, .clock, .moon, .sunr: return 12
        case .globe: return 13
        case .invite, .share, .grid, .book: return 17
        case .edit: return 14
        case .story, .chat, .video, .save: return 20
        case .leave: return 16
        }
    }
}

/// Stroke drawing in a 24×24 box, using the current foreground style.
struct StrokeIcon: View {
    let markup: String
    var size: CGFloat
    var lineWidth: CGFloat
    var body: some View {
        ViewBoxShape(path: SVG.markup(markup))
            .stroke(style: StrokeStyle(lineWidth: lineWidth * size / 24, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

/// `I.name(w)` from the mock-up.
struct Ico: View {
    let icon: UIIcon
    var size: CGFloat?
    init(_ icon: UIIcon, _ size: CGFloat? = nil) { self.icon = icon; self.size = size }
    var body: some View {
        let (m, sw) = icon.def
        let s = size ?? icon.defaultSize
        if icon == .more {
            ViewBoxShape(path: SVG.markup(m)).fill().frame(width: s, height: s)
        } else {
            StrokeIcon(markup: m, size: s, lineWidth: sw)
        }
    }
}

/// `hicon(k, w, sw)` from the mock-up.
struct HIcon: View {
    let key: String
    var size: CGFloat = 22
    var lineWidth: CGFloat = 2
    init(_ key: String, _ size: CGFloat = 22, _ lineWidth: CGFloat = 2) { self.key = key; self.size = size; self.lineWidth = lineWidth }
    var body: some View {
        StrokeIcon(markup: HabitIcon.markup[key] ?? HabitIcon.markup["clean"]!, size: size, lineWidth: lineWidth)
    }
}
