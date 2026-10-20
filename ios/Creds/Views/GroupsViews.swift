import SwiftUI
import Combine

// MARK: - Groups tab

struct GroupsView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        Page { _ in
            GHead(eyebrow: "Your circles", title: "Groups") {
                Button { m.push(.friends) } label: {
                    HStack(spacing: 8) {
                        AvStack(list: Array(m.friends.prefix(3)), size: 24, max: 3)
                        Text("Friends").font(.sans(13, .semibold)).foregroundStyle(c.ink)
                    }
                    .padding(.leading, 6).padding(.trailing, 12).frame(height: 38)
                    .background(Capsule().fill(c.card).shadow(color: c.shadow.opacity(0.75), radius: 6, y: 5))
                    .overlay(Capsule().strokeBorder(c.line, lineWidth: 1))
                }
                .buttonStyle(.press)
                IconBtn(acc: true, label: "New group", action: { m.createGroup() }) { Ico(.plus, 18) }
            }
            Spotlight()
            if !m.invites.isEmpty {
                Sec(title: "Invitations", count: m.invites.count)
                ForEach(m.invites) { v in InviteCard(v: v) }
            }
            Sec(title: "Your groups", count: m.groups.count)
            if m.groups.isEmpty {
                EmptyNote(text: "No groups yet. Start one with + or join a community above.")
            } else {
                ForEach(m.groups) { g in GroupCard(g: g) }
            }
        }
    }
}

/// Community banner: auto-advances, pauses while touched.
private struct Spotlight: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pos: Int? = 0
    @State private var hold = Date.distantPast
    private let timer = Timer.publish(every: 4.2, on: .main, in: .common).autoconnect()

    var body: some View {
        let picks = Array(stableSorted(m.communities.filter { !m.joined($0.id) }) { a, b in
            a.friends.count != b.friends.count ? b.friends.count - a.friends.count : b.size - a.size
        }.prefix(4))
        let n = picks.count + 1
        VStack(spacing: 0) {
            GeometryReader { g in
                let w = g.size.width - 26
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(Array(picks.enumerated()), id: \.element.id) { i, cm in
                            Poster(cm: cm, width: w, height: 160).id(i)
                        }
                        DiscoverPoster(width: w).id(picks.count)
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $pos, anchor: .leading)
                .contentMargins(.horizontal, 16, for: .scrollContent)
                .padding(.horizontal, -16)
                .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in hold = Date().addingTimeInterval(8) })
            }
            .frame(height: 160)
            .padding(.top, 14)
            HStack(spacing: 5) {
                ForEach(0..<n, id: \.self) { i in
                    Capsule().fill(i == (pos ?? 0) ? c.acc : c.line2).frame(width: i == (pos ?? 0) ? 16 : 5, height: 5)
                }
            }
            .animation(.easeOut(duration: 0.3), value: pos)
            .padding(.top, 10)
        }
        .onReceive(timer) { _ in
            guard m.tab == .groups, m.stack.isEmpty, m.mode == .app, Date() >= hold, m.sheet == nil, m.overlay == nil, !reduceMotion else { return }
            let i = pos ?? 0
            withAnimation(.easeInOut(duration: 0.5)) { pos = i + 1 >= n ? 0 : i + 1 }
        }
    }
}

