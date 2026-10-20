import SwiftUI
import Observation

enum Tab: String, CaseIterable { case today, groups, trophies, recap }

enum RouteKind { case profile, settings, notifs, friends, friend, addfriends, discover, group }

struct Route: Hashable {
    let r: RouteKind
    var id: String? = nil
    let uid = UUID()
}

enum SheetType { case details, create, group, community, trophy, proof, post, react, comments, avatar, editprofile, groupmenu, invitefriends, friendmenu, invitehabit }

/// Whatever the open bottom sheet needs (mirrors the mock-up's `S.sheet`).
struct SheetState {
    var type: SheetType
    var presentID = UUID()
    var tall = false
    var id = ""
    var p = ""
    var k = ""
    // create habit / create group
    var name = ""
    var desc = ""
    var ic = "water"
    var freq = "Every day"
    var with = "solo"
    var friends: [String] = []
    var gid: String? = nil
    /// Custom schedule: weekday indexes, Monday = 0.
    var days: [Int] = []
    var goal = ""
    var perm: TaskPerm = .members
    var fromHabit: String? = nil
    // photo proof
    var shot = false
    var flash = 0
    var caption = ""
    var photo: UIImage? = nil
    var showCamera = false
    var photoError: String? = nil
    var saving = false
    // comments
    var text = ""
    // avatar / invite friends / profile
    var sel = ""
    var selSet: [String] = []
    var full = ""
    var bio = ""
}

struct ToastState: Identifiable {
    let id = UUID()
    let msg: String
    let icon: UIIcon
    let undo: (() -> Void)?
}

enum DayMark {
    case done, missed, rest, pending, upcoming
    var label: String {
        switch self {
        case .done: return "done"
        case .missed: return "missed"
        case .rest: return "rest day"
        case .pending: return "today, not done yet"
        case .upcoming: return "upcoming"
        }
    }
}

enum Overlay: Equatable { case recap(UUID), celebrate(String), story(UUID) }

@MainActor @Observable
final class AppModel {
    // flow
    var mode: Mode = .onboard
    enum Mode { case onboard, app }
    var step = 0
    var obName = ""
    var obEmail = ""
    var obPassword = ""
    var obAttempted = false
    var obGoals: Set<String> = []
    var obAdded: Set<String> = ["mina", "preston", "caitlyn"]
    var tab: Tab = .today
    var stack: [Route] = []
    var anim: String? = nil
    var day = 6

    // data
    var people: [String: Person] = Seed.people()
    var friends: [String] = Seed.friends
    var habits: [Habit] = Seed.habits()
    var groups: [HabitGroup] = Seed.groups()
    var invites: [Invite] = Seed.invites()
    var communities: [Community] = Seed.communities()
    var notifs: [Notif] = Seed.notifs()
    var trophies: [Trophy] = Seed.trophies()
    /// The user's profile picture; nil shows the default profile icon.
    var myPhoto: UIImage? = nil
    var reacts: [String: String] = [:]
    var comments: [String: [Comment]] = [:]
    var requests: [String] = ["sofia"]
    var q = ""
    var cat = "All"
    var trView = "book"
    var pinned: [String] = ["t16", "t11", "t5"]
    var recapSeen = false
    var settings: [String: Bool] = ["notif": true, "sound": true, "haptics": true, "share": true]
    var contactInvited: Set<Int> = []
    var theme: ThemeName = .paper
    var story: [StoryItem] = []
    /// Habit waiting on the "undo check-in?" confirmation.
    var pendingUncheck: String? = nil
    private let storyStore = StoryStore()
    private let photoStore = ProfilePhotoStore()

    // chrome
    var sheet: SheetState? = nil
    var toast: ToastState? = nil
    var overlay: Overlay? = nil
    var voiceI = 0
    var trPageTarget: String? = nil

    private var toastTask: Task<Void, Never>? = nil

    init() { story = storyStore.load(); myPhoto = photoStore.load() }

    // MARK: - lookups

    func H(_ id: String?) -> Habit? { habits.first { $0.id == id } }
    func G(_ id: String?) -> HabitGroup? { groups.first { $0.id == id } }
    func C(_ id: String) -> Community? { communities.first { $0.id == id } }
    func T(_ id: String) -> Trophy? { trophies.first { $0.id == id } }
    func hIndex(_ id: String) -> Int? { habits.firstIndex { $0.id == id } }
    func gIndex(_ id: String) -> Int? { groups.firstIndex { $0.id == id } }

    func person(_ p: String) -> Person { people[p] ?? Person(name: p, full: p, handle: p, av: "a1", bio: "") }
    func nameOf(_ p: String) -> String { p == "me" ? "You" : person(p).name }

