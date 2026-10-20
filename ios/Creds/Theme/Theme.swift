import SwiftUI
import UIKit

// Palette: Encore's paper / stage themes with Creds' burgundy as the main colour.
// Type: New York headings (serif), SF Pro body, SF Mono labels — all ship with iOS.

enum ThemeName: String { case paper, stage }

struct Palette {
    let bg, bg2, card, card2, line, line2: Color
    let ink, ink2, ink3: Color
    let acc, acc2, accSoft, accMid: Color
    let goldInk, goldSoft: Color
    let yel, yelSoft, yelTrack, yelInk: Color
    let tabBg, grain, shadow: Color
    /// Neutral gray behind red icons (Tile).
    let tile: Color
    let isStage: Bool

    // matches the Today page: warm pale page, blush cards (card2), white controls (card), brick red
    static let paper = Palette(
        bg: Color(hex: 0xFCF9F7), bg2: Color(hex: 0xF3EDEA), card: Color(hex: 0xFFFFFF), card2: Color(hex: 0xEEE7E4),
        line: Color(hex: 0xE4DBD7), line2: Color(hex: 0xCDC1BC),
        ink: Color(hex: 0x141010), ink2: Color(hex: 0x746764), ink3: Color(hex: 0x99908E),
        acc: Color(hex: 0x931E14), acc2: Color(hex: 0xA8301F), accSoft: Color(hex: 0xF5E4E0), accMid: Color(hex: 0xE0B6AD),
        goldInk: Color(hex: 0x8C6A22), goldSoft: Color(hex: 0xF2E8CF),
        yel: Color(hex: 0xF2C14E), yelSoft: Color(hex: 0xFBF0CF), yelTrack: Color(hex: 0xF6E3AE), yelInk: Color(hex: 0x7E5A0B),
        tabBg: Color(hex: 0xFCF9F7, alpha: 0.94), grain: Color(hex: 0x141010, alpha: 0.03), shadow: Color(hex: 0x3A0A12, alpha: 0.18),
        tile: Color(hex: 0xF5F0EE),
        isStage: false)

    static let stage = Palette(
        bg: Color(hex: 0x120C0E), bg2: Color(hex: 0x1A1214), card: Color(hex: 0x1D1517), card2: Color(hex: 0x251B1D),
        line: Color(hex: 0x35282B), line2: Color(hex: 0x4E3D41),
        ink: Color(hex: 0xF3EAE4), ink2: Color(hex: 0xBFAFA8), ink3: Color(hex: 0x86776F),
        acc: Color(hex: 0xC14A62), acc2: Color(hex: 0xD8647A), accSoft: Color(hex: 0x33161D), accMid: Color(hex: 0x6E2534),
        goldInk: Color(hex: 0xD9B465), goldSoft: Color(hex: 0x2C2215),
        yel: Color(hex: 0xE8B94A), yelSoft: Color(hex: 0x33280F), yelTrack: Color(hex: 0x4A3A16), yelInk: Color(hex: 0xF0CC6A),
        tabBg: Color(hex: 0x120C0E, alpha: 0.94), grain: Color(hex: 0xFFFFFF, alpha: 0.035), shadow: Color(hex: 0x000000, alpha: 0.7),
        tile: Color(hex: 0x2C2829),
        isStage: true)

    static func of(_ t: ThemeName) -> Palette { t == .stage ? .stage : .paper }

    /// The Today page's own warm look.
    var today: TodayLook { isStage ? .stage(self) : .paper }

    /// color-mix(in srgb, acc X%, card)
    func accOn(_ pct: Double, _ base: Color? = nil) -> Color { Color.mix(acc, base ?? card, pct) }
}

/// Today page colours: warm pale page, blush cards, brick-red accents.
struct TodayLook {
    let bg, ink, text, muted, section, card, circle, dot, shadow, red: Color

    static let paper = TodayLook(
        bg: Color(hex: 0xFCF9F7), ink: Color(hex: 0x332620), text: Color(hex: 0x141010), muted: Color(hex: 0x99908E),
        section: Color(hex: 0x746764), card: Color(hex: 0xEEE7E4), circle: .white, dot: Color(hex: 0xDED4CF),
        shadow: Color(hex: 0xEEE7E4), red: Color(hex: 0x931E14))

