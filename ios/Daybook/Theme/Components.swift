import SwiftUI

// MARK: - Surfaces

/// `.card`: cream, soft shadow, faint accent outline, 18pt radius.
struct CardModifier: ViewModifier {
    @Environment(\.pal) private var c
    var padding: EdgeInsets
    var radius: CGFloat = 18
    var fill: Color? = nil
    var outline: Color? = nil
    var outlineWidth: CGFloat = 1
    var flat = false
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill ?? c.card)
                    .shadow(color: flat ? .clear : c.shadow.opacity(0.75), radius: 6, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(outline ?? (flat ? c.line : c.acc.opacity(0.14)), lineWidth: outlineWidth)
            )
    }
}

extension View {
    func card(_ pad: CGFloat = 16, radius: CGFloat = 18, fill: Color? = nil, outline: Color? = nil, outlineWidth: CGFloat = 1, flat: Bool = false) -> some View {
        modifier(CardModifier(padding: EdgeInsets(top: pad, leading: pad, bottom: pad, trailing: pad), radius: radius, fill: fill, outline: outline, outlineWidth: outlineWidth, flat: flat))
    }
    func card(v: CGFloat, h: CGFloat, radius: CGFloat = 18, fill: Color? = nil, outline: Color? = nil, outlineWidth: CGFloat = 1, flat: Bool = false) -> some View {
        modifier(CardModifier(padding: EdgeInsets(top: v, leading: h, bottom: v, trailing: h), radius: radius, fill: fill, outline: outline, outlineWidth: outlineWidth, flat: flat))
    }
    /// `.blk` spacing between detail blocks.
    func blk() -> some View { padding(.top, 16) }
}

/// Hand-cut icon tile (slightly uneven corners, tilted).
struct Tile<Content: View>: View {
    @Environment(\.pal) private var c
    var size: CGFloat = 44
    var on = false
    var gold = false
    var rotate = true
    var radiusScale: CGFloat = 1
    @ViewBuilder var content: Content

    var body: some View {
        let k = size / 44 * radiusScale
        let shape = UnevenRoundedRectangle(topLeadingRadius: 13 * k, bottomLeadingRadius: 13.5 * k, bottomTrailingRadius: 13 * k, topTrailingRadius: 13 * k, style: .continuous)
        let fill: Color = on ? c.acc : gold ? c.goldSoft : c.accOn(0.11)
        let fg: Color = on ? Brand.onWine : gold ? c.goldInk : c.acc
        content
            .foregroundStyle(fg)
            .frame(width: size, height: size)
            .background(shape.fill(fill))
            .overlay(shape.strokeBorder(on ? .clear : gold ? Brand.gold.opacity(0.4) : c.acc.opacity(0.3), lineWidth: 1))
            .rotationEffect(.degrees(rotate ? -2 : 0))
    }
}

/// Rubber ink stamp.
struct Stamp<Content: View>: View {
    var size: CGFloat = 80
    var color: Color
    var fill: Color = .clear
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 2) { content }
            .font(.mono(size * 0.13, .medium))
            .tracking(size * 0.13 * 0.12)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(Circle().fill(fill))
            .overlay(Circle().strokeBorder(color, lineWidth: size * 0.05))
            .overlay(Circle().inset(by: size * 0.08).stroke(color.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
            .opacity(0.92)
    }
}

// MARK: - Buttons

enum BtnKind { case primary, ink, line, ghost, cream, ghostLight, ghostCream }

struct Btn: ButtonStyle {
    @Environment(\.pal) private var c
    @Environment(\.isEnabled) private var enabled
    var kind: BtnKind = .primary
    var small = false
    var full = true
    var fg: Color? = nil

    func makeBody(configuration: Configuration) -> some View {
        let h: CGFloat = small ? 36 : (kind == .ghost || kind == .ghostCream ? 40 : 48)
        let r: CGFloat = small ? 10 : 12
        let shape = RoundedRectangle(cornerRadius: r, style: .continuous)
        let (bg, fg, lip): (Color, Color, Color?) = {
            switch kind {
            case .primary: return (c.acc, Brand.onWine, c.acc.opacity(0.3))
            case .ink: return (c.ink, c.bg, .black.opacity(0.15))
            case .line: return (c.card, c.acc, nil)
            case .ghost: return (.clear, c.ink2, nil)
            case .cream: return (Brand.cream, Brand.wineInk, nil)
            case .ghostLight: return (.clear, Color(hex: 0xF6EBE6), nil)
            case .ghostCream: return (.clear, Brand.cream, nil)
            }
        }()
        let pressed = configuration.isPressed
        return HStack(spacing: 8) { configuration.label }
            .font(.sans(small ? 13 : 15, .semibold))
            .foregroundStyle(self.fg ?? fg)
            .lineLimit(1)
            .padding(.horizontal, small ? 13 : 16)
            .frame(maxWidth: full ? .infinity : nil)
            .frame(height: h)
            .background(
                ZStack {
                    if let lip { shape.fill(lip).offset(y: pressed ? 1 : 3) }
                    shape.fill(bg)
                }
            )
            .overlay {
                if kind == .line { shape.strokeBorder(c.acc.opacity(0.5), lineWidth: 1.2) }
                if kind == .ghostLight { shape.strokeBorder(Color.white.opacity(0.3), lineWidth: 1) }
            }
            .contentShape(shape)
            .offset(y: pressed && lip != nil ? 2 : 0)
            .opacity(enabled ? 1 : 0.35)
            .animation(.easeOut(duration: 0.12), value: pressed)
    }
}