    func isDone(_ h: Habit, _ p: String) -> Bool { h.mem[p]?.done != nil }
    func streak(_ h: Habit, _ p: String) -> Int { guard let r = h.mem[p] else { return 0 }; return r.s + (r.done != nil ? 1 : 0) }
    func week(_ h: Habit, _ p: String) -> [Int] { guard let r = h.mem[p] else { return Array(repeating: 0, count: 7) }; return r.hist + [r.done != nil ? 1 : 0] }
    func weekCount(_ h: Habit, _ p: String) -> Int { week(h, p).reduce(0, +) }
    func peopleOf(_ h: Habit) -> [String] { h.mem.keys.filter { $0 == "me" || friends.contains($0) } }
    func doneCount(_ h: Habit) -> Int { peopleOf(h).filter { isDone(h, $0) }.count }
    func shared(_ h: Habit) -> Bool { peopleOf(h).count > 1 }
    /// Your photo counts only once it's saved; everyone else's check-in carries their photo.
    func hasPhoto(_ h: Habit, _ p: String) -> Bool {
        if p == "me" { return h.mem["me"].map { $0.done != nil && ($0.proof || $0.sample != nil) } ?? false }
        return isDone(h, p)
    }
    /// Members on the habit's group (communities count everyone), or just the people on the habit.
    func groupSize(_ h: Habit) -> Int { G(h.group).map(groupSize) ?? peopleOf(h).count }
    func groupSize(_ g: HabitGroup) -> Int { g.size ?? g.members.count }
    /// Big groups only show photos that were taken: no counts, no empty frames.
    func isLarge(_ h: Habit) -> Bool { groupSize(h) > 15 }
    func captionOf(_ h: Habit, _ p: String) -> String {
        h.mem[p]?.caption ?? Seed.captions[h.id + ":" + p] ?? "Day \(streak(h, p))."
    }
    var required: [Habit] { habits.filter { !$0.optional } }
    func dayRatio(_ i: Int) -> Double {
        let hs = required
        return hs.isEmpty ? 0 : Double(hs.filter { week($0, "me")[i] != 0 }.count) / Double(hs.count)
    }
    func joined(_ id: String) -> Bool { G(id) != nil }
    /// Every task in a group, in list order.
    func tasks(of gid: String) -> [Habit] { habits.filter { $0.group == gid } }
    /// Admins-only groups let just their admins add tasks; otherwise any member can.
    func canAddTask(_ g: HabitGroup) -> Bool { g.taskPerm == .members || g.admins.contains("me") }
    func isAdmin(_ g: HabitGroup) -> Bool { g.admins.contains("me") }
    func chTotal(_ ch: Challenge?) -> Int { guard let ch else { return 0 }; return ch.c.values.reduce(0, +) + (ch.others ?? 0) }
    var unreadCount: Int { notifs.filter(\.unread).count }
    var topRoute: Route? { stack.last }
    var voice: String { Seed.voice[voiceI % Seed.voice.count] }

    // MARK: - flow

    func obNext() { obAttempted = false; step += 1 }
    func obBack() { obAttempted = false; step = max(0, step - 1) }

