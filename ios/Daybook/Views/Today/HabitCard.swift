import SwiftUI

/// A compact habit card with a one-tap completion stamp.
struct HabitCard: View {
    let habit: Habit
    let day: Date
    let friendsByID: [UUID: Friend]
    var showStreaks = true
    let onToggle: () -> Void
    let onOpen: () -> Void

    @Environment(\.cardDensity) private var density

    private var isDone: Bool { habit.isCompleted(on: day) }

    var body: some View {
        let checkIn = habit.myCheckIn(on: day)
        HStack(alignment: .center, spacing: 10) {
            Button(action: onOpen) {
                HStack(alignment: .top, spacing: 12) {
                    SymbolBadge(symbol: habit.symbol, tint: habit.tint, size: density == .compact ? 40 : 46, filled: isDone)
                    VStack(alignment: .leading, spacing: density == .compact ? 4 : 6) {
                        Text(habit.name)
                            .font(.display(.headline))
                            .foregroundStyle(Palette.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        metaLine
                        HStack(spacing: 8) {
                            WeekDots(days: Day.lastDays(7, endingOn: day),
                                     isDone: { habit.isCompleted(on: $0) },
                                     isScheduled: { habit.rule.isFlexible || habit.isScheduled(on: $0) },
                                     tint: habit.tint, cell: 11)
                            if checkIn?.hasNote == true {
                                Image(systemName: "note.text").font(.caption).foregroundStyle(Palette.inkSecondary)
                                    .accessibilityLabel("Has a note")
                            }
                            if checkIn?.hasPhoto == true {
                                Image(systemName: "photo.fill").font(.caption).foregroundStyle(Palette.inkSecondary)
                                    .accessibilityLabel("Has photo proof")
                            }
                        }
                        if habit.isShared, !participants.isEmpty {
                            AvatarStack(avatars: participants, size: 24)
                                .padding(.top, 2)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens history and details")

            CompletionStamp(isDone: isDone, tint: habit.tint, size: density == .compact ? 44 : 50, habitName: habit.name, action: onToggle)
        }
        .card(tint: habit.tint, emphasized: isDone, padding: density == .compact ? 10 : 14)
    }

    private var participants: [(id: UUID, config: AvatarConfig, done: Bool)] {
        habit.participantIDs.compactMap { id in
            guard let friend = friendsByID[id] else { return nil }
            return (id, friend.avatar, habit.friendCompleted(id, on: day))
        }
    }

    @ViewBuilder
    private var metaLine: some View {
        let timeText = habit.timeOfDay == .anytime ? "Anytime" : Day.timeText(minutes: habit.scheduledMinutes)
        let streak = habit.currentStreak
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                metaItems(timeText: timeText, streak: streak)
            }
            VStack(alignment: .leading, spacing: 3) {
                metaItems(timeText: timeText, streak: streak)
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Palette.inkSecondary)
    }

    @ViewBuilder
    private func metaItems(timeText: String, streak: Streak) -> some View {
        Label(timeText, systemImage: habit.timeOfDay.symbol)
            .labelStyle(CompactLabelStyle())
        if habit.rule.isFlexible {
            let done = Day.week(containing: day).filter { habit.isCompleted(on: $0) }.count
            Label("\(done) of \(habit.rule.timesPerWeek) this week", systemImage: "calendar")
                .labelStyle(CompactLabelStyle())
        }
        Label(habit.isShared ? "Shared" : "Solo", systemImage: habit.isShared ? "person.2.fill" : "person.fill")
            .labelStyle(CompactLabelStyle())
        if showStreaks, habit.showStreak, streak.count >= 2 {
            Label(streak.label, systemImage: "flame.fill")
                .labelStyle(CompactLabelStyle())
                .foregroundStyle(Palette.orange)
        }
    }
}

struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon.imageScale(.small)
            configuration.title
        }
    }
}

/// Seven tappable days of the current week with a small completion ring each.
struct WeekStrip: View {
    @Binding var selection: Date
    let progress: (Date) -> Double
    let onSelect: () -> Void
    @Environment(\.accent) private var accent

    var body: some View {
        let days = Day.week(containing: Day.today)
        HStack(spacing: 4) {
            ForEach(days, id: \.self) { day in
                let isSelected = day == selection
                let isFuture = day > Day.today
                let value = progress(day)
                Button {
                    guard !isFuture else { return }
                    selection = day
                    onSelect()
                } label: {
                    VStack(spacing: 4) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(isSelected ? Palette.onAccent : Palette.inkSecondary)
                        ZStack {
                            if !isSelected, !isFuture {
                                ProgressRing(progress: value, lineWidth: 2.5, tint: accent)
                                    .frame(width: 30, height: 30)
                            }
                            Text(day.formatted(.dateTime.day()))
                                .font(.display(.subheadline, weight: .heavy))
                                .foregroundStyle(isSelected ? Palette.onAccent : (isFuture ? Palette.inkFaint : Palette.ink))
                        }
                        .frame(height: 30)
                        Circle()
                            .fill(day == Day.today ? (isSelected ? Palette.onAccent : accent) : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSelected ? accent : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isFuture)
                .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).month().day()))
                .accessibilityValue(isFuture ? "Upcoming" : "\(value.percentText) complete")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.card))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(accent.opacity(0.18), lineWidth: 1))
    }
}
