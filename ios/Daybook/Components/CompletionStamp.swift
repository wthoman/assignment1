import SwiftUI

/// The one-tap completion control. Fills with the habit's tint and stamps a checkmark.
/// The data change happens on tap; the animation follows.
struct CompletionStamp: View {
    let isDone: Bool
    let tint: TintToken
    var size: CGFloat = 50
    let habitName: String
    let action: () -> Void

    @Environment(\.motionReduced) private var motionReduced
    @State private var stampScale: CGFloat = 1
    @State private var stampRotation: Double = 0
    @State private var ringPulse = false

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(isDone ? tint.color : Palette.card)
                Circle()
                    .strokeBorder(isDone ? tint.color : Palette.lineStrong, style: StrokeStyle(lineWidth: 2, dash: isDone ? [] : [5, 4]))
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.42, weight: .black))
                        .foregroundStyle(tint.onColor)
                        .scaleEffect(stampScale)
                        .rotationEffect(.degrees(stampRotation))
                        .transition(.identity)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: size * 0.3, weight: .bold))
                        .foregroundStyle(Palette.inkFaint)
                }
                Circle()
                    .stroke(tint.color, lineWidth: 2)
                    .scaleEffect(ringPulse ? 1.45 : 1)
                    .opacity(ringPulse ? 0 : 0.0001)
            }
            .frame(width: size, height: size)
            .frame(width: max(size, Metrics.minTap), height: max(size, Metrics.minTap))
            .contentShape(Circle())
        }
        .buttonStyle(StampPressStyle())
        .onChange(of: isDone) { _, done in
            guard done, !motionReduced else { return }
            stampScale = 1.7
            stampRotation = -18
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                stampScale = 1
                stampRotation = -6
            }
            ringPulse = false
            withAnimation(.easeOut(duration: 0.55)) { ringPulse = true }
        }
        .accessibilityLabel(habitName)
        .accessibilityValue(isDone ? "Completed" : "Not completed")
        .accessibilityHint(isDone ? "Double tap to undo" : "Double tap to check in")
        .accessibilityAddTraits(isDone ? [.isSelected, .isButton] : .isButton)
    }
}

private struct StampPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Seven small squares for the last week; filled squares are completed days.
struct WeekDots: View {
    let days: [Date]
    let isDone: (Date) -> Bool
    let isScheduled: (Date) -> Bool
    var tint: TintToken = .burgundy
    var cell: CGFloat = 13

    var body: some View {
        HStack(spacing: 4) {
            ForEach(days, id: \.self) { day in
                let done = isDone(day)
                let scheduled = isScheduled(day)
                let isToday = day == Day.today
                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .fill(done ? tint.color : (scheduled ? Palette.paperDeep : Color.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .strokeBorder(isToday ? Palette.ink.opacity(0.55) : (scheduled ? Palette.line : Palette.line.opacity(0.6)),
                                          style: StrokeStyle(lineWidth: isToday ? 1.4 : 1, dash: scheduled || done ? [] : [2, 2]))
                    )
                    .frame(width: cell, height: cell)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Last seven days")
        .accessibilityValue("\(days.filter(isDone).count) of \(days.filter(isScheduled).count) scheduled days completed")
    }
}