/// A community poster.
struct Poster: View {
    @Environment(AppModel.self) private var m
    let cm: Community
    let width: CGFloat
    let height: CGFloat
    var titleSize: CGFloat = 30 * 0.86
    var body: some View {
        let f = cm.friends.filter { m.friends.contains($0) }
        let ink = PosterBackground.ink(cm.look), accent = cm.look == .paper ? Brand.wine : ink
        VStack(alignment: .leading, spacing: 0) {
            Text("\(f.isEmpty ? "Picked for you" : "Your friends are in") · \(cm.cat)")
                .font(.mono(9.5)).tracking(1.33).textCase(.uppercase).foregroundStyle(accent).opacity(0.85).lineLimit(1)
            Spacer(minLength: 0)
            italLast(cm.name, size: titleSize / 0.86, emColor: cm.look == .paper ? Brand.wine : nil)
                .font(.serifRaw(titleSize)).tracking(-0.4).lineSpacing(-4)
                .frame(maxWidth: width * 0.88 - 28, alignment: .leading)
            Text("\(cm.size.formatted()) members · \(cm.pct)% checked in today").font(.sans(12.5)).opacity(0.82).padding(.top, 4).lineLimit(1)
            HStack(spacing: 8) {
                if !f.isEmpty { AvStack(list: f, size: 22, max: 3, ring: .black.opacity(0.2)) }
                Text(f.isEmpty ? String(cm.desc.split(separator: ".").first ?? "") : f.map { m.person($0).name }.joined(separator: " + "))
                    .font(.mono(9.5)).tracking(0.95).textCase(.uppercase).opacity(0.75).lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if m.joined(cm.id) {
                    PosterPill(label: "Joined", ghost: true)
                } else {
                    Button { m.join(cm.id) } label: { PosterPill(label: "Join") }.buttonStyle(.press)
                }
            }
            .padding(.top, 10)
        }
        .foregroundStyle(ink)
        .padding(14)
        .frame(width: width, height: height, alignment: .leading)
        .background(alignment: .bottomTrailing) {
            ZStack(alignment: .bottomTrailing) {
                PosterBackground(look: cm.look)
                HIcon(cm.ic, 120, 0.9).foregroundStyle(ink).opacity(0.2).offset(x: 16, y: 22)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay { if cm.look == .paper { RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color(hex: 0xD6CCC0), lineWidth: 1) } }
        .contentShape(Rectangle())
        .onTapGesture { m.openCommunity(cm.id) }
        .accessibilityAddTraits(.isButton)
    }
}

private struct DiscoverPoster: View {
    @Environment(AppModel.self) private var m
    let width: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Discover").font(.mono(9.5)).tracking(1.33).textCase(.uppercase).opacity(0.85)
            Spacer(minLength: 0)
            Text("Find your \(Text("people").italic())").font(.serif(30)).tracking(-0.4)
            Text("\(m.communities.count) open communities · search by habit").font(.sans(12.5)).opacity(0.82).padding(.top, 4)
            HStack {
                Spacer()
                HStack(spacing: 5) { Text("Explore all"); Ico(.right, 12) }.modifier(PillStyle(ghost: false))
            }
            .padding(.top, 10)
        }
        .foregroundStyle(Brand.onWine)
        .padding(14)
        .frame(width: width, height: 160, alignment: .leading)
        .background(PosterBackground(look: .curtain))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { m.push(.discover) }
        .accessibilityAddTraits(.isButton)
    }
}

/// Yellow pill on posters (.pbtn).
struct PosterPill: View {
    let label: String
    var ghost = false
    var body: some View { Text(label).modifier(PillStyle(ghost: ghost)) }
}

struct PillStyle: ViewModifier {
    @Environment(\.pal) private var c
    let ghost: Bool
    func body(content: Content) -> some View {
        content
            .font(.sans(12, .bold))
            .foregroundStyle(ghost ? AnyShapeStyle(.foreground) : AnyShapeStyle(Brand.wineInk))
            .padding(.horizontal, 12).frame(height: 28)
            .background(Capsule().fill(ghost ? .clear : c.yel))
            .overlay { if ghost { Capsule().strokeBorder(.foreground, lineWidth: 1) } }
            .fixedSize()
    }
}

private struct InviteCard: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let v: Invite
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                GroupIcon(ic: v.ic)
                Text(v.name).font(.sans(20, .medium)).foregroundStyle(c.ink).frame(maxWidth: .infinity, alignment: .leading)
                AvStack(list: v.members, size: 22, max: 3)
            }
            Text("\(m.person(v.from).name) invited you").font(.sans(12.5)).foregroundStyle(c.ink2).padding(.top, 6).padding(.leading, 38)
            HStack(spacing: 8) {
                Button("Join") { m.invJoin(v.id) }.buttonStyle(.btn(.primary, small: true))
                Button("Not now") { m.invNo(v.id) }.buttonStyle(Btn(kind: .ghost, small: true, full: false))
                Spacer()
                HStack(spacing: 4) { Text("Tap to preview"); Ico(.right, 12) }.font(.sans(12)).foregroundStyle(c.yelInk)
            }
            .padding(.top, 12)
        }
        .card(14, fill: c.yelSoft, outline: c.yel.opacity(0.7), outlineWidth: 1.2)
        .padding(.bottom, 10)
        .contentShape(Rectangle())
        .onTapGesture { m.push(.group, v.id) }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Preview \(v.name)")
    }
}

