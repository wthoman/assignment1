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

/// A demo check-in photo for seed data: a soft-lit scene in the habit's colours with its icon as the subject.
/// `variant` moves the light and shifts the colours so friends' photos don't all look alike.
struct SamplePhoto: View {
    let ic: String
    var variant = 0
    private static let looks: [String: (top: UInt32, bottom: UInt32, glow: UInt32)] = [
        "water": (0xA9DCEB, 0x2D6A8A, 0xE9FBFF), "run": (0xF7C887, 0xB9473A, 0xFFF1C9), "read": (0xEFDDC2, 0x8A5A3C, 0xFFF6E2),
        "study": (0x4A4E6E, 0x1B1D30, 0xF3C67A), "calm": (0xCFC0EA, 0x5B4888, 0xF8F0FF), "phone": (0x3A3A48, 0x15151C, 0x9FB4FF),
        "sleep": (0x46507E, 0x171A33, 0xD9DEFF), "eat": (0xC9E2A4, 0x4F7A3A, 0xF6FFE6), "pray": (0xF3D9B0, 0x9A6B48, 0xFFF4DE),
        "create": (0xF4C6B8, 0xA2486A, 0xFFEFE8), "strength": (0xC9CED6, 0x464D5A, 0xFFFFFF), "sunrise": (0xFFD39A, 0xD0614A, 0xFFF6D6),
        "talk": (0xBFE0D8, 0x3E7A70, 0xF0FFFB), "music": (0xE7B7D6, 0x6E3466, 0xFFE9F6), "clean": (0xD8EEF0, 0x5C8C93, 0xFFFFFF),
        "pill": (0xF0D2D2, 0x9C4D57, 0xFFF3F3)
    ]
    var body: some View {
        let look = Self.looks[ic] ?? Self.looks["clean"]!
        let v = abs(variant) % 3
        let light = [UnitPoint(x: 0.28, y: 0.22), UnitPoint(x: 0.74, y: 0.18), UnitPoint(x: 0.5, y: 0.34)][v]
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: look.top), Color(hex: look.bottom)], startPoint: .top, endPoint: .bottom)
                    .hueRotation(.degrees(Double(v) * 9 - 9))
                RadialGradient(colors: [Color(hex: look.glow).opacity(0.85), .clear], center: light, startRadius: 0, endRadius: max(w, h) * 0.62)
                // out-of-focus lights
                ForEach(0..<6, id: \.self) { k in
                    let x = CGFloat((k * 37 + v * 23) % 100) / 100, y = CGFloat((k * 53 + v * 31) % 60) / 100
                    Circle().fill(Color(hex: look.glow).opacity(0.18 + Double(k % 3) * 0.06))
                        .frame(width: w * (0.14 + CGFloat(k % 3) * 0.07))
                        .blur(radius: w * 0.025)
                        .position(x: x * w, y: y * h)
                }
                // the surface it's sitting on
                Ellipse().fill(Color(hex: look.bottom).opacity(0.55))
                    .frame(width: w * 1.5, height: h * 0.42)
                    .position(x: w / 2, y: h * 1.02)
                    .blur(radius: w * 0.02)
                Ellipse().fill(.black.opacity(0.22))
                    .frame(width: w * 0.5, height: h * 0.06)
                    .position(x: w / 2, y: h * 0.72)
                    .blur(radius: w * 0.03)
                HIcon(ic, min(w, h) * 0.5, 1.6)
                    .foregroundStyle(.white.opacity(0.94))
                    .shadow(color: .black.opacity(0.28), radius: w * 0.03, y: w * 0.02)
                    .rotationEffect(.degrees(Double(v) * 6 - 6))
                    .position(x: w / 2, y: h * 0.5)
                // vignette
                RadialGradient(colors: [.clear, .black.opacity(0.28)], center: .center, startRadius: min(w, h) * 0.35, endRadius: max(w, h) * 0.8)
            }
            .frame(width: w, height: h)
        }
        .clipped()
        .accessibilityLabel("Sample photo")
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
