import SwiftUI

// MARK: - Button styles

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color?
    var fullWidth = true
    @Environment(\.accent) private var accent
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.display(.body))
            .foregroundStyle(Palette.onAccent)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 50)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill((tint ?? accent).opacity(isEnabled ? 1 : 0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: (tint ?? accent).opacity(configuration.isPressed ? 0 : 0.25), radius: 0, x: 0, y: configuration.isPressed ? 0 : 3)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var fullWidth = true
    @Environment(\.accent) private var accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.display(.body, weight: .semibold))
            .foregroundStyle(accent)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 48)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .fill(Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .strokeBorder(accent.opacity(0.5), lineWidth: 1.2)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Small bordered action used inside cards ("React", "Remind").
struct InlineActionStyle: ButtonStyle {
    var tint: Color?
    var filled = false
    @Environment(\.accent) private var accent

    func makeBody(configuration: Configuration) -> some View {
        let color = tint ?? accent
        configuration.label
            .font(.display(.footnote, weight: .semibold))
            .foregroundStyle(filled ? Palette.onAccent : color)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(filled ? color : color.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(color.opacity(filled ? 0 : 0.3), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Gentle press for tappable cards.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

/// Round icon button for navigation bars and headers (44pt target).
struct IconCircleButton: View {
    let symbol: String
    let label: String
    var badge = false
    let action: () -> Void
    @Environment(\.accent) private var accent

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Palette.card))
                .overlay(Circle().strokeBorder(accent.opacity(0.25), lineWidth: 1))
                .overlay(alignment: .topTrailing) {
                    if badge {
                        Circle()
                            .fill(Palette.orange)
                            .frame(width: 11, height: 11)
                            .overlay(Circle().strokeBorder(Palette.card, lineWidth: 2))
                            .offset(x: 1, y: -1)
                    }
                }
                .frame(width: Metrics.minTap, height: Metrics.minTap)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(badge ? "Unread items" : "")
    }
}

// MARK: - Chips

/// Selectable chip. Rounded rectangle (not a pill) to keep a handmade feel.
struct ChoiceChip: View {
    let title: String
    var symbol: String?
    let isSelected: Bool
    var tint: TintToken?
    let action: () -> Void
    @Environment(\.accent) private var accent

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol).font(.footnote.weight(.semibold))
                }
                Text(title).font(.display(.subheadline, weight: .semibold))
            }
            .foregroundStyle(isSelected ? (tint?.onColor ?? Palette.onAccent) : Palette.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 40)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isSelected ? (tint?.color ?? accent) : Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : Palette.line, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

/// Row of tint swatches.
struct TintPicker: View {
    @Binding var selection: TintToken
    var choices: [TintToken] = TintToken.userChoices
    var onChange: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(choices) { tint in
                Button {
                    selection = tint
                    onChange?()
                } label: {
                    Circle()
                        .fill(tint.color)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().strokeBorder(Palette.ink.opacity(selection == tint ? 0.9 : 0.12), lineWidth: selection == tint ? 2.5 : 1))
                        .overlay {
                            if selection == tint {
                                Image(systemName: "checkmark").font(.caption.weight(.heavy)).foregroundStyle(tint.onColor)
                            }
                        }
                        .frame(width: 40, height: 40)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tint.label)
                .accessibilityAddTraits(selection == tint ? .isSelected : [])
            }
        }
    }
}

// MARK: - Progress

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 7
    var tint: Color?
    @Environment(\.accent) private var accent
    @Environment(\.motionReduced) private var motionReduced

    var body: some View {
        ZStack {
            Circle().stroke(Palette.line.opacity(0.7), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(tint ?? accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(motionReduced ? nil : .spring(response: 0.5, dampingFraction: 0.85), value: progress)
    }
}

struct ProgressBar: View {
    var progress: Double
    var tint: Color?
    var height: CGFloat = 10
    @Environment(\.accent) private var accent
    @Environment(\.motionReduced) private var motionReduced

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2).fill(Palette.paperDeep)
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(tint ?? accent)
                    .frame(width: max(height, proxy.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: height)
        .overlay(RoundedRectangle(cornerRadius: height / 2).strokeBorder(Palette.line, lineWidth: 0.5))
        .animation(motionReduced ? nil : .spring(response: 0.5, dampingFraction: 0.85), value: progress)
        .accessibilityElement()
        .accessibilityValue(progress.percentText)
    }
}

// MARK: - Empty states

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            SymbolBadge(symbol: symbol, tint: .cream, size: 64, filled: true)
            Text(title)
                .font(.display(.title3))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.callout)
                .foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                    .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Flow layout

/// Wraps children onto new lines, like chips in a tag field.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if x > 0, x + size.width > maxWidth {
                y += lineHeight + lineSpacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: proposal.width ?? widest, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += lineHeight + lineSpacing
                x = bounds.minX
                lineHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: min(size.width, bounds.width), height: size.height))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Adaptive stack

/// Horizontal normally, vertical at accessibility text sizes so nothing gets squeezed.
struct AdaptiveStack<Content: View>: View {
    var spacing: CGFloat = 12
    var horizontalAlignment: VerticalAlignment = .center
    @ViewBuilder var content: () -> Content
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
            : AnyLayout(HStackLayout(alignment: horizontalAlignment, spacing: spacing))
        layout { content() }
    }
}