    var obNameError: String? { obName.trimmingCharacters(in: .whitespaces).isEmpty ? "Enter your name." : nil }
    var obEmailError: String? {
        let e = obEmail.trimmingCharacters(in: .whitespaces)
        if e.isEmpty { return "Enter your email." }
        return e.range(of: #"^[A-Z0-9._%+-]+@[A-Z0-9-]+(\.[A-Z0-9-]+)*\.[A-Z]{2,}$"#, options: [.regularExpression, .caseInsensitive]) == nil
            ? "Enter a valid email, like you@school.edu." : nil
    }
    var obPasswordError: String? {
        if obPassword.isEmpty { return "Create a password." }
        return obPassword.count < 8 ? "Your password needs at least 8 characters." : nil
    }
    /// Account step: only continue once name, email and password are valid.
    func obAccountContinue() {
        obAttempted = true
        guard obNameError == nil, obEmailError == nil, obPasswordError == nil else { return }
        let full = obName.trimmingCharacters(in: .whitespaces)
        people["me"]?.full = full
        people["me"]?.name = String(full.split(separator: " ").first ?? Substring(full))
        obNext()
    }
    func toggleGoal(_ id: String) { if obGoals.contains(id) { obGoals.remove(id) } else { obGoals.insert(id) } }
    func toggleObAdd(_ id: String) { if obAdded.contains(id) { obAdded.remove(id) } else { obAdded.insert(id) } }
    func obFinish() {
        mode = .app; tab = .today; stack = []
        showToast("Welcome to Creds, \(person("me").name)")
    }
    func selectTab(_ t: Tab) { tab = t; stack = [] }
    func push(_ r: RouteKind, _ id: String? = nil) {
        stack.append(Route(r: r, id: id))
        if sheet != nil { closeSheet() }
    }
    func back() { if !stack.isEmpty { stack.removeLast() } }
    func selectDay(_ i: Int) { day = i }

    // MARK: - sheets & toasts

    func openSheet(_ s: SheetState) {
        var s = s
        s.presentID = UUID()
        sheet = s
    }
    func closeSheet() { sheet = nil }

    func showToast(_ msg: String, undo: (() -> Void)? = nil, icon: UIIcon = .check) {
        toastTask?.cancel()
        let t = ToastState(msg: msg, icon: icon, undo: undo)
        toast = t
        let wait: UInt64 = undo != nil ? 4_000_000_000 : 2_400_000_000
        toastTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: wait)
            guard !Task.isCancelled, let self, self.toast?.id == t.id else { return }
            self.toast = nil
        }
    }
    func runUndo() {
        let fn = toast?.undo
        toastTask?.cancel()
        toast = nil
        fn?()
    }

    // MARK: - check-ins

    /// Tapping a check: done → ask before undoing; otherwise the camera, since every check-in needs a photo.
    func check(_ id: String) {
        guard let h = H(id) else { return }
        if isDone(h, "me") { pendingUncheck = id }
        else { openSheet(SheetState(type: .proof, id: id)) }
    }

    func confirmUncheck() {
        guard let id = pendingUncheck else { return }
        pendingUncheck = nil
        undoCheck(id)
    }

    /// Stamps today's check-in. Only called once a captured photo has been saved.
    private func checkOff(_ id: String) {
        guard let i = hIndex(id), !isDone(habits[i], "me") else { return }
        habits[i].mem["me"]?.done = Seed.now
        habits[i].mem["me"]?.sample = nil
        if let gid = habits[i].group, let gi = gIndex(gid), groups[gi].ch != nil {   // the linked habit adds to the group total
            groups[gi].ch!.c["me"] = (groups[gi].ch!.c["me"] ?? 0) + 1
        }
        voiceI += 1
        Feedback.checkOff(self)
    }

    func undoCheck(_ id: String) {
        guard let i = hIndex(id) else { return }
        let prev = habits[i].mem["me"]
        let name = habits[i].name
        let gid = habits[i].group
        reopen(i)
        showToast("Unstamped \(name).", undo: { [weak self] in
            guard let self, let i = self.hIndex(id) else { return }
            self.habits[i].mem["me"] = prev
            if let gid, let gi = self.gIndex(gid), self.groups[gi].ch != nil { self.groups[gi].ch!.c["me"] = (self.groups[gi].ch!.c["me"] ?? 0) + 1 }
        }, icon: .refresh)
    }

    /// Marks today's check-in as not done and takes it back off the group total.
    private func reopen(_ i: Int) {
        habits[i].mem["me"]?.done = nil
        habits[i].mem["me"]?.proof = false
        habits[i].mem["me"]?.sample = nil
        if let gid = habits[i].group, let gi = gIndex(gid), let c = groups[gi].ch?.c["me"], c > 0 { groups[gi].ch!.c["me"] = c - 1 }
    }

    func openDetails(_ id: String) { openSheet(SheetState(type: .details, id: id)) }
    /// Shutter: open the real camera, or explain why it can't open.
    func shoot() {
        sheet?.photoError = nil
        Task { @MainActor in
            if let problem = await Camera.availabilityProblem() {
                sheet?.photoError = problem
            } else {
                sheet?.showCamera = true
            }
        }
    }
    func captured(_ image: UIImage) {
        sheet?.showCamera = false
        sheet?.photo = image
        sheet?.shot = true
        sheet?.photoError = nil
        sheet?.flash += 1
    }
    func retake() { sheet?.shot = false; sheet?.photo = nil; sheet?.photoError = nil }

    /// Saves the photo to the story; the task is stamped only once that has succeeded.
    func postProof(_ id: String) {
        guard let i = hIndex(id), let s = sheet, !s.saving else { return }
        guard let photo = s.photo else {
            sheet?.photoError = "Take a photo first. \(habits[i].name) stays open until a photo is added."
            return
        }
        sheet?.saving = true
        let cap = s.caption.trimmingCharacters(in: .whitespaces)
        let h = habits[i]
        do {
            let item = try storyStore.add(photo, habit: h, caption: cap.isEmpty ? nil : cap, time: h.mem["me"]?.done ?? Seed.now,
                                          place: G(h.group)?.name ?? "Just me", to: story)
            story.append(item)
        } catch {
            sheet?.saving = false
            sheet?.photoError = "Your photo wasn’t saved to your story: \(error.localizedDescription). \(isDone(h, "me") ? "Try posting again." : "\(h.name) is still open — try again.")"
            return
        }
        if !isDone(h, "me") { checkOff(id) }
        habits[i].mem["me"]?.proof = true
        habits[i].mem["me"]?.sample = nil
        habits[i].mem["me"]?.caption = cap.isEmpty ? nil : cap
        closeSheet()
        showToast(shared(h) ? "Posted to \(G(h.group)?.name ?? "your friends") and your story" : "Added to your story", icon: .camera)
    }
    /// Latest story photo for a habit (today's post).
    func storyItem(for habitId: String) -> StoryItem? { story.last { $0.habitId == habitId } }
    func storyImage(_ item: StoryItem) -> UIImage? { storyStore.image(item) }
    func openStory() { if !story.isEmpty { overlay = .story(UUID()) } }
    func viewPost(_ id: String, _ p: String) { openSheet(SheetState(type: .post, id: id, p: p)) }
    /// Without its photo the check-in no longer counts, so the task opens again.
    func removePhoto(_ id: String) {
        guard let i = hIndex(id) else { return }
        if let item = storyItem(for: id) {
            storyStore.remove(item, from: story)
            story.removeAll { $0.id == item.id }
        }
        reopen(i)
        habits[i].mem["me"]?.caption = nil
        closeSheet()
        showToast("Photo removed · \(habits[i].name) is open again", icon: .camera)
    }
    func deleteHabit(_ id: String) {
        guard let i = hIndex(id) else { return }
        let h = habits.remove(at: i)
        closeSheet()
        showToast("Deleted \(h.name)", undo: { [weak self] in self?.habits.insert(h, at: min(i, self?.habits.count ?? 0)) }, icon: .x)
    }

    // MARK: - create habit

    func openCreate() { openSheet(SheetState(type: .create, name: "", ic: "water", freq: "Every day", with: "solo")) }
    /// New task already pointed at a group (from the group page).
    func openCreate(in gid: String) {
        guard let g = G(gid), canAddTask(g) else { return }
        openSheet(SheetState(type: .create, name: "", ic: g.ic, freq: "Every day", with: "group", gid: gid))
    }

    func createGo() {
        guard let f = sheet else { return }
        let name = f.name.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { showToast("Give your habit a name first", icon: .info); return }
        if f.with == "group" && f.gid == nil { showToast("Pick a group for this habit", icon: .info); return }
        if f.with == "group", let g = G(f.gid), !canAddTask(g) { showToast("Only admins can add tasks to \(g.name)", icon: .lock); return }
        if f.freq == "Custom" && f.days.isEmpty { showToast("Pick at least one day", icon: .info); return }
        let freq = f.freq == "Custom" ? Self.freqLabel(f.days) : f.freq
        let id = "h" + String(Int(Date().timeIntervalSince1970 * 1000), radix: 36)
        var mm = Ordered<Member>([("me", mem(0, [0, 0, 0, 0, 0, 0]))])
        if f.with == "friends" { f.friends.forEach { mm[$0] = mem(0, [0, 0, 0, 0, 0, 0]) } }
        if f.with == "group", let g = G(f.gid) { g.members.forEach { if $0 != "me" { mm[$0] = mem(0, [0, 0, 0, 0, 0, 0]) } } }
        habits.insert(Habit(id: id, name: name, ic: f.ic, time: "Anytime", tod: "anytime", freq: freq, group: f.with == "group" ? f.gid : nil, mem: mm), at: 0)
        closeSheet()
        if f.with == "group", let gid = f.gid {
            showToast("“\(name)” added to \(G(gid)?.name ?? "the group")")   // stay on the group page
        } else {
            mode = .app; tab = .today; stack = []; day = 6; anim = id
            showToast("“\(name)” added to your book")
        }
    }

    static let weekdayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    /// "Mon, Wed, Fri" — or the preset name when the custom days match one.
    static func freqLabel(_ days: [Int]) -> String {
        let d = Set(days).sorted()
        if d.count == 7 { return "Every day" }
        if d == [0, 1, 2, 3, 4] { return "Weekdays" }
        return d.map { weekdayNames[$0] }.joined(separator: ", ")
    }

    /// Whether the habit is planned for that date; a custom schedule rests on the days it leaves out.
    func scheduled(_ h: Habit, _ d: Date) -> Bool {
        let i = (Day.cal.component(.weekday, from: d) + 5) % 7   // Monday = 0
        switch h.freq {
        case "Every day": return true
        case "Weekdays": return i < 5
        default:
            let days = h.freq.split(separator: ",").compactMap { Self.weekdayNames.firstIndex(of: $0.trimmingCharacters(in: .whitespaces)) }
            return days.isEmpty || days.contains(i)
        }
    }

    /// How one day of a habit reads: done, missed (scheduled, not done), rest (not on the schedule), today still open, or ahead.
    func dayMark(_ h: Habit, _ d: Date) -> DayMark {
        let diff = Day.cal.dateComponents([.day], from: d, to: Seed.today).day ?? 0
        if diff >= 0 && diff <= 6 && week(h, "me")[6 - diff] != 0 { return .done }
        if !scheduled(h, d) { return .rest }
        if diff < 0 { return .upcoming }
        return diff == 0 ? .pending : .missed
    }

    func toggleDay(_ i: Int) {
        guard sheet != nil else { return }
        if let k = sheet?.days.firstIndex(of: i) { sheet?.days.remove(at: k) } else { sheet?.days.append(i) }
    }

    // MARK: - groups

    func openGroup(_ id: String) {
        if sheet != nil { closeSheet() }
        stack.append(Route(r: .group, id: id))
    }

    func makeGroup(_ habitId: String) {
        guard let h = H(habitId) else { return }
        openSheet(SheetState(type: .group, tall: true, name: h.name + " crew", desc: "", ic: h.ic, goal: "", fromHabit: h.id))
    }
    func createGroup() { openSheet(SheetState(type: .group, tall: true, name: "", desc: "", ic: "water", goal: "")) }

    func groupGo() {
        guard let f = sheet else { return }
        let name = f.name.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { showToast("Give your group a name", icon: .info); return }
        let id = "g" + String(Int(Date().timeIntervalSince1970 * 1000), radix: 36)
        let members = ["me"] + f.friends
        let c = Ordered<Int>(members.map { ($0, 0) })
        let goalText = f.goal.trimmingCharacters(in: .whitespaces)
        let goalN = Int(goalText.prefix { $0.isNumber }) ?? 20
        let desc = f.desc.trimmingCharacters(in: .whitespaces)
        groups.insert(HabitGroup(id: id, name: name, ic: f.ic, type: "friends", habit: f.fromHabit, notif: "Everything",
                            desc: desc.isEmpty ? "A new circle. Be kind, show up." : desc, members: members,
                            ch: goalText.isEmpty ? nil : Challenge(title: goalText, detail: "Your first challenge together.", unit: "check-ins", goal: goalN == 0 ? 20 : goalN, left: 7, c: c),
                            fin: [], admins: ["me"], taskPerm: f.perm), at: 0)
        if let hid = f.fromHabit, let hi = hIndex(hid) {
            habits[hi].group = id
            f.friends.forEach { habits[hi].mem[$0] = mem(0, [0, 0, 0, 0, 0, 0]) }
        }
        closeSheet()
        tab = .groups; stack = [Route(r: .group, id: id)]
        showToast("\(name) is ready")
    }

    func openCommunity(_ id: String) { openSheet(SheetState(type: .community, id: id)) }

    func join(_ id: String) {
        guard let c = C(id) else { return }
        if joined(id) { openGroup(id); return }
        joinCommunity(id)
        showToast("Joined \(c.name) · it’s in your groups")
    }

    private func joinCommunity(_ id: String) {
        guard !joined(id), let ci = communities.firstIndex(where: { $0.id == id }) else { return }
        let c = communities[ci]
        let f = c.friends.filter { friends.contains($0) }
        var mm = Ordered<Member>([("me", mem(0, [0, 0, 0, 0, 0, 0]))])
        for (i, p) in f.enumerated() {
            let s = 3 + i * 6
            let hist = [0, 1, 1, 1, 1, 1].enumerated().map { k, v in k > 5 - s ? 1 : v }
            mm[p] = i == 0 ? mem(s, hist, "8:45 AM", sample: 0) : mem(s, hist)
        }
        habits.append(Habit(id: c.id, name: c.habit ?? c.name, ic: c.ic, time: "Anytime", tod: "anytime", freq: "Every day", group: c.id, mem: mm))
        var cc = Ordered<Int>([("me", 0)])
        for (i, p) in f.enumerated() { cc[p] = 3 + i }
        let goal = Int((Double(c.size) * 2.5).rounded())
        groups.append(HabitGroup(id: c.id, name: c.name, ic: c.ic, type: "community", habit: c.id, notif: "Milestones", size: c.size + 1, desc: c.desc, members: ["me"] + f,
                            ch: Challenge(title: "\(c.habit ?? c.name): \(goal.formatted()) check-ins this week", detail: "Everyone in the community adds to one total.", unit: "check-ins",
                                          goal: goal, left: 4, c: cc, others: Int((Double(c.size) * 1.6).rounded())),
                            fin: [], taskPerm: .admins))
        communities[ci].size += 1
    }

    func joinInvite(_ id: String) {
        guard let v = invites.first(where: { $0.id == id }) else { return }
        var mm = Ordered<Member>([("me", mem(0, [0, 0, 0, 0, 0, 0]))])
        for (i, p) in v.members.enumerated() {
            mm[p] = i < 2 ? mem(2 + i * 3, [0, 1, 1, 1, 1, 1], "\(8 + i):\(String(format: "%02d", 10 + i * 25)) AM", sample: i)
                          : mem(2 + i * 3, [0, 1, 1, 1, 1, 1])
        }
        habits.append(Habit(id: "h-" + v.id, name: "Get outside", ic: v.ic, time: "Anytime", tod: "anytime", freq: "Every day", group: v.id, mem: mm))
        var ch = v.ch
        ch.c["me"] = 0
        groups.append(HabitGroup(id: v.id, name: v.name, ic: v.ic, type: "friends", habit: "h-" + v.id, notif: "Everything", desc: v.desc, members: ["me"] + v.members, ch: ch, fin: [],
                                 admins: [v.from], taskPerm: .members))
        invites.removeAll { $0.id == id }
        if let ni = notifs.firstIndex(where: { $0.group == id }) { notifs[ni].res = "Accepted"; notifs[ni].unread = false }
    }

    func invJoin(_ id: String) {
        let v = invites.first { $0.id == id }
        joinInvite(id)
        showToast("Joined \(v?.name ?? "the group")")
    }
    func invNo(_ id: String) {
        guard let i = invites.firstIndex(where: { $0.id == id }) else { return }
        let v = invites.remove(at: i)
        showToast("Invitation hidden", undo: { [weak self] in self?.invites.insert(v, at: min(i, self?.invites.count ?? 0)) })
    }

    func logOne(_ id: String) {
        guard let gi = gIndex(id), groups[gi].ch != nil else { return }
        let before = chTotal(groups[gi].ch)
        groups[gi].ch!.c["me"] = (groups[gi].ch!.c["me"] ?? 0) + 1
        let g = groups[gi]
        if before < g.ch!.goal && chTotal(g.ch) >= g.ch!.goal {
            overlay = .celebrate(id)
            Feedback.bigMoment(self)
        } else {
            showToast("Logged one for \(g.name)")
        }
    }
    func logMinus(_ id: String) {
        guard let gi = gIndex(id), let c = groups[gi].ch?.c["me"], c > 0 else { return }
        groups[gi].ch!.c["me"] = c - 1
    }
    func setGroupNotif(_ id: String, _ v: String) { if let gi = gIndex(id) { groups[gi].notif = v } }
    /// Only an admin can change who adds tasks.
    func setTaskPerm(_ id: String, _ v: TaskPerm) {
        guard let gi = gIndex(id), isAdmin(groups[gi]) else { return }
        groups[gi].taskPerm = v
    }

    func groupMenu(_ id: String) { openSheet(SheetState(type: .groupmenu, id: id)) }
    func inviteFriends(_ id: String) { openSheet(SheetState(type: .invitefriends, id: id)) }
    func invPick(_ p: String) {
        guard sheet != nil else { return }
        if let i = sheet!.selSet.firstIndex(of: p) { sheet!.selSet.remove(at: i) } else { sheet!.selSet.append(p) }
    }
    func invSend(_ id: String) {
        guard let gi = gIndex(id), let sel = sheet?.selSet else { return }
        for p in sel {
            groups[gi].members.append(p)
            if groups[gi].ch != nil { groups[gi].ch!.c[p] = 0 }
            for hi in habits.indices where habits[hi].group == id { habits[hi].mem[p] = mem(0, [0, 0, 0, 0, 0, 0]) }
        }
        closeSheet()
        showToast("Invited \(sel.map { person($0).name }.joined(separator: " and "))")
    }

    func leaveGroup(_ id: String) {
        guard let gi = gIndex(id) else { return }
        let g = groups[gi]
        let snapHabits = habits
        groups.remove(at: gi)
        // community tasks go with the community; a friends group's tasks stay as your own
        if g.type == "community" { habits.removeAll { $0.group == id } }
        else {
            for hi in habits.indices where habits[hi].group == id {
                habits[hi].group = nil
                for p in habits[hi].mem.keys where p != "me" { habits[hi].mem[p] = nil }
            }
        }
        if sheet != nil { closeSheet() }
        if topRoute?.id == id { stack.removeLast() }
        showToast("Left \(g.name)", undo: { [weak self] in
            guard let self else { return }
            self.groups.insert(g, at: min(gi, self.groups.count))
            self.habits = snapHabits
        }, icon: .leave)
    }

    // MARK: - social

    func openReact(_ k: String) { openSheet(SheetState(type: .react, k: k)) }
    func rxPick(_ k: String, _ v: String) {
        let had = reacts[k] == v
        if had { reacts[k] = nil } else { reacts[k] = v }
        closeSheet()
        let rx = Seed.reactions.first { $0.k == v }!
        showToast(had ? "Reaction removed" : "Sent \(rx.l)", icon: rx.ic)
    }
    func openComments(_ k: String) { openSheet(SheetState(type: .comments, tall: true, k: k)) }
    func sendComment(_ k: String) {
        let txt = (sheet?.text ?? "").trimmingCharacters(in: .whitespaces)
        if txt.isEmpty { return }
        comments[k, default: []].append(Comment(p: "me", t: txt))
        sheet?.text = ""
        showToast("Comment posted", icon: .comment)
    }

    func removeRow(_ p: String) {
        guard let i = friends.firstIndex(of: p) else { return }
        friends.remove(at: i)
        showToast("Removed \(person(p).name)", undo: { [weak self] in self?.friends.insert(p, at: min(i, self?.friends.count ?? 0)) }, icon: .x)
    }
    func acceptReq(_ p: String) {
        if !friends.contains(p) { friends.append(p) }
        people[p]?.mutual = people[p]?.mutual ?? 1
        people[p]?.since = "Oct 2026"
        requests.removeAll { $0 == p }
        if let ni = notifs.firstIndex(where: { $0.who == p && $0.kind == "friend" }) { notifs[ni].res = "Accepted"; notifs[ni].unread = false }
        showToast("You and \(person(p).name) are friends now", icon: .heart)
    }
    func declineReq(_ p: String) {
        requests.removeAll { $0 == p }
        if let ni = notifs.firstIndex(where: { $0.who == p && $0.kind == "friend" }) { notifs[ni].res = "Declined"; notifs[ni].unread = false }
    }
    func contactInvite(_ i: Int) { contactInvited.insert(i); showToast("Invite sent", icon: .invite) }
    func friendMenu(_ p: String) { openSheet(SheetState(type: .friendmenu, p: p)) }
    func removeFriend(_ p: String) {
        guard let i = friends.firstIndex(of: p) else { return }
        friends.remove(at: i)
        closeSheet()
        back()
        showToast("Removed \(person(p).name)", undo: { [weak self] in self?.friends.insert(p, at: min(i, self?.friends.count ?? 0)) })
    }
    func inviteHabit(_ p: String) { openSheet(SheetState(type: .invitehabit, p: p)) }
    func inviteToHabit(_ id: String, _ p: String) {
        guard let i = hIndex(id) else { return }
        habits[i].mem[p] = mem(0, [0, 0, 0, 0, 0, 0])
        closeSheet()
        showToast("Invited \(person(p).name) to \(habits[i].name)", icon: .invite)
    }

    // MARK: - notifications

    func notifTap(_ id: String) {
        guard let i = notifs.firstIndex(where: { $0.id == id }) else { return }
        notifs[i].unread = false
        let n = notifs[i]
        if n.kind == "recap" { stack = []; tab = .recap }
        else if n.kind == "award" { stack = []; tab = .trophies }
        else if n.kind == "milestone" { stack.append(Route(r: .group, id: "hydration")) }
        else if let who = n.who, friends.contains(who) { stack.append(Route(r: .friend, id: who)) }
    }
    func notifYes(_ id: String) {
        guard let n = notifs.first(where: { $0.id == id }) else { return }
        if n.kind == "friend", let who = n.who { acceptReq(who) }
        else if n.kind == "invite", let g = n.group { joinInvite(g); showToast("Joined Touch Grass Club") }
    }
    func notifNo(_ id: String) {
        guard let i = notifs.firstIndex(where: { $0.id == id }) else { return }
        notifs[i].res = "Declined"; notifs[i].unread = false
        let n = notifs[i]
        if n.kind == "friend" { requests.removeAll { $0 == n.who } }
        if n.kind == "invite" { invites.removeAll { $0.id == n.group } }
    }
    func markRead() {
        for i in notifs.indices { notifs[i].unread = false }
        showToast("All caught up")
    }

    // MARK: - trophies

    func openTrophy(_ id: String) {
        openSheet(SheetState(type: .trophy, id: id))
        if let i = trophies.firstIndex(where: { $0.id == id }), trophies[i].fresh { trophies[i].fresh = false }
    }
    func pin(_ id: String) {
        if let i = pinned.firstIndex(of: id) { pinned.remove(at: i) }
        else if pinned.count >= 6 { showToast("Your showcase holds 6. Unpin one first."); return }
        else { pinned.append(id) }
    }

    // MARK: - recap

    func playRecap() { overlay = .recap(UUID()) }
    /// Reached the award slide: the medal lands in the case.
    func recapReachedAward() {
        if let i = trophies.firstIndex(where: { $0.id == "t19" }), trophies[i].got == nil {
            trophies[i].got = "Wk 40"; trophies[i].fresh = true
            Feedback.bigMoment(self)
        }
        recapSeen = true
    }
    func closeOverlay() { overlay = nil }
    func wsTrophies() { mode = .app; tab = .trophies; stack = []; overlay = nil }

    // MARK: - profile & settings

    func avatarPicker() { openSheet(SheetState(type: .avatar)) }
    func setPhoto(_ image: UIImage) {
        do {
            myPhoto = try photoStore.save(image)
            showToast("Profile picture updated")
        } catch {
            showToast("Your picture wasn’t saved: \(error.localizedDescription)")
        }
    }
    func removePhoto() { photoStore.remove(); myPhoto = nil; showToast("Profile picture removed") }
    func editProfile() { openSheet(SheetState(type: .editprofile, full: person("me").full, bio: person("me").bio)) }
    func profileSave() {
        guard let s = sheet else { return }
        let full = s.full.trimmingCharacters(in: .whitespaces)
        if !full.isEmpty { people["me"]?.full = full }
        people["me"]?.bio = s.bio.trimmingCharacters(in: .whitespaces)
        closeSheet()
        showToast("Profile saved")
    }
    func toggleSetting(_ k: String) { settings[k] = !(settings[k] ?? false) }

    func reset() {
        overlay = nil
        sheet = nil
        pendingUncheck = nil
        storyStore.removeAll()
        photoStore.remove()
        story = []
        let fresh = AppModel()
        mode = .onboard; step = 0; obGoals = fresh.obGoals; obAdded = fresh.obAdded
        obName = ""; obEmail = ""; obPassword = ""; obAttempted = false
        tab = .today; stack = []; anim = nil; day = 6
        people = fresh.people; friends = fresh.friends; habits = fresh.habits; groups = fresh.groups; invites = fresh.invites
        communities = fresh.communities; notifs = fresh.notifs; trophies = fresh.trophies; myPhoto = nil
        reacts = [:]; comments = [:]; requests = fresh.requests; q = ""; cat = "All"; trView = "book"
        pinned = fresh.pinned; recapSeen = false; settings = fresh.settings; contactInvited = []
        showToast("Demo data reset")
    }

    // MARK: - recap stats

    /// `n` done out of `due` scheduled days (rest days aren't due unless done anyway).
    struct WeekRow { let h: Habit; let n: Int; let due: Int; let marks: [DayMark] }
    struct RecapPicks {
        var perfect: (p: String, h: Habit, s: Int)?
        var second: FeedEvent?
        var myBest: Habit?
        var myCount: Int
        var rows: [WeekRow]
        var pct: Int
        var delta: Int
        var best: WeekRow?
        var weak: WeekRow?
    }

    func recapPicks() -> RecapPicks {
        var perfect: (p: String, h: Habit, s: Int)? = nil
        for h in habits {
            for p in peopleOf(h) where p != "me" && weekCount(h, p) == 7 && (perfect == nil || streak(h, p) > perfect!.s) {
                perfect = (p, h, streak(h, p))
            }
        }
        let started = Seed.events.first { $0.kind == "started" && friends.contains($0.who ?? "") }
        let comeback = Seed.events.first { $0.kind == "comeback" && friends.contains($0.who ?? "") }
        let myBest = habits.dropFirst().reduce(habits.first) { b, h in
            guard let b else { return h }
            return streak(h, "me") > streak(b, "me") ? h : b
        }
        let myCount = habits.reduce(0) { $0 + weekCount($1, "me") }
        let rows = stableSorted(required.map { h in
            let marks = (0..<7).map { dayMark(h, Day.date($0)) }
            return WeekRow(h: h, n: marks.filter { $0 == .done }.count, due: marks.filter { $0 != .rest }.count, marks: marks)
        }) { a, b in
            // best share of due days first
            let ra = a.due > 0 ? a.n * 1000 / a.due : 0, rb = b.due > 0 ? b.n * 1000 / b.due : 0
            return ra != rb ? rb - ra : streak(b.h, "me") - streak(a.h, "me")
        }
        let done = rows.reduce(0) { $0 + $1.n }, total = rows.reduce(0) { $0 + $1.due }
        let pct = total > 0 ? Int((Double(done) / Double(total) * 100).rounded()) : 0
        return RecapPicks(perfect: perfect, second: started ?? comeback, myBest: myBest, myCount: myCount, rows: rows, pct: pct,
                          delta: pct - Seed.prevWeekPct, best: rows.first, weak: rows.last)
    }
}

