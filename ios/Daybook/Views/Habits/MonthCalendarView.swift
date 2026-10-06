import SwiftData
import SwiftUI

/// Monthly history: colored dots per completed habit, stamped days when everything was done.
struct MonthCalendarView: View {
    let focusHabit: Habit?
    @Environment(AppModel.self) private var model
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var selectedDay: Date? = Day.today
    @State private var filter: Habit?
    @State private var didLoad = false

    var body: some View {
        let shown = filter.map { [$0] } ?? habits.filter { $0.status != .archived }
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MonthGrid(focusHabit: filter, habits: shown, selectedDay: $selectedDay, compact: false)
                    .card()
                legend(shown)
                if let day = selectedDay {
                    dayDetail(day, habits: shown)
                }
            }
            .padding(Metrics.gutter)
        }
        .background(PaperBackground())
        .navigationTitle(filter?.name ?? "Month")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { filter = nil } label: { Label("All habits", systemImage: filter == nil ? "checkmark" : "square.grid.2x2") }
                    Divider()
                    ForEach(habits.filter { $0.status != .archived }) { habit in
                        Button { filter = habit } label: {
                            Label(habit.name, systemImage: filter?.id == habit.id ? "checkmark" : habit.symbol)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Filter habits")
            }
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            filter = focusHabit
        }
    }

    private func legend(_ shown: [Habit]) -> some View {
        FlowLayout(spacing: 10, lineSpacing: 6) {
            ForEach(shown.prefix(10)) { habit in
                HStack(spacing: 5) {
                    Circle().fill(habit.tint.color).frame(width: 9, height: 9)
                    Text(habit.name).font(.caption).foregroundStyle(Palette.inkSecondary)
                }
            }
            HStack(spacing: 5) {
                Circle().strokeBorder(Palette.burgundy, lineWidth: 1.5).frame(width: 12, height: 12)
                Text("Everything stamped").font(.caption).foregroundStyle(Palette.inkSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Legend")
    }

    private func dayDetail(_ day: Date, habits: [Habit]) -> some View {
        let relevant = habits.filter { $0.isCompleted(on: day) || ($0.isScheduled(on: day) && $0.status == .active) }
        return VStack(alignment: .leading, spacing: 10) {
            Eyebrow(day.formatted(.dateTime.weekday(.wide).month(.wide).day()))
            if relevant.isEmpty {
                Text("Nothing scheduled. A rest day.").font(.callout).foregroundStyle(Palette.inkSecondary)
            }
            ForEach(relevant) { habit in
                let checkIn = habit.myCheckIn(on: day)
                HStack(spacing: 10) {
                    SymbolBadge(symbol: habit.symbol, tint: habit.tint, size: 32, filled: checkIn != nil)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name).font(.subheadline.weight(.semibold)).foregroundStyle(Palette.ink)
                        if let checkIn {
                            Text(checkIn.isComeback ? "Comeback at \(checkIn.completedAt.formatted(date: .omitted, time: .shortened))" : "Done at \(checkIn.completedAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption).foregroundStyle(Palette.inkSecondary)
                            if checkIn.hasNote { Text(checkIn.note).font(.hand(15)).foregroundStyle(Palette.inkSecondary) }
                        } else {
                            Text(day < Day.today ? "Not this time — that's okay." : "Not yet").font(.caption).foregroundStyle(Palette.inkFaint)
                        }
                    }
                    Spacer()
                    if day <= Day.today, habit.status == .active {
                        Button {
                            model.toggleCompletion(habit, on: day)
                        } label: {
                            Text(checkIn == nil ? "Log" : "Undo")
                        }
                        .buttonStyle(InlineActionStyle(tint: habit.tint.color, filled: checkIn == nil))
                        .accessibilityLabel(checkIn == nil ? "Log \(habit.name) for this day" : "Undo \(habit.name) for this day")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

/// Reusable month grid.
struct MonthGrid: View {
    let focusHabit: Habit?
    let habits: [Habit]
    @Binding var selectedDay: Date?
    var compact = false

    @Environment(AppModel.self) private var model
    @Environment(\.accent) private var accent
    @State private var month = Day.startOfMonth(Day.today)

    var body: some View {
        let days = monthDays
        VStack(spacing: 10) {
            HStack {
                Button { shift(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .accessibilityLabel("Previous month")
                Spacer()
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.display(.headline))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Button { shift(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .disabled(month >= Day.startOfMonth(Day.today))
                    .accessibilityLabel("Next month")
            }
            .buttonStyle(.plain)
            .foregroundStyle(accent)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(Day.orderedVeryShortSymbols().enumerated()), id: \.offset) { _, symbol in
                    Text(symbol).font(.caption2.weight(.bold)).foregroundStyle(Palette.inkFaint)
                }
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: compact ? 34 : 46)
                    }
                }
            }
        }
        .gesture(DragGesture(minimumDistance: 30).onEnded { value in
            if value.translation.width < -40 { shift(1) } else if value.translation.width > 40 { shift(-1) }
        })
    }

    private var monthDays: [Date?] {
        let calendar = Day.calendar
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let firstWeekday = Day.weekday(month)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leading) + range.map { Day.add($0 - 1, to: month) }
    }

    private func shift(_ months: Int) {
        guard let next = Day.calendar.date(byAdding: .month, value: months, to: month) else { return }
        if next > Day.startOfMonth(Day.today) { return }
        month = Day.startOfMonth(next)
        model.feedback(.selection)
    }

    private func dayCell(_ day: Date) -> some View {
        let done = habits.filter { $0.isCompleted(on: day) }
        let required = habits.filter { $0.status == .active && !$0.isOptional && !$0.rule.isFlexible && $0.isScheduled(on: day) }
        let allDone = !required.isEmpty && required.allSatisfy { $0.isCompleted(on: day) } && day <= Day.today
        let isSelected = selectedDay == day
        let isFuture = day > Day.today
        let height: CGFloat = compact ? 34 : 46
        return Button {
            guard !isFuture else { return }
            selectedDay = day
            model.feedback(.selection)
        } label: {
            VStack(spacing: 3) {
                Text(day.formatted(.dateTime.day()))
                    .font(.system(.caption, design: .rounded, weight: day == Day.today ? .heavy : .semibold))
                    .foregroundStyle(focusHabit != nil && !done.isEmpty ? (focusHabit?.tint.onColor ?? Palette.ink) : (isFuture ? Palette.inkFaint : Palette.ink))
                if focusHabit == nil, !compact {
                    HStack(spacing: 2) {
                        ForEach(done.prefix(4)) { habit in
                            Circle().fill(habit.tint.color).frame(width: 5, height: 5)
                        }
                    }
                    .frame(height: 5)
                }
            }
            .frame(maxWidth: .infinity, minHeight: height)
            .background {
                if let focus = focusHabit {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(done.isEmpty ? Color.clear : focus.tint.color)
                        .overlay {
                            if done.isEmpty, focus.isScheduled(on: day), day < Day.today, day >= Day.start(focus.startDate) {
                                RoundedRectangle(cornerRadius: 8).strokeBorder(Palette.line, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                            }
                        }
                }
            }
            .overlay {
                if allDone, focusHabit == nil {
                    Circle().strokeBorder(Palette.burgundy.opacity(0.75), lineWidth: 1.5)
                        .rotationEffect(.degrees(-12))
                        .padding(1)
                }
                if isSelected {
                    RoundedRectangle(cornerRadius: 8).strokeBorder(accent, lineWidth: 2)
                }
                if focusHabit != nil, focusHabit?.myCheckIn(on: day)?.isComeback == true {
                    Image(systemName: "arrow.uturn.up").font(.system(size: 8, weight: .black)).foregroundStyle(Palette.onAccent)
                        .offset(x: 12, y: -12)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).month().day()))
        .accessibilityValue(done.isEmpty ? "No check-ins" : "\(done.count) completed" + (allDone ? ", everything done" : ""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Paused and archived habits, plus reordering.
struct ManageHabitsView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var pendingDelete: Habit?
    @State private var sheet: HabitSheet?

    var body: some View {
        List {
            Section {
                ForEach(habits.filter { $0.status == .active }) { habit in
                    row(habit)
                }
                .onMove { source, destination in
                    var active = habits.filter { $0.status == .active }
                    active.move(fromOffsets: source, toOffset: destination)
                    model.moveHabits(active + habits.filter { $0.status != .active })
                }
            } header: {
                Text("Active")
            } footer: {
                Text("Drag to reorder how habits appear on Today.")
            }
            let paused = habits.filter { $0.status == .paused }
            if !paused.isEmpty {
                Section("Paused") {
                    ForEach(paused) { habit in
                        row(habit)
                            .swipeActions {
                                Button { model.setStatus(.active, for: habit) } label: { Label("Resume", systemImage: "play.fill") }
                                    .tint(Palette.sage)
                            }
                    }
                }
            }
            let archived = habits.filter { $0.status == .archived }
            if !archived.isEmpty {
                Section("Archived") {
                    ForEach(archived) { habit in
                        row(habit)
                            .swipeActions {
                                Button { model.setStatus(.active, for: habit) } label: { Label("Restore", systemImage: "tray.and.arrow.up.fill") }
                                    .tint(Palette.sage)
                            }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(PaperBackground())
        .navigationTitle("Your habits")
        .toolbar {
            EditButton()
            Button { sheet = .create } label: { Image(systemName: "plus") }.accessibilityLabel("New habit")
        }
        .sheet(item: $sheet) { HabitSheetHost(sheet: $0) }
        .confirmationDialog("Delete this habit?", isPresented: Binding(isPresent: $pendingDelete), titleVisibility: .visible, presenting: pendingDelete) { habit in
            Button("Delete “\(habit.name)”", role: .destructive) { model.delete(habit) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in Text("Its whole history will be removed.") }
    }

    private func row(_ habit: Habit) -> some View {
        Button { model.router.push(.habit(habit)) } label: {
            HStack(spacing: 12) {
                SymbolBadge(symbol: habit.symbol, tint: habit.tint, size: 36, filled: habit.status == .active)
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name).font(.display(.body, weight: .semibold)).foregroundStyle(Palette.ink)
                    Text(habit.scheduleSummary).font(.caption).foregroundStyle(Palette.inkSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Palette.inkFaint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Palette.card)
        .contextMenu {
            if habit.status != .active {
                Button { model.setStatus(.active, for: habit) } label: { Label("Resume", systemImage: "play.circle") }
            } else {
                Button { model.setStatus(.paused, for: habit) } label: { Label("Pause", systemImage: "pause.circle") }
                Button { model.setStatus(.archived, for: habit) } label: { Label("Archive", systemImage: "archivebox") }
            }
            Button(role: .destructive) {
                model.feedback(.warning)
                pendingDelete = habit
            } label: { Label("Delete…", systemImage: "trash") }
        }
    }
}
