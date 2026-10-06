import SwiftUI

/// Circle with scalloped (bumpy) edge, like a bottle cap or rosette.
struct ScallopShape: Shape {
    var bumps = 14
    var depth: CGFloat = 0.08

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let inner = radius * (1 - depth)
        var path = Path()
        let steps = bumps * 12
        for i in 0...steps {
            let angle = Double(i) / Double(steps) * 2 * .pi
            let wave = (1 + cos(angle * Double(bumps))) / 2
            let r = inner + (radius - inner) * CGFloat(wave)
            let point = CGPoint(x: center.x + r * CGFloat(cos(angle)), y: center.y + r * CGFloat(sin(angle)))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct StarShape: Shape {
    var points = 5
    var innerRatio: CGFloat = 0.5

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        var path = Path()
        for i in 0..<(points * 2) {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let r = i.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(x: center.x + r * CGFloat(cos(angle)), y: center.y + r * CGFloat(sin(angle)))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

/// Admission-ticket rectangle with notches on both sides.
struct TicketShape: Shape {
    var cornerRadius: CGFloat = 10
    var notch: CGFloat = 0.14

    func path(in rect: CGRect) -> Path {
        let notchRadius = rect.height * notch
        let base = Path(roundedRect: rect, cornerRadius: cornerRadius)
        var notches = Path()
        notches.addEllipse(in: CGRect(x: rect.minX - notchRadius, y: rect.midY - notchRadius, width: notchRadius * 2, height: notchRadius * 2))
        notches.addEllipse(in: CGRect(x: rect.maxX - notchRadius, y: rect.midY - notchRadius, width: notchRadius * 2, height: notchRadius * 2))
        return base.subtracting(notches)
    }
}

/// Postage stamp with a perforated edge.
struct PerforatedShape: Shape {
    var holeRadius: CGFloat = 3.2

    func path(in rect: CGRect) -> Path {
        let base = Path(rect)
        var path = Path()
        let spacing = holeRadius * 3
        var x = rect.minX + spacing / 2
        while x < rect.maxX {
            path.addEllipse(in: CGRect(x: x - holeRadius, y: rect.minY - holeRadius, width: holeRadius * 2, height: holeRadius * 2))
            path.addEllipse(in: CGRect(x: x - holeRadius, y: rect.maxY - holeRadius, width: holeRadius * 2, height: holeRadius * 2))
            x += spacing
        }
        var y = rect.minY + spacing / 2
        while y < rect.maxY {
            path.addEllipse(in: CGRect(x: rect.minX - holeRadius, y: y - holeRadius, width: holeRadius * 2, height: holeRadius * 2))
            path.addEllipse(in: CGRect(x: rect.maxX - holeRadius, y: y - holeRadius, width: holeRadius * 2, height: holeRadius * 2))
            y += spacing
        }
        return base.subtracting(path)
    }
}

/// Award ribbon: a disc with two tails.
struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let discSize = min(rect.width, rect.height * 0.72)
        let disc = CGRect(x: rect.midX - discSize / 2, y: rect.minY, width: discSize, height: discSize)
        var path = Path()
        let tailTop = disc.midY + discSize * 0.2
        let tailWidth = discSize * 0.28
        // Left tail
        path.move(to: CGPoint(x: rect.midX - tailWidth * 1.2, y: tailTop))
        path.addLine(to: CGPoint(x: rect.midX - tailWidth * 1.5, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - tailWidth * 0.85, y: rect.maxY - tailWidth * 0.5))
        path.addLine(to: CGPoint(x: rect.midX - tailWidth * 0.3, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - tailWidth * 0.1, y: tailTop))
        path.closeSubpath()
        // Right tail
        path.move(to: CGPoint(x: rect.midX + tailWidth * 1.2, y: tailTop))
        path.addLine(to: CGPoint(x: rect.midX + tailWidth * 1.5, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + tailWidth * 0.85, y: rect.maxY - tailWidth * 0.5))
        path.addLine(to: CGPoint(x: rect.midX + tailWidth * 0.3, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + tailWidth * 0.1, y: tailTop))
        path.closeSubpath()
        // Union (not addPath) so overlapping tails don't punch holes in the disc.
        return path.union(ScallopShape(bumps: 16, depth: 0.07).path(in: disc))
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.95))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.02, y: rect.minY + h * 0.32),
                      control1: CGPoint(x: rect.minX + w * 0.3, y: rect.minY + h * 0.78),
                      control2: CGPoint(x: rect.minX - w * 0.04, y: rect.minY + h * 0.55))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.18),
                      control1: CGPoint(x: rect.minX + w * 0.08, y: rect.minY + h * 0.02),
                      control2: CGPoint(x: rect.minX + w * 0.4, y: rect.minY + h * 0.0))
        path.addCurve(to: CGPoint(x: rect.maxX - w * 0.02, y: rect.minY + h * 0.32),
                      control1: CGPoint(x: rect.maxX - w * 0.4, y: rect.minY + h * 0.0),
                      control2: CGPoint(x: rect.maxX - w * 0.08, y: rect.minY + h * 0.02))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.95),
                      control1: CGPoint(x: rect.maxX + w * 0.04, y: rect.minY + h * 0.55),
                      control2: CGPoint(x: rect.maxX - w * 0.3, y: rect.minY + h * 0.78))
        path.closeSubpath()
        return path
    }
}