/// Square group icon (.gic): red on gray, like Tile.
struct GroupIcon: View {
    @Environment(\.pal) private var c
    let ic: String
    var body: some View {
        HIcon(ic, 23).foregroundStyle(c.acc)
            .frame(width: 38, height: 38)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(c.tile))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(c.line.opacity(0.6), lineWidth: 1))
    }
}

/// "Open" tag (.tagx).
struct OpenTag: View {
    @Environment(\.pal) private var c
    var body: some View {
        HStack(spacing: 4) { Ico(.globe, 10); Text("Open") }
            .font(.mono(9.5)).tracking(0.95).textCase(.uppercase)
            .foregroundStyle(c.yelInk)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 5).fill(c.yelSoft))
    }
}

private struct GroupCard: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let g: HabitGroup
    var body: some View {
        let tot = m.chTotal(g.ch)
        Button { m.openGroup(g.id) } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    GroupIcon(ic: g.ic)
                    HStack(spacing: 4) {
                        Text(g.name).font(.sans(20, .medium)).foregroundStyle(c.ink).multilineTextAlignment(.leading)
                        if g.type == "community" { OpenTag() }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    AvStack(list: g.members.filter { $0 != "me" }, size: 22, max: 3)
                }
                if let ch = g.ch {
                    VStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Text(ch.title).font(.sans(12.5)).foregroundStyle(c.ink).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(tot.formatted())/\(ch.goal.formatted())").font(.mono(12.5)).foregroundStyle(c.ink2)
                        }
                        PBar(pct: Double(tot) / Double(ch.goal) * 100).padding(.top, 6)
                    }
                    .padding(.top, 9)
                    .overlay(alignment: .top) { Rectangle().fill(c.line).frame(height: 1) }
                    .padding(.top, 10)
                }
            }
            .card(v: 12, h: 14, fill: c.card, outline: c.line)
        }
        .buttonStyle(.press)
        .padding(.bottom, 10)
    }
}

// MARK: - Discover

struct DiscoverView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        @Bindable var m = m
        Page { _ in
            NavBar(title: "Discover")
            HStack(spacing: 10) {
                Ico(.search).foregroundStyle(c.ink3)
                TextField("", text: $m.q, prompt: Text("Search communities").foregroundStyle(c.ink3))
                    .font(.sans(15.5, .medium)).foregroundStyle(c.ink).autocorrectionDisabled()
            }
            .padding(.horizontal, 14).frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(c.card))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(c.line, lineWidth: 1))
            .padding(.top, 4).padding(.bottom, 12)
            Bleed(inset: 16, spacing: 6) {
                ForEach(Seed.cats, id: \.self) { ct in Chip(label: ct, on: m.cat == ct) { m.cat = ct } }
            }
            DiscoverList()
        }
    }
}

