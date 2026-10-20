import SwiftUI

// MARK: - Profile

struct ProfileView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        let me = m.person("me")
        let best = m.habits.dropFirst().reduce(m.habits.first) { b, h in
            guard let b else { return h }
            return m.streak(h, "me") > m.streak(b, "me") ? h : b
        }
        let pins = m.pinned.compactMap { m.T($0) }
        let bars = [5, 6, 4, 6, 3, 2, 4], top = bars.max()!
        let fav = Array(stableSorted(m.habits) { a, b in
            (m.weekCount(b, "me") + m.streak(b, "me")) - (m.weekCount(a, "me") + m.streak(a, "me"))
        }.prefix(3))
        Page { _ in
            NavBar(title: "Profile") { IconBtn(label: "Settings", action: { m.push(.settings) }) { Ico(.gear) } }
            VStack(spacing: 0) {
                Av(p: "me", size: 104)
                    .overlay { if !m.story.isEmpty { StoryRing() } }
                    .contentShape(Circle())
                    .onTapGesture { m.openStory() }
                    .accessibilityAddTraits(m.story.isEmpty ? [] : .isButton)
                    .accessibilityHint(m.story.isEmpty ? "" : "Shows your story")
                    .overlay(alignment: .topTrailing) {
                        Button { m.avatarPicker() } label: {
                            Ico(.edit, 13).foregroundStyle(Brand.onWine).frame(width: 30, height: 30)
                                .background(Circle().fill(c.acc)).background(Circle().stroke(c.card, lineWidth: 6))
                        }
                        .buttonStyle(.press)
                        .offset(x: 2, y: 72 - 16)
                        .accessibilityLabel("Change profile picture")
                    }
                Text(me.full).font(.serif(32)).foregroundStyle(c.ink).padding(.top, 12)
                Text("@\(me.handle) · joined Aug 2026").font(.sans(13)).foregroundStyle(c.ink2).padding(.top, 4)
                Text(me.bio).font(.serif(17)).italic().foregroundStyle(c.acc).padding(.top, 8)
                HStack(spacing: 8) {
                    Button { m.editProfile() } label: { Ico(.edit, 13); Text("Edit profile") }.buttonStyle(.btn(.line, small: true))
                    Button { m.showToast("Profile link copied") } label: { Ico(.share, 15); Text("Share") }.buttonStyle(.btn(.line, small: true))
                }
                .padding(.top, 14)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .card()
            StatGrid(items: [
                (.check, nil, "233", "Total check-ins", 30),
                (.flame, 16, "\(best.map { m.streak($0, "me") } ?? 0)", "Current streak · \(best?.name ?? "")", 30),
                (.groups, 16, "\(m.groups.count)", "Groups", 30),
                (.heart, 16, "\(m.friends.count)", "Friends", 30)
            ])
            VStack(alignment: .leading, spacing: 0) {
                BlkHead(left: "Showcase") { Eyebrow("\(pins.count)/6") }
                if pins.isEmpty {
                    Text("Pin trophies from your case to show them off here.").font(.sans(13.5)).foregroundStyle(c.ink2)
                } else {
                    FlowLayout(spacing: 4) {
                        ForEach(Array(pins.enumerated()), id: \.element.id) { i, t in
                            Button { m.openTrophy(t.id) } label: { PrizeArt(trophy: t, width: 66) }
                                .buttonStyle(.press)
                                .rotationEffect(.degrees([-6, 4, -3, 6, -4, 2][i % 6]))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8).padding(.bottom, 2)
                }
            }
            .card().blk()
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("Strongest days")
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<7, id: \.self) { i in
                        VStack(spacing: 5) {
                            UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 3, bottomTrailingRadius: 3, topTrailingRadius: 6)
                                .fill(bars[i] == top ? c.acc : c.accMid)
                                .frame(height: 14 + CGFloat(bars[i]) / CGFloat(top) * 64)
                            Text(String(Array("MTWTFSS")[i])).font(.mono(9.5)).foregroundStyle(c.ink3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 96, alignment: .bottom)
                .padding(.top, 6)
            }
            .card().blk()
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("Favorite habits")
                ForEach(Array(fav.enumerated()), id: \.element.id) { i, h in
                    Button { m.openDetails(h.id) } label: {
                        Divided(first: i == 0) {
                            HStack(spacing: 12) {
                                Tile(size: 46, on: true) { HIcon(h.ic, 27) }
                                TwoLine(title: h.name, sub: "\(20 + m.weekCount(h, "me") * 9) check-ins")
                                Ico(.right).foregroundStyle(c.ink)
                            }
                        }
                    }
                    .buttonStyle(.press)
                }
            }
            .card().blk()
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("Past recaps")
                ForEach(Array([(1, "Steady Week"), (2, "Comeback Kid"), (3, "Early Bird")].map { k, award in
                    let end = Day.weekEnd(k)
                    return (Day.fmt(end, "MMM"), Day.cal.component(.day, from: end), "Week \(Day.weekNum(end)) · \(award)")
                }.enumerated()), id: \.offset) { i, w in
                    Button { m.playRecap() } label: {
                        Divided(first: i == 0) {
                            HStack(spacing: 12) {
                                DateBox(month: w.0, day: w.1)
                                TwoLine(title: w.2, sub: "Replay the curtain")
                                Ico(.right).foregroundStyle(c.ink)
                            }
                        }
                    }
                    .buttonStyle(.press)
                }
            }
            .card().blk()
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("Friends & groups")
                Button { m.push(.friends) } label: {
                    Divided(first: true) {
                        HStack(spacing: 12) {
                            AvStack(list: m.friends, size: 34, max: 6)
                            Spacer(minLength: 0)
                            Ico(.right).foregroundStyle(c.ink)
                        }
                    }
                }
                .buttonStyle(.press)
                ForEach(m.groups) { g in
                    Button { m.openGroup(g.id) } label: {
                        Divided(first: false) {
                            HStack(spacing: 12) {
                                Tile(size: 46) { HIcon(g.ic, 27) }
                                TwoLine(title: g.name, sub: "\(g.type == "community" ? (g.size ?? 0).formatted() : "\(g.members.count)") members")
                                Ico(.right).foregroundStyle(c.ink)
                            }
                        }
                    }
                    .buttonStyle(.press)
                }
            }
            .card().blk()
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        let me = m.person("me")
        Page { _ in
            NavBar(title: "Settings")
            Button { m.editProfile() } label: {
                HStack(spacing: 12) {
                    Av(p: "me", size: 48)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(me.full).font(.sans(16, .semibold)).foregroundStyle(c.ink)
                        Text("@\(me.handle) · Edit profile").font(.sans(12)).foregroundStyle(c.ink3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Ico(.right).foregroundStyle(c.ink)
                }
                .card(v: 12, h: 14)
            }
            .buttonStyle(.press)
            .padding(.bottom, 12)
            SettingsLabel("Appearance")
            VStack(spacing: 0) {
                SetRow(first: true, icon: .palette, title: "Theme", sub: "Paper by day, Stage by night") {
                    Seg(options: [("paper", "Paper"), ("stage", "Stage")], selected: m.theme.rawValue, height: 28, font: 12) { v in
                        withAnimation(.easeInOut(duration: 0.25)) { m.theme = ThemeName(rawValue: v) ?? .paper }
                    }
                    .frame(width: 150)
                }
            }
            .card(v: 4, h: 14).padding(.bottom, 12)
            SettingsLabel("Notifications & feel")
            VStack(spacing: 0) {
                ToggleRow(first: true, k: "notif", label: "Notifications", sub: "Invites, comments and your recap", icon: .bell)
                ToggleRow(first: false, k: "sound", label: "Sounds", sub: "A soft tap when you check off", icon: .sound)
                ToggleRow(first: false, k: "haptics", label: "Haptics", sub: "Little buzzes for big moments", icon: .vib)
            }
            .card(v: 4, h: 14).padding(.bottom, 12)
            SettingsLabel("Privacy")
            VStack(spacing: 0) {
                ToggleRow(first: true, k: "share", label: "Share my activity", sub: "Friends see your check-ins and photos", icon: .eye)
            }
            .card(v: 4, h: 14).padding(.bottom, 12)
            SettingsLabel("Account")
            VStack(spacing: 0) {
                Button { m.avatarPicker() } label: {
                    SetRow(first: true, icon: .user, iconSize: 16, title: "Change profile picture") { Ico(.right).foregroundStyle(c.ink) }
                }
                .buttonStyle(.press)
                Button { m.reset() } label: {
                    SetRow(first: false, icon: .refresh, title: "Reset demo data") { Ico(.right).foregroundStyle(c.ink) }
                }
                .buttonStyle(.press)
                Button { m.showToast("Logged out (mock)") } label: {
                    SetRow(first: false, icon: .leave, title: "Log out", titleColor: c.acc) { EmptyView() }
                }
                .buttonStyle(.press)
            }
            .card(v: 4, h: 14).padding(.bottom, 12)
            Text("Creds 1.0 · demo build").font(.sans(12)).foregroundStyle(c.ink3).frame(maxWidth: .infinity).padding(.top, 2)
        }
    }
}

