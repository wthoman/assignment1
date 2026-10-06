import SwiftData
import SwiftUI

/// Sheets presented from social surfaces.
enum SocialSheet: Identifiable {
    case react(ActivityItem)
    case comment(ActivityItem)
    case remind(Friend, String, ActivityItem?)
    case gift(Friend)
    case inviteToHabit(Friend)

    var id: String {
        switch self {
        case .react(let item): "react-\(item.id)"
        case .comment(let item): "comment-\(item.id)"
        case .remind(let friend, _, _): "remind-\(friend.id)"
        case .gift(let friend): "gift-\(friend.id)"
        case .inviteToHabit(let friend): "invite-\(friend.id)"
        }
    }
}

struct SocialSheetHost: View {
    let sheet: SocialSheet

    var body: some View {
        switch sheet {
        case .react(let item): ReactionSheet(item: item)
        case .comment(let item): CommentSheet(item: item)
        case .remind(let friend, let habit, let item): SendReminderSheet(friend: friend, habitName: habit, item: item)
        case .gift(let friend): GiftSheet(friend: friend)
        case .inviteToHabit(let friend): InviteToHabitSheet(friend: friend)
        }
    }
}

struct FriendsView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \ActivityItem.createdAt, order: .reverse) private var activity: [ActivityItem]
    @Query(sort: \Friend.name) private var allFriends: [Friend]
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var sheet: SocialSheet?

    var body: some View {
        let friends = allFriends.filter { $0.status == .friend }
        let byID = Dictionary(allFriends.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let feed = activity.filter { item in
            guard let actor = item.actorID else { return true }
            return byID[actor]?.status == .friend
        }
        let requests = allFriends.filter { $0.status == .incoming }

        List {
            if !friends.isEmpty {
                circleRow(friends)
                    .plainRow(top: 8)
            }
            if !requests.isEmpty {
                requestsCard(requests).plainRow()
            }
            rankingCard(friends).plainRow()

            SectionHeader("Activity", subtitle: "Pull down for the latest")
                .plainRow(top: 14, bottom: 2)

            if feed.isEmpty {
                EmptyStateView(symbol: "person.2.wave.2", title: "It's quiet in here",
                               message: "Add a friend or share a habit to see check-ins, comebacks and cheers.",
                               actionTitle: "Add friends") { model.router.push(.addFriends) }
                    .plainRow()
            }
            ForEach(feed) { item in
                ActivityCard(item: item, actor: item.actorID.flatMap { byID[$0] }, me: model.me, myHabits: habits, sheet: $sheet)
                    .plainRow(top: 5, bottom: 5)
                    .swipeActions(edge: .trailing) {
                        Button { sheet = .react(item) } label: { Label("React", systemImage: "hands.clap.fill") }
                            .tint(Palette.rose)
                    }
            }
            Color.clear.frame(height: 20).plainRow()
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(PaperBackground())
        .navigationTitle("Friends")
        .refreshable { await model.refreshFeed() }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { model.router.push(.quizzes) } label: { Image(systemName: "questionmark.bubble") }
                    .accessibilityLabel("Friend quizzes")
                Button { model.router.push(.groups) } label: { Image(systemName: "person.3") }
                    .accessibilityLabel("Groups")
                Button { model.router.push(.addFriends) } label: { Image(systemName: "person.badge.plus") }
                    .accessibilityLabel("Add friends")
            }
        }
        .sheet(item: $sheet) { SocialSheetHost(sheet: $0) }
    }

    /// Friends you can tap into. A short horizontal row is the one place sideways scrolling helps.
    private func circleRow(_ friends: [Friend]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(friends) { friend in
                    Button { model.router.push(.friend(friend)) } label: {
                        VStack(spacing: 4) {
                            AvatarView(config: friend.avatar, size: 56)
                            Text(friend.firstName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Palette.ink)
                                .lineLimit(1)
                        }
                        .frame(width: 66)
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("\(friend.name) profile")
                }
                Button { model.router.push(.addFriends) } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.title3.weight(.bold))
                            .frame(width: 56, height: 56)
                            .background(Circle().strokeBorder(Palette.lineStrong, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                        Text("Add").font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Palette.burgundy)
                    .frame(width: 66)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add friends")
            }
            .padding(.vertical, 4)
        }
    }

    private func requestsCard(_ requests: [Friend]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Friend requests")
            ForEach(requests) { friend in
                AdaptiveStack(spacing: 10) {
                    HStack(spacing: 10) {
                        AvatarView(config: friend.avatar, size: 40, showsCompanion: false)
                        VStack(alignment: .leading) {
                            Text(friend.name).font(.display(.subheadline, weight: .semibold)).foregroundStyle(Palette.ink)
                            Text("\(friend.mutualFriendCount) mutual").font(.caption).foregroundStyle(Palette.inkSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    HStack(spacing: 8) {
                        Button("Accept") { model.acceptFriend(friend) }
                            .buttonStyle(InlineActionStyle(filled: true))
                        Button { model.declineFriend(friend) } label: { Image(systemName: "xmark") }
                            .buttonStyle(InlineActionStyle(tint: Palette.inkSecondary))
                            .accessibilityLabel("Decline \(friend.firstName)")
                    }
                }
            }
        }
        .card()
    }

    /// Supportive leaderboard: everyone gets a kind label, nobody is "last".
    private func rankingCard(_ friends: [Friend]) -> some View {
        let myWeek = habits.flatMap { habit in Day.week(containing: Day.today).filter { habit.isCompleted(on: $0) } }.count
        var entries: [(name: String, avatar: AvatarConfig, count: Int, isMe: Bool)] = friends.map { ($0.firstName, $0.avatar, $0.weekCompletions, false) }
        if let me = model.me { entries.append(("You", me.avatar, myWeek, true)) }
        entries.sort { $0.count > $1.count }
        let labels = ["Setting the pace", "Right there", "Steady hands", "On the board", "Showing up", "In the mix", "Warming up"]
        return VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Eyebrow("This week's check-ins")
                    Spacer()
                    HandNote("everyone counts", size: 15, rotation: -2)
                }
                Eyebrow("This week's check-ins")
            }
            ForEach(Array(entries.prefix(5).enumerated()), id: \.offset) { index, entry in
                HStack(spacing: 10) {
                    Text("\(index + 1)")
                        .font(.display(.subheadline, weight: .heavy))
                        .foregroundStyle(index == 0 ? Palette.gold : Palette.inkFaint)
                        .frame(width: 18)
                    AvatarView(config: entry.avatar, size: 30, showsCompanion: false)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(entry.name).font(.subheadline.weight(entry.isMe ? .heavy : .semibold)).foregroundStyle(Palette.ink)
                        Text(labels[safe: index] ?? "Showing up").font(.caption2).foregroundStyle(Palette.inkSecondary)
                    }
                    Spacer()
                    Text("\(entry.count)")
                        .font(.display(.headline, weight: .heavy))
                        .foregroundStyle(entry.isMe ? Palette.burgundy : Palette.ink)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .card()
    }
}

