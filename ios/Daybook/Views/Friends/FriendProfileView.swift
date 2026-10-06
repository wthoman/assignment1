import SwiftData
import SwiftUI

struct FriendProfileView: View {
    let friend: Friend
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var groups: [HabitGroup]
    @Query private var collectibles: [Collectible]
    @State private var sheet: SocialSheet?
    @State private var confirmRemove = false
    @State private var confirmBlock = false

    var body: some View {
        let sharedHabits = habits.filter { $0.participantIDs.contains(friend.id) && $0.status == .active }
        let commonGroups = groups.filter { $0.isMember && $0.memberIDs.contains(friend.id) }
        let showcase = friend.showcaseKeys.compactMap { key in collectibles.first { $0.key == key } }
        let personality = Catalog.personality(friend.personality)

        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    AvatarView(config: friend.avatar, size: 112)
                    Text(friend.name).font(.display(.title2, weight: .heavy)).foregroundStyle(Palette.ink)
                    Text("@\(friend.handle)\(friend.pronouns.isEmpty ? "" : " · \(friend.pronouns)")")
                        .font(.subheadline).foregroundStyle(Palette.inkSecondary)
                    Text(friend.bio).font(.hand(18)).foregroundStyle(Palette.ink.opacity(0.85)).multilineTextAlignment(.center)
                    Label(personality.name, systemImage: personality.symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(personality.tint.onColor)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 8).fill(personality.tint.color))
                    if friend.mutualFriendCount > 0 {
                        Text("\(friend.mutualFriendCount) mutual friend\(friend.mutualFriendCount == 1 ? "" : "s") · friends since \(friend.since.formatted(.dateTime.month(.abbreviated).year()))")
                            .font(.caption).foregroundStyle(Palette.inkSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .card()

                if friend.status == .friend {
                    HStack(spacing: 8) {
                        Button { sheet = .remind(friend, friend.favoriteHabits.first ?? "", nil) } label: { Label("Remind", systemImage: "bell") }
                            .buttonStyle(SecondaryButtonStyle())
                        Button { sheet = .gift(friend) } label: { Label("Gift", systemImage: "gift") }
                            .buttonStyle(SecondaryButtonStyle())
                        Button { sheet = .inviteToHabit(friend) } label: { Label("Invite", systemImage: "person.badge.plus") }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                    .labelStyle(VerticalLabelStyle())
                } else if friend.status == .incoming {
                    HStack {
                        Button("Accept request") { model.acceptFriend(friend) }.buttonStyle(PrimaryButtonStyle())
                        Button("Decline") { model.declineFriend(friend) }.buttonStyle(SecondaryButtonStyle())
                    }
                } else if friend.status == .suggested {
                    Button { model.requestFriend(friend) } label: { Label("Add friend", systemImage: "person.badge.plus") }
                        .buttonStyle(PrimaryButtonStyle())
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    StatTile(value: friend.consistency.percentText, label: "Consistency", symbol: "chart.line.uptrend.xyaxis", tint: .sage)
                    StatTile(value: "\(friend.totalCompletions)", label: "Total check-ins", symbol: "checkmark.seal.fill", tint: .burgundy)
                    StatTile(value: "\(friend.comebackCount)", label: "Comebacks", symbol: "arrow.uturn.up.circle.fill", tint: .orange)
                    StatTile(value: Day.longName(forWeekday: friend.strongestWeekday), label: "Strongest day", symbol: "calendar", tint: .gold)
                }

                if !showcase.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow("Showcase")
                        HStack(spacing: -6) {
                            ForEach(Array(showcase.enumerated()), id: \.element.key) { index, item in
                                StickerView(item, size: 72, forceUnlocked: true)
                                    .rotationEffect(.degrees(Double((index * 7) % 15) - 7))
                                    .accessibilityLabel(item.name)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
                }

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow("Together")
                    if sharedHabits.isEmpty && commonGroups.isEmpty {
                        Text("No shared habits yet. Invite \(friend.firstName) to one of yours.")
                            .font(.callout).foregroundStyle(Palette.inkSecondary)
                    }
                    ForEach(sharedHabits) { habit in
                        Button { model.router.push(.habit(habit)) } label: {
                            HStack(spacing: 10) {
                                SymbolBadge(symbol: habit.symbol, tint: habit.tint, size: 32, filled: habit.friendCompleted(friend.id, on: Day.today))
                                Text(habit.name).font(.subheadline.weight(.semibold)).foregroundStyle(Palette.ink)
                                Spacer()
                                Text(habit.friendCompleted(friend.id, on: Day.today) ? "Done today" : "Not yet today")
                                    .font(.caption).foregroundStyle(Palette.inkSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    ForEach(commonGroups) { group in
                        Button { model.router.push(.group(group)) } label: {
                            HStack(spacing: 10) {
                                SymbolBadge(symbol: group.symbol, tint: group.tint, size: 32)
                                Text(group.name).font(.subheadline.weight(.semibold)).foregroundStyle(Palette.ink)
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.inkFaint)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    if !friend.favoriteHabits.isEmpty {
                        Text("Favorite habits: \(friend.favoriteHabits.joined(separator: ", "))")
                            .font(.caption).foregroundStyle(Palette.inkSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
            }
            .padding(Metrics.gutter)
        }
        .background(PaperBackground())
        .navigationTitle(friend.firstName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if friend.status == .friend {
                        Button(role: .destructive) { confirmRemove = true } label: { Label("Remove friend", systemImage: "person.badge.minus") }
                    }
                    if friend.status != .blocked {
                        Button(role: .destructive) { confirmBlock = true } label: { Label("Block", systemImage: "hand.raised") }
                    } else {
                        Button { model.unblock(friend) } label: { Label("Unblock", systemImage: "hand.raised.slash") }
                    }
                } label: { Image(systemName: "ellipsis.circle") }
                .accessibilityLabel("More options")
            }
        }
        .sheet(item: $sheet) { SocialSheetHost(sheet: $0) }
        .confirmationDialog("Remove \(friend.firstName)?", isPresented: $confirmRemove, titleVisibility: .visible) {
            Button("Remove friend", role: .destructive) { model.removeFriend(friend); dismiss() }
        } message: { Text("They'll leave your shared habits. You can add them again later.") }
        .confirmationDialog("Block \(friend.firstName)?", isPresented: $confirmBlock, titleVisibility: .visible) {
            Button("Block", role: .destructive) { model.block(friend); dismiss() }
        } message: { Text("They won't see your activity or be able to send reminders. You can unblock in Settings.") }
        .onChange(of: confirmRemove || confirmBlock) { _, value in if value { model.feedback(.warning) } }
    }
}

struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 3) {
            configuration.icon
            configuration.title.font(.caption.weight(.semibold))
        }
    }
}

// MARK: - Add friends

struct AddFriendsView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \Friend.name) private var people: [Friend]
    @State private var search = ""

    var body: some View {
        let matches = { (friend: Friend) in search.isEmpty || friend.name.localizedCaseInsensitiveContains(search) || friend.handle.localizedCaseInsensitiveContains(search) }
        let incoming = people.filter { $0.status == .incoming && matches($0) }
        let suggested = people.filter { ($0.status == .suggested || $0.status == .requested) && matches($0) }
        let current = people.filter { $0.status == .friend && matches($0) }
        let invitees = Catalog.extraContacts.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }

        List {
            if !incoming.isEmpty {
                Section("Requests") {
                    ForEach(incoming) { friend in
                        HStack {
                            personRow(friend, detail: "\(friend.mutualFriendCount) mutual")
                            Button("Accept") { model.acceptFriend(friend) }.buttonStyle(InlineActionStyle(filled: true))
                            Button { model.declineFriend(friend) } label: { Image(systemName: "xmark") }
                                .buttonStyle(InlineActionStyle(tint: Palette.inkSecondary))
                                .accessibilityLabel("Decline")
                        }
                        .listRowBackground(Palette.card)
                    }
                }
            }
            Section {
                ForEach(suggested) { friend in
                    HStack {
                        personRow(friend, detail: friend.contactDetail)
                        Button(friend.status == .requested ? "Requested" : "Add") { model.requestFriend(friend) }
                            .buttonStyle(InlineActionStyle(filled: friend.status != .requested))
                            .disabled(friend.status == .requested)
                    }
                    .listRowBackground(Palette.card)
                }
                if suggested.isEmpty {
                    Text("Everyone in your contacts on \(Brand.name) is already a friend.").font(.callout).foregroundStyle(Palette.inkSecondary)
                        .listRowBackground(Palette.card)
                }
            } header: {
                Text("From your contacts")
            } footer: {
                Text("Demo contacts — \(Brand.name) never reads your real address book.")
            }
            Section("Invite to \(Brand.name)") {
                ForEach(invitees, id: \.name) { contact in
                    HStack {
                        Image(systemName: "person.crop.circle").font(.title).foregroundStyle(Palette.inkFaint)
                        VStack(alignment: .leading) {
                            Text(contact.name).font(.body.weight(.semibold)).foregroundStyle(Palette.ink)
                            Text(contact.detail).font(.caption).foregroundStyle(Palette.inkSecondary)
                        }
                        Spacer()
                        ShareLink(item: "Join me on \(Brand.name)! We can keep each other going with tiny habits. https://\(Brand.shareDomain)/invite/\(model.me?.handle ?? "friend")") {
                            Text("Invite")
                        }
                        .buttonStyle(InlineActionStyle())
                    }
                    .listRowBackground(Palette.card)
                }
            }
            if !current.isEmpty {
                Section("Friends (\(current.count))") {
                    ForEach(current) { friend in
                        Button { model.router.push(.friend(friend)) } label: { personRow(friend, detail: "@\(friend.handle)") }
                            .buttonStyle(.plain)
                            .listRowBackground(Palette.card)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(PaperBackground())
        .searchable(text: $search, prompt: "Search names")
        .navigationTitle("Add friends")
    }

    private func personRow(_ friend: Friend, detail: String) -> some View {
        HStack(spacing: 12) {
            AvatarView(config: friend.avatar, size: 40, showsCompanion: false)
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name).font(.display(.body, weight: .semibold)).foregroundStyle(Palette.ink)
                Text(detail).font(.caption).foregroundStyle(Palette.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 48)
        .contentShape(Rectangle())
    }
}

// MARK: - Quizzes

struct QuizzesView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \Quiz.createdAt, order: .reverse) private var quizzes: [Quiz]
    @Query private var friends: [Friend]
    @State private var showNew = false

    var body: some View {
        let byID = Dictionary(friends.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "hand.raised.fingers.spread.fill").foregroundStyle(Palette.orange)
                    Text("Votes are just for fun. Results marked **Voted by friends** can appear in your weekly superlatives, separately from awards calculated from activity.")
                        .font(.footnote).foregroundStyle(Palette.inkSecondary)
                }
                .card(padding: 12)
                if quizzes.isEmpty {
                    EmptyStateView(symbol: "questionmark.bubble", title: "No quizzes yet", message: "Start one and see what your circle thinks.", actionTitle: "New quiz") { showNew = true }
                }
                ForEach(quizzes) { quiz in
                    QuizCard(quiz: quiz, byID: byID)
                }
            }
            .padding(Metrics.gutter)
        }
        .background(PaperBackground())
        .navigationTitle("Friend quizzes")
        .toolbar {
            Button { showNew = true } label: { Image(systemName: "plus") }
                .accessibilityLabel("New quiz")
        }
        .confirmationDialog("Ask your circle", isPresented: $showNew, titleVisibility: .visible) {
            ForEach(Catalog.quizPrompts.filter { prompt in !quizzes.contains { $0.prompt == prompt.prompt } }, id: \.tag) { prompt in
                Button(prompt.prompt) { model.createQuiz(prompt: prompt.prompt, tag: prompt.tag) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct QuizCard: View {
    let quiz: Quiz
    let byID: [UUID: Friend]
    @Environment(AppModel.self) private var model

    var body: some View {
        let myVote = quiz.myResponse?.choiceID
        let total = max(1, quiz.responses.count)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Voted by friends")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(Palette.sky)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Palette.sky.opacity(0.15)))
                Spacer()
                Text("\(quiz.responses.count) votes").font(.caption).foregroundStyle(Palette.inkFaint)
            }
            Text(quiz.prompt).font(.display(.headline)).foregroundStyle(Palette.ink)
            ForEach(quiz.optionIDs, id: \.self) { id in
                let isMe = id == model.meID
                let name = isMe ? "You" : (byID[id]?.firstName ?? "Friend")
                let avatar = isMe ? model.me?.avatar : byID[id]?.avatar
                let votes = quiz.votes(for: id)
                Button {
                    model.vote(quiz, for: id)
                } label: {
                    HStack(spacing: 10) {
                        if let avatar { AvatarView(config: avatar, size: 30, showsCompanion: false) }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(name).font(.subheadline.weight(myVote == id ? .heavy : .semibold)).foregroundStyle(Palette.ink)
                                if myVote == id { Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.burgundy).font(.caption) }
                                Spacer()
                                if myVote != nil { Text("\(votes)").font(.caption.monospacedDigit()).foregroundStyle(Palette.inkSecondary) }
                            }
                            if myVote != nil {
                                ProgressBar(progress: Double(votes) / Double(total), tint: id == quiz.leaderID ? Palette.burgundy : Palette.rose, height: 6)
                            }
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(myVote == id ? Palette.burgundy.opacity(0.08) : Color.clear))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(name)
                .accessibilityValue(myVote == nil ? "" : "\(votes) votes")
                .accessibilityAddTraits(myVote == id ? .isSelected : [])
            }
            if myVote == nil {
                HandNote("tap to vote — results appear after", size: 15)
            }
        }
        .card()
    }
}
