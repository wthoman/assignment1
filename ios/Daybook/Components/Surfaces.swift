import SwiftUI

// MARK: - Paper background

/// Warm beige page with a faint speckled grain. Drawn once and cached by the GPU.
struct PaperBackground: View {
    var tone: Color = Palette.paper

    var body: some View {
        tone
            .overlay {
                Canvas { context, size in
                    var rng = SeededGenerator(seed: 42)
                    let count = Int(size.width * size.height / 900)
                    for _ in 0..<count {
                        let x = Double.random(in: 0...size.width, using: &rng)
                        let y = Double.random(in: 0...size.height, using: &rng)
                        let r = Double.random(in: 0.4...1.1, using: &rng)
                        let alpha = Double.random(in: 0.03...0.08, using: &rng)
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(Palette.ink.opacity(alpha)))
                    }
                }
                .drawingGroup()
                .accessibilityHidden(true)
            }
            .ignoresSafeArea()
    }
}

/// Faint ruled notebook lines.
struct RuledLines: View {
    var spacing: CGFloat = 26
    var margin = true

    var body: some View {
        Canvas { context, size in
            var y = spacing
            while y < size.height {
                context.stroke(Path { $0.move(to: CGPoint(x: 0, y: y)); $0.addLine(to: CGPoint(x: size.width, y: y)) },
                               with: .color(Palette.sky.opacity(0.28)), lineWidth: 0.7)
                y += spacing
            }
            if margin {
                context.stroke(Path { $0.move(to: CGPoint(x: 28, y: 0)); $0.addLine(to: CGPoint(x: 28, y: size.height)) },
                               with: .color(Palette.rose.opacity(0.35)), lineWidth: 0.8)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Cards

struct CardStyle: ViewModifier {
    var tint: TintToken?
    var emphasized = false
    var padding: CGFloat?
    @Environment(\.cardDensity) private var density
    @Environment(\.accent) private var accent
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let pad = padding ?? (density == .compact ? 12 : 16)
        content
            .padding(pad)
            .background {
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .fill(Palette.card)
                    .overlay {
                        if let tint, emphasized {
                            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                                .fill(tint.color.opacity(0.12))
                        }
                    }
                    .shadow(color: Palette.shadow, radius: 6, x: 0, y: 3)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: contrast == .increased ? 1.5 : 1)
            }
    }

    private var borderColor: Color {
        if emphasized, let tint { return tint.color.opacity(0.7) }
        return contrast == .increased ? Palette.lineStrong : accent.opacity(0.22)
    }
}

extension View {
    /// Cream card with a thin warm border and soft shadow.
    func card(tint: TintToken? = nil, emphasized: Bool = false, padding: CGFloat? = nil) -> some View {
        modifier(CardStyle(tint: tint, emphasized: emphasized, padding: padding))
    }
}

// MARK: - Labels

/// Small uppercase burgundy label above sections.
struct Eyebrow: View {
    let text: String
    @Environment(\.accent) private var accent

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.eyebrow)
            .tracking(1.1)
            .foregroundStyle(accent)
            .accessibilityAddTraits(.isHeader)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var count: Int?
    var trailing: AnyView?

    init(_ title: String, subtitle: String? = nil, count: Int? = nil, trailing: AnyView? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.count = count
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.display(.headline))
                        .foregroundStyle(Palette.ink)
                    if let count {
                        Text("\(count)")
                            .font(.display(.caption, weight: .heavy))
                            .foregroundStyle(Palette.inkSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Palette.paperDeep))
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Palette.inkSecondary)
                }
            }
            Spacer(minLength: 0)
            trailing
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Handwritten annotation in burgundy ink.
struct HandNote: View {
    let text: String
    var size: CGFloat = 17
    var rotation: Double = -3
    @Environment(\.accent) private var accent

    init(_ text: String, size: CGFloat = 17, rotation: Double = -3) {
        self.text = text
        self.size = size
        self.rotation = rotation
    }

    var body: some View {
        Text(text)
            .font(.hand(size))
            .foregroundStyle(accent.opacity(0.85))
            .rotationEffect(.degrees(rotation))
    }
}

/// A strip of washi tape.
struct TapeStrip: View {
    var tint: TintToken = .gold
    var width: CGFloat = 54
    var rotation: Double = -8

    var body: some View {
        Rectangle()
            .fill(tint.color.opacity(0.45))
            .overlay(
                HStack(spacing: 5) {
                    ForEach(0..<Int(width / 8), id: \.self) { _ in
                        Rectangle().fill(Color.white.opacity(0.18)).frame(width: 2)
                    }
                }
            )
            .frame(width: width, height: 16)
            .mask(PerforatedShape(holeRadius: 1.5))
            .rotationEffect(.degrees(rotation))
            .shadow(color: Palette.shadow, radius: 1, y: 1)
            .accessibilityHidden(true)
    }
}

/// Circular ink stamp with text, used for "DONE", "GOAL", etc.
struct InkStamp: View {
    let text: String
    var symbol: String = "checkmark"
    var color: Color = Palette.burgundy
    var size: CGFloat = 76

    var body: some View {
        ZStack {
            Circle().strokeBorder(color, lineWidth: size * 0.05)
            Circle().strokeBorder(color.opacity(0.7), style: StrokeStyle(lineWidth: size * 0.02, dash: [3, 3])).padding(size * 0.1)
            VStack(spacing: 0) {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.3, weight: .black))
                Text(text.uppercased())
                    .font(.system(size: size * 0.13, weight: .black, design: .rounded))
                    .tracking(1)
            }
            .foregroundStyle(color)
        }
        .frame(width: size, height: size)
        .opacity(0.9)
        .accessibilityHidden(true)
    }
}
