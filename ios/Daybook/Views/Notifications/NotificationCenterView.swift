import SwiftData
import SwiftUI

struct NotificationCenterView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \NotificationItem.createdAt, order: .reverse) private var items: [NotificationItem]
    @Query private var friends: [Friend]
    @State private var showUnreadOnly = false

    var body: some View {
        let byID = Dictionary(friends.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let shown = showUnreadOnly ? items.filter { !$0.isRead } : items
        let today = shown.filter { Day.start($0.createdAt) == Day.today }
        let earlier = shown.filter { Day.start($0.createdAt) != Day.today }

        List {
            if !model.prefs.notificationsEnabled {
                Label("Notifications are turned off. Turn them on in Settings.", systemImage: "bell.slash.fill")
                    .font(.footnote)
                    .foregroundStyle(Palette.inkSecondary)
                    .listRowBackground(Palette.card)
            }
            if shown.isEmpty {
                EmptyStateView(symbol: "bell", title: showUnreadOnly ? "All caught up" : "Nothing yet",
                               message: "Reactions, invitations and awards will land here.")
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            if !today.isEmpty {
                Section("Today") { rows(today, byID: byID) }
            }
            if !earlier.isEmpty {
                Section("Earlier") { rows(earlier, byID: byID) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(PaperBackground())
        .navigationTitle("Notifications")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Toggle("Unread only", isOn: $showUnreadOnly)
                    Button { model.markAllRead() } label: { Label("Mark all as read", systemImage: "checkmark.circle") }
                    Button { model.router.push(.settingsSection(.notifications)) } label: { Label("Notification settings", systemImage: "gearshape") }
                } label: { Image(systemName: "ellipsis.circle") }
                .accessibilityLabel("Notification options")
            }
        }
    }

    @ViewBuilder
    private func rows(_ list: [NotificationItem], byID: [UUID: Friend]) -> some View {
        ForEach(list) { item in
            NotificationRow(item: item, actor: item.actorID.flatMap { byID[$0] })
                .listRowBackground(item.isRead ? Palette.card : Palette.card.opacity(0.6))
                .contentShape(Rectangle())
                .onTapGesture { open(item) }
                .swipeActions(edge: .leading) {
                    Button { model.markRead(item, !item.isRead) } label: {
                        Label(item.isRead ? "Unread" : "Read", systemImage: item.isRead ? "envelope.badge" : "envelope.open")
                    }
                    .tint(Palette.sky)
                }
                .swipeActions(edge: .trailing) {
                    Button { model.dismiss(item) } label: { Label("Dismiss", systemImage: "xmark") }
                        .tint(Palette.inkFaint)
                }
                .accessibilityAction(named: item.isRead ? "Mark unread" : "Mark read") { model.markRead(item, !item.isRead) }
                .accessibilityAction(named: "Dismiss") { model.dismiss(item) }
        }
    }

    private func open(_ item: NotificationItem) {
        model.markRead(item)
        switch item.kind {
        case .award: model.router.tab = .collection
        case .recap: model.router.tab = .recap
        case .quiz: model.router.push(.quizzes)
        case .groupInvite, .groupMilestone:
            if let group = model.group(item.refID) { model.router.push(.group(group)) } else { model.router.push(.groups) }
        case .friendRequest:
            if let friend = model.friend(item.refID ?? item.actorID) { model.router.push(.friend(friend)) }
        case .gift: model.router.push(.gifts)
        case .reaction, .comment: model.router.tab = .friends
        case .reminder, .habitInvite:
            if let friend = model.friend(item.actorID) { model.router.push(.friend(friend)) }
        }
    }
}

struct NotificationRow: View {
    let item: NotificationItem
    let actor: Friend?
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                if let actor {
                    AvatarView(config: actor.avatar, size: 42, showsCompanion: false)
                } else {
                    SymbolBadge(symbol: item.kind.symbol, tint: item.kind.tint, size: 42, filled: true)
                }
                if actor != nil {
                    Image(systemName: item.kind.symbol)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(item.kind.tint.onColor)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(item.kind.tint.color))
                        .overlay(Circle().strokeBorder(Palette.card, lineWidth: 2))
                        .offset(x: 4, y: 4)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title).font(.subheadline.weight(item.isRead ? .medium : .bold)).foregroundStyle(Palette.ink)
                    Spacer(minLength: 4)
                    Text(Day.relative(item.createdAt)).font(.caption2).foregroundStyle(Palette.inkFaint)
                }
                Text(item.body).font(.caption).foregroundStyle(Palette.inkSecondary).fixedSize(horizontal: false, vertical: true)
                if item.kind.isInvitation, item.resolution == nil, item.title.contains("accepted") == false {
                    HStack(spacing: 8) {
                        Button("Accept") { model.respond(to: item, accept: true) }
                            .buttonStyle(InlineActionStyle(filled: true))
                        Button("Decline") { model.respond(to: item, accept: false) }
                            .buttonStyle(InlineActionStyle(tint: Palette.inkSecondary))
                    }
                    .padding(.top, 4)
                } else if let resolution = item.resolution {
                    Text(resolution.capitalized).font(.caption.weight(.bold)).foregroundStyle(resolution == "accepted" ? Palette.sage : Palette.inkFaint)
                }
            }
            if !item.isRead {
                Circle().fill(Palette.orange).frame(width: 9, height: 9).padding(.top, 6)
                    .accessibilityLabel("Unread")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
