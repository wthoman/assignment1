import SwiftUI

// MARK: - Friends

struct FriendsView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        Page { _ in
            NavBar(title: "Friends")
            if !m.requests.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("Friend requests", acc: true).padding(.top, 4).padding(.bottom, 2)
                    ForEach(Array(m.requests.enumerated()), id: \.element) { i, p in
                        RequestRow(p: p, first: i == 0, divider: c.yel.opacity(0.45))
                    }
                }
                .card(v: 8, h: 14, fill: c.yelSoft, outline: c.yel.opacity(0.7), outlineWidth: 1.2)
                .padding(.bottom, 12)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("My friends \(Text("(\(m.friends.count))").foregroundStyle(c.ink3))").font(.serif(26)).foregroundStyle(c.ink)
                    Spacer()
                    Button { m.push(.addfriends) } label: { Ico(.plus, 22).foregroundStyle(c.ink2).frame(width: 36, height: 36) }
                        .buttonStyle(.press).accessibilityLabel("Add friends")
                }
                .padding(.bottom, 6)
                if m.friends.isEmpty {
                    Text("No friends yet. Tap + to add some.").font(.sans(15)).foregroundStyle(c.ink3).padding(.vertical, 12)
                }
                ForEach(Array(m.friends.enumerated()), id: \.element) { i, p in
                    Divided(first: i == 0, vpad: 9) {
                        HStack(spacing: 10) {
                            Button { m.push(.friend, p) } label: {
                                HStack(spacing: 12) {
                                    Av(p: p, size: 44)
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(m.person(p).full).font(.sans(15, .semibold)).foregroundStyle(c.ink)
                                        Text("@\(m.person(p).handle)").font(.sans(12.5)).foregroundStyle(c.ink3)
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                            .buttonStyle(.press)
                            Button("Remove") { m.removeRow(p) }
                                .font(.sans(12.5)).foregroundStyle(c.ink3)
                                .padding(.horizontal, 11).frame(height: 30)
                                .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(c.line2, lineWidth: 1))
                                .buttonStyle(.press)
                        }
                    }
                }
            }
            .padding(.top, 14).padding(.horizontal, 16).padding(.bottom, 6)
            .card(0)
        }
    }
}

/// A friend-request row (.req).
struct RequestRow: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let p: String
    let first: Bool
    var divider: Color? = nil
    var body: some View {
        HStack(spacing: 12) {
            Av(p: p, size: 40)
            TwoLine(title: m.person(p).full, sub: "1 mutual friend")
            Button("Accept") { m.acceptReq(p) }.buttonStyle(.btn(.primary, small: true))
            Button { m.declineReq(p) } label: {
                Ico(.x, 14).foregroundStyle(c.ink2).frame(width: 32, height: 32)
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(c.line2, lineWidth: 1))
            }
            .buttonStyle(.press).accessibilityLabel("Decline")
        }
        .padding(.vertical, 10)
        .overlay(alignment: .top) { if !first { Rectangle().fill(divider ?? c.line).frame(height: 1) } }
    }
}

// MARK: - Friend profile

