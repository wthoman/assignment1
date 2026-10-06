import SwiftData
import SwiftUI

/// Sheets the Today tab can present for a habit.
enum HabitSheet: Identifiable {
    case create
    case edit(Habit)
    case note(Habit, Date)
    case photo(Habit, Date)
    case reminder(Habit)
    case invite(Habit)

    var id: String {
        switch self {
        case .create: "create"
        case .edit(let h): "edit-\(h.id)"
        case .note(let h, let d): "note-\(h.id)-\(d.timeIntervalSince1970)"
        case .photo(let h, let d): "photo-\(h.id)-\(d.timeIntervalSince1970)"
        case .reminder(let h): "reminder-\(h.id)"
        case .invite(let h): "invite-\(h.id)"
        }
    }
}

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var friends: [Friend]
    @Query(filter: #Predicate<NotificationItem> { !$0.isRead }) private var unread: [NotificationItem]

    @State private var selectedDate = Day.today
    @State private var sheet: HabitSheet?
    @State private var pendingDelete: Habit?
    @ScaledMetric(relativeTo: .title3) private var ringSize: CGFloat = 84

    var body: some View {
        let day = selectedDate
        let active = habits.filter { $0.status == .active && Day.start($0.startDate) <= day }
        let friendsByID = Dictionary(friends.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let sections = TodaySections(habits: active, day: day)
        let hiddenCount = habits.filter { $0.status != .active }.count

        List {
            header
                .plainRow(top: 4)
            WeekStrip(selection: $selectedDate, progress: { TodaySections(habits: active, day: $0).progress }, onSelect: {
                model.feedback(.selection)
            })
            .plainRow()
            progressCard(sections)
                .plainRow()

            if active.isEmpty {
                EmptyStateView(symbol: "square.and.pencil", title: "A fresh page",
                               message: "Add your first habit. Start small — tiny habits are the ones that stick.",
                               actionTitle: "Add a habit") { sheet = .create }
                    .plainRow()
            }

            habitSection("Up Next", subtitle: "Scheduled for \(dayLabel(day))", items: sections.upNext, friendsByID: friendsByID)
            habitSection("Shared Today", subtitle: "Friends are checking in too", items: sections.shared, friendsByID: friendsByID)
            habitSection("Completed", subtitle: nil, items: sections.completed, friendsByID: friendsByID)
            habitSection("Optional Today", subtitle: "Bonus points, never a penalty", items: sections.optional, friendsByID: friendsByID)

            footer(hiddenCount: hiddenCount)
                .plainRow(bottom: 24)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(PaperBackground())
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .refreshable {
            try? await Task.sleep(for: .milliseconds(400))
            selectedDate = Day.today
        }
        .sheet(item: $sheet) { sheet in
            HabitSheetHost(sheet: sheet)
        }
        .confirmationDialog("Delete this habit?", isPresented: Binding(isPresent: $pendingDelete), titleVisibility: .visible, presenting: pendingDelete) { habit in
            Button("Delete “\(habit.name)” and its history", role: .destructive) { model.delete(habit) }
            Button("Archive instead") { model.setStatus(.archived, for: habit) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("This removes every check-in, note and photo. Archiving keeps your history.")
        }
        .onChange(of: pendingDelete?.id) { _, value in
            if value != nil { model.feedback(.warning) }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                .font(.eyebrow)
                .tracking(1)
                .foregroundStyle(Palette.inkSecondary)
            Text(Encouragement.greeting(name: model.me?.name ?? "friend"))
                .font(.display(.title, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if selectedDate != Day.today {
                Button {
                    selectedDate = Day.today
                    model.feedback(.selection)
                } label: {
                    Label("Viewing \(selectedDate.formatted(.dateTime.weekday(.wide).month().day())) · Back to today", systemImage: "arrow.uturn.backward")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.burgundy)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func progressCard(_ sections: TodaySections) -> some View {
        let consistency = habits.overallConsistency()
        return AdaptiveStack(spacing: 16) {
            ZStack {
                ProgressRing(progress: sections.progress, lineWidth: 8)
                VStack(spacing: 0) {
                    Text(sections.progress.percentText)
                        .font(.display(.title3, weight: .heavy))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText(value: sections.progress))
                    Text("today")
                        .font(.caption2.weight(.semibold))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .foregroundStyle(Palette.inkSecondary)
                }
            }
            .frame(width: min(ringSize, 150), height: min(ringSize, 150))
            VStack(alignment: .leading, spacing: 6) {
                Text(Encouragement.dayMessage(style: model.prefs.encouragement, done: sections.requiredDone, total: sections.requiredTotal))
                    .font(.display(.subheadline, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("28-day consistency \(consistency?.percentText ?? "—")")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkSecondary)
                Text("One missed day a week is always forgiven.")
                    .font(.hand(14, relativeTo: .caption))
                    .foregroundStyle(Palette.burgundy.opacity(0.8))
            }
            Spacer(minLength: 0)
        }
        .card()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sections.requiredDone) of \(sections.requiredTotal) habits done today. 28-day consistency \(consistency?.percentText ?? "not available yet").")
    }

    // MARK: Sections

    @ViewBuilder
    private func habitSection(_ title: String, subtitle: String?, items: [Habit], friendsByID: [UUID: Friend]) -> some View {
        if !items.isEmpty {
            SectionHeader(title, subtitle: subtitle, count: items.count)
                .plainRow(top: 14, bottom: 2)
            ForEach(items) { habit in
                HabitCard(habit: habit, day: selectedDate, friendsByID: friendsByID, showStreaks: model.prefs.showStreaks,
                          onToggle: { model.toggleCompletion(habit, on: selectedDate) },
                          onOpen: {
                              model.feedback(.cardPress)
                              model.router.push(.habit(habit))
                          })
                    .plainRow(top: 5, bottom: 5)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            model.toggleCompletion(habit, on: selectedDate)
                        } label: {
                            Label(habit.isCompleted(on: selectedDate) ? "Undo" : "Done",
                                  systemImage: habit.isCompleted(on: selectedDate) ? "arrow.uturn.backward" : "checkmark")
                        }
                        .tint(habit.tint.color)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button { sheet = .note(habit, selectedDate) } label: { Label("Note", systemImage: "note.text") }
                            .tint(Palette.gold)
                        Button { model.router.push(.habit(habit)) } label: { Label("History", systemImage: "calendar") }
                            .tint(Palette.sage)
                    }
                    .contextMenu {
                        habitMenu(habit)
                    } preview: {
                        HabitPreviewCard(habit: habit)
                    }
            }
        }
    }

    @ViewBuilder
    private func habitMenu(_ habit: Habit) -> some View {
        let done = habit.isCompleted(on: selectedDate)
        Button { model.toggleCompletion(habit, on: selectedDate) } label: {
            Label(done ? "Undo check-in" : "Check in", systemImage: done ? "arrow.uturn.backward" : "checkmark.circle")
        }
        Button { sheet = .note(habit, selectedDate) } label: { Label("Add a note", systemImage: "note.text") }
        Button { sheet = .photo(habit, selectedDate) } label: { Label("Photo proof", systemImage: "camera") }
        Divider()
        Button { sheet = .edit(habit) } label: { Label("Edit habit", systemImage: "pencil") }
        Button { sheet = .reminder(habit) } label: { Label("Adjust reminder", systemImage: "bell") }
        Button { sheet = .invite(habit) } label: { Label("Invite friends", systemImage: "person.badge.plus") }
        Button { model.router.push(.habit(habit)) } label: { Label("Open history", systemImage: "calendar") }
        Divider()
        Button { model.setStatus(.paused, for: habit) } label: { Label("Pause", systemImage: "pause.circle") }
        Button { model.setStatus(.archived, for: habit) } label: { Label("Archive", systemImage: "archivebox") }
        Button(role: .destructive) { pendingDelete = habit } label: { Label("Delete…", systemImage: "trash") }
    }

    private func footer(hiddenCount: Int) -> some View {
        VStack(spacing: 10) {
            Button {
                sheet = .create
            } label: {
                Label("New habit", systemImage: "plus")
            }
            .buttonStyle(SecondaryButtonStyle())
            HStack(spacing: 12) {
                Button {
                    model.router.push(.calendar(nil))
                } label: {
                    Label("Month view", systemImage: "calendar")
                }
                .buttonStyle(InlineActionStyle())
                Button {
                    model.router.push(.manageHabits)
                } label: {
                    Label(hiddenCount > 0 ? "Paused & archived (\(hiddenCount))" : "Manage habits", systemImage: "tray.full")
                }
                .buttonStyle(InlineActionStyle())
            }
        }
        .padding(.top, 8)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                model.router.push(.profile)
            } label: {
                if let me = model.me {
                    AvatarView(config: me.avatar, size: 34, showsCompanion: false)
                } else {
                    Image(systemName: "person.crop.circle")
                }
            }
            .accessibilityLabel("Your profile")
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                model.router.push(.notifications)
            } label: {
                Image(systemName: unread.isEmpty ? "bell" : "bell.badge.fill")
                    .symbolRenderingMode(unread.isEmpty ? .monochrome : .palette)
                    .foregroundStyle(Palette.orange, Palette.burgundy)
            }
            .accessibilityLabel(unread.isEmpty ? "Notifications" : "Notifications, \(unread.count) unread")
            Button {
                sheet = .create
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .accessibilityLabel("New habit")
        }
    }

    private func dayLabel(_ day: Date) -> String {
        day == Day.today ? "today" : day.formatted(.dateTime.weekday(.wide))
    }
}

/// Groups the day's habits into Today sections.
struct TodaySections {
    var upNext: [Habit] = []
    var shared: [Habit] = []
    var completed: [Habit] = []
    var optional: [Habit] = []
    var requiredTotal = 0
    var requiredDone = 0

    init(habits: [Habit], day: Date) {
        for habit in habits {
            let done = habit.isCompleted(on: day)
            let flexible = habit.rule.isFlexible
            let scheduled = habit.isScheduled(on: day)
            let required = scheduled && !habit.isOptional && !flexible
            if required {
                requiredTotal += 1
                if done { requiredDone += 1 }
            }
            if done {
                completed.append(habit)
            } else if required {
                if habit.isShared { shared.append(habit) } else { upNext.append(habit) }
            } else if habit.isOptional && scheduled {
                optional.append(habit)
            } else if flexible {
                let weekDone = Day.week(containing: day).filter { habit.isCompleted(on: $0) }.count
                if weekDone < habit.rule.timesPerWeek { optional.append(habit) }
            }
        }
        upNext.sort { $0.scheduledMinutes < $1.scheduledMinutes }
        shared.sort { $0.scheduledMinutes < $1.scheduledMinutes }
        completed.sort { ($0.myCheckIn(on: day)?.completedAt ?? .distantPast) > ($1.myCheckIn(on: day)?.completedAt ?? .distantPast) }
    }

    var progress: Double {
        requiredTotal == 0 ? (completed.isEmpty ? 0 : 1) : Double(requiredDone) / Double(requiredTotal)
    }
}

/// Long-press preview: a bigger look at the habit's recent history.
struct HabitPreviewCard: View {
    let habit: Habit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                SymbolBadge(symbol: habit.symbol, tint: habit.tint, size: 52, filled: true)
                VStack(alignment: .leading) {
                    Text(habit.name).font(.display(.title3)).foregroundStyle(Palette.ink)
                    Text(habit.scheduleSummary).font(.subheadline).foregroundStyle(Palette.inkSecondary)
                }
            }
            WeekDots(days: Day.lastDays(14, endingOn: Day.today), isDone: { habit.isCompleted(on: $0) },
                     isScheduled: { habit.rule.isFlexible || habit.isScheduled(on: $0) }, tint: habit.tint, cell: 16)
            HStack(spacing: 18) {
                stat(habit.rollingConsistency?.percentText ?? "—", "consistency")
                stat("\(habit.myCheckIns.count)", "check-ins")
                stat("\(habit.comebackCount)", "comebacks")
            }
        }
        .padding(18)
        .frame(width: 320)
        .background(Palette.card)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading) {
            Text(value).font(.display(.title3, weight: .heavy)).foregroundStyle(Palette.ink)
            Text(label).font(.caption).foregroundStyle(Palette.inkSecondary)
        }
    }
}

extension View {
    /// List row with no separator or background, for card layouts inside a plain List.
    func plainRow(top: CGFloat = 6, bottom: CGFloat = 6) -> some View {
        listRowInsets(EdgeInsets(top: top, leading: Metrics.gutter, bottom: bottom, trailing: Metrics.gutter))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
