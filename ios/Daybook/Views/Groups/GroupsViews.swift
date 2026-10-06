import Charts
import SwiftData
import SwiftUI

struct GroupsListView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \HabitGroup.createdAt, order: .reverse) private var groups: [HabitGroup]
    @Query private var friends: [Friend]
    @State private var showCreate = false

    var body: some View {
        let byID = Dictionary(friends.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let mine = groups.filter(\.isMember)
        let invites = groups.filter { $0.isInvited && !$0.isMember }
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if !invites.isEmpty {
                    SectionHeader("Invitations", count: invites.count)
                    ForEach(invites) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            GroupRow(group: group, byID: byID)
                            HStack {
                                Button("Join") { model.join(group) }.buttonStyle(InlineActionStyle(filled: true))
                                Button("Not now") { model.declineInvite(group) }.buttonStyle(InlineActionStyle(tint: Palette.inkSecondary))
                                Spacer()
                                Button("Preview") { model.router.push(.group(group)) }.buttonStyle(InlineActionStyle())
                            }
                        }
                        .card(tint: group.tint, emphasized: true)
                    }
                }
                SectionHeader("Your groups", count: mine.count)
                if mine.isEmpty {
                    EmptyStateView(symbol: "person.3", title: "No groups yet", message: "Start a small circle and set a goal you can reach together.", actionTitle: "Create a group") { showCreate = true }
                }
                ForEach(mine) { group in
                    Button { model.router.push(.group(group)) } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            GroupRow(group: group, byID: byID)
                            if let challenge = group.activeChallenges.first(where: { $0.kind == .collective }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(challenge.title).font(.caption.weight(.semibold)).foregroundStyle(Palette.ink).lineLimit(1)
                                        Spacer()
                                        Text("\(challenge.total)/\(challenge.goal)").font(.caption.monospacedDigit()).foregroundStyle(Palette.inkSecondary)
                                    }
                                    ProgressBar(progress: challenge.progress, tint: group.tint.color, height: 8)
                                }
                            }
                        }
                        .card()
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(Metrics.gutter)
        }
        .background(PaperBackground())
        .navigationTitle("Groups")
        .toolbar {
            Button { showCreate = true } label: { Image(systemName: "plus") }
                .accessibilityLabel("Create group")
        }
        .sheet(isPresented: $showCreate) { GroupFormView(group: nil) }
    }
}

struct GroupRow: View {
    let group: HabitGroup
    let byID: [UUID: Friend]

    var body: some View {
        HStack(spacing: 12) {
            SymbolBadge(symbol: group.symbol, tint: group.tint, size: 46, filled: true)
            VStack(alignment: .leading, spacing: 3) {
                Text(group.name).font(.display(.headline)).foregroundStyle(Palette.ink)
                Text(group.detail).font(.caption).foregroundStyle(Palette.inkSecondary).lineLimit(2)
            }
            Spacer(minLength: 0)
            AvatarStack(avatars: group.memberIDs.compactMap { id in byID[id].map { (id, $0.avatar, false) } }, size: 24, maxShown: 3)
        }
    }
}

// MARK: - Detail

struct GroupDetailView: View {
    let group: HabitGroup
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Query private var friends: [Friend]
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var showEdit = false
    @State private var showChallenge = false
    @State private var showInvite = false
    @State private var confirmLeave = false