extension ButtonStyle where Self == Btn {
    static var btn: Btn { Btn() }
    static func btn(_ kind: BtnKind, small: Bool = false, full: Bool = true) -> Btn { Btn(kind: kind, small: small, full: small ? false : full) }
}

/// Plain press feedback for custom tappable rows.
struct PressStyle: ButtonStyle {
    var scale: CGFloat = 1
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

extension ButtonStyle where Self == PressStyle {
    static var press: PressStyle { PressStyle() }
}

struct Chip: View {
    @Environment(\.pal) private var c
    let label: String
    var on = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.sans(13, .semibold))
                .lineLimit(1)
                .foregroundStyle(on ? Brand.onWine : c.ink2)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(on ? c.acc : c.card))
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(on ? .clear : c.line, lineWidth: 1))
        }
        .buttonStyle(.press)
    }
}

struct IconBtn<Content: View>: View {
    @Environment(\.pal) private var c
    var acc = false
    var badge: Int = 0
    var label: String
    let action: () -> Void
    @ViewBuilder var content: Content
    var body: some View {
        Button(action: action) {
            content
                .foregroundStyle(acc ? Brand.onWine : c.ink)
                .frame(width: 38, height: 38)
                .background(Circle().fill(acc ? c.acc : c.card).shadow(color: acc ? .clear : c.shadow.opacity(0.75), radius: 6, y: 5))
                .overlay(Circle().strokeBorder(acc ? .clear : c.line, lineWidth: 1))
                .overlay(alignment: .topTrailing) {
                    if badge > 0 {
                        Text("\(badge)").font(.sans(10, .bold)).foregroundStyle(Brand.onWine)
                            .padding(.horizontal, 4).frame(minWidth: 17, minHeight: 17)
                            .background(Capsule().fill(c.acc))
                            .background(Capsule().stroke(c.bg, lineWidth: 4))
                            .offset(x: 3, y: -3)
                    }
                }
        }
        .buttonStyle(.press)
        .accessibilityLabel(label)
    }
}

struct CloseX: View {
    @Environment(\.pal) private var c
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Ico(.x).foregroundStyle(c.ink)
                .frame(width: 34, height: 34)
                .background(Circle().fill(c.card))
                .overlay(Circle().strokeBorder(c.line, lineWidth: 1))
        }
        .buttonStyle(.press)
        .accessibilityLabel("Close")
    }
}

/// Segmented control (.seg).
struct Seg: View {
    @Environment(\.pal) private var c
    let options: [(String, String)]   // value, label
    let selected: String?
    var height: CGFloat = 34
    var font: CGFloat = 13
    let pick: (String) -> Void
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { v, l in
                Button { pick(v) } label: {
                    Text(l).font(.sans(font, .semibold)).lineLimit(1)
                        .foregroundStyle(selected == v ? c.ink : c.ink2)
                        .frame(maxWidth: .infinity).frame(height: height)
                        .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(selected == v ? c.card : .clear)
                            .shadow(color: selected == v ? c.shadow.opacity(0.75) : .clear, radius: 6, y: 5))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(c.bg2))
    }
}

/// The little on/off switch (.sw).
struct Switch: View {
    @Environment(\.pal) private var c
    let on: Bool
    var body: some View {
        Capsule().fill(on ? c.acc : c.line2)
            .frame(width: 46, height: 28)
            .overlay(alignment: on ? .trailing : .leading) {
                Circle().fill(.white).frame(width: 22, height: 22).shadow(color: .black.opacity(0.25), radius: 1.5, y: 1).padding(3)
            }
            .animation(.easeInOut(duration: 0.2), value: on)
    }
}

/// Labelled text field (.field).
struct Field: View {
    @Environment(\.pal) private var c
    var label: String? = nil
    var placeholder = ""
    @Binding var text: String
    var secure = false
    var compact = false
    @FocusState private var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let label {
                Text(label).font(.mono(10)).tracking(1.4).textCase(.uppercase).foregroundStyle(c.ink3)
            }
            Group {
                if secure {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(c.ink3).font(.sans(16)))
                } else {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(c.ink3).font(.sans(16)))
                }
            }
            .font(.sans(16, .medium))
            .foregroundStyle(c.ink)
            .tint(c.acc)
            .autocorrectionDisabled()
            .focused($focused)
        }
        .padding(.horizontal, compact ? 12 : 14)
        .padding(.vertical, compact ? 8 : 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(c.card))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(focused ? c.acc : c.line, lineWidth: focused ? 1.5 : 1))
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
    }
}

// MARK: - Progress

