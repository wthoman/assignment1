import SwiftUI

/// Small SVG reader so the mock-up's hand-drawn icons, avatars and trophies render natively
/// from the exact same path data.
enum SVG {
    private static var cache: [String: Path] = [:]

    /// Parses a list of `<path>`, `<circle>`, `<rect>`, `<ellipse>` elements into one path.
    static func markup(_ m: String) -> Path {
        if let p = cache[m] { return p }
        var out = Path()
        let ns = m as NSString
        for match in elementRegex.matches(in: m, range: NSRange(location: 0, length: ns.length)) {
            let tag = ns.substring(with: match.range(at: 1))
            let attrs = attributes(ns.substring(with: match.range(at: 2)))
            out.addPath(element(tag, attrs))
        }
        cache[m] = out
        return out
    }

    /// Parses a single path `d` string.
    static func path(_ d: String) -> Path {
        if let p = cache["d:" + d] { return p }
        let p = parse(d)
        cache["d:" + d] = p
        return p
    }

    private static let elementRegex = try! NSRegularExpression(pattern: "<(path|circle|rect|ellipse)\\b([^>]*)/?>")
    private static let attrRegex = try! NSRegularExpression(pattern: "([a-zA-Z-]+)=\"([^\"]*)\"")

    private static func attributes(_ s: String) -> [String: String] {
        var out: [String: String] = [:]
        let ns = s as NSString
        for m in attrRegex.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            out[ns.substring(with: m.range(at: 1))] = ns.substring(with: m.range(at: 2))
        }
        return out
    }

    static func element(_ tag: String, _ a: [String: String]) -> Path {
        func n(_ k: String) -> CGFloat { CGFloat(Double(a[k] ?? "0") ?? 0) }
        var p: Path
        switch tag {
        case "circle":
            let r = n("r")
            p = Path(ellipseIn: CGRect(x: n("cx") - r, y: n("cy") - r, width: r * 2, height: r * 2))
        case "ellipse":
            p = Path(ellipseIn: CGRect(x: n("cx") - n("rx"), y: n("cy") - n("ry"), width: n("rx") * 2, height: n("ry") * 2))
        case "rect":
            let r = CGRect(x: n("x"), y: n("y"), width: n("width"), height: n("height"))
            let rx = min(n("rx"), r.width / 2, r.height / 2)
            p = rx > 0 ? Path(roundedRect: r, cornerSize: CGSize(width: rx, height: rx)) : Path(r)
        default:
            p = parse(a["d"] ?? "")
        }
        if let t = a["transform"], t.hasPrefix("rotate(") {
            let nums = t.dropFirst(7).dropLast().split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
            if let deg = nums.first {
                let cx = nums.count > 2 ? nums[1] : 0, cy = nums.count > 2 ? nums[2] : 0
                let tr = CGAffineTransform(translationX: cx, y: cy).rotated(by: deg * .pi / 180).translatedBy(x: -cx, y: -cy)
                p = p.applying(tr)
            }
        }
        return p
    }

    // MARK: path data

    private enum Tok { case cmd(Character), num(CGFloat) }

    private static func tokenize(_ s: String) -> [Tok] {
        let b = Array(s.utf8)
        var out: [Tok] = []
        var i = 0
        let cmds = Set("MmLlHhVvCcSsQqTtAaZz".utf8)
        func isDigit(_ c: UInt8) -> Bool { c >= 48 && c <= 57 }
        while i < b.count {
            let c = b[i]
            if cmds.contains(c) {
                out.append(.cmd(Character(UnicodeScalar(c)))); i += 1; continue
            }
            if c == 45 || c == 43 || c == 46 || isDigit(c) {
                var j = i
                if c == 45 || c == 43 { j += 1 }
                var dot = false, exp = false
                while j < b.count {
                    let ch = b[j]
                    if isDigit(ch) { j += 1 }
                    else if ch == 46 && !dot && !exp { dot = true; j += 1 }
                    else if (ch == 101 || ch == 69) && !exp {
                        exp = true; j += 1
                        if j < b.count, b[j] == 45 || b[j] == 43 { j += 1 }
                    } else { break }
                }
                let str = String(decoding: b[i..<j], as: UTF8.self)
                out.append(.num(CGFloat(Double(str) ?? 0)))
                i = j
                continue
            }
            i += 1
        }
        return out
    }

    private static func parse(_ d: String) -> Path {
        let toks = tokenize(d)
        var p = Path()
        var i = 0
        var cmd: Character = "M"
        var cur = CGPoint.zero, start = CGPoint.zero
        var lastC: CGPoint? = nil   // last cubic control point (for S)
        var lastQ: CGPoint? = nil   // last quad control point (for T)

        func num() -> CGFloat {
            guard i < toks.count, case .num(let v) = toks[i] else { return 0 }
            i += 1; return v
        }
        func hasNum() -> Bool {
            guard i < toks.count, case .num = toks[i] else { return false }
            return true
        }

        while i < toks.count {
            if case .cmd(let c) = toks[i] {
                cmd = c; i += 1
                if c == "Z" || c == "z" {
                    p.closeSubpath(); cur = start; lastC = nil; lastQ = nil
                    continue
                }
            } else if cmd == "Z" || cmd == "z" {
                i += 1; continue
            }
            guard hasNum() else { continue }
            let rel = cmd.isLowercase
            let o = rel ? cur : .zero
            var nextC: CGPoint? = nil, nextQ: CGPoint? = nil
            switch cmd {
            case "M", "m":
                let pt = CGPoint(x: o.x + num(), y: o.y + num())
                p.move(to: pt); cur = pt; start = pt
                cmd = rel ? "l" : "L"
            case "L", "l":
                let pt = CGPoint(x: o.x + num(), y: o.y + num())
                p.addLine(to: pt); cur = pt
            case "H", "h":
                let pt = CGPoint(x: (rel ? cur.x : 0) + num(), y: cur.y)
                p.addLine(to: pt); cur = pt
            case "V", "v":
                let pt = CGPoint(x: cur.x, y: (rel ? cur.y : 0) + num())
                p.addLine(to: pt); cur = pt
            case "C", "c":
                let c1 = CGPoint(x: o.x + num(), y: o.y + num())
                let c2 = CGPoint(x: o.x + num(), y: o.y + num())
                let pt = CGPoint(x: o.x + num(), y: o.y + num())
                p.addCurve(to: pt, control1: c1, control2: c2); cur = pt; nextC = c2
            case "S", "s":
                let c1 = lastC.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let c2 = CGPoint(x: o.x + num(), y: o.y + num())
                let pt = CGPoint(x: o.x + num(), y: o.y + num())
                p.addCurve(to: pt, control1: c1, control2: c2); cur = pt; nextC = c2
            case "Q", "q":
                let c1 = CGPoint(x: o.x + num(), y: o.y + num())
                let pt = CGPoint(x: o.x + num(), y: o.y + num())
                p.addQuadCurve(to: pt, control: c1); cur = pt; nextQ = c1
            case "T", "t":
                let c1 = lastQ.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let pt = CGPoint(x: o.x + num(), y: o.y + num())
                p.addQuadCurve(to: pt, control: c1); cur = pt; nextQ = c1
            case "A", "a":
                let rx = num(), ry = num(), rot = num(), large = num() != 0, sweep = num() != 0
                let pt = CGPoint(x: o.x + num(), y: o.y + num())
                arc(&p, from: cur, to: pt, rx: rx, ry: ry, phiDeg: rot, large: large, sweep: sweep)
                cur = pt
            default:
                i += 1
            }
            lastC = nextC; lastQ = nextQ
        }
        return p
    }

    private static func arc(_ p: inout Path, from p1: CGPoint, to p2: CGPoint, rx rxIn: CGFloat, ry ryIn: CGFloat,
                            phiDeg: CGFloat, large: Bool, sweep: Bool) {
        if p1 == p2 { return }
        var rx = abs(rxIn), ry = abs(ryIn)
        if rx == 0 || ry == 0 { p.addLine(to: p2); return }
        let phi = phiDeg * .pi / 180, cp = cos(phi), sp = sin(phi)
        let dx2 = (p1.x - p2.x) / 2, dy2 = (p1.y - p2.y) / 2
        let x1p = cp * dx2 + sp * dy2, y1p = -sp * dx2 + cp * dy2
        let lam = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lam > 1 { rx *= sqrt(lam); ry *= sqrt(lam) }
        let num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
        let den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
        let coef = (large != sweep ? 1 : -1) * sqrt(max(0, num / den))
        let cxp = coef * rx * y1p / ry, cyp = coef * -ry * x1p / rx
        let cx = cp * cxp - sp * cyp + (p1.x + p2.x) / 2
        let cy = sp * cxp + cp * cyp + (p1.y + p2.y) / 2
        func ang(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat { atan2(ux * vy - uy * vx, ux * vx + uy * vy) }
        let t1 = ang(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
        var dt = ang((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
        if !sweep && dt > 0 { dt -= 2 * .pi }
        if sweep && dt < 0 { dt += 2 * .pi }
        let segs = max(1, Int(ceil(abs(dt) / (.pi / 2))))
        let delta = dt / CGFloat(segs)
        let alpha = 4 / 3 * tan(delta / 4)
        func pt(_ t: CGFloat) -> CGPoint {
            CGPoint(x: cx + rx * cos(t) * cp - ry * sin(t) * sp, y: cy + rx * cos(t) * sp + ry * sin(t) * cp)
        }
        func dv(_ t: CGFloat) -> CGPoint {
            CGPoint(x: -rx * sin(t) * cp - ry * cos(t) * sp, y: -rx * sin(t) * sp + ry * cos(t) * cp)
        }
        var a = t1
        for k in 0..<segs {
            let b = a + delta
            let s = pt(a), e = k == segs - 1 ? p2 : pt(b)
            let da = dv(a), db = dv(b)
            p.addCurve(to: e,
                       control1: CGPoint(x: s.x + alpha * da.x, y: s.y + alpha * da.y),
                       control2: CGPoint(x: e.x - alpha * db.x, y: e.y - alpha * db.y))
            a = b
        }
    }
}

/// A path drawn in a fixed viewBox, scaled to fit its frame.
struct ViewBoxShape: Shape {
    let path: Path
    var box: CGFloat = 24
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / box
        let dx = rect.minX + (rect.width - box * s) / 2, dy = rect.minY + (rect.height - box * s) / 2
        return path.applying(CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: dx, ty: dy))
    }
}