    var body: some View {
        let byID = Dictionary(friends.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(byID)
                if !group.isMember {
                    Button("Join \(group.name)") { model.join(group) }.buttonStyle(PrimaryButtonStyle(tint: group.tint.color))
                }
                ForEach(group.activeChallenges) { challenge in
                    if challenge.kind == .prediction {
                        PredictionCard(challenge: challenge, group: group, byID: byID)
                    } else {
                        ChallengeCard(challenge: challenge, group: group, byID: byID)
                    }
                }
                let finished = group.challenges.filter(\.isFinished)
                if !finished.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Finished")
                        ForEach(finished) { challenge in
                            HStack(spacing: 10) {
                                SymbolBadge(symbol: challenge.symbol, tint: group.tint, size: 32, filled: challenge.isComplete)
                                VStack(alignment: .leading) {
                                    Text(challenge.title).font(.subheadline.weight(.semibold)).foregroundStyle(Palette.ink)
                                    Text(challenge.isComplete ? "Goal reached · \(challenge.total) \(challenge.unit)" : "\(challenge.total) of \(challenge.goal) — still counts")
                                        .font(.caption).foregroundStyle(Palette.inkSecondary)
                                }
                                Spacer()
                                if challenge.isComplete { InkStamp(text: "Done", color: group.tint.color, size: 40).rotationEffect(.degrees(-10)) }
                            }
                        }
                    }
                    .card()
                }
                if group.isMember {
                    settingsCard
                }
            }
            .padding(Metrics.gutter)
        }
        .background(PaperBackground())
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if group.isMember {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showChallenge = true } label: { Label("New challenge", systemImage: "flag") }
                        Button { showInvite = true } label: { Label("Invite friends", systemImage: "person.badge.plus") }
                        Button { showEdit = true } label: { Label("Edit group", systemImage: "pencil") }
                        Button { model.router.push(.share(.milestone)) } label: { Label("Share milestone", systemImage: "square.and.arrow.up") }
                        Divider()
                        Button(role: .destructive) { confirmLeave = true } label: { Label("Leave group", systemImage: "rectangle.portrait.and.arrow.right") }
                    } label: { Image(systemName: "ellipsis.circle") }
                    .accessibilityLabel("Group actions")
                }
            }
        }
        .sheet(isPresented: $showEdit) { GroupFormView(group: group) }
        .sheet(isPresented: $showChallenge) { ChallengeFormView(group: group) }
        .sheet(isPresented: $showInvite) { GroupInviteSheet(group: group) }
        .confirmationDialog("Leave \(group.name)?", isPresented: $confirmLeave, titleVisibility: .visible) {
            Button("Leave group", role: .destructive) { model.leave(group); dismiss() }
        } message: { Text("Your past contributions stay in the group's history.") }
        .onChange(of: confirmLeave) { _, value in if value { model.feedback(.warning) } }
    }

    private func header(_ byID: [UUID: Friend]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                SymbolBadge(symbol: group.symbol, tint: group.tint, size: 60, filled: true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name).font(.display(.title2, weight: .heavy)).foregroundStyle(Palette.ink)
                    Text("\(group.memberCount) members").font(.subheadline).foregroundStyle(Palette.inkSecondary)
                }
            }
            Text(group.detail).font(.hand(18)).foregroundStyle(Palette.ink.opacity(0.85))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if group.isMember, let me = model.me {
                        memberChip(name: "You", avatar: me.avatar, friend: nil)
                    }
                    ForEach(group.memberIDs, id: \.self) { id in
                        if let friend = byID[id] { memberChip(name: friend.firstName, avatar: friend.avatar, friend: friend) }
                    }
                }
            }
        }
        .card(tint: group.tint, emphasized: true)
    }

    private func memberChip(name: String, avatar: AvatarConfig, friend: Friend?) -> some View {
        Button {
            if let friend { model.router.push(.friend(friend)) }
        } label: {
            VStack(spacing: 3) {
                AvatarView(config: avatar, size: 44, showsCompanion: false)
                Text(name).font(.caption2.weight(.semibold)).foregroundStyle(Palette.ink)
            }
            .frame(minWidth: 50)
        }
        .buttonStyle(.plain)
        .disabled(friend == nil)
    }

    private var settingsCard: some View {
        let linked = habits.first { $0.groupID == group.id }
        return VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Settings")
            Picker("Notifications", selection: Binding(get: { group.notify }, set: { model.setNotify($0, for: group) })) {
                ForEach(GroupNotifyLevel.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            Menu {
                Button("None") { model.linkHabit(nil, to: group) }
                ForEach(habits.filter { $0.status == .active }) { habit in
                    Button(habit.name) { model.linkHabit(habit, to: group) }
                }
            } label: {
                HStack {
                    Label("Counts toward challenges", systemImage: "link")
                        .font(.subheadline).foregroundStyle(Palette.ink)
                    Spacer()
                    Text(linked?.name ?? "None").font(.subheadline.weight(.semibold))
                    Image(systemName: "chevron.up.chevron.down").font(.caption)
                }
                .frame(minHeight: 44)
            }
            Text("Checking in on the linked habit adds to this group's active challenge automatically.")
                .font(.caption).foregroundStyle(Palette.inkSecondary)
        }
        .card()
    }
}

// MARK: - Challenge cards

struct ChallengeCard: View {
    let challenge: Challenge
    let group: HabitGroup
    let byID: [UUID: Friend]
    @Environment(AppModel.self) private var model

