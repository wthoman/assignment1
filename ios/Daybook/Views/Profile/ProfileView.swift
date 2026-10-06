import Charts
import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query(filter: #Predicate<Friend> { $0.statusRaw == "friend" }, sort: \Friend.name) private var friends: [Friend]
    @Query private var collectibles: [Collectible]
    @Query(sort: \WeeklyRecap.weekStart, order: .reverse) private var recaps: [WeeklyRecap]
    @Query(filter: #Predicate<HabitGroup> { $0.isMember }) private var groups: [HabitGroup]
    @Query(filter: #Predicate<Gift> { !$0.opened }) private var unopenedGifts: [Gift]
    @State private var editing = false

    var body: some View {
        if let me = model.me {
            content(me)
        } else {
            EmptyStateView(symbol: "person.crop.circle", title: "No profile", message: "Finish onboarding to create one.")
        }
    }

    private func content(_ me: UserProfile) -> some View {
        let myCheckIns = habits.flatMap(\.myCheckIns)
        let consistency = habits.overallConsistency()
        let comebacks = habits.reduce(0) { $0 + $1.comebackCount }
        let showcase = me.showcaseKeys.compactMap { key in collectibles.first { $0.key == key } }
        let superlatives = collectibles.filter { $0.category == .superlative && $0.isUnlocked }
        let favorites = habits.filter { $0.status == .active }.sorted { $0.myCheckIns.count > $1.myCheckIns.count }.prefix(3)
        let weekdayTotals = Stats.weekdayTotals(myCheckIns.map(\.day))

        return ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Button { model.router.push(.avatar) } label: {
                        AvatarView(config: me.avatar, size: 124)
                            .overlay(alignment: .bottomLeading) {
                                Image(systemName: "paintbrush.pointed.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Palette.onAccent)
                                    .frame(width: 30, height: 30)
                                    .background(Circle().fill(Palette.burgundy))
                            }
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("Customize avatar")
                    Text(me.name).font(.display(.title2, weight: .heavy)).foregroundStyle(Palette.ink)
                    Text("@\(me.handle)\(me.pronouns.isEmpty ? "" : " · \(me.pronouns)")").font(.subheadline).foregroundStyle(Palette.inkSecondary)
                    if !me.bio.isEmpty {
                        Text(me.bio).font(.hand(18)).foregroundStyle(Palette.ink.opacity(0.85)).multilineTextAlignment(.center)
                    }
                    if let personality = me.personality.map(Catalog.personality) {
                        Label(personality.name, systemImage: personality.symbol)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(personality.tint.onColor)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 8).fill(personality.tint.color))
                    }
                    HStack(spacing: 8) {
                        Button("Edit profile") { editing = true }.buttonStyle(InlineActionStyle())
                        Button { model.router.push(.gifts) } label: {
                            Label(unopenedGifts.isEmpty ? "Gifts" : "Gifts (\(unopenedGifts.count))", systemImage: unopenedGifts.isEmpty ? "gift" : "gift.fill")
                        }
                        .buttonStyle(InlineActionStyle(filled: !unopenedGifts.isEmpty))
                        Button { model.router.push(.share(.progress)) } label: { Label("Share", systemImage: "square.and.arrow.up") }
                            .buttonStyle(InlineActionStyle())
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .card()

                // Stats
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    StatTile(value: consistency?.percentText ?? "—", label: "Consistency score", symbol: "chart.line.uptrend.xyaxis", tint: .sage)
                    StatTile(value: "\(myCheckIns.count)", label: "Total completions", symbol: "checkmark.seal.fill", tint: .burgundy)
                    StatTile(value: "\(comebacks)", label: "Comebacks", symbol: "arrow.uturn.up.circle.fill", tint: .orange)
                    StatTile(value: "\(friends.count)", label: "Friends", symbol: "person.2.fill", tint: .sky)
                }

                // Showcase
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Eyebrow("Showcase")
                        Spacer()
                        Text("\(showcase.count)/\(AppModel.showcaseLimit)").font(.caption).foregroundStyle(Palette.inkFaint)
                    }
                    if showcase.isEmpty {
                        Text("Pin stickers from your Collection to show them off here.").font(.callout).foregroundStyle(Palette.inkSecondary)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: -4)], spacing: 4) {
                            ForEach(Array(showcase.enumerated()), id: \.element.key) { index, item in
                                StickerView(item, size: 78)
                                    .rotationEffect(.degrees(Double((index * 11) % 17) - 8))
                                    .accessibilityLabel(item.name)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                // Strongest days
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Strongest days")
                    let ordered = Day.orderedWeekdays()
                    Chart(ordered, id: \.self) { weekday in
                        BarMark(x: .value("Day", Day.shortName(forWeekday: weekday)), y: .value("Check-ins", weekdayTotals[weekday]))
                            .foregroundStyle(weekdayTotals[weekday] == weekdayTotals.max() ? Palette.burgundy : Palette.rose)
                            .cornerRadius(4)
                    }
                    .chartYAxis(.hidden)
                    .frame(height: 110)
                }
                .card()

                // Favorites
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow("Favorite habits")
                    ForEach(Array(favorites)) { habit in
                        Button { model.router.push(.habit(habit)) } label: {
                            HStack(spacing: 10) {
                                SymbolBadge(symbol: habit.symbol, tint: habit.tint, size: 32, filled: true)
                                Text(habit.name).font(.subheadline.weight(.semibold)).foregroundStyle(Palette.ink)
                                Spacer()
                                Text("\(habit.myCheckIns.count) stamps").font(.caption).foregroundStyle(Palette.inkSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Button { model.router.push(.calendar(nil)) } label: { Label("Full history", systemImage: "calendar") }
                        .buttonStyle(InlineActionStyle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                // Superlatives & recaps
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow("Superlatives & past recaps")
                    if !superlatives.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(superlatives) { item in
                                Label(item.name, systemImage: item.symbol)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(item.tint.onColor)
                                    .padding(.horizontal, 8).padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 7).fill(item.tint.color))
                            }
                        }
                    }
                    ForEach(recaps.prefix(3)) { PastRecapRow(recap: $0) }
                    Button("All recaps") { model.router.push(.recapArchive) }.buttonStyle(InlineActionStyle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                // Friends & groups
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow("Friends & groups")
                    AvatarStack(avatars: friends.map { ($0.id, $0.avatar, false) }, size: 34, maxShown: 6)
                    ForEach(groups) { group in
                        Button { model.router.push(.group(group)) } label: {
                            HStack(spacing: 10) {
                                SymbolBadge(symbol: group.symbol, tint: group.tint, size: 30)
                                Text(group.name).font(.subheadline.weight(.semibold)).foregroundStyle(Palette.ink)
                                Spacer()
                                Text("\(group.memberCount) members").font(.caption).foregroundStyle(Palette.inkSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    HStack {
                        Button { model.router.push(.groups) } label: { Label("Groups", systemImage: "person.3") }.buttonStyle(InlineActionStyle())
                        Button { model.router.push(.addFriends) } label: { Label("Add friends", systemImage: "person.badge.plus") }.buttonStyle(InlineActionStyle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                if me.reminderPasses + me.comebackBoosts + me.doubleReactionTokens > 0 {
                    HStack(spacing: 8) {
                        StatPill(value: "\(me.reminderPasses)", label: "reminder passes", tint: .sky)
                        StatPill(value: "\(me.comebackBoosts)", label: "comeback boosts", tint: .orange)
                        StatPill(value: "\(me.doubleReactionTokens)", label: "double reactions", tint: .rose)
                    }
                    .card(padding: 10)
                }
            }
            .padding(Metrics.gutter)
        }
        .background(PaperBackground())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { model.router.push(.settings) } label: { Image(systemName: "gearshape") }
                    .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $editing) { EditProfileSheet(profile: me) }
    }
}

struct EditProfileSheet: View {
    let profile: UserProfile
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var handle = ""
    @State private var bio = ""
    @State private var pronouns = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Display name", text: $name)
                    TextField("Handle", text: $handle).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Pronouns (optional)", text: $pronouns)
                }
                Section {
                    TextField("A line about you", text: $bio, axis: .vertical).lineLimit(2...4)
                } header: { Text("Bio") } footer: { Text("\(bio.count)/160") }
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        model.updateProfile(name: name, handle: handle, bio: bio, pronouns: pronouns)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || bio.count > 160)
                }
            }
            .onAppear {
                name = profile.name; handle = profile.handle; bio = profile.bio; pronouns = profile.pronouns
            }
        }
    }
}