/// Rounded hexagon badge.
struct BadgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var points: [CGPoint] = []
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3 - .pi / 2
            points.append(CGPoint(x: center.x + radius * CGFloat(cos(angle)), y: center.y + radius * CGFloat(sin(angle))))
        }
        var path = Path()
        let corner = radius * 0.18
        for i in 0..<6 {
            let current = points[i]
            let next = points[(i + 1) % 6]
            let previous = points[(i + 5) % 6]
            let start = interpolate(current, previous, corner / radius)
            let end = interpolate(current, next, corner / radius)
            if i == 0 { path.move(to: start) } else { path.addLine(to: start) }
            path.addQuadCurve(to: end, control: current)
        }
        path.closeSubpath()
        return path
    }

    private func interpolate(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}

/// A slightly wobbly rounded rectangle for a hand-cut paper look.
struct WobblyRect: Shape {
    var seed: UInt64 = 1
    var amount: CGFloat = 1.6

    func path(in rect: CGRect) -> Path {
        var rng = SeededGenerator(seed: seed)
        func jitter() -> CGFloat { CGFloat(Double.random(in: -1...1, using: &rng)) * amount }
        let r: CGFloat = min(14, min(rect.width, rect.height) / 4)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY + jitter()))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: rect.minY + jitter()), control: CGPoint(x: rect.midX, y: rect.minY + jitter()))
        path.addQuadCurve(to: CGPoint(x: rect.maxX + jitter(), y: rect.minY + r), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX + jitter(), y: rect.maxY - r), control: CGPoint(x: rect.maxX + jitter(), y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: rect.maxY + jitter()), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.maxY + jitter()), control: CGPoint(x: rect.midX, y: rect.maxY + jitter()))
        path.addQuadCurve(to: CGPoint(x: rect.minX + jitter(), y: rect.maxY - r), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX + jitter(), y: rect.minY + r), control: CGPoint(x: rect.minX + jitter(), y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY + jitter()), control: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

/// Type-erased sticker silhouette.
struct StickerSilhouette: Shape {
    var shape: StickerShape

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .circle: Circle().path(in: rect)
        case .scallop: ScallopShape().path(in: rect)
        case .star: StarShape(points: 6, innerRatio: 0.62).path(in: rect)
        case .ticket: TicketShape().path(in: rect.insetBy(dx: 0, dy: rect.height * 0.16))
        case .stamp: PerforatedShape().path(in: rect.insetBy(dx: rect.width * 0.06, dy: rect.height * 0.06))
        case .ribbon: RibbonShape().path(in: rect)
        case .heart: HeartShape().path(in: rect)
        case .badge: BadgeShape().path(in: rect)
        }
    }
}