struct FriendProfileView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let p: String
    var body: some View {
        if let f = m.people[p] {
            let sharedH = m.habits.filter { $0.mem[p] != nil }
            let common = m.groups.filter { $0.members.contains(p) }
            let cur = sharedH.map { m.streak($0, p) }.max() ?? 0
            let unlocked = m.trophies.filter { $0.got != nil }
            let hn = hashN(p)
            Page { _ in
                NavBar(title: f.name) { IconBtn(label: "More", action: { m.friendMenu(p) }) { Ico(.more) } }
                VStack(spacing: 0) {
                    Av(p: p, size: 104)
                    Text(f.full).font(.serif(32)).foregroundStyle(c.ink).padding(.top, 12)
                    Text("@\(f.handle)").font(.sans(13)).foregroundStyle(c.ink2).padding(.top, 4)
                    Text(f.bio).font(.serif(17)).italic().foregroundStyle(c.acc).padding(.top, 8)
                    if m.friends.contains(p) {
                        Text("\(f.mutual ?? 1) mutual friends · friends since \(f.since ?? "Oct 2026")").font(.sans(12)).foregroundStyle(c.ink3).padding(.top, 6)
                        Button { m.inviteHabit(p) } label: { Ico(.invite, 15); Text("Invite to a habit") }
                            .buttonStyle(.btn(.primary, small: true)).padding(.top, 14)
                    } else {
                        Button("Add friend") { m.acceptReq(p) }.buttonStyle(.btn(.primary, small: true)).padding(.top, 14)
                    }
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .card()
                StatGrid(items: [
                    (.check, nil, "\(120 + hn % 260)", "Total check-ins", 30),
                    (.flame, 16, "\(cur != 0 ? cur : hn % 9 + 2)", "Current streak", 30),
                    (.cal, nil, f.strong ?? "Monday", "Strongest day", 26 / 0.86),
                    (.groups, 16, "\(common.count)", "Groups together", 30)
                ])
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("Showcase")
                    if !unlocked.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { i in
                                PrizeArt(trophy: unlocked[(hn + i * 5) % unlocked.count], width: 62).rotationEffect(.degrees([-6, 4, -2][i]))
                            }
                        }
                        .frame(maxWidth: .infinity).padding(.top, 8).padding(.bottom, 2)
                    }
                }
                .card().blk()
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("Together")
                    ForEach(Array(sharedH.enumerated()), id: \.element.id) { i, h in
                        Divided(first: i == 0) {
                            HStack(spacing: 12) {
                                Tile(size: 34, on: m.isDone(h, p)) { HIcon(h.ic, 17) }
                                TwoLine(title: h.name, sub: m.isDone(h, p) ? "Done today" : "Not yet today")
                            }
                        }
                    }
                    ForEach(Array(common.enumerated()), id: \.element.id) { i, g in
                        Button { m.openGroup(g.id) } label: {
                            Divided(first: sharedH.isEmpty && i == 0) {
                                HStack(spacing: 12) {
                                    Tile(size: 34) { HIcon(g.ic, 17) }
                                    TwoLine(title: g.name, sub: "Group · \(g.members.count) members")
                                    Ico(.right).foregroundStyle(c.ink)
                                }
                            }
                        }
                        .buttonStyle(.press)
                    }
                    if sharedH.isEmpty && common.isEmpty {
                        Text("No shared habits yet. Invite \(f.name) to one of yours.").font(.sans(13.5)).foregroundStyle(c.ink2).padding(.top, 8)
                    }
                }
                .card().blk()
            }
        } else {
            Color.clear.onAppear { m.back() }
        }
    }
}

/// 2×2 stat cards (.stats).
struct StatGrid: View {
    @Environment(\.pal) private var c
    let items: [(UIIcon, CGFloat?, String, String, CGFloat)]
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, it in
                VStack(alignment: .leading, spacing: 0) {
                    Ico(it.0, it.1).foregroundStyle(c.acc).padding(.bottom, 6)
                    Text(it.2).font(.serif(it.4)).foregroundStyle(c.ink).lineLimit(1).minimumScaleFactor(0.6)
                    Text(it.3).font(.sans(12)).foregroundStyle(c.ink3).lineLimit(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .card(v: 12, h: 14)
            }
        }
        .padding(.top, 12)
    }
}

// MARK: - Add friends

struct AddFriendsView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    @State private var search = ""
    var body: some View {
        Page { _ in
            NavBar(title: "Add friends")
            HStack(spacing: 10) {
                Ico(.search).foregroundStyle(c.ink3)
                TextField("", text: $search, prompt: Text("Search names or @handles").foregroundStyle(c.ink3))
                    .font(.sans(15.5, .medium)).foregroundStyle(c.ink).autocorrectionDisabled()
            }
            .padding(.horizontal, 14).frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(c.card))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(c.line, lineWidth: 1))
            .padding(.top, 4).padding(.bottom, 12)
            if !m.requests.isEmpty {
                Sec(title: "Requests", count: m.requests.count)
                VStack(spacing: 0) {
                    ForEach(Array(m.requests.enumerated()), id: \.element) { i, p in RequestRow(p: p, first: i == 0) }
                }
                .card(v: 4, h: 14)
            }
            Sec(title: "From your contacts")
            VStack(spacing: 0) {
                ForEach(Array(Seed.contacts.enumerated()), id: \.offset) { i, ct in
                    let invited = m.contactInvited.contains(i)
                    HStack(spacing: 12) {
                        AvatarArt(id: ct.av).frame(width: 40, height: 40)
                        TwoLine(title: ct.n, sub: ct.s)
                        Button(invited ? "Invited" : "Invite") { m.contactInvite(i) }.buttonStyle(.btn(invited ? .line : .primary, small: true))
                    }
                    .padding(.vertical, 10)
                    .overlay(alignment: .top) { if i > 0 { Rectangle().fill(c.line).frame(height: 1) } }
                }
            }
            .card(v: 4, h: 14)
            Text("Demo contacts. Daybook never reads your real address book.").font(.sans(12)).foregroundStyle(c.ink3)
                .padding(.horizontal, 4).padding(.top, 8)
            Button { m.showToast("Invite link copied") } label: { Ico(.link); Text("Copy my invite link") }
                .buttonStyle(.btn(.line)).padding(.top, 16)
        }
    }
}