struct GiftsInboxView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \Gift.createdAt, order: .reverse) private var gifts: [Gift]
    @Query private var friends: [Friend]

    var body: some View {
        let byID = Dictionary(friends.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let received = gifts.filter { $0.toID == nil }
        let sent = gifts.filter { $0.fromID == nil }
        List {
            Section {
                if received.isEmpty {
                    Text("No gifts yet.").foregroundStyle(Palette.inkSecondary).listRowBackground(Palette.card)
                }
                ForEach(received) { gift in
                    let sender = gift.fromID.flatMap { byID[$0] }
                    HStack(spacing: 12) {
                        SymbolBadge(symbol: gift.opened ? gift.kind.symbol : "gift.fill", tint: gift.kind.tint, size: 42, filled: !gift.opened)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(gift.opened ? gift.kind.label : "A gift from \(sender?.firstName ?? "a friend")")
                                .font(.subheadline.weight(.bold)).foregroundStyle(Palette.ink)
                            Text("“\(gift.message)”").font(.hand(15)).foregroundStyle(Palette.inkSecondary)
                            if gift.opened, let key = gift.itemKey { Text("Unlocked: \(itemName(key))").font(.caption).foregroundStyle(Palette.sage) }
                        }
                        Spacer()
                        if !gift.opened {
                            Button("Open") { model.open(gift) }.buttonStyle(InlineActionStyle(filled: true))
                        }
                    }
                    .listRowBackground(Palette.card)
                }
            } header: { Text("Received") } footer: { Text("Gifts are free power-ups and cosmetics from friends. Nothing in \(Brand.name) costs money.") }
            if !sent.isEmpty {
                Section("Sent") {
                    ForEach(sent) { gift in
                        HStack {
                            Image(systemName: gift.kind.symbol).foregroundStyle(gift.kind.tint.color)
                            Text("\(gift.kind.label) to \(gift.toID.flatMap { byID[$0]?.firstName } ?? "a friend")").font(.subheadline)
                            Spacer()
                            Text(Day.relative(gift.createdAt)).font(.caption).foregroundStyle(Palette.inkFaint)
                        }
                        .listRowBackground(Palette.card)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(PaperBackground())
        .navigationTitle("Gifts")
    }

    private func itemName(_ key: String) -> String {
        Catalog.cosmetics.first { $0.key == key }?.name ?? Catalog.collectible(key)?.name ?? key
    }
}
