import Charts
import SwiftData
import SwiftUI

/// History and stats for one habit.
struct HabitDetailView: View {
    let habit: Habit
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Query private var friends: [Friend]
    @State private var sheet: HabitSheet?
    @State private var confirmDelete = false

    var body: some View {
        if habit.modelContext == nil || habit.isDeleted {
            EmptyStateView(symbol: "trash", title: "Habit deleted", message: "This habit no longer exists.")
                .background(PaperBackground())
        } else {
            content
        }
    }

    private var content: some View {
        let friendsByID = Dictionary(friends.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                statsGrid
                weeklyChart
                MonthGrid(focusHabit: habit, habits: [habit], selectedDay: .constant(nil), compact: true)
                    .card()
                if habit.isShared {
                    sharedProgress(friendsByID: friendsByID)
                }
                recentCheckIns
                actions
            }
            .padding(Metrics.gutter)
        }
        .background(PaperBackground())
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { sheet = .edit(habit) } label: { Label("Edit", systemImage: "pencil") }
                    Button { sheet = .reminder(habit) } label: { Label("Reminder", systemImage: "bell") }
                    Button { sheet = .invite(habit) } label: { Label("Invite friends", systemImage: "person.badge.plus") }
                    Button { model.router.push(.share(.completion)) } label: { Label("Share", systemImage: "square.and.arrow.up") }
                    Divider()
                    if habit.status == .active {
                        Button { model.setStatus(.paused, for: habit) } label: { Label("Pause", systemImage: "pause.circle") }
                        Button { model.setStatus(.archived, for: habit) } label: { Label("Archive", systemImage: "archivebox") }
                    } else {
                        Button { model.setStatus(.active, for: habit) } label: { Label("Resume", systemImage: "play.circle") }
                    }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete…", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Habit actions")
            }
        }
        .sheet(item: $sheet) { HabitSheetHost(sheet: $0) }
        .confirmationDialog("Delete “\(habit.name)”?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete habit and history", role: .destructive) {
                model.delete(habit)
                dismiss()
            }
            Button("Archive instead") { model.setStatus(.archived, for: habit) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
        .onChange(of: confirmDelete) { _, value in if value { model.feedback(.warning) } }
    }

    private var headerCard: some View {
        let done = habit.isCompleted(on: Day.today)
        return HStack(spacing: 14) {
            SymbolBadge(symbol: habit.symbol, tint: habit.tint, size: 60, filled: done)
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name).font(.display(.title2, weight: .heavy)).foregroundStyle(Palette.ink)
                Text("\(habit.category.label) · \(habit.scheduleSummary)").font(.subheadline).foregroundStyle(Palette.inkSecondary)
                if habit.status != .active {
                    Text(habit.status == .paused ? "Paused" : "Archived")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Palette.paperDeep))
                } else if !habit.notes.isEmpty {
                    Text(habit.notes).font(.hand(16)).foregroundStyle(Palette.burgundy.opacity(0.85))
                }
            }
            Spacer(minLength: 0)
            if habit.status == .active, habit.isScheduled(on: Day.today) || habit.rule.isFlexible || habit.isOptional {
                CompletionStamp(isDone: done, tint: habit.tint, habitName: habit.name) {
                    model.toggleCompletion(habit)
                }
            }
        }
        .card(tint: habit.tint, emphasized: done)
    }

    private var statsGrid: some View {
        let streak = habit.currentStreak
        let showStreak = model.prefs.showStreaks && habit.showStreak
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            StatTile(value: habit.rollingConsistency?.percentText ?? "—", label: "28-day consistency", symbol: "chart.line.uptrend.xyaxis", tint: .sage)
            StatTile(value: "\(habit.myCheckIns.count)", label: "Total check-ins", symbol: "checkmark.seal.fill", tint: habit.tint)
            StatTile(value: "\(habit.comebackCount)", label: "Comebacks", symbol: "arrow.uturn.up.circle.fill", tint: .orange)
            if showStreak {
                StatTile(value: streak.label, label: "Current streak · best \(habit.bestStreak)", symbol: "flame.fill", tint: .gold)
            } else {
                StatTile(value: "\(Day.between(habit.startDate, Day.today) + 1)", label: "Days on the page", symbol: "book.pages.fill", tint: .gold)
            }
        }
    }

    private var weeklyChart: some View {
        let weeks = (0..<8).reversed().map { offset -> (Date, Int) in
            let start = Day.add(-7 * offset, to: Day.startOfWeek(Day.today))
            let count = (0..<7).map { Day.add($0, to: start) }.filter { habit.isCompleted(on: $0) }.count
            return (start, count)
        }
        return VStack(alignment: .leading, spacing: 8) {
            Eyebrow("Last 8 weeks")
            Chart(weeks, id: \.0) { week in
                BarMark(x: .value("Week", week.0, unit: .weekOfYear), y: .value("Check-ins", week.1))
                    .foregroundStyle(habit.tint.color.gradient)
                    .cornerRadius(5)
            }
            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) }
            .chartXAxis { AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated).day()) } }
            .frame(height: 140)
            .accessibilityLabel("Weekly check-ins chart")
            .accessibilityValue(weeks.map { "\($0.1)" }.joined(separator: ", "))
        }
        .card()
    }

    private func sharedProgress(friendsByID: [UUID: Friend]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Together this week")
            let week = Day.week(containing: Day.today).filter { $0 <= Day.today }
            row(name: "You", avatar: model.me?.avatar, count: week.filter { habit.isCompleted(on: $0) }.count, total: week.count)
            ForEach(habit.participantIDs, id: \.self) { id in
                if let friend = friendsByID[id] {
                    Button { model.router.push(.friend(friend)) } label: {
                        row(name: friend.firstName, avatar: friend.avatar, count: week.filter { habit.friendCompleted(id, on: $0) }.count, total: week.count)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .card()
    }

    private func row(name: String, avatar: AvatarConfig?, count: Int, total: Int) -> some View {
        HStack(spacing: 10) {
            if let avatar { AvatarView(config: avatar, size: 32, showsCompanion: false) }
            Text(name).font(.display(.subheadline, weight: .semibold)).foregroundStyle(Palette.ink).frame(width: 64, alignment: .leading)
            ProgressBar(progress: total == 0 ? 0 : Double(count) / Double(total), tint: habit.tint.color, height: 8)
            Text("\(count)/\(total)").font(.caption.monospacedDigit()).foregroundStyle(Palette.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var recentCheckIns: some View {
        let recent = habit.myCheckIns.sorted { $0.day > $1.day }.prefix(10)
        return VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Recent check-ins")
            if recent.isEmpty {
                Text("No check-ins yet. The first one is the best one.")
                    .font(.callout).foregroundStyle(Palette.inkSecondary)
            }
            ForEach(Array(recent)) { checkIn in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: checkIn.isComeback ? "arrow.uturn.up.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(checkIn.isComeback ? Palette.orange : habit.tint.color)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(checkIn.day.formatted(.dateTime.weekday(.abbreviated).month().day()))
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Palette.ink)
                        + Text("  \(checkIn.completedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption).foregroundStyle(Palette.inkSecondary)
                        if checkIn.isComeback {
                            Text("Comeback!").font(.caption.weight(.bold)).foregroundStyle(Palette.orange)
                        }
                        if checkIn.hasNote {
                            Text(checkIn.note).font(.hand(16)).foregroundStyle(Palette.inkSecondary)
                        }
                    }
                    Spacer()
                    if let data = checkIn.photoData, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .rotationEffect(.degrees(3))
                            .accessibilityLabel("Photo proof")
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var actions: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button { sheet = .note(habit, Day.today) } label: { Label("Note", systemImage: "note.text") }
                    .buttonStyle(SecondaryButtonStyle())
                Button { sheet = .photo(habit, Day.today) } label: { Label("Photo", systemImage: "camera") }
                    .buttonStyle(SecondaryButtonStyle())
            }
            Button { model.router.push(.calendar(habit)) } label: { Label("Full calendar", systemImage: "calendar") }
                .buttonStyle(SecondaryButtonStyle())
        }
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let symbol: String
    var tint: TintToken = .burgundy

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.footnote.weight(.bold))
                .foregroundStyle(tint == .cream ? Palette.inkSecondary : tint.color)
            Text(value)
                .font(.display(.title2, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(Palette.inkSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 12)
        .accessibilityElement(children: .combine)
    }
}
