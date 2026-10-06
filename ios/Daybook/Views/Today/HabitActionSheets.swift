import PhotosUI
import SwiftData
import SwiftUI

/// Routes a `HabitSheet` to its view.
struct HabitSheetHost: View {
    let sheet: HabitSheet

    var body: some View {
        switch sheet {
        case .create: HabitFormView(habit: nil)
        case .edit(let habit): HabitFormView(habit: habit)
        case .note(let habit, let day): NoteSheet(habit: habit, day: day)
        case .photo(let habit, let day): PhotoProofSheet(habit: habit, day: day)
        case .reminder(let habit): ReminderSheet(habit: habit)
        case .invite(let habit): InviteFriendsSheet(habit: habit)
        }
    }
}

// MARK: - Note

struct NoteSheet: View {
    let habit: Habit
    let day: Date
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool
    private let limit = 140

    var body: some View {
        let isDone = habit.isCompleted(on: day)
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    SymbolBadge(symbol: habit.symbol, tint: habit.tint, size: 38, filled: isDone)
                    VStack(alignment: .leading) {
                        Text(habit.name).font(.display(.headline)).foregroundStyle(Palette.ink)
                        Text(day.formatted(.dateTime.weekday(.wide).month().day())).font(.caption).foregroundStyle(Palette.inkSecondary)
                    }
                }
                ZStack(alignment: .topLeading) {
                    RuledLines(spacing: 28, margin: true)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    TextField("How did it go?", text: $text, axis: .vertical)
                        .font(.hand(20, relativeTo: .body))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(4...6)
                        .focused($focused)
                        .padding(.leading, 36)
                        .padding(.top, 6)
                        .padding(.trailing, 10)
                        .onChange(of: text) { _, value in
                            if value.count > limit { text = String(value.prefix(limit)) }
                        }
                }
                .frame(minHeight: 150)
                .background(RoundedRectangle(cornerRadius: 14).fill(Palette.card))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.line))
                HStack {
                    if !isDone {
                        Label("Saving a note also checks in", systemImage: "checkmark.seal")
                            .font(.caption)
                            .foregroundStyle(Palette.inkSecondary)
                    }
                    Spacer()
                    Text("\(text.count)/\(limit)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(text.count >= limit ? Palette.orange : Palette.inkFaint)
                }
                FlowLayout(spacing: 6) {
                    ForEach(["Felt good", "Tiny version", "Hard, did it anyway", "With a friend"], id: \.self) { starter in
                        ChoiceChip(title: starter, isSelected: false) {
                            text = text.isEmpty ? starter : "\(text) \(starter.lowercased())"
                        }
                    }
                }
                Spacer()
            }
            .padding(Metrics.gutter)
            .background(PaperBackground())
            .navigationTitle("Quick note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isDone ? "Save" : "Save & check in") {
                        model.saveNote(text, for: habit, on: day)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                text = habit.myCheckIn(on: day)?.note ?? ""
                focused = true
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Photo proof

struct PhotoProofSheet: View {
    let habit: Habit
    let day: Date
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var selection: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isLoading = false
    @State private var loadFailed = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white)
                        .shadow(color: Palette.shadow.opacity(2), radius: 6, y: 4)
                    VStack(spacing: 10) {
                        Group {
                            if let imageData, let image = UIImage(data: imageData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                ZStack {
                                    Palette.paperDeep
                                    VStack(spacing: 8) {
                                        Image(systemName: isLoading ? "hourglass" : "photo.on.rectangle.angled")
                                            .font(.system(size: 34))
                                        Text(isLoading ? "Developing…" : "No photo yet")
                                            .font(.hand(18))
                                    }
                                    .foregroundStyle(Palette.inkSecondary)
                                }
                            }
                        }
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        Text(habit.name)
                            .font(.hand(20))
                            .foregroundStyle(Palette.ink)
                            .padding(.bottom, 14)
                    }
                    .padding([.top, .horizontal], 12)
                }
                .rotationEffect(.degrees(-1.5))
                .overlay(alignment: .top) { TapeStrip(tint: .rose, width: 70, rotation: 4).offset(y: -8) }
                .padding(.horizontal, 8)
                .accessibilityElement()
                .accessibilityLabel(imageData == nil ? "No photo selected" : "Selected photo for \(habit.name)")

                if loadFailed {
                    Label("That photo couldn't be loaded. Try another.", systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(Palette.orange)
                }

                PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                    Label(imageData == nil ? "Choose a photo" : "Choose a different photo", systemImage: "photo.badge.plus")
                }
                .buttonStyle(SecondaryButtonStyle())

                if habit.myCheckIn(on: day)?.hasPhoto == true {
                    Button(role: .destructive) {
                        model.savePhoto(nil, for: habit, on: day)
                        dismiss()
                    } label: {
                        Label("Remove photo", systemImage: "trash")
                    }
                    .buttonStyle(InlineActionStyle(tint: Palette.burgundy))
                }

                Text("Photos stay on this device. Shared cards hide them unless you choose otherwise.")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSecondary)
                    .multilineTextAlignment(.center)
                Spacer(minLength: 0)
            }
            .padding(Metrics.gutter)
            .background(PaperBackground())
            .navigationTitle("Photo proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Attach") {
                        model.savePhoto(imageData, for: habit, on: day)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(imageData == nil)
                }
            }
            .onAppear { imageData = habit.myCheckIn(on: day)?.photoData }
            .onChange(of: selection) { _, item in
                guard let item else { return }
                isLoading = true
                loadFailed = false
                Task {
                    let data = try? await item.loadTransferable(type: Data.self)
                    let resized = data.flatMap { ImageDownsampler.jpegData(from: $0, maxDimension: 1200) }
                    await MainActor.run {
                        isLoading = false
                        if let resized { imageData = resized } else { loadFailed = true }
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Reminder

struct ReminderSheet: View {
    let habit: Habit
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var enabled = false
    @State private var time = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Remind me", isOn: $enabled)
                    if enabled {
                        DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    }
                } footer: {
                    Text(enabled ? "Reminders follow this habit's schedule (\(habit.scheduleSummary.lowercased())). Quiet hours move them to the end of quiet time." : "You can still check in anytime.")
                }
                if model.prefs.quietHoursEnabled {
                    Section {
                        LabeledContent("Quiet hours", value: "\(Day.timeText(minutes: model.prefs.quietStartMinutes)) – \(Day.timeText(minutes: model.prefs.quietEndMinutes))")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .navigationTitle("Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        model.setReminder(habit, enabled: enabled, minutes: Day.minutesOfDay(time))
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                enabled = habit.reminderEnabled
                time = Day.date(Day.today, atMinutes: habit.reminderMinutes)
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Invite friends

struct InviteFriendsSheet: View {
    let habit: Habit
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Friend> { $0.statusRaw == "friend" }, sort: \Friend.name) private var friends: [Friend]
    @State private var selected: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(friends) { friend in
                        let already = habit.participantIDs.contains(friend.id)
                        Button {
                            guard !already else { return }
                            if selected.contains(friend.id) { selected.remove(friend.id) } else { selected.insert(friend.id) }
                            model.feedback(.selection)
                        } label: {
                            FriendPickRow(friend: friend, isSelected: already || selected.contains(friend.id), detail: already ? "Already in" : nil)
                        }
                        .buttonStyle(.plain)
                        .disabled(already)
                        .listRowBackground(Palette.card)
                    }
                } header: {
                    Text("Invite to “\(habit.name)”")
                } footer: {
                    Text("Friends see check-ins on this habit only. Your other habits stay private.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .overlay {
                if friends.isEmpty {
                    EmptyStateView(symbol: "person.2", title: "No friends yet", message: "Add friends from the Friends tab first.")
                }
            }
            .navigationTitle("Invite friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        model.invite(selected, to: habit)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(selected.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// Avatar + name row with a checkmark, used by friend pickers.
struct FriendPickRow: View {
    let friend: Friend
    let isSelected: Bool
    var detail: String?

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(config: friend.avatar, size: 40, showsCompanion: false)
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name).font(.display(.body, weight: .semibold)).foregroundStyle(Palette.ink)
                Text(detail ?? "@\(friend.handle)").font(.caption).foregroundStyle(Palette.inkSecondary)
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Palette.burgundy : Palette.line)
        }
        .frame(minHeight: 48)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