private struct DiscoverList: View {
    @Environment(AppModel.self) private var m
    var body: some View {
        let q = m.q.trimmingCharacters(in: .whitespaces).lowercased()
        let list = m.communities.filter { cm in
            (m.cat == "All" || cm.cat == m.cat) && (q.isEmpty || (cm.name + " " + cm.desc + " " + cm.cat).lowercased().contains(q))
        }
        if list.isEmpty {
            EmptyNote(text: "No communities match “\(m.q)”.").padding(.top, 12)
        } else if !q.isEmpty || m.cat != "All" {
            Sec(title: "Results", count: list.count)
            ForEach(list) { CommunityRow(cm: $0) }
        } else {
            let pop = Array(stableSorted(list) { a, b in b.size - a.size }.prefix(4))
            let fr = list.filter { !$0.friends.isEmpty && !m.joined($0.id) }
            let rest = list.filter { cm in !fr.contains { $0.id == cm.id } }
            Sec(title: "Popular this week")
            Bleed(inset: 16, spacing: 10) {
                ForEach(pop) { Poster(cm: $0, width: 168, height: 208, titleSize: 27) }
            }
            .scrollTargetBehavior(.viewAligned)
            .padding(.top, 10 - 8)
            if !fr.isEmpty {
                Sec(title: "Your friends are in", count: fr.count)
                ForEach(fr) { CommunityRow(cm: $0) }
            }
            Sec(title: "More to explore", count: rest.count)
            ForEach(rest) { CommunityRow(cm: $0) }
        }
    }
}

private struct CommunityRow: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let cm: Community
    var body: some View {
        let f = cm.friends.filter { m.friends.contains($0) }
        HStack(spacing: 12) {
            Tile(size: 48) { HIcon(cm.ic, 28) }
            VStack(alignment: .leading, spacing: 0) {
                Text(cm.name).font(.sans(15, .medium)).foregroundStyle(c.ink)
                Text("\(cm.size.formatted()) members · \(cm.pct)% today").font(.sans(12)).foregroundStyle(c.ink3).padding(.top, 2)
                if !f.isEmpty {
                    HStack(spacing: 6) {
                        AvStack(list: f, size: 20, max: 3)
                        Text("\(f.map { m.person($0).name }.joined(separator: " + ")) \(f.count > 1 ? "are" : "is") in").font(.sans(11.5)).foregroundStyle(c.ink2)
                    }
                    .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            JoinButton(joined: m.joined(cm.id)) { m.join(cm.id) }
        }
        .card(12)
        .padding(.bottom, 8)
        .contentShape(Rectangle())
        .onTapGesture { m.openCommunity(cm.id) }
        .accessibilityAddTraits(.isButton)
    }
}

struct CommunitySheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        if let s = m.sheet, let cm = m.C(s.id) {
            let f = cm.friends.filter { m.friends.contains($0) }
            let ink = PosterBackground.ink(cm.look)
            VStack(spacing: 0) {
                SheetHead { Color.clear.frame(height: 1) }
                SheetBody {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Open community · \(cm.cat)").font(.mono(9.5)).tracking(1.33).textCase(.uppercase).opacity(0.85)
                            .foregroundStyle(cm.look == .paper ? Brand.wine : ink)
                        Spacer(minLength: 0)
                        italLast(cm.name, size: 42 / 0.86, emColor: cm.look == .paper ? Brand.wine : nil).tracking(-0.6)
                    }
                    .foregroundStyle(ink)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading).frame(height: 190)
                    .background(alignment: .bottomTrailing) {
                        ZStack(alignment: .bottomTrailing) {
                            PosterBackground(look: cm.look)
                            HIcon(cm.ic, 130, 0.9).foregroundStyle(ink).opacity(0.2).offset(x: 16, y: 22)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay { if cm.look == .paper { RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color(hex: 0xD6CCC0), lineWidth: 1) } }
                    Text(cm.desc).font(.sans(15)).lineSpacing(4).foregroundStyle(c.ink2).padding(.top, 14)
                    HStack(spacing: 8) {
                        Ledger(value: cm.size.formatted(), label: "members")
                        Ledger(value: "\(cm.pct)%", label: "checked in today")
                        Ledger(value: "\(f.count)", label: "friends here")
                    }
                    .padding(.top, 14)
                    Lbl(text: "House rules")
                    VStack(spacing: 0) {
                        ForEach(Array(["Check in once a day, before midnight", "Photos are welcome, never required", "Be kind in the comments"].enumerated()), id: \.offset) { i, r in
                            Divided(first: i == 0) {
                                HStack(alignment: .top, spacing: 12) {
                                    Text(String(format: "%02d", i + 1)).font(.mono(10.5)).foregroundStyle(c.acc).padding(.top, 2)
                                    Text(r).font(.sans(14)).foregroundStyle(c.ink)
                                }
                            }
                        }
                    }
                    .card(v: 2, h: 14)
                    if !f.isEmpty {
                        Lbl(text: "Friends here")
                        HStack(spacing: 10) {
                            AvStack(list: f, size: 34, max: 4)
                            Text(f.map { m.person($0).name }.joined(separator: " + ")).font(.sans(13)).foregroundStyle(c.ink2)
                        }
                    }
                    Group {
                        if m.joined(cm.id) {
                            Button("Joined · Open group") { m.openGroup(cm.id) }.buttonStyle(.btn(.line))
                        } else {
                            Button("Join community") { m.join(cm.id) }.buttonStyle(.btn)
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
    }
}

private struct Ledger: View {
    @Environment(\.pal) private var c
    let value, label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.serif(26)).foregroundStyle(c.ink).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.sans(11.5)).foregroundStyle(c.ink3).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10).padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(c.card))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(c.line, lineWidth: 1))
    }
}

