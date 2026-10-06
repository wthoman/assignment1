import SwiftUI
import UIKit

// MARK: - Color tokens

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8) & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    /// A color that adapts to dark mode and the system "Increase Contrast" setting.
    static func dynamic(light: UInt32, dark: UInt32, lightHC: UInt32? = nil, darkHC: UInt32? = nil) -> UIColor {
        UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let highContrast = traits.accessibilityContrast == .high
            switch (isDark, highContrast) {
            case (false, false): return UIColor(hex: light)
            case (false, true): return UIColor(hex: lightHC ?? light)
            case (true, false): return UIColor(hex: dark)
            case (true, true): return UIColor(hex: darkHC ?? dark)
            }
        }
    }
}

/// Every color in the app comes from here. Never hard-code hex values in views.
enum Palette {
    // Surfaces
    static let paper = Color(uiColor: .dynamic(light: 0xF3E8D2, dark: 0x1C1514))
    static let paperDeep = Color(uiColor: .dynamic(light: 0xEADBBE, dark: 0x251C1A))
    static let card = Color(uiColor: .dynamic(light: 0xFBF6EC, dark: 0x2B211F, lightHC: 0xFFFDF8, darkHC: 0x241B19))
    static let cardRaised = Color(uiColor: .dynamic(light: 0xFFFBF3, dark: 0x342825))

    // Text
    static let ink = Color(uiColor: .dynamic(light: 0x271C1B, dark: 0xF3E8D2, lightHC: 0x120B0A, darkHC: 0xFFFFFF))
    static let inkSecondary = Color(uiColor: .dynamic(light: 0x6A5650, dark: 0xC8B6A6, lightHC: 0x3F302C, darkHC: 0xE8DCCF))
    static let inkFaint = Color(uiColor: .dynamic(light: 0x9A8778, dark: 0x8F7E72, lightHC: 0x5E4C44, darkHC: 0xC0B0A2))

    // Lines
    static let line = Color(uiColor: .dynamic(light: 0xDCC9B4, dark: 0x4A3936, lightHC: 0x8C6A5E, darkHC: 0x9C847A))
    static let lineStrong = Color(uiColor: .dynamic(light: 0x6F1725, dark: 0xC4566C, lightHC: 0x4E0D18, darkHC: 0xE9899A)).opacity(0.55)

    // Brand + supporting
    static let burgundy = Color(uiColor: .dynamic(light: 0x6F1725, dark: 0xD0556E, lightHC: 0x520E1A, darkHC: 0xF08EA0))
    static let rose = Color(uiColor: .dynamic(light: 0xC98986, dark: 0xD99A97))
    static let orange = Color(uiColor: .dynamic(light: 0xD98A4E, dark: 0xE79C63))
    static let gold = Color(uiColor: .dynamic(light: 0xC59A3E, dark: 0xD9B05A))
    static let sage = Color(uiColor: .dynamic(light: 0x8A9F7C, dark: 0x9DB48F))
    static let sky = Color(uiColor: .dynamic(light: 0x8FB0C4, dark: 0xA1C0D3))
    static let cream = Color(uiColor: .dynamic(light: 0xE9D9BC, dark: 0x5B4A3F))
    static let inkBlue = Color(uiColor: .dynamic(light: 0x2B3F5E, dark: 0x8FA6CC))

    static let onAccent = Color(uiColor: .dynamic(light: 0xFBF6EC, dark: 0x1C1514))
    static let shadow = Color(uiColor: .dynamic(light: 0x5A3A2A, dark: 0x000000)).opacity(0.14)

    /// Spotlight gradient used only in the recap.
    static let spotlight = RadialGradient(
        colors: [Color(uiColor: .dynamic(light: 0xFFF3DA, dark: 0x4A2E26)), Color(uiColor: .dynamic(light: 0xF0DDBC, dark: 0x1C1514))],
        center: .top, startRadius: 20, endRadius: 520)
}

/// Named tints that user content (habits, groups, collectibles) can carry.
enum TintToken: String, Codable, CaseIterable, Identifiable {
    case burgundy, rose, orange, gold, sage, sky, cream, ink

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .burgundy: Palette.burgundy
        case .rose: Palette.rose
        case .orange: Palette.orange
        case .gold: Palette.gold
        case .sage: Palette.sage
        case .sky: Palette.sky
        case .cream: Palette.cream
        case .ink: Palette.inkBlue
        }
    }

    /// Pale wash for backgrounds behind the tint.
    var soft: Color { color.opacity(0.2) }

    /// Readable foreground on top of `color`.
    var onColor: Color {
        switch self {
        case .burgundy, .ink: Palette.onAccent
        default: Palette.ink
        }
    }

    var label: String {
        switch self {
        case .burgundy: "Burgundy"
        case .rose: "Dusty rose"
        case .orange: "Apricot"
        case .gold: "Marigold"
        case .sage: "Sage"
        case .sky: "Pale sky"
        case .cream: "Cream"
        case .ink: "Ink blue"
        }
    }

    static let userChoices: [TintToken] = [.burgundy, .rose, .orange, .gold, .sage, .sky, .ink]
}

/// User-selectable app accent.
enum AccentChoice: String, Codable, CaseIterable, Identifiable {
    case burgundy, forest, ink, terracotta

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .burgundy: Palette.burgundy
        case .forest: Color(uiColor: .dynamic(light: 0x2F5A3A, dark: 0x7FB58C))
        case .ink: Color(uiColor: .dynamic(light: 0x23395B, dark: 0x8AA6D6))
        case .terracotta: Color(uiColor: .dynamic(light: 0x9E4527, dark: 0xE38A63))
        }
    }

    var label: String {
        switch self {
        case .burgundy: "Burgundy"
        case .forest: "Forest"
        case .ink: "Ink"
        case .terracotta: "Terracotta"
        }
    }
}

// MARK: - Typography

extension Font {
    /// Friendly bold rounded type for headings, numbers and buttons.
    static func display(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    /// Oversized serif used for recap and award moments.
    static func award(_ style: Font.TextStyle, weight: Font.Weight = .black) -> Font {
        .system(style, design: .serif, weight: weight)
    }

    /// Handwritten annotation. Falls back to the system font if the face is unavailable.
    static func hand(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("Noteworthy-Bold", size: size, relativeTo: style)
    }

    static let eyebrow = Font.system(.caption, design: .rounded, weight: .heavy)
}

// MARK: - Spacing & metrics

enum Metrics {
    static let cardRadius: CGFloat = 18
    static let controlRadius: CGFloat = 12
    static let gutter: CGFloat = 16
    static let minTap: CGFloat = 44
}

// MARK: - Environment

private struct AccentKey: EnvironmentKey {
    static let defaultValue: Color = Palette.burgundy
}

private struct DensityKey: EnvironmentKey {
    static let defaultValue: CardDensity = .comfortable
}

private struct ReduceMotionKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// The current app accent (user-selectable in Settings → Appearance).
    var accent: Color {
        get { self[AccentKey.self] }
        set { self[AccentKey.self] = newValue }
    }

    var cardDensity: CardDensity {
        get { self[DensityKey.self] }
        set { self[DensityKey.self] = newValue }
    }

    /// True when either the system or the in-app setting asks for reduced motion.
    var motionReduced: Bool {
        get { self[ReduceMotionKey.self] }
        set { self[ReduceMotionKey.self] = newValue }
    }
}
