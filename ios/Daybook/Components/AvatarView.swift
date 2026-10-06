import SwiftUI

/// Fully drawn avatar (no image assets). Scales cleanly from 24pt to 200pt.
struct AvatarView: View {
    let config: AvatarConfig
    var size: CGFloat = 44
    var showsCompanion = true

    private var s: CGFloat { size }
    private var headWidth: CGFloat {
        switch config.head {
        case .round: s * 0.42
        case .bean: s * 0.4
        case .square: s * 0.41
        case .tall: s * 0.36
        }
    }
    private var headHeight: CGFloat {
        switch config.head {
        case .round: s * 0.42
        case .bean: s * 0.47
        case .square: s * 0.42
        case .tall: s * 0.5
        }
    }
    private var headY: CGFloat { -s * 0.07 }
    private var topY: CGFloat { headY - headHeight / 2 }

    var body: some View {
        ZStack {
            figure
                .frame(width: s, height: s)
                .clipShape(frameShape)
                .overlay { frameOverlay }
            if showsCompanion, config.companion != .none, size >= 40 {
                companionBadge
                    .offset(x: s * 0.38, y: s * 0.36)
            }
        }
        .frame(width: s, height: s)
        .accessibilityHidden(true)
    }

    // MARK: Figure

    private var figure: some View {
        ZStack {
            config.background.color.opacity(0.85)
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: s * 0.9)
                .offset(x: -s * 0.2, y: -s * 0.25)
            hairBack
            bodyShape
            headShape(config.skinColor)
                .frame(width: headWidth, height: headHeight)
                .offset(y: headY)
            face
            hairFront
            accessory
        }
    }

    private func headShape(_ color: Color) -> some View {
        Group {
            switch config.head {
            case .round: Circle().fill(color)
            case .bean: Ellipse().fill(color)
            case .square: RoundedRectangle(cornerRadius: s * 0.12, style: .continuous).fill(color)
            case .tall: Capsule().fill(color)
            }
        }
    }

    private var bodyShape: some View {
        let width = s * 0.74
        let height = s * 0.5
        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: s * 0.22, style: .continuous)
                .fill(config.outfit == .overalls ? Palette.cream : config.outfitUIColor)
            switch config.outfit {
            case .tee:
                Ellipse().fill(config.skinColor).frame(width: s * 0.16, height: s * 0.08).offset(y: -s * 0.03)
            case .hoodie:
                Capsule().fill(config.outfitUIColor.opacity(0.75)).overlay(Capsule().strokeBorder(Color.black.opacity(0.12), lineWidth: 1))
                    .frame(width: s * 0.36, height: s * 0.1).offset(y: -s * 0.02)
                HStack(spacing: s * 0.08) {
                    Capsule().fill(Color.white.opacity(0.8)).frame(width: s * 0.015, height: s * 0.1)
                    Capsule().fill(Color.white.opacity(0.8)).frame(width: s * 0.015, height: s * 0.1)
                }
                .offset(y: s * 0.07)
            case .stripe:
                VStack(spacing: s * 0.045) {
                    ForEach(0..<6, id: \.self) { _ in
                        Rectangle().fill(Palette.cream.opacity(0.9)).frame(height: s * 0.03)
                    }
                }
                .padding(.top, s * 0.08)
                .clipShape(RoundedRectangle(cornerRadius: s * 0.22, style: .continuous))
                Ellipse().fill(config.skinColor).frame(width: s * 0.14, height: s * 0.07).offset(y: -s * 0.03)
            case .overalls:
                RoundedRectangle(cornerRadius: s * 0.04).fill(config.outfitUIColor).frame(width: s * 0.3, height: s * 0.4).offset(y: s * 0.1)
                HStack(spacing: s * 0.2) {
                    Rectangle().fill(config.outfitUIColor).frame(width: s * 0.05, height: s * 0.14)
                    Rectangle().fill(config.outfitUIColor).frame(width: s * 0.05, height: s * 0.14)
                }
            case .sweater:
                Capsule().fill(config.outfitUIColor.opacity(0.7)).frame(width: s * 0.22, height: s * 0.07).offset(y: -s * 0.01)
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.15), lineWidth: 1).frame(width: s * 0.22, height: s * 0.07).offset(y: -s * 0.01))
            }
        }
        .frame(width: width, height: height)
        .offset(y: s * 0.4)
    }

    private var face: some View {
        let eyeY = headY - headHeight * 0.02
        let eyeX = headWidth * 0.22
        let eyeSize = max(2, s * 0.045)
        let ink = Palette.ink.opacity(0.9)
        return ZStack {
            if config.cheeks {
                Circle().fill(Palette.rose.opacity(0.55)).frame(width: s * 0.07).offset(x: -headWidth * 0.32, y: eyeY + headHeight * 0.14)
                Circle().fill(Palette.rose.opacity(0.55)).frame(width: s * 0.07).offset(x: headWidth * 0.32, y: eyeY + headHeight * 0.14)
            }
            eye(config.eyes == .wink ? .happy : config.eyes, size: eyeSize, color: ink).offset(x: -eyeX, y: eyeY)
            eye(config.eyes == .wink ? .dot : config.eyes, size: eyeSize, color: ink).offset(x: eyeX, y: eyeY)
            mouth(color: ink).offset(y: headY + headHeight * 0.2)
        }
    }

    @ViewBuilder
    private func eye(_ style: AvatarConfig.Eyes, size: CGFloat, color: Color) -> some View {
        switch style {
        case .dot, .wink:
            Circle().fill(color).frame(width: size, height: size * 1.15)
        case .happy:
            Circle().trim(from: 0.55, to: 0.95).stroke(color, style: StrokeStyle(lineWidth: max(1, s * 0.018), lineCap: .round))
                .frame(width: size * 1.6, height: size * 1.6)
                .offset(y: size * 0.3)
        case .sleepy:
            Capsule().fill(color).frame(width: size * 1.6, height: max(1, s * 0.016))
        }
    }

    @ViewBuilder
    private func mouth(color: Color) -> some View {
        let w = headWidth * 0.32
        switch config.mouth {
        case .smile:
            Circle().trim(from: 0.08, to: 0.42).stroke(color, style: StrokeStyle(lineWidth: max(1, s * 0.02), lineCap: .round))
                .frame(width: w, height: w)
                .offset(y: -w * 0.35)
        case .grin:
            Circle().trim(from: 0, to: 0.5).fill(color).frame(width: w, height: w).offset(y: -w * 0.3)
                .overlay(Circle().trim(from: 0, to: 0.5).fill(Palette.rose).frame(width: w * 0.55, height: w * 0.55).offset(y: -w * 0.12))
        case .flat:
            Capsule().fill(color).frame(width: w * 0.7, height: max(1, s * 0.018))
        case .o:
            Circle().strokeBorder(color, lineWidth: max(1, s * 0.018)).frame(width: w * 0.42, height: w * 0.5)
        }
    }

    // MARK: Hair

    private func cap(_ fraction: CGFloat, color: Color, scale: CGFloat = 1.08) -> some View {
        headShape(color)
            .frame(width: headWidth * scale, height: headHeight * scale)
            .mask(alignment: .top) {
                Rectangle().frame(height: headHeight * scale * fraction)
            }
            .offset(y: headY - headHeight * 0.03)
    }

    @ViewBuilder
    private var hairBack: some View {
        let color = config.hairUIColor
        switch config.hair {
        case .bob:
            RoundedRectangle(cornerRadius: s * 0.14, style: .continuous).fill(color)
                .frame(width: headWidth * 1.28, height: headHeight * 0.98)
                .offset(y: headY + headHeight * 0.06)
        case .long:
            RoundedRectangle(cornerRadius: s * 0.16, style: .continuous).fill(color)
                .frame(width: headWidth * 1.32, height: headHeight * 1.45)
                .offset(y: headY + headHeight * 0.32)
        case .curly:
            ForEach(0..<9, id: \.self) { index in
                let angle = Double(index) / 8 * .pi + .pi
                Circle().fill(color).frame(width: s * 0.16)
                    .offset(x: CGFloat(cos(angle)) * headWidth * 0.55, y: headY + CGFloat(sin(angle)) * headHeight * 0.5 + headHeight * 0.05)
            }
        case .bun:
            Circle().fill(color).frame(width: s * 0.18).offset(y: topY - s * 0.04)
        case .none, .buzz, .swoop:
            EmptyView()
        }
    }

    @ViewBuilder
    private var hairFront: some View {
        let color = config.hairUIColor
        switch config.hair {
        case .none:
            EmptyView()
        case .buzz:
            cap(0.26, color: color.opacity(0.88), scale: 1.03)
        case .bob, .long:
            cap(0.36, color: color)
        case .curly:
            cap(0.3, color: color)
        case .bun:
            cap(0.34, color: color)
        case .swoop:
            ZStack {
                cap(0.3, color: color)
                Ellipse().fill(color).frame(width: headWidth * 0.8, height: headHeight * 0.3)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -headWidth * 0.12, y: topY + headHeight * 0.14)
            }
        }
    }

    // MARK: Accessories

    @ViewBuilder
    private var accessory: some View {
        let eyeY = headY - headHeight * 0.02
        let eyeX = headWidth * 0.22
        switch config.accessory {
        case .none:
            EmptyView()
        case .glasses:
            let lens = s * 0.12
            ZStack {
                Circle().stroke(Palette.ink, lineWidth: max(1, s * 0.018)).frame(width: lens).offset(x: -eyeX)
                Circle().stroke(Palette.ink, lineWidth: max(1, s * 0.018)).frame(width: lens).offset(x: eyeX)
                Rectangle().fill(Palette.ink).frame(width: eyeX * 2 - lens, height: max(1, s * 0.016))
            }
            .offset(y: eyeY)
        case .beanie:
            ZStack {
                cap(0.42, color: Palette.burgundy, scale: 1.14)
                Capsule().fill(Palette.burgundy.opacity(0.85))
                    .frame(width: headWidth * 1.16, height: s * 0.07)
                    .offset(y: topY + headHeight * 0.36)
                Circle().fill(Palette.gold).frame(width: s * 0.09).offset(y: topY - s * 0.04)
            }
        case .flower:
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    let angle = Double(index) / 5 * 2 * .pi
                    Circle().fill(Palette.rose).frame(width: s * 0.06)
                        .offset(x: CGFloat(cos(angle)) * s * 0.035, y: CGFloat(sin(angle)) * s * 0.035)
                }
                Circle().fill(Palette.gold).frame(width: s * 0.045)
            }
            .offset(x: headWidth * 0.45, y: topY + headHeight * 0.18)
        case .headphones:
            ZStack {
                Circle().trim(from: 0.52, to: 0.98)
                    .stroke(Palette.ink.opacity(0.85), style: StrokeStyle(lineWidth: max(1.5, s * 0.035), lineCap: .round))
                    .frame(width: headWidth * 1.3, height: headWidth * 1.3)
                    .offset(y: headY)
                RoundedRectangle(cornerRadius: s * 0.03).fill(Palette.burgundy)
                    .frame(width: s * 0.08, height: s * 0.14).offset(x: -headWidth * 0.62, y: headY + s * 0.02)
                RoundedRectangle(cornerRadius: s * 0.03).fill(Palette.burgundy)
                    .frame(width: s * 0.08, height: s * 0.14).offset(x: headWidth * 0.62, y: headY + s * 0.02)
            }
        case .cap:
            ZStack {
                cap(0.36, color: Palette.sky, scale: 1.1)
                Capsule().fill(Palette.sky).frame(width: headWidth * 0.62, height: s * 0.05)
                    .offset(x: headWidth * 0.42, y: topY + headHeight * 0.32)
            }
        case .bandana:
            Capsule().fill(Palette.burgundy)
                .frame(width: headWidth * 1.04, height: s * 0.065)
                .offset(y: topY + headHeight * 0.26)
        }
    }

    // MARK: Frame & companion

    private var frameShape: AnyShape {
        switch config.frame {
        case .none, .gold: AnyShape(Circle())
        case .scallop: AnyShape(ScallopShape(bumps: 12, depth: 0.06))
        case .stamp: AnyShape(PerforatedShape(holeRadius: max(1.5, s * 0.025)))
        case .tape: AnyShape(RoundedRectangle(cornerRadius: s * 0.16, style: .continuous))
        }
    }

    @ViewBuilder
    private var frameOverlay: some View {
        switch config.frame {
        case .none:
            Circle().strokeBorder(Palette.ink.opacity(0.12), lineWidth: 1)
        case .gold:
            Circle().strokeBorder(
                AngularGradient(colors: [Palette.gold, Color(uiColor: UIColor(hex: 0xF4D78A)), Palette.gold, Color(uiColor: UIColor(hex: 0xA97C2A)), Palette.gold], center: .center),
                lineWidth: max(2, s * 0.06))
        case .scallop:
            ScallopShape(bumps: 12, depth: 0.06).stroke(Palette.burgundy.opacity(0.5), lineWidth: max(1, s * 0.02))
        case .stamp:
            Rectangle().strokeBorder(Palette.cream, lineWidth: max(2, s * 0.05)).padding(max(1.5, s * 0.025))
        case .tape:
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: s * 0.16, style: .continuous).strokeBorder(Palette.ink.opacity(0.12), lineWidth: 1)
                if size >= 36 {
                    TapeStrip(tint: .gold, width: s * 0.5, rotation: -6).offset(y: -s * 0.06)
                }
            }
        }
    }

    private var companionBadge: some View {
        let symbol: String = switch config.companion {
        case .none: ""
        case .sprout: "leaf.fill"
        case .cat: "cat.fill"
        case .snail: "tortoise.fill"
        case .bird: "bird.fill"
        }
        let tint: TintToken = switch config.companion {
        case .sprout: .sage
        case .cat: .orange
        case .snail: .gold
        case .bird: .sky
        case .none: .cream
        }
        return Image(systemName: symbol)
            .font(.system(size: s * 0.15, weight: .bold))
            .foregroundStyle(tint.onColor)
            .frame(width: s * 0.32, height: s * 0.32)
            .background(Circle().fill(tint.color))
            .overlay(Circle().strokeBorder(Palette.card, lineWidth: max(1.5, s * 0.025)))
    }
}