// MARK: - Group page

struct GroupPageView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let id: String

    private struct Info {
        let name, ic, type, desc: String
        let size: Int?
        let members: [String]
        let ch: Challenge?
        let fin: [Finished]
        let notif: String
    }

    var body: some View {
        let g = m.G(id), inv = g == nil ? m.invites.first { $0.id == id } : nil
        if let info = g.map({ Info(name: $0.name, ic: $0.ic, type: $0.type, desc: $0.desc, size: $0.size, members: $0.members, ch: $0.ch, fin: $0.fin, notif: $0.notif) })
            ?? inv.map({ Info(name: $0.name, ic: $0.ic, type: "friends", desc: $0.desc, size: nil, members: $0.members, ch: $0.ch, fin: [], notif: "Everything") }) {
            let isMember = g != nil, ts = g.map { m.tasks(of: $0.id) } ?? []
            let taskNames = ts.map(\.name)
            Page { _ in
                NavBar(title: info.name) {
                    if isMember { IconBtn(label: "Group options", action: { m.groupMenu(id) }) { Ico(.more) } }
                }
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        Tile(size: 66, on: true) { HIcon(info.ic, 38) }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(info.name).font(.sans(30, .medium)).foregroundStyle(c.ink)
                            Text(info.type == "community" ? "\((info.size ?? 0).formatted()) members · open community" : "\(info.members.count) members")
                                .font(.sans(13)).foregroundStyle(c.ink2)
                        }
                    }
                    Text(info.desc).font(.serif(17)).italic().foregroundStyle(c.acc).padding(.top, 10)
                    Bleed(inset: 16, spacing: 12) {
                        ForEach(info.members, id: \.self) { p in
                            Button { if p != "me" { m.push(.friend, p) } } label: {
                                VStack(spacing: 5) {
                                    Av(p: p, size: 44)
                                    Text(m.nameOf(p)).font(.sans(11.5, .semibold)).foregroundStyle(c.ink).lineLimit(1)
                                }
                                .frame(width: 52)
                            }
                            .buttonStyle(.press)
                        }
                    }
                    .padding(.top, 14)
                }
                .card()
                if !isMember {
                    Button("Join \(info.name)") { m.invJoin(id) }.buttonStyle(.btn).padding(.top, 12)
                }
                if let g {
                    GroupTasks(g: g, tasks: ts).blk()
                }
                if let ch = info.ch {
                    ChallengeCard(gid: id, ch: ch, isMember: isMember, habitName: taskNames.isEmpty ? nil : taskNames.joined(separator: " or ")).blk()
                }
                if !info.fin.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Eyebrow("Finished")
                        ForEach(Array(info.fin.enumerated()), id: \.offset) { i, f in
                            Divided(first: i == 0) {
                                HStack(spacing: 12) {
                                    Tile(size: 46, on: f.ok) { Ico(.trophy, 25) }
                                    TwoLine(title: f.t, sub: f.r, titleSize: 14)
                                    if f.ok {
                                        Stamp(size: 40, color: c.acc) { Text("Done").font(.mono(7, .medium)) }.rotationEffect(.degrees(-10))
                                    }
                                }
                            }
                        }
                    }
                    .card().blk()
                }
                if isMember && !taskNames.isEmpty {
                    Text("Counts toward challenges: \(Text(taskNames.joined(separator: ", ")).fontWeight(.bold).foregroundStyle(c.ink))")
                        .font(.sans(12.5)).foregroundStyle(c.ink3).padding(.top, 18)
                }
                // last on the page; leaving lives in the ••• menu
                if let g, !ts.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Today’s Photos").font(.sans(24, .semibold)).foregroundStyle(c.today.text)
                                .accessibilityAddTraits(.isHeader)
                            Spacer(minLength: 8)
                            if ts.count == 1 { PhotoCount(g: g, h: ts[0]) }
                        }
                        .padding(.bottom, 16)
                        if ts.count == 1 {
                            TodayStrip(h: ts[0])
                        } else {
                            // one grid per task
                            ForEach(ts) { h in
                                HStack(alignment: .firstTextBaseline) {
                                    HStack(spacing: 8) {
                                        HIcon(h.ic, 18).foregroundStyle(c.today.red)
                                        Text(h.name).font(.sans(18, .semibold)).foregroundStyle(c.today.text)
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityAddTraits(.isHeader)
                                    Spacer(minLength: 8)
                                    PhotoCount(g: g, h: h)
                                }
                                .padding(.bottom, 12)
                                TodayStrip(h: h).padding(.bottom, 28)
                            }
                        }
                    }
                    .padding(.top, 30)
                }
            }
        } else {
            Color.clear.onAppear { if m.topRoute?.id == id { m.back() } }
        }
    }
}

