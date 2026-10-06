import SwiftData
import SwiftUI

// MARK: - Reactions

struct ReactionSheet: View {
    let item: ActivityItem
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var choice: ReactionKind?

    var body: some View {
        VStack(spacing: 18) {
            Text("Send a reaction")
                .font(.display(.title3))
                .foregroundStyle(Palette.ink)
                .padding(.top, 22)
            Text(item.title)
                .font(.subheadline)
                .foregroundStyle(Palette.inkSecondary)
            HStack(spacing: 10) {
                ForEach(ReactionKind.allCases) { kind in
                    let selected = choice == kind
                    Button {
                        choice = kind
                        model.feedback(.selection)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: kind.symbol)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(selected ? kind.tint.onColor : kind.tint.color)
                                .frame(width: 56, height: 56)
                                .background(
                                    ScallopShape(bumps: 10, depth: 0.06)
                                        .fill(selected ? kind.tint.color : kind.tint.color.opacity(0.15))
                                )
                                .scaleEffect(selected ? 1.12 : 1)
                                .animation(.spring(response: 0.25, dampingFraction: 0.55), value: selected)
                            Text(kind.label)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Palette.inkSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(kind.label)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.horizontal, Metrics.gutter)
            Button {
                if let choice { model.react(choice, to: item) }
                dismiss()
            } label: {
                Text(item.myReaction()?.kind == choice ? "Remove reaction" : "Send")
            }
            .buttonStyle(PrimaryButtonStyle(tint: choice?.tint.color))
            .disabled(choice == nil)
            .padding(.horizontal, Metrics.gutter)
            Spacer(minLength: 0)
        }
        .background(PaperBackground())
        .onAppear { choice = item.myReaction()?.kind }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Comments

struct CommentSheet: View {
    let item: ActivityItem
    @Environment(AppModel.self) private var model
    @Query private var friends: [Friend]
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        let byID = Dictionary(friends.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if item.comments.isEmpty {
                            Text("No comments yet. Be the first to say something kind.")
                                .font(.callout)
                                .foregroundStyle(Palette.inkSecondary)
                                .padding(.top, 20)
                        }
                        ForEach(item.comments.sorted { $0.createdAt < $1.createdAt }) { comment in
                            let author = comment.authorID.flatMap { byID[$0] }
                            HStack(alignment: .top, spacing: 10) {
                                if let avatar = author?.avatar ?? (comment.authorID == nil ? model.me?.avatar : nil) {
                                    AvatarView(config: avatar, size: 32, showsCompanion: false)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(author?.firstName ?? "You").font(.caption.weight(.bold)).foregroundStyle(Palette.ink)
                                    Text(comment.text).font(.callout).foregroundStyle(Palette.ink)
                                    Text(Day.relative(comment.createdAt)).font(.caption2).foregroundStyle(Palette.inkFaint)
                                }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Palette.card))
                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(Metrics.gutter)
                }
                VStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Catalog.commentStarters, id: \.self) { starter in
                                ChoiceChip(title: starter, isSelected: false) { text = starter }
                            }
                        }
                    }
                    HStack(spacing: 8) {
                        TextField("Say something kind…", text: $text, axis: .vertical)
                            .lineLimit(1...3)
                            .focused($focused)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Palette.card))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.line))
                            .onChange(of: text) { _, value in if value.count > 140 { text = String(value.prefix(140)) } }
                        Button {
                            model.comment(text, on: item)
                            text = ""
                        } label: {
                            Image(systemName: "arrow.up.circle.fill").font(.system(size: 34))
                        }
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityLabel("Send comment")
                    }
                }
                .padding(Metrics.gutter)
                .background(Palette.paperDeep.opacity(0.6))
            }
            .background(PaperBackground())
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Reminder