/// Overlapping friend avatars, optionally marking who completed.
struct AvatarStack: View {
    let avatars: [(id: UUID, config: AvatarConfig, done: Bool)]
    var size: CGFloat = 26
    var maxShown = 4

    var body: some View {
        HStack(spacing: -size * 0.32) {
            ForEach(Array(avatars.prefix(maxShown).enumerated()), id: \.element.id) { index, item in
                AvatarView(config: item.config, size: size, showsCompanion: false)
                    .overlay(Circle().strokeBorder(Palette.card, lineWidth: 2))
                    .overlay(alignment: .bottomTrailing) {
                        if item.done {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: size * 0.42, weight: .bold))
                                .foregroundStyle(Palette.onAccent, Palette.sage)
                                .background(Circle().fill(Palette.card).padding(1))
                                .offset(x: 3, y: 3)
                        }
                    }
                    .zIndex(Double(maxShown - index))
            }
            if avatars.count > maxShown {
                Text("+\(avatars.count - maxShown)")
                    .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkSecondary)
                    .frame(width: size, height: size)
                    .background(Circle().fill(Palette.paperDeep))
                    .overlay(Circle().strokeBorder(Palette.card, lineWidth: 2))
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(avatars.count) people, \(avatars.filter(\.done).count) done")
    }
}