/// "2 of 5 done" for one task; hidden in groups over 15 people.
private struct PhotoCount: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let g: HabitGroup
    let h: Habit
    var body: some View {
        if m.groupSize(g) <= 15 {
            Text("\(m.doneCount(h)) of \(m.peopleOf(h).count) done").font(.sans(14)).foregroundStyle(c.today.muted)
        }
    }
}

/// The group's tasks, each with its own schedule and check-ins, plus "Add task" for whoever may add one.
private struct GroupTasks: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let g: HabitGroup
    let tasks: [Habit]
    var body: some View {
        let t = c.today
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Tasks").font(.sans(24, .semibold)).foregroundStyle(t.text).accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                Text("\(tasks.count)").font(.sans(14)).foregroundStyle(t.muted)
            }
            .padding(.bottom, 12)
            if tasks.isEmpty {
                Text("No tasks yet.").font(.sans(14)).foregroundStyle(t.muted).padding(.bottom, 10)
            }
            ForEach(tasks) { h in HabitCard(h: h) }
            if m.canAddTask(g) {
                Button { m.openCreate(in: g.id) } label: { Ico(.plus, 18); Text("Add task") }
                    .buttonStyle(Btn(kind: .line, fg: t.red))
                    .padding(.top, 2)
            } else {
                HStack(spacing: 6) {
                    Ico(.lock, 13)
                    Text("Only admins can add tasks to this group.")
                }
                .font(.sans(13)).foregroundStyle(t.muted).padding(.top, 2)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

private struct ChallengeCard: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let gid: String
    let ch: Challenge
    let isMember: Bool
    let habitName: String?
    var body: some View {
        let tot = m.chTotal(ch), pct = min(100, Int((Double(tot) / Double(ch.goal) * 100).rounded()))
        let contrib = stableSorted(ch.c.entries) { a, b in b.1 - a.1 }
        let maxC = max(1, contrib.map(\.1).max() ?? 1)
        let lead = contrib.first { $0.0 != "me" }
        let mine = ch.c["me"] ?? 0
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(pct >= 100 ? "Goal reached" : "\(ch.left) days left", acc: true)
            Text(ch.title).font(.sans(16, .semibold)).foregroundStyle(c.ink).padding(.top, 4)
            Text(ch.detail).font(.sans(12.5)).foregroundStyle(c.ink3).padding(.top, 2)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(tot.formatted()).font(.serif(44)).foregroundStyle(c.ink)
                Text("of \(ch.goal.formatted()) \(ch.unit)").font(.sans(13)).foregroundStyle(c.ink2)
                Spacer(minLength: 0)
                Text("\(pct)%").font(.serif(26)).foregroundStyle(c.acc)
            }
            .padding(.top, 12)
            PBar(pct: Double(pct), height: 14, big: true).padding(.top, 8)
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("Contributions")
                ForEach(contrib, id: \.0) { p, n in
                    ContribRow(name: m.nameOf(p), frac: Double(n) / Double(maxC), count: n, me: p == "me")
                }
                if let others = ch.others {
                    ContribRow(name: "Everyone else", frac: 1, count: others, me: false, muted: true)
                }
                if let lead {
                    Text("\(m.person(lead.0).name) is leading the charge · \(contrib.count) people chipping in")
                        .font(.serifRaw(15)).italic().foregroundStyle(c.acc).padding(.top, 10)
                }
            }
            .padding(.top, 14)
            if isMember {
                HStack(spacing: 8) {
                    Button { m.logOne(gid) } label: { Ico(.plus, 17); Text("Log one") }.buttonStyle(.btn)
                    Button("−") { m.logMinus(gid) }.buttonStyle(Btn(kind: .line, full: false)).frame(width: 48)
                        .disabled(mine == 0).accessibilityLabel("Remove one")
                }
                .padding(.top, 14)
                Text("You’ve added \(mine).\(habitName.map { " Checking off \($0) adds one automatically." } ?? "")")
                    .font(.sans(12.5)).foregroundStyle(c.ink3).multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity).padding(.top, 8)
            }
        }
        .card()
    }
}