/// Stable sort with a JS-style comparator (negative → a first).
func stableSorted<T>(_ list: [T], _ cmp: (T, T) -> Int) -> [T] {
    list.enumerated().sorted { x, y in
        let r = cmp(x.element, y.element)
        return r != 0 ? r < 0 : x.offset < y.offset
    }.map(\.element)
}

// MARK: - dates & times

enum Day {
    static let cal: Calendar = { var c = Calendar(identifier: .gregorian); c.locale = Locale(identifier: "en_US"); return c }()
    /// Index 0…6 in the 7-day window ending today.
    static func date(_ i: Int) -> Date { cal.date(byAdding: .day, value: -(6 - i), to: Seed.today)! }
    static func fmt(_ d: Date, _ format: String) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US"); f.setLocalizedDateFormatFromTemplate(format)
        return f.string(from: d)
    }
    static func narrow(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US"); f.dateFormat = "EEEEE"
        return f.string(from: d)
    }
    static func weekday(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US"); f.dateFormat = "EEEE"
        return f.string(from: d)
    }
    /// "6:30 AM" → minutes since midnight.
    static func tmin(_ t: String) -> Int {
        let parts = t.split(separator: " ")
        guard parts.count == 2 else { return 0 }
        let hm = parts[0].split(separator: ":").compactMap { Int($0) }
        guard hm.count == 2 else { return 0 }
        var h = hm[0]
        if parts[1] == "PM" && h != 12 { h += 12 }
        if parts[1] == "AM" && h == 12 { h = 0 }
        return h * 60 + hm[1]
    }
    static func hasTime(_ h: Habit) -> Bool { h.time.contains { $0.isNumber } }
}