/// One entry in the social feed.
struct ActivityCard: View {
    let item: ActivityItem
    let actor: Friend?
    let me: UserProfile?
    let myHabits: [Habit]
    @Binding var sheet: SocialSheet?
    @Environment(AppModel.self) private var model

    var body: some View {
        let isMine = item.actorID == nil
        let sharedHabit = item.habitID.flatMap { id in myHabits.first { $0.id == id } }
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Button {
                    if let actor { model.router.push(.friend(actor)) }
                } label: {
                    if let actor {
                        AvatarView(config: actor.avatar, size: 42, showsCompanion: false)
                    } else if isMine, let me, item.kind != .groupMilestone, item.kind != .prediction, item.kind != .ranking {
                        AvatarView(config: me.avatar, size: 42, showsCompanion: false)
                    } else {
                        SymbolBadge(symbol: item.symbol, tint: item.tint, size: 42, filled: true)
                    }
                }
                .buttonStyle(.plain)
                .disabled(actor == nil)
                .accessibilityLabel(actor.map { "\($0.name) profile" } ?? "")

                VStack(alignment: .leading, spacing: 3) {
                    Text(headline)
                        .font(.subheadline)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        if item.kind == .checkIn || item.kind == .sharedHabit || item.kind == .comeback {
                            Label(item.title, systemImage: item.symbol)
                                .labelStyle(CompactLabelStyle())
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(item.tint == .cream ? Palette.inkSecondary : item.tint.color)
                        }
                        Text(Day.relative(item.createdAt)).font(.caption).foregroundStyle(Palette.inkFaint)
                    }
                }
                Spacer(minLength: 0)
                if item.kind == .comeback {
                    InkStamp(text: "Back", symbol: "arrow.uturn.up", color: Palette.orange, size: 46)
                        .rotationEffect(.degrees(12))
                }
            }
            if !item.detail.isEmpty {
                Text(item.detail)
                    .font(.hand(17, relativeTo: .callout))
                    .foregroundStyle(Palette.ink.opacity(0.85))
                    .padding(.leading, 52)
                    .fixedSize(horizontal: false, vertical: true)
            }
            reactionSummary
            actions(isMine: isMine, sharedHabit: sharedHabit)
        }
        .card(tint: item.kind == .comeback ? .orange : (item.kind == .groupMilestone ? item.tint : nil),
              emphasized: item.kind == .comeback || item.kind == .groupMilestone)
        .contextMenu {
            if let actor {
                Button { model.router.push(.friend(actor)) } label: { Label("Open \(actor.firstName)'s profile", systemImage: "person.crop.circle") }
                Button { sheet = .inviteToHabit(actor) } label: { Label("Invite to a habit", systemImage: "person.badge.plus") }
                Button { sheet = .gift(actor) } label: { Label("Send a gift", systemImage: "gift") }
                Button { sheet = .remind(actor, item.title, item) } label: { Label("Send a reminder", systemImage: "bell") }
            }
            Button { sheet = .react(item) } label: { Label("React", systemImage: "hands.clap") }
            Button { sheet = .comment(item) } label: { Label("Comment", systemImage: "text.bubble") }
        }
    }

    private var headline: AttributedString {
        let name = actor?.firstName ?? "You"
        var bold = AttributedString(name)
        bold.font = .subheadline.weight(.bold)
        let lowered = " " + item.title.prefix(1).lowercased() + item.title.dropFirst()
        let rest: String
        switch item.kind {
        case .checkIn: rest = " checked in"
        case .sharedHabit: rest = item.title.hasPrefix("Started") ? lowered : " checked in on a shared habit"
        case .comeback: rest = " made a comeback"
        case .collectible, .gift, .joinedGroup: rest = lowered
        case .reminder: rest = " sent a reminder"
        case .groupMilestone, .prediction, .ranking:
            var title = AttributedString(item.title)
            title.font = .subheadline.weight(.bold)
            return title
        }
        return bold + AttributedString(rest)
    }

    @ViewBuilder
    private var reactionSummary: some View {
        let counts = Dictionary(grouping: item.reactions, by: \.kind).mapValues(\.count)
        if !counts.isEmpty || !item.comments.isEmpty {
            HStack(spacing: 8) {
                ForEach(ReactionKind.allCases.filter { counts[$0] != nil }) { kind in
                    HStack(spacing: 3) {
                        Image(systemName: kind.symbol).foregroundStyle(kind.tint.color)
                        Text("\(counts[kind] ?? 0)").foregroundStyle(Palette.inkSecondary)
                    }
                    .font(.caption.weight(.semibold))
                }
                if !item.comments.isEmpty {
                    Button { sheet = .comment(item) } label: {
                        Label("\(item.comments.count)", systemImage: "text.bubble.fill")
                            .labelStyle(CompactLabelStyle())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.inkSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(item.comments.count) comments")
                }
                if let latest = item.comments.sorted(by: { $0.createdAt > $1.createdAt }).first {
                    Text("“\(latest.text)”")
                        .font(.caption)
                        .italic()
                        .foregroundStyle(Palette.inkSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 52)
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func actions(isMine: Bool, sharedHabit: Habit?) -> some View {
        let mine = item.myReaction()
        FlowLayout(spacing: 8, lineSpacing: 8) {
            Button { sheet = .react(item) } label: {
                Label(mine == nil ? "React" : mine?.kind.label ?? "Reacted", systemImage: mine?.kind.symbol ?? "hands.clap")
            }
            .buttonStyle(InlineActionStyle(tint: mine?.kind.tint.color, filled: mine != nil))
            Button { sheet = .comment(item) } label: { Label("Comment", systemImage: "text.bubble") }
                .buttonStyle(InlineActionStyle())
            if !isMine, let actor {
                if item.kind == .comeback {
                    Button { model.celebrateComeback(item) } label: {
                        Label(item.celebratedByMe ? "Celebrated" : "Celebrate", systemImage: "party.popper")
                    }
                    .buttonStyle(InlineActionStyle(tint: Palette.orange, filled: !item.celebratedByMe))
                    .disabled(item.celebratedByMe)
                } else if let sharedHabit, item.kind == .sharedHabit, sharedHabit.status == .active {
                    let done = sharedHabit.isCompleted(on: Day.today)
                    Button {
                        if !done { model.toggleCompletion(sharedHabit) }
                    } label: {
                        Label(done ? "You're in" : "Me too", systemImage: done ? "checkmark" : "plus")
                    }
                    .buttonStyle(InlineActionStyle(tint: sharedHabit.tint.color, filled: !done))
                    .disabled(done)
                    .accessibilityLabel(done ? "You completed \(sharedHabit.name)" : "Complete \(sharedHabit.name) together")
                } else if item.kind == .checkIn || item.kind == .sharedHabit {
                    Button { sheet = .remind(actor, item.title, item) } label: {
                        Image(systemName: item.remindedByMe ? "bell.badge.fill" : "bell")
                    }
                    .buttonStyle(InlineActionStyle())
                    .accessibilityLabel("Send \(actor.firstName) a reminder")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 52)
    }
}