struct SendReminderSheet: View {
    let friend: Friend
    let habitName: String
    let item: ActivityItem?
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var message = Catalog.reminderTemplates[0]
    @State private var habit = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        AvatarView(config: friend.avatar, size: 48)
                        VStack(alignment: .leading) {
                            Text("To \(friend.firstName)").font(.display(.headline)).foregroundStyle(Palette.ink)
                            Text(friend.allowsReminders ? "Reminders are welcome" : "\(friend.firstName) has reminders turned off")
                                .font(.caption).foregroundStyle(Palette.inkSecondary)
                        }
                    }
                }
                Section("About") {
                    TextField("Habit", text: $habit)
                    if !friend.favoriteHabits.isEmpty {
                        Picker("Their habits", selection: $habit) {
                            ForEach(([habitName] + friend.favoriteHabits).uniqued(), id: \.self) { Text($0).tag($0) }
                        }
                    }
                }
                Section("Message") {
                    ForEach(Catalog.reminderTemplates, id: \.self) { template in
                        Button {
                            message = template
                            model.feedback(.selection)
                        } label: {
                            HStack {
                                Text(template).foregroundStyle(Palette.ink)
                                Spacer()
                                if message == template { Image(systemName: "checkmark").foregroundStyle(Palette.burgundy) }
                            }
                        }
                    }
                    TextField("Or write your own", text: $message, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .navigationTitle("Supportive reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        model.sendReminder(to: friend, habitName: habit.isEmpty ? "their habit" : habit, message: message, from: item)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(message.trimmingCharacters(in: .whitespaces).isEmpty || !friend.allowsReminders)
                }
            }
            .onAppear { habit = habitName }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Gift

struct GiftSheet: View {
    let friend: Friend
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<CosmeticItem> { $0.isUnlocked }, sort: \CosmeticItem.name) private var cosmetics: [CosmeticItem]
    @Query(filter: #Predicate<Collectible> { $0.isUnlocked }, sort: \Collectible.sortIndex) private var stickers: [Collectible]
    @State private var kind: GiftKind = .reminderPass
    @State private var itemKey: String?
    @State private var message = "Thought you could use this!"

    private var needsItem: Bool { kind == .cosmetic || kind == .sticker }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(GiftKind.allCases) { option in
                        Button {
                            kind = option
                            itemKey = nil
                            model.feedback(.selection)
                        } label: {
                            HStack(spacing: 12) {
                                SymbolBadge(symbol: option.symbol, tint: option.tint, size: 38, filled: kind == option)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.label).font(.display(.subheadline, weight: .semibold)).foregroundStyle(Palette.ink)
                                    Text(option.detail).font(.caption).foregroundStyle(Palette.inkSecondary)
                                }
                                Spacer()
                                if kind == option { Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.burgundy) }
                            }
                        }
                        .accessibilityAddTraits(kind == option ? .isSelected : [])
                    }
                } header: {
                    Text("For \(friend.firstName)")
                } footer: {
                    Text("Gifts are free and just for fun. There's nothing to buy in \(Brand.name).")
                }
                if kind == .cosmetic {
                    Section("Pick an item") {
                        Picker("Item", selection: $itemKey) {
                            Text("Choose…").tag(String?.none)
                            ForEach(cosmetics.filter { $0.value != "none" }) { Text("\($0.name) (\($0.slot.label))").tag(Optional($0.key)) }
                        }
                    }
                }
                if kind == .sticker {
                    Section("Pick a sticker") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 64))], spacing: 10) {
                            ForEach(stickers.filter { $0.category != .superlative }) { sticker in
                                Button {
                                    itemKey = sticker.key
                                    model.feedback(.selection)
                                } label: {
                                    StickerView(sticker, size: 56)
                                        .padding(4)
                                        .background(RoundedRectangle(cornerRadius: 10).strokeBorder(itemKey == sticker.key ? Palette.burgundy : .clear, lineWidth: 2))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(sticker.name)
                                .accessibilityAddTraits(itemKey == sticker.key ? .isSelected : [])
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section("Note") {
                    TextField("Message", text: $message, axis: .vertical).lineLimit(1...3)
                }
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .navigationTitle("Send a gift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        model.sendGift(kind, to: friend, itemKey: itemKey, message: message)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(needsItem && itemKey == nil)
                }
            }
        }
    }
}

// MARK: - Invite friend into one of my habits

struct InviteToHabitSheet: View {
    let friend: Friend
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Habit> { $0.statusRaw == "active" }, sort: \Habit.sortOrder) private var habits: [Habit]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(habits.filter { $0.privacy != .onlyMe }) { habit in
                        let already = habit.participantIDs.contains(friend.id)
                        Button {
                            model.invite([friend.id], to: habit)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                SymbolBadge(symbol: habit.symbol, tint: habit.tint, size: 36)
                                VStack(alignment: .leading) {
                                    Text(habit.name).font(.display(.body, weight: .semibold)).foregroundStyle(Palette.ink)
                                    Text(already ? "\(friend.firstName) is already in" : habit.scheduleSummary).font(.caption).foregroundStyle(Palette.inkSecondary)
                                }
                                Spacer()
                                Image(systemName: already ? "checkmark.circle.fill" : "paperplane").foregroundStyle(Palette.burgundy)
                            }
                        }
                        .disabled(already)
                        .listRowBackground(Palette.card)
                    }
                } footer: {
                    Text("Private habits aren't listed.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .navigationTitle("Invite \(friend.firstName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}
