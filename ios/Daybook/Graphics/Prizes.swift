import SwiftUI

/// Trophies & medals, drawn from the mock-up's SVGs.
enum Tier {
    static func colors(_ tier: String) -> [Color] {
        switch tier {
        case "bronze": return [Color(hex: 0xF0C49A), Color(hex: 0xB7743F), Color(hex: 0x7A4520)]
        case "silver": return [Color(hex: 0xF4F5F7), Color(hex: 0xBBC1C7), Color(hex: 0x7B838B)]
        case "platinum": return [Color(hex: 0xFBFAFF), Color(hex: 0xCFCCE0), Color(hex: 0x8C88A6)]
        default: return [Color(hex: 0xF6DE8F), Color(hex: 0xC9A04A), Color(hex: 0x8C6A22)]
        }
    }
    static func level(_ tier: String) -> Int { ["bronze": 1, "silver": 2, "gold": 3, "platinum": 4][tier] ?? 1 }
}

struct CupArt: View {
    let tier: String
    var body: some View {
        Canvas { ctx, size in
            let t = Tier.colors(tier)
            ctx.scaleBy(x: size.width / 120, y: size.height / 160)
            func grad(_ p: Path) -> GraphicsContext.Shading {
                let r = p.boundingRect
                return .linearGradient(Gradient(stops: [.init(color: t[2], location: 0), .init(color: t[0], location: 0.35),
                                                        .init(color: t[1], location: 0.7), .init(color: t[2], location: 1)]),
                                       startPoint: CGPoint(x: r.minX, y: r.midY), endPoint: CGPoint(x: r.maxX, y: r.midY))
            }
            let cup = SVG.path("M30 14h60v30c0 20-13 36-30 36S30 64 30 44z")
            ctx.fill(cup, with: grad(cup))
            let handles = SVG.path("M30 22H16c0 18 8 28 18 30M90 22h14c0 18-8 28-18 30")
            ctx.stroke(handles, with: grad(handles), style: StrokeStyle(lineWidth: 7, lineCap: .round))
            let stem = Path(CGRect(x: 52, y: 78, width: 16, height: 22))
            ctx.fill(stem, with: grad(stem))
            let foot = SVG.path("M38 100h44l6 16H32z")
            ctx.fill(foot, with: grad(foot))
            ctx.fill(Path(roundedRect: CGRect(x: 24, y: 116, width: 72, height: 30), cornerRadius: 3), with: .color(Brand.wineDeep))
            let plate = Path(roundedRect: CGRect(x: 40, y: 124, width: 40, height: 13), cornerRadius: 2)
            ctx.opacity = 0.85
            ctx.fill(plate, with: grad(plate))
            ctx.opacity = 0.5
            ctx.fill(SVG.path("M60 28l4 9 9.8.9-7.4 6.5 2.2 9.6L60 49l-8.6 5 2.2-9.6-7.4-6.5 9.8-.9z"), with: .color(.white))
        }
        .aspectRatio(120 / 160, contentMode: .fit)
    }
}

struct MedalArt: View {
    let tier: String
    var body: some View {
        Canvas { ctx, size in
            let t = Tier.colors(tier)
            ctx.scaleBy(x: size.width / 100, y: size.height / 140)
            ctx.fill(SVG.path("M26 2h18l16 58H42z"), with: .color(Brand.wine))
            ctx.fill(SVG.path("M56 2h18L58 60H40z"), with: .color(Brand.wine2))
            ctx.fill(SVG.path("M33 2h4l14 52h-4zM63 2h4L53 54h-4z"), with: .color(Brand.gold2.opacity(0.85)))
            let disc = Path(ellipseIn: CGRect(x: 14, y: 58, width: 72, height: 72))
            ctx.fill(disc, with: .radialGradient(Gradient(stops: [.init(color: t[0], location: 0), .init(color: t[1], location: 0.6), .init(color: t[2], location: 1)]),
                                                 center: CGPoint(x: 14 + 72 * 0.38, y: 58 + 72 * 0.32), startRadius: 0, endRadius: 72 * 0.75))
            ctx.stroke(Path(ellipseIn: CGRect(x: 23, y: 67, width: 54, height: 54)), with: .color(t[2].opacity(0.55)), lineWidth: 2.4)
            ctx.fill(SVG.path("M50 76l5.2 10.6 11.7 1.7-8.5 8.2 2 11.6L50 102.6l-10.4 5.5 2-11.6-8.5-8.2 11.7-1.7z"), with: .color(.white.opacity(0.55)))
        }
        .aspectRatio(100 / 140, contentMode: .fit)
    }
}

/// `prize(t, w)`: trophies at width w, medals at .82w.
struct PrizeArt: View {
    let trophy: Trophy
    let width: CGFloat
    var body: some View {
        if trophy.kind == "trophy" {
            CupArt(tier: trophy.tier).frame(width: width)
        } else {
            MedalArt(tier: trophy.tier).frame(width: width * 0.82)
        }
    }
}

struct TierDots: View {
    @Environment(\.pal) private var c
    let tier: String
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...4, id: \.self) { i in
                Circle().fill(i <= Tier.level(tier) ? Brand.gold : c.line).frame(width: 6, height: 6)
            }
        }
    }
}
