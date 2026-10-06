import SwiftData
import SwiftUI

/// Create or edit a habit. Validates before saving and offers sensible defaults.
struct HabitFormView: View {
    let habit: Habit?
    var prefill: HabitDraft?

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Friend> { $0.statusRaw == "friend" }, sort: \Friend.name) private var friends: [Friend]

    @State private var draft = HabitDraft()
    @State private var original = HabitDraft()
    @State private var didLoad = false
    @State private var showErrors = false
    @State private var confirmDiscard = false
    @FocusState private var nameFocused: Bool

    private var isEditing: Bool { habit != nil }

    var body: some View {
        NavigationStack {
            Form {
                previewSection
                basicsSection
                scheduleSection
                reminderSection
                sharingSection
                detailsSection
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .navigationTitle(isEditing ? "Edit habit" : "New habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if draft != original { confirmDiscard = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .fontWeight(.bold)
                }
            }
            .confirmationDialog("Discard changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            }
            .interactiveDismissDisabled(draft != original)
            .onAppear(perform: load)
        }
    }

    // MARK: Sections

    private var previewSection: some View {
        Section {
            HStack(spacing: 12) {
                SymbolBadge(symbol: draft.symbol, tint: draft.tint, size: 50, filled: true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(draft.trimmedName.isEmpty ? "Your new habit" : draft.trimmedName)
                        .font(.display(.headline))
                        .foregroundStyle(draft.trimmedName.isEmpty ? Palette.inkFaint : Palette.ink)
                    Text("\(draft.rule.summary) · \(draft.timeOfDay == .anytime ? "Anytime" : draft.scheduledTime.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(Palette.inkSecondary)
                    if draft.isShared, !draft.participantIDs.isEmpty {
                        Text("With \(draft.participantIDs.count) friend\(draft.participantIDs.count == 1 ? "" : "s")")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(draft.tint.color)
                    }
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Preview")
        }
        .listRowBackground(draft.tint.color.opacity(0.12))
    }

    private var basicsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Name, e.g. Morning walk", text: $draft.name)
                    .font(.display(.body, weight: .semibold))
                    .focused($nameFocused)
                    .submitLabel(.done)
                if (showErrors || !draft.name.isEmpty), let error = draft.nameError {
                    FieldError(error)
                }
            }
            Picker("Category", selection: $draft.category) {
                ForEach(HabitCategory.allCases) { category in
                    Label(category.label, systemImage: category.defaultSymbol).tag(category)
                }
            }
            .onChange(of: draft.category) { _, category in
                if !category.symbolChoices.contains(draft.symbol) { draft.symbol = category.defaultSymbol }
                if !isEditing { draft.tint = category.defaultTint }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon").font(.subheadline).foregroundStyle(Palette.inkSecondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 8)], spacing: 8) {
                    ForEach(draft.category.symbolChoices, id: \.self) { symbol in
                        Button {
                            draft.symbol = symbol
                            model.feedback(.selection)
                        } label: {
                            SymbolBadge(symbol: symbol, tint: draft.tint, size: 44, filled: draft.symbol == symbol)
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(symbol.replacingOccurrences(of: ".", with: " "))
                        .accessibilityAddTraits(draft.symbol == symbol ? .isSelected : [])
                    }
                }
            }
            .padding(.vertical, 4)
            VStack(alignment: .leading, spacing: 6) {
                Text("Color").font(.subheadline).foregroundStyle(Palette.inkSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    TintPicker(selection: $draft.tint) { model.feedback(.selection) }
                }
            }
        } header: {
            Text("Basics")
        }
    }

    private var scheduleSection: some View {
        Section {
            Picker("Repeats", selection: $draft.frequency) {
                ForEach(Frequency.allCases) { Text($0.label).tag($0) }
            }
            if draft.frequency == .custom {
                WeekdayPicker(selection: $draft.weekdays)
                if showErrors, let error = draft.scheduleError { FieldError(error) }
            }
            if draft.frequency == .timesPerWeek {
                Stepper("\(draft.timesPerWeek)× a week", value: $draft.timesPerWeek, in: 1...7)
            }
            Picker("Time of day", selection: $draft.timeOfDay) {
                ForEach(TimeOfDay.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .onChange(of: draft.timeOfDay) { _, value in
                draft.scheduledTime = Day.date(Day.today, atMinutes: value.defaultMinutes)
                if !draft.reminderEnabled { draft.reminderTime = draft.scheduledTime }
            }
            if draft.timeOfDay != .anytime {
                DatePicker("Scheduled time", selection: $draft.scheduledTime, displayedComponents: .hourAndMinute)
            }
            DatePicker("Starts", selection: $draft.startDate, displayedComponents: .date)
            Toggle("Target date", isOn: $draft.hasTargetDate.animation())
            if draft.hasTargetDate {
                DatePicker("Finish by", selection: $draft.targetDate, in: Day.add(1, to: draft.startDate)..., displayedComponents: .date)
                if let error = draft.dateError { FieldError(error) }
            }
        } header: {
            Text("Schedule")
        } footer: {
            Text(draft.frequency == .timesPerWeek ? "Flexible habits can be done any day. They show under Optional until the week's target is met." : "Missing one scheduled day a week never lowers your consistency score.")
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle("Remind me", isOn: $draft.reminderEnabled.animation())
            if draft.reminderEnabled {
                DatePicker("Reminder time", selection: $draft.reminderTime, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Reminder")
        } footer: {
            if draft.reminderEnabled {
                Text("We'll ask for notification permission when you save, if we haven't already.")
            }
        }
    }

    private var sharingSection: some View {
        Section {
            Picker("Mode", selection: $draft.isShared.animation()) {
                Label("Solo", systemImage: "person.fill").tag(false)
                Label("Shared", systemImage: "person.2.fill").tag(true)
            }
            .pickerStyle(.segmented)
            if draft.isShared {
                if friends.isEmpty {
                    Text("Add friends from the Friends tab to share habits.")
                        .font(.footnote)
                        .foregroundStyle(Palette.inkSecondary)
                }
                ForEach(friends) { friend in
                    Button {
                        if draft.participantIDs.contains(friend.id) { draft.participantIDs.remove(friend.id) } else { draft.participantIDs.insert(friend.id) }
                        model.feedback(.selection)
                    } label: {
                        FriendPickRow(friend: friend, isSelected: draft.participantIDs.contains(friend.id))
                    }
                    .buttonStyle(.plain)
                }
                if showErrors, let error = draft.sharingError { FieldError(error) }
            }
            Picker("Who can see it", selection: $draft.privacy) {
                ForEach(Visibility.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
            }
        } header: {
            Text("Friends & privacy")
        }
    }

    private var detailsSection: some View {
        Section {
            TextField("Notes (optional)", text: $draft.notes, axis: .vertical)
                .lineLimit(2...4)
            Picker("Photo proof", selection: $draft.proof) {
                ForEach(ProofMode.allCases) { Text($0.label).tag($0) }
            }
            Toggle("Optional habit", isOn: $draft.isOptional)
            Toggle("Show streak", isOn: $draft.showStreak)
        } header: {
            Text("Details")
        } footer: {
            Text("Optional habits never count against your consistency. Streaks are always secondary to consistency.")
        }
    }

    // MARK: Actions

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        if let habit {
            draft = HabitDraft(habit: habit)
        } else if let prefill {
            draft = prefill
        } else {
            nameFocused = true
        }
        original = draft
    }

    private func save() {
        guard draft.isValid else {
            showErrors = true
            model.feedback(.error)
            return
        }
        if let habit {
            model.updateHabit(habit, from: draft)
        } else {
            _ = model.createHabit(from: draft)
        }
        dismiss()
    }
}

struct FieldError: View {
    let message: String

    init(_ message: String) { self.message = message }

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.footnote.weight(.medium))
            .foregroundStyle(Palette.burgundy)
            .accessibilityLabel("Error: \(message)")
    }
}

/// Seven toggles for choosing weekdays, ordered by the user's first weekday.
struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    @Environment(\.accent) private var accent

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Day.orderedWeekdays(), id: \.self) { weekday in
                let isOn = selection.contains(weekday)
                Button {
                    if isOn { selection.remove(weekday) } else { selection.insert(weekday) }
                } label: {
                    Text(String(Day.shortName(forWeekday: weekday).prefix(2)))
                        .font(.display(.footnote, weight: .bold))
                        .foregroundStyle(isOn ? Palette.onAccent : Palette.ink)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(RoundedRectangle(cornerRadius: 10).fill(isOn ? accent : Palette.paperDeep))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Day.longName(forWeekday: weekday))
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
