import SwiftUI

/// Paper grain: a fine dot grid (radial-gradient 11px pattern).
struct Grain: View {
    @Environment(\.pal) private var c
    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            var y: CGFloat = 0
            while y < size.height + 11 {
                var x: CGFloat = 0
                while x < size.width + 11 {
                    p.addEllipse(in: CGRect(x: x - 0.85, y: y - 0.85, width: 1.7, height: 1.7))
                    x += 11
                }
                y += 11
            }
            ctx.fill(p, with: .color(c.grain))
        }
        .allowsHitTesting(false)
    }
}

/// repeating-linear-gradient(90deg, …) with hard stops.
struct Stripes: View {
    let bands: [(Color, CGFloat)]   // colour + width
    var body: some View {
        Canvas { ctx, size in
            let period = bands.reduce(0) { $0 + $1.1 }
            var x: CGFloat = 0
            while x < size.width {
                for (col, w) in bands {
                    ctx.fill(Path(CGRect(x: x, y: 0, width: w + 0.5, height: size.height)), with: .color(col))
                    x += w
                }
                if period <= 0 { break }
            }
        }
    }

    /// The burgundy theatre curtain used on posters, the ticket and the recap.
    static let curtain = Stripes(bands: [(Color(hex: 0x3A0A12), 6), (Color(hex: 0x5A1220), 10), (Color(hex: 0x8A2233), 6), (Color(hex: 0x5A1220), 8)])
    static let splash = Stripes(bands: [(Color(hex: 0x2A0710), 4), (Color(hex: 0x4E101C), 10), (Color(hex: 0x7A1E2E), 8), (Color(hex: 0x4E101C), 8)])
    static let drape = Stripes(bands: [(Color(hex: 0x3A0A12), 6), (Color(hex: 0x5A1220), 10), (Color(hex: 0x8A2233), 8), (Color(hex: 0x6F1725), 8), (Color(hex: 0x3A0A12), 8)])
    static let valance = Stripes(bands: [(Color(hex: 0x3A0A12), 10), (Color(hex: 0x6F1725), 12), (Color(hex: 0x4E101C), 8)])
}

/// The black-and-cream checker floor seen in perspective.
struct CheckerFloor: View {
    var cell: CGFloat = 28
    var tilt: Double = 55
    var perspective: CGFloat = 0.6
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x151010)))
            var p = Path()
            let h = cell / 2
            var row = 0
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = row % 2 == 0 ? 0 : h
                while x < size.width {
                    p.addRect(CGRect(x: x, y: y, width: h, height: h))
                    x += cell
                }
                y += h; row += 1
            }
            ctx.fill(p, with: .color(Color(hex: 0xEFE6DA)))
        }
        .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: perspective)
        .allowsHitTesting(false)
    }
}

/// The burgundy "stage photo" fill used for proof photos.
struct PhotoFill: View {
    var floorCell: CGFloat = 28
    var floorHeight: CGFloat = 90
    var floorOpacity: Double = 0.3
    var center = UnitPoint(x: 0.5, y: 0.32)
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .bottom) {
                RadialGradient(stops: [.init(color: Brand.wine3, location: 0), .init(color: Brand.wine, location: 0.48), .init(color: Brand.wineInk, location: 0.92)],
                               center: center, startRadius: 0, endRadius: max(g.size.width, g.size.height) * 0.6)
                CheckerFloor(cell: floorCell)
                    .frame(width: g.size.width * 1.4, height: floorHeight)
                    .offset(y: floorHeight * 0.4)
                    .opacity(floorOpacity)
            }
            .frame(width: g.size.width, height: g.size.height)
        }
        .clipped()
    }
}

/// Community poster looks.
enum PosterLook: String { case wine, curtain, ink, paper }

struct PosterBackground: View {
    let look: PosterLook
    var body: some View {
        switch look {
        case .wine:
            GeometryReader { g in
                RadialGradient(stops: [.init(color: Brand.wine3, location: 0), .init(color: Brand.wine, location: 0.48), .init(color: Brand.wineInk, location: 1)],
                               center: UnitPoint(x: 0.4, y: 0.25), startRadius: 0, endRadius: max(g.size.width, g.size.height) * 0.95)
            }
        case .curtain:
            ZStack {
                Stripes.curtain
                GeometryReader { g in
                    RadialGradient(colors: [Color(red: 1, green: 150 / 255, blue: 160 / 255).opacity(0.3), .clear],
                                   center: UnitPoint(x: 0.35, y: 0.35), startRadius: 0, endRadius: max(g.size.width, g.size.height) * 0.6)
                }
                LinearGradient(stops: [.init(color: .clear, location: 0.35), .init(color: .black.opacity(0.55), location: 1)], startPoint: .top, endPoint: .bottom)
            }
        case .ink:
            Color(hex: 0x161012)
        case .paper:
            Color(hex: 0xF7F3EE)
        }
    }
    static func ink(_ look: PosterLook) -> Color {
        switch look {
        case .ink: return Color(hex: 0xF3EAE4)
        case .paper: return Color(hex: 0x141010)
        default: return Brand.onWine
        }
    }
}

/// Washi tape strip.
struct Tape: View {
    @Environment(\.pal) private var c
    var wine = false
    var body: some View {
        ZStack {
            (wine ? c.acc.opacity(0.45) : Brand.gold2.opacity(0.7))
            Stripes(bands: [(Color.white.opacity(0.35), 3), (Color.clear, 6)])
        }
        .frame(width: 64, height: 16)
        .clipShape(TapeShape())
        .opacity(0.85)
    }
}

struct TapeShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let pts: [(CGFloat, CGFloat)] = [(0.03, 0), (0.97, 0.04), (1, 0.5), (0.97, 0.96), (0.03, 1), (0, 0.5)]
        p.move(to: CGPoint(x: r.minX + pts[0].0 * r.width, y: r.minY + pts[0].1 * r.height))
        for q in pts.dropFirst() { p.addLine(to: CGPoint(x: r.minX + q.0 * r.width, y: r.minY + q.1 * r.height)) }
        p.closeSubpath()
        return p
    }
}

/// Horizontal ruled lines every 28pt (.ruled).
struct Ruled: View {
    let color: Color
    var marginX: CGFloat? = nil
    var marginColor: Color = .clear
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 27
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(color))
                y += 28
            }
            if let mx = marginX { ctx.fill(Path(CGRect(x: mx, y: 0, width: 1, height: size.height)), with: .color(marginColor)) }
        }
        .allowsHitTesting(false)
    }
}