    var body: some View {
        let contributions = challenge.contributions.sorted { $0.count > $1.count }
        let mine = challenge.count(for: model.meID)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(challenge.isComplete ? "Goal reached" : "\(challenge.daysLeft) day\(challenge.daysLeft == 1 ? "" : "s") left")
                    Text(challenge.title).font(.display(.headline)).foregroundStyle(Palette.ink)
                    Text(challenge.detail).font(.caption).foregroundStyle(Palette.inkSecondary)
                }
                Spacer()
                if challenge.isComplete {
                    InkStamp(text: "Goal", symbol: "flag.checkered", color: Palette.burgundy, size: 58)
                        .rotationEffect(.degrees(-12))
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(challenge.total)").font(.display(.title, weight: .heavy)).foregroundStyle(Palette.ink)
                        .contentTransition(.numericText(value: Double(challenge.total)))
                    Text("of \(challenge.goal) \(challenge.unit)").font(.subheadline).foregroundStyle(Palette.inkSecondary)
                    Spacer()
                    Text(challenge.progress.percentText).font(.display(.subheadline, weight: .heavy)).foregroundStyle(group.tint.color)
                }
                ZStack(alignment: .leading) {
                    ProgressBar(progress: challenge.progress, tint: group.tint.color, height: 14)
                    GeometryReader { proxy in
                        ForEach([25, 50, 75], id: \.self) { mark in
                            Rectangle().fill(Palette.card).frame(width: 2, height: 14)
                                .offset(x: proxy.size.width * CGFloat(mark) / 100)
                        }
                    }
                    .frame(height: 14)
                    .accessibilityHidden(true)
                }
            }
            .accessibilityElement(children: .combine)

            // Milestones to cheer
            let reached = challenge.reachedMilestones
            if !reached.isEmpty {
                HStack(spacing: 6) {
                    ForEach(reached, id: \.self) { mark in
                        let reacted = challenge.reactedMilestones.contains(mark)
                        Button {
                            model.reactToMilestone(challenge, milestone: mark)
                        } label: {
                            Label("\(mark)%", systemImage: reacted ? "hands.clap.fill" : "hands.clap")
                        }
                        .buttonStyle(InlineActionStyle(tint: Palette.ink, filled: reacted))
                        .disabled(reacted)
                        .accessibilityLabel(reacted ? "Cheered \(mark) percent milestone" : "Cheer the \(mark) percent milestone")
                    }
                    Spacer(minLength: 0)
                }
            }

            // Contributions chart
            if !contributions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Contributions").font(.caption.weight(.bold)).foregroundStyle(Palette.inkSecondary)
                    Chart(contributions, id: \.memberID) { entry in
                        BarMark(x: .value("Count", entry.count), y: .value("Member", name(for: entry.memberID)))
                            .foregroundStyle(entry.memberID == model.meID ? Palette.burgundy : group.tint.color)
                            .cornerRadius(4)
                            .annotation(position: .trailing) {
                                Text("\(entry.count)").font(.caption2.monospacedDigit()).foregroundStyle(Palette.inkSecondary)
                            }
                    }
                    .chartXAxis(.hidden)
                    .frame(height: CGFloat(contributions.count) * 26 + 10)
                    HandNote(supportiveLine(contributions), size: 15)
                }
            }

            if group.isMember, !challenge.isFinished {
                HStack(spacing: 10) {
                    Button {
                        model.logContribution(challenge, amount: 1)
                    } label: {
                        Label("Log one", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: Palette.burgundy))
                    Button {
                        model.logContribution(challenge, amount: -1)
                    } label: {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(SecondaryButtonStyle(fullWidth: false))
                    .disabled(mine == 0)
                    .accessibilityLabel("Remove one of my contributions")
                }
                Text("You've added \(mine).").font(.caption).foregroundStyle(Palette.inkSecondary)
            }
        }
        .card()
    }

    private func name(for id: UUID) -> String {
        id == model.meID ? "You" : (byID[id]?.firstName ?? "Friend")
    }

    /// Celebrates contributors without singling anyone out negatively.
    private func supportiveLine(_ entries: [Contribution]) -> String {
        guard let top = entries.first else { return "" }
        let topName = name(for: top.memberID)
        let helpers = entries.filter { $0.count > 0 }.count
        return "\(topName) is leading the charge · \(helpers) people chipping in"
    }
}