// MARK: - Notifications

struct NotificationsView: View {
    @Environment(AppModel.self) private var m
    var body: some View {
        let now = m.notifs.filter { !$0.earlier }, early = m.notifs.filter(\.earlier)
        Page { _ in
            NavBar(title: "Notifications") { IconBtn(label: "Mark all read", action: { m.markRead() }) { Ico(.check) } }
            Sec(title: "Today")
            ForEach(now) { NotifRow(n: $0) }
            if !early.isEmpty {
                Sec(title: "Earlier")
                ForEach(early) { NotifRow(n: $0) }
            }
        }
    }
}

private struct NotifRow: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let n: Notif
    static let kindIcon: [String: UIIcon] = ["friend": .invite, "invite": .groups, "reaction": .heart, "comment": .comment, "milestone": .trophy, "recap": .film, "award": .trophy]

    var body: some View {
        let icon = Self.kindIcon[n.kind] ?? .bell
        let pending = n.act && n.res == nil
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let who = n.who {
                    Av(p: who, size: 42).overlay(alignment: .bottomTrailing) {
                        Ico(icon, 11).foregroundStyle(Brand.onWine).frame(width: 20, height: 20)
                            .background(Circle().fill(c.acc)).background(Circle().stroke(c.card, lineWidth: 4)).offset(x: 4, y: 4)
                    }
                } else {
                    Tile(size: 42, on: true) { Ico(icon, 19) }
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    Text(n.title).font(.sans(14, .semibold)).foregroundStyle(c.ink).frame(maxWidth: .infinity, alignment: .leading)
                    Text(n.time).font(.sans(11)).foregroundStyle(c.ink3)
                }
                Text(n.body).font(.sans(12.5)).foregroundStyle(c.ink2).padding(.top, 2)
                if pending {
                    HStack(spacing: 6) {
                        Button("Accept") { m.notifYes(n.id) }.buttonStyle(.btn(.primary, small: true))
                        Button("Decline") { m.notifNo(n.id) }.buttonStyle(.btn(.line, small: true))
                    }
                    .padding(.top, 8)
                }
                if let res = n.res {
                    Text(res).font(.sans(12, .semibold)).foregroundStyle(res == "Accepted" ? c.acc : c.ink3).padding(.top, 6)
                }
            }
        }
        .card(12, fill: n.unread ? c.yelSoft : nil)
        .overlay(alignment: .bottomTrailing) {
            if n.unread { Circle().fill(c.acc).frame(width: 8, height: 8).padding(.trailing, 12).padding(.bottom, 14) }
        }
        .padding(.bottom, 8)
        .contentShape(Rectangle())
        .onTapGesture { if !pending { m.notifTap(n.id) } }
        .accessibilityAddTraits(pending ? [] : .isButton)
    }
}

// MARK: - Friend sheets

struct FriendMenuSheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        if let s = m.sheet {
            SheetBody(top: 10) {
                Text(m.person(s.p).full).font(.serif(26)).foregroundStyle(c.ink).padding(.bottom, 8)
                Button { m.removeFriend(s.p) } label: {
                    SetRow(first: true, icon: .x, title: "Remove friend", sub: "They’ll leave your shared habits") { EmptyView() }
                }
                .buttonStyle(.press)
                Button { m.showToast("Blocked (mock)") } label: {
                    SetRow(first: false, icon: .lock, iconSize: 15, title: "Block", titleColor: c.acc) { EmptyView() }
                }
                .buttonStyle(.press)
            }
        }
    }
}

struct InviteHabitSheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        if let s = m.sheet {
            let mine = m.habits.filter { $0.mem[s.p] == nil }
            VStack(spacing: 0) {
                SheetHead {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow("Invite \(m.person(s.p).name)", acc: true)
                        Text("to one of your habits").font(.serif(26)).foregroundStyle(c.ink)
                    }
                }
                SheetBody {
                    if mine.isEmpty {
                        EmptyNote(text: "They’re already in all of your habits.")
                    }
                    ForEach(Array(mine.enumerated()), id: \.element.id) { i, h in
                        Button { m.inviteToHabit(h.id, s.p) } label: {
                            Divided(first: i == 0) {
                                HStack(spacing: 12) {
                                    Tile(size: 34) { HIcon(h.ic, 17) }
                                    TwoLine(title: h.name, sub: "\(h.freq) · \(h.time)")
                                    Ico(.right).foregroundStyle(c.ink)
                                }
                            }
                        }
                        .buttonStyle(.press)
                    }
                }
            }
        }
    }
}