struct Ring: View {
    let size: CGFloat
    let stroke: CGFloat
    let pct: Double
    var track: Color
    var color: Color
    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: stroke)
            Circle().trim(from: 0, to: min(1, max(0, pct)))
                .stroke(color, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .padding(stroke / 2)
        .frame(width: size, height: size)
    }
}

enum DotState { case off, half, on }

/// Seven small squares, one per day (.dots7).
struct Dots7: View {
    @Environment(\.pal) private var c
    let states: [DotState]
    var size: CGFloat = 10
    var radius: CGFloat = 3
    var gap: CGFloat = 3
    var body: some View {
        HStack(spacing: gap) {
            ForEach(Array(states.enumerated()), id: \.offset) { i, s in
                let now = i == 6
                let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
                shape.fill(s == .on ? c.acc : s == .half ? Color.mix(c.acc, c.bg2, 0.38) : c.bg2)
                    .overlay {
                        if s == .off { shape.strokeBorder(now ? c.ink.opacity(0.55) : c.line, lineWidth: now ? 1.4 : 1) }
                        else if s == .half && now { shape.strokeBorder(c.ink.opacity(0.55), lineWidth: 1.4) }
                    }
                    .frame(width: size, height: size)
            }
        }
    }
    static func from(_ w: [Int]) -> [DotState] { w.map { $0 != 0 ? .on : .off } }
}

struct PBar: View {
    @Environment(\.pal) private var c
    let pct: Double   // 0…100
    var height: CGFloat = 6
    var big = false
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(c.bg2)
                Capsule().fill(c.yel).frame(width: g.size.width * min(1, max(0, pct / 100)))
                if big {
                    ForEach([0.25, 0.5, 0.75], id: \.self) { f in
                        Rectangle().fill(c.card).frame(width: g.size.width * 0.008).offset(x: g.size.width * (f - 0.004))
                    }
                }
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
    }
}

// MARK: - Headings & rows

/// Section header (.sec).
struct Sec: View {
    @Environment(\.pal) private var c
    let title: String
    var count: Int? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title).font(.serif(23)).foregroundStyle(c.ink)
            if let count {
                Text("\(count)").font(.mono(10.5)).foregroundStyle(c.ink2)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Capsule().fill(c.bg2))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
        .padding(.top, 22).padding(.bottom, 8)
    }
}

/// Header of a pushed page (.nav-bar).
struct NavBar<Right: View>: View {
    @Environment(\.pal) private var c
    @Environment(AppModel.self) private var m
    let title: String
    @ViewBuilder var right: Right
    var body: some View {
        HStack(spacing: 10) {
            IconBtn(label: "Back", action: { m.back() }) { Ico(.back, 19) }
            Text(title).font(.sans(16, .semibold)).foregroundStyle(c.ink).lineLimit(1).frame(maxWidth: .infinity)
            right.frame(minWidth: 38)
        }
        .frame(minHeight: 38)
        .padding(.bottom, 14)
    }
}

extension NavBar where Right == Color {
    init(title: String) { self.title = title; self.right = Color.clear }
}

/// Page header with eyebrow + big title + trailing actions (.g-head).
struct GHead<Trailing: View>: View {
    @Environment(\.pal) private var c
    let eyebrow: String
    let title: String
    @ViewBuilder var trailing: Trailing
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(eyebrow)
                Text(title).font(.serif(34)).tracking(-0.5).foregroundStyle(c.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(.bottom, 4)
    }
}

struct EmptyNote: View {
    @Environment(\.pal) private var c
    let text: String
    var body: some View {
        Text(text).font(.sans(13.5)).foregroundStyle(c.ink3).multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22).padding(.horizontal, 16)
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(c.line2, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
    }
}

/// Small mono label with a trailing rule (.lbl in sheets).
struct Lbl: View {
    @Environment(\.pal) private var c
    let text: String
    var body: some View {
        Text(text).font(.mono(10)).tracking(1.4).textCase(.uppercase).foregroundStyle(c.ink3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 18).padding(.bottom, 8)
    }
}

/// Row with a hairline divider above (lrow / set-row / req …).
struct Divided<Content: View>: View {
    @Environment(\.pal) private var c
    var first: Bool
    var vpad: CGFloat = 10
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(.vertical, vpad)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) { if !first { Rectangle().fill(c.line).frame(height: 1) } }
    }
}

/// Two-line text block used in rows.
struct TwoLine: View {
    @Environment(\.pal) private var c
    let title: String
    var sub: String? = nil
    var titleSize: CGFloat = 14.5
    var subSize: CGFloat = 12
    var titleColor: Color? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(.sans(titleSize, .semibold)).foregroundStyle(titleColor ?? c.ink).lineLimit(2)
            if let sub { Text(sub).font(.sans(subSize)).foregroundStyle(c.ink3).lineLimit(2) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Horizontal scroller that bleeds to the screen edge.
struct Bleed<Content: View>: View {
    var inset: CGFloat = 16
    var spacing: CGFloat = 8
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) { content }
                .padding(.horizontal, inset)
                .padding(.vertical, 2)
        }
        .padding(.horizontal, -inset)
    }
}