struct PredictionCard: View {
    let challenge: Challenge
    let group: HabitGroup
    let byID: [UUID: Friend]
    @Environment(AppModel.self) private var model

    var body: some View {
        let options: [UUID] = (group.isMember ? [model.meID] : []) + group.memberIDs
        let myPick = challenge.votes.first { $0.voterID == model.meID }?.choiceID
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Prediction · \(challenge.daysLeft) days left")
            Text(challenge.title).font(.display(.headline)).foregroundStyle(Palette.ink)
            Text(challenge.detail).font(.caption).foregroundStyle(Palette.inkSecondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 8)], spacing: 8) {
                ForEach(options, id: \.self) { id in
                    let isMe = id == model.meID
                    let votes = challenge.votes.filter { $0.choiceID == id }.count
                    Button {
                        model.predict(challenge, winner: id)
                    } label: {
                        VStack(spacing: 4) {
                            if let avatar = isMe ? model.me?.avatar : byID[id]?.avatar {
                                AvatarView(config: avatar, size: 44, showsCompanion: false)
                            }
                            Text(isMe ? "You" : (byID[id]?.firstName ?? "Friend")).font(.caption.weight(.semibold)).foregroundStyle(Palette.ink)
                            Text("\(votes) vote\(votes == 1 ? "" : "s")").font(.caption2).foregroundStyle(Palette.inkSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 92)
                        .background(RoundedRectangle(cornerRadius: 12).fill(myPick == id ? Palette.inkBlue.opacity(0.14) : Palette.paperDeep.opacity(0.5)))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(myPick == id ? Palette.inkBlue : Color.clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .disabled(!group.isMember)
                    .accessibilityAddTraits(myPick == id ? .isSelected : [])
                }
            }
            if group.isMember {
                Button {
                    model.resolvePrediction(challenge)
                } label: {
                    Label("Reveal result (demo)", systemImage: "wand.and.stars")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(myPick == nil)
                Text(myPick == nil ? "Pick someone to lock in your guess." : "Results come from activity, not votes. Bragging rights only.")
                    .font(.caption).foregroundStyle(Palette.inkSecondary)
            }
        }
        .card()
    }
}

// MARK: - Forms

struct GroupFormView: View {
    let group: HabitGroup?
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Friend> { $0.statusRaw == "friend" }, sort: \Friend.name) private var friends: [Friend]
    @State private var name = ""
    @State private var detail = ""
    @State private var symbol = "person.3.fill"
    @State private var tint: TintToken = .sage
    @State private var members: Set<UUID> = []
    @State private var didLoad = false

    private let symbols = ["person.3.fill", "drop.fill", "book.fill", "tree.fill", "figure.run", "moon.stars.fill", "dumbbell.fill", "leaf.fill", "music.note", "fork.knife", "heart.fill", "sun.max.fill"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Group name", text: $name)
                    TextField("What's it about?", text: $detail, axis: .vertical).lineLimit(1...3)
                }
                Section("Look") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 8) {
                        ForEach(symbols, id: \.self) { item in
                            Button { symbol = item } label: {
                                SymbolBadge(symbol: item, tint: tint, size: 42, filled: symbol == item).frame(width: 48, height: 48)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(symbol == item ? .isSelected : [])
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) { TintPicker(selection: $tint) }
                }
                Section("Members") {
                    ForEach(friends) { friend in
                        Button {
                            if members.contains(friend.id) { members.remove(friend.id) } else { members.insert(friend.id) }
                        } label: { FriendPickRow(friend: friend, isSelected: members.contains(friend.id)) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .navigationTitle(group == nil ? "New group" : "Edit group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(group == nil ? "Create" : "Save") {
                        if let group {
                            model.updateGroup(group, name: name, detail: detail, symbol: symbol, tint: tint, memberIDs: members)
                        } else {
                            let created = model.createGroup(name: name, detail: detail, symbol: symbol, tint: tint, memberIDs: members)
                            model.router.push(.group(created))
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                guard !didLoad else { return }
                didLoad = true
                if let group {
                    name = group.name; detail = group.detail; symbol = group.symbol; tint = group.tint; members = Set(group.memberIDs)
                }
            }
        }
    }
}

struct ChallengeFormView: View {
    let group: HabitGroup
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var detail = ""
    @State private var symbol = "flag.fill"
    @State private var unit = "check-ins"
    @State private var goal = 20
    @State private var days = 7
    @State private var kind: ChallengeKind = .collective

    var body: some View {
        NavigationStack {
            Form {
                Section("Start from an idea") {
                    ForEach(Catalog.challengeTemplates) { template in
                        Button {
                            title = template.title; detail = template.detail; symbol = template.symbol
                            unit = template.unit; goal = template.goal; days = template.days; kind = template.kind
                            model.feedback(.selection)
                        } label: {
                            Label(template.title, systemImage: template.symbol).foregroundStyle(Palette.ink)
                        }
                    }
                }
                Section("Challenge") {
                    Picker("Type", selection: $kind) {
                        ForEach(ChallengeKind.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    TextField("Title", text: $title)
                    TextField("Details", text: $detail, axis: .vertical).lineLimit(1...3)
                    if kind == .collective {
                        TextField("Unit (e.g. sessions)", text: $unit)
                        Stepper("Goal: \(goal) \(unit)", value: $goal, in: 1...500)
                    }
                    Stepper("Lasts \(days) day\(days == 1 ? "" : "s")", value: $days, in: 1...60)
                }
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .navigationTitle("New challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        model.createChallenge(in: group, title: title, detail: detail, symbol: symbol, unit: unit, goal: goal, days: days, kind: kind)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct GroupInviteSheet: View {
    let group: HabitGroup
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Friend> { $0.statusRaw == "friend" }, sort: \Friend.name) private var friends: [Friend]
    @State private var selected: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List(friends) { friend in
                let already = group.memberIDs.contains(friend.id)
                Button {
                    if selected.contains(friend.id) { selected.remove(friend.id) } else { selected.insert(friend.id) }
                } label: { FriendPickRow(friend: friend, isSelected: already || selected.contains(friend.id), detail: already ? "Member" : nil) }
                    .buttonStyle(.plain)
                    .disabled(already)
                    .listRowBackground(Palette.card)
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .navigationTitle("Invite to \(group.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") { model.invite(selected, to: group); dismiss() }
                        .fontWeight(.bold)
                        .disabled(selected.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// Full-screen stamp moment when a group reaches its goal.
struct GroupCelebrationView: View {
    let challenge: Challenge
    @Environment(AppModel.self) private var model
    @Environment(\.motionReduced) private var motionReduced
    @State private var stamped = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { model.finishCelebration() }
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20).fill(Palette.card)
                        .overlay(RuledLines(spacing: 24, margin: false).clipShape(RoundedRectangle(cornerRadius: 20)))
                    VStack(spacing: 14) {
                        Text(challenge.group?.name ?? "Your group")
                            .font(.eyebrow).tracking(1.2).foregroundStyle(Palette.burgundy)
                        Text("Goal reached!")
                            .font(.award(.largeTitle))
                            .foregroundStyle(Palette.burgundy)
                        Text("\(challenge.total) \(challenge.unit) together")
                            .font(.display(.headline)).foregroundStyle(Palette.ink)
                        Text(challenge.title).font(.hand(18)).foregroundStyle(Palette.inkSecondary).multilineTextAlignment(.center)
                        HStack(spacing: -10) {
                            ForEach(challenge.contributions.prefix(6), id: \.memberID) { entry in
                                if let avatar = entry.memberID == model.meID ? model.me?.avatar : model.friend(entry.memberID)?.avatar {
                                    AvatarView(config: avatar, size: 40, showsCompanion: false)
                                        .overlay(Circle().strokeBorder(Palette.card, lineWidth: 2))
                                }
                            }
                        }
                    }
                    .padding(26)
                    InkStamp(text: "Together", symbol: "flag.checkered", color: Palette.burgundy, size: 104)
                        .rotationEffect(.degrees(stamped ? -14 : -40))
                        .scaleEffect(stamped ? 1 : 2.4)
                        .opacity(stamped ? 0.9 : 0)
                        .offset(x: 100, y: -110)
                }
                .frame(maxWidth: 340)
                .fixedSize(horizontal: false, vertical: true)
                Button("Hooray!") { model.finishCelebration() }
                    .buttonStyle(PrimaryButtonStyle(fullWidth: false))
            }
            .padding(Metrics.gutter)
        }
        .onAppear {
            if motionReduced {
                stamped = true
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.25)) { stamped = true }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}