    static func stage(_ c: Palette) -> TodayLook {
        TodayLook(bg: c.bg, ink: c.ink, text: c.ink, muted: c.ink3, section: c.ink2, card: c.card2, circle: c.card,
                  dot: c.line2, shadow: c.card2, red: c.acc)
    }
}

enum Brand {
    static let wine = Color(hex: 0x6F1725)
    static let wine2 = Color(hex: 0x8A2233)
    static let wine3 = Color(hex: 0xA63446)
    static let wineDeep = Color(hex: 0x3A0A12)
    static let wineInk = Color(hex: 0x24060B)
    static let gold = Color(hex: 0xB8913A)
    static let gold2 = Color(hex: 0xE2C67A)
    static let onWine = Color(hex: 0xFBF2EC)
    static let stage = Color(hex: 0x120C0E)
    static let cream = Color(hex: 0xF6EDE6)
}

private struct PaletteKey: EnvironmentKey { static let defaultValue = Palette.paper }
extension EnvironmentValues {
    var pal: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }

    init(hexString: String) {
        let s = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        self.init(hex: UInt32(s, radix: 16) ?? 0)
    }

    /// Mix `a` into `b` by `t` (0…1), like CSS color-mix in srgb.
    static func mix(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let ua = UIColor(a), ub = UIColor(b)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        ua.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        ub.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = CGFloat(t)
        return Color(.sRGB, red: r1 * t + r2 * (1 - t), green: g1 * t + g2 * (1 - t), blue: b1 * t + b2 * (1 - t), opacity: a1 * t + a2 * (1 - t))
    }
}

// MARK: - Type

extension Font {
    /// New York, bold like the Today greeting, scaled by the mock-up's --ds (.86).
    static func serif(_ size: CGFloat) -> Font { .system(size: size * 0.86, weight: .bold, design: .serif) }
    /// Serif without the --ds scale (used where the CSS sets a fixed size).
    static func serifRaw(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .serif) }
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight, design: .monospaced) }
    static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight) }
}

extension View {
    /// Small uppercase label (.eyebrow), in the Today page's sans.
    func eyebrowStyle(_ color: Color, size: CGFloat = 10.5, tracking: CGFloat = 0.06) -> some View {
        self.font(.sans(size + 1.5, .semibold)).tracking((size + 1.5) * tracking).textCase(.uppercase).foregroundStyle(color)
    }
}

struct Eyebrow: View {
    @Environment(\.pal) private var c
    let text: String
    var acc = false
    var size: CGFloat = 10.5
    var color: Color? = nil
    init(_ text: String, acc: Bool = false, size: CGFloat = 10.5, color: Color? = nil) {
        self.text = text; self.acc = acc; self.size = size; self.color = color
    }
    var body: some View {
        Text(text).eyebrowStyle(color ?? (acc ? c.acc : c.ink3), size: size).lineLimit(1)
    }
}

/// "Take your <em>seat.</em>" — a heading whose emphasised part is italic + accent.
struct EmTitle: View {
    @Environment(\.pal) private var c
    let lead: String
    let em: String
    var size: CGFloat = 34
    var emColor: Color? = nil
    var body: some View {
        Text("\(lead)\(Text(em).italic().foregroundStyle(emColor ?? c.acc))")
            .font(.serif(size))
            .tracking(-0.015 * size)
            .lineSpacing(-4)
    }
}

/// Last word italic (posters).
func italLast(_ name: String, size: CGFloat, emColor: Color? = nil) -> Text {
    var words = name.split(separator: " ").map(String.init)
    let last = words.popLast() ?? ""
    let lead = words.isEmpty ? "" : words.joined(separator: " ") + " "
    let em = Text(last).italic()
    let emC = emColor.map { em.foregroundStyle($0) } ?? em
    return Text("\(lead)\(emC)").font(.serifRaw(size * 0.86))
}