private struct ContribRow: View {
    @Environment(\.pal) private var c
    let name: String
    let frac: Double
    let count: Int
    let me: Bool
    var muted = false
    var body: some View {
        HStack(spacing: 8) {
            Text(name).font(.sans(12.5, me ? .bold : .regular)).foregroundStyle(muted ? c.ink3 : c.ink).lineLimit(1).frame(width: 62, alignment: .leading)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(c.bg2)
                    Capsule().fill(muted ? c.line2 : me ? c.acc : c.yel).frame(width: g.size.width * frac)
                }
            }
            .frame(height: 10)
            Text("\(count)").font(.mono(12.5, me ? .bold : .regular)).foregroundStyle(c.ink2).frame(minWidth: 26, alignment: .trailing).fixedSize()
        }
        .padding(.top, 6)
    }
}

// MARK: - Group sheets

struct CreateGroupSheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        if let s = m.sheet {
            VStack(spacing: 0) {
                SheetHead {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow("New group", acc: true)
                        EmTitle(lead: "Start a ", em: "circle.", size: 26)
                    }
                }
                SheetBody {
                    Field(label: "Group name", placeholder: "e.g. Night Owls Anonymous", text: m.field(\.name))
                    Field(label: "What's it about?", placeholder: "One line so friends know", text: m.field(\.desc)).padding(.top, 8)
                    Lbl(text: "Icon")
                    IconPicker(selected: s.ic) { m.sheet?.ic = $0 }
                    Lbl(text: "Invite friends · \(s.friends.count)")
                    FriendPicker(list: m.friends, selected: s.friends) { p in
                        if let i = m.sheet?.friends.firstIndex(of: p) { m.sheet?.friends.remove(at: i) } else { m.sheet?.friends.append(p) }
                    }
                    Lbl(text: "Who can add tasks")
                    Seg(options: [(TaskPerm.admins.rawValue, "Only admins"), (TaskPerm.members.rawValue, "Any member")], selected: s.perm.rawValue) {
                        m.sheet?.perm = TaskPerm(rawValue: $0) ?? .members
                    }
                    Text(s.perm == .admins ? "Just you (and admins you add) can create tasks in this group." : "Everyone in the group can create tasks.")
                        .font(.sans(12.5)).foregroundStyle(c.ink3).padding(.top, 6)
                    Lbl(text: "First challenge (optional)")
                    Field(label: "Goal", placeholder: "e.g. 30 early nights this week", text: m.field(\.goal))
                    Button("Create group") { m.groupGo() }.buttonStyle(.btn).padding(.top, 16)
                }
            }
        }
    }
}

