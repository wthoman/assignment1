import SwiftUI

/// An SF Symbol inside a slightly hand-cut warm tile. Used for habit categories and list icons.
struct SymbolBadge: View {
    let symbol: String
    var tint: TintToken = .burgundy
    var size: CGFloat = 44
    var filled = false

    var body: some View {
        ZStack {
            WobblyRect(seed: symbol.stableHash, amount: size * 0.025)
                .fill(filled ? tint.color : tint.color.opacity(0.18))
            WobblyRect(seed: symbol.stableHash &+ 1, amount: size * 0.025)
                .stroke(tint.color.opacity(filled ? 0 : 0.45), lineWidth: 1)
            Image(systemName: symbol)
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundStyle(filled ? tint.onColor : tint == .cream ? Palette.inkSecondary : tint.color)
                .symbolRenderingMode(.monochrome)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(Double(Int(symbol.stableHash % 7)) - 3))
        .accessibilityHidden(true)
    }
}

/// A collectible drawn as a die-cut sticker with a white border.
struct StickerView: View {
    let shape: StickerShape
    let symbol: String
    let tint: TintToken
    var size: CGFloat = 84
    var locked = false
    var rarity: Rarity = .common
    var showsShine = true

    var body: some View {
        ZStack {
            // White die-cut border
            StickerSilhouette(shape: shape)
                .fill(locked ? Palette.paperDeep : Color.white.opacity(0.95))
                .shadow(color: Palette.shadow.opacity(locked ? 0 : 1.6), radius: locked ? 0 : 3, x: 1, y: 3)
            StickerSilhouette(shape: shape)
                .fill(locked ? Palette.paperDeep : tint.color)
                .padding(size * 0.07)
            if locked {
                StickerSilhouette(shape: shape)
                    .stroke(Palette.inkFaint, style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                    .padding(size * 0.07)
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(Palette.inkFaint)
            } else {
                // Inner ink ring
                StickerSilhouette(shape: shape)
                    .stroke(tint.onColor.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                    .padding(size * 0.14)
                Image(systemName: symbol)
                    .font(.system(size: size * 0.3, weight: .bold))
                    .foregroundStyle(tint.onColor)
                    .offset(y: shape == .ribbon ? -size * 0.13 : 0)
                if showsShine, rarity >= .rare {
                    StickerSilhouette(shape: shape)
                        .fill(LinearGradient(colors: [Color.white.opacity(0.45), .clear, Color.white.opacity(0.18), .clear],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .padding(size * 0.07)
                        .blendMode(.screen)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

extension StickerView {
    init(_ item: Collectible, size: CGFloat = 84, forceUnlocked: Bool = false) {
        self.init(shape: item.shape, symbol: item.symbol, tint: item.tint, size: size,
                  locked: !(item.isUnlocked || forceUnlocked), rarity: item.rarity)
    }
}

/// Little rarity pips.
struct RarityDots: View {
    let rarity: Rarity
    @Environment(\.accent) private var accent

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < rarity.dots ? (rarity == .legendary ? Palette.gold : accent) : Palette.line)
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(rarity.label)
    }
}