private struct SettingsLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View { Eyebrow(text).padding(.top, 2).padding(.horizontal, 4).padding(.bottom, 6) }
}

private struct ToggleRow: View {
    @Environment(AppModel.self) private var m
    let first: Bool
    let k, label, sub: String
    let icon: UIIcon
    var body: some View {
        Button { m.toggleSetting(k) } label: {
            SetRow(first: first, icon: icon, title: label, sub: sub) { Switch(on: m.settings[k] ?? false) }
        }
        .buttonStyle(.plain)
        .accessibilityValue(m.settings[k] == true ? "On" : "Off")
    }
}

// MARK: - Profile sheets

struct AvatarSheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        VStack(spacing: 0) {
            SheetHead {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow("Profile picture", acc: true)
                    EmTitle(lead: "Pick your ", em: "look.", size: 26)
                }
            }
            SheetBody {
                ProfilePic(size: 120).frame(maxWidth: .infinity)
                ProfilePhotoPicker { Text(m.myPhoto == nil ? "Choose from library" : "Choose a different photo") }
                    .buttonStyle(.btn).padding(.top, 20)
                if m.myPhoto != nil {
                    Button("Remove picture") { m.removePhoto() }.buttonStyle(.btn(.line)).padding(.top, 8)
                }
            }
        }
    }
}

struct EditProfileSheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        VStack(spacing: 0) {
            SheetHead { Text("Edit profile").font(.serif(26)).foregroundStyle(c.ink) }
            SheetBody {
                Field(label: "Name", text: m.field(\.full))
                Field(label: "Bio", text: m.field(\.bio)).padding(.top, 8)
                Button("Save") { m.profileSave() }.buttonStyle(.btn).padding(.top, 16)
            }
        }
    }
}