/// Settings-style row (.set-row).
struct SetRow<Trailing: View>: View {
    @Environment(\.pal) private var c
    let first: Bool
    let icon: UIIcon
    var iconSize: CGFloat? = nil
    let title: String
    var sub: String? = nil
    var titleColor: Color? = nil
    @ViewBuilder var trailing: Trailing
    var body: some View {
        Divided(first: first, vpad: 11) {
            HStack(spacing: 12) {
                Tile(size: 42, rotate: false, radiusScale: 0.95) { Ico(icon, (iconSize ?? icon.defaultSize) * 1.35) }
                TwoLine(title: title, sub: sub, titleSize: 15, titleColor: titleColor)
                trailing
            }
        }
    }
}

struct GroupMenuSheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        if let s = m.sheet, let g = m.G(s.id) {
            SheetBody(top: 10) {
                Text(g.name).font(.sans(26, .medium)).foregroundStyle(c.ink).padding(.bottom, 8)
                Eyebrow("Notifications from this group")
                Seg(options: ["Everything", "Milestones", "Off"].map { ($0, $0) }, selected: g.notif) { m.setGroupNotif(g.id, $0) }
                    .padding(.top, 10).padding(.bottom, 14)
                Eyebrow("Who can add tasks")
                Seg(options: [(TaskPerm.admins.rawValue, "Only admins"), (TaskPerm.members.rawValue, "Any member")], selected: g.taskPerm.rawValue) {
                    m.setTaskPerm(g.id, TaskPerm(rawValue: $0) ?? .members)
                }
                .padding(.top, 10)
                .disabled(!m.isAdmin(g)).opacity(m.isAdmin(g) ? 1 : 0.55)
                Text(m.isAdmin(g) ? "You’re an admin of this group." : "Only admins can change this.")
                    .font(.sans(12.5)).foregroundStyle(c.ink3).padding(.top, 6).padding(.bottom, 14)
                if g.type == "friends" {
                    Button { m.inviteFriends(g.id) } label: {
                        SetRow(first: true, icon: .invite, title: "Invite friends") { Ico(.right).foregroundStyle(c.ink) }
                    }
                    .buttonStyle(.press)
                }
                Button { m.showToast("Group link copied") } label: {
                    SetRow(first: g.type != "friends", icon: .link, title: "Copy group link") { EmptyView() }
                }
                .buttonStyle(.press)
                Button { m.pendingLeave = g.id } label: {
                    SetRow(first: false, icon: .leave, title: g.type == "community" ? "Leave community" : "Leave group", titleColor: c.acc) { EmptyView() }
                }
                .buttonStyle(.press)
            }
        }
    }
}

struct InviteFriendsSheet: View {
    @Environment(AppModel.self) private var m
    var body: some View {
        if let s = m.sheet, let g = m.G(s.id) {
            let avail = m.friends.filter { !g.members.contains($0) }
            VStack(spacing: 0) {
                SheetHead {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow("Invite to", acc: true)
                        Text(g.name).font(.sans(26, .medium))
                    }
                }
                SheetBody {
                    if avail.isEmpty {
                        EmptyNote(text: "Every friend is already in this group.")
                    } else {
                        FriendPicker(list: avail, selected: s.selSet) { m.invPick($0) }
                        Button(s.selSet.isEmpty ? "Pick friends" : "Invite \(s.selSet.count)") { m.invSend(g.id) }
                            .buttonStyle(.btn).disabled(s.selSet.isEmpty).padding(.top, 16)
                    }
                }
            }
        }
    }
}

// MARK: - Previews (Editor → Canvas)

#Preview("Groups") { CredsPreview { $0.selectTab(.groups) } }
#Preview("Group page") { CredsPreview { $0.selectTab(.groups); $0.openGroup("hydration") } }
#Preview("Discover") { CredsPreview { $0.selectTab(.groups); $0.push(.discover) } }
