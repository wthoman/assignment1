import SwiftUI

/// Preset drawn avatars (Creds look, limited customisation).
struct AvatarPreset {
    let n: String
    let bg, skin, hair, shirt: String
    let st: String
    var gl = false
}

enum Avatars {
    static let all: [String: AvatarPreset] = [
        "a1": AvatarPreset(n: "Bob", bg: "E9CFC9", skin: "F1C8A6", hair: "3A2219", shirt: "6F1725", st: "bob"),
        "a2": AvatarPreset(n: "Bun", bg: "DED6E6", skin: "E8B98E", hair: "1E1412", shirt: "2D2A33", st: "bun"),
        "a3": AvatarPreset(n: "Crop", bg: "CFDCE3", skin: "C98E62", hair: "2A1A12", shirt: "B8913A", st: "short"),
        "a4": AvatarPreset(n: "Waves", bg: "F0DFC2", skin: "F5D2B5", hair: "8A4A26", shirt: "8A2233", st: "long", gl: true),
        "a5": AvatarPreset(n: "Curls", bg: "E6D3D7", skin: "9A6544", hair: "16100E", shirt: "E2C67A", st: "curly"),
        "a6": AvatarPreset(n: "Buzz", bg: "D7E0CF", skin: "E2AE84", hair: "4A2C1A", shirt: "3A4A5E", st: "buzz"),
        "a7": AvatarPreset(n: "Sunny", bg: "E8D9C6", skin: "F0C49E", hair: "C9A15A", shirt: "6F1725", st: "short", gl: true),
        "a8": AvatarPreset(n: "Fade", bg: "DCD4CC", skin: "7A4D33", hair: "120C0A", shirt: "B8913A", st: "buzz"),
        "a9": AvatarPreset(n: "Long", bg: "EAD3CF", skin: "E9BE96", hair: "5B2A1A", shirt: "3A0A12", st: "long"),
        "a10": AvatarPreset(n: "Specs", bg: "D3D9E2", skin: "F3D0B0", hair: "2B1D16", shirt: "8C6A22", st: "bob", gl: true)
    ]
    static let pickable = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"]

    static let caps: [String: String] = [
        "bob": "M29 44 C30 27 70 27 71 44 C64 37 56 34 47 35 C40 36 33 39 29 44Z",
        "bun": "M29 45 C29 27 71 27 71 45 C66 38 58 35 50 35 C42 35 34 38 29 45Z",
        "short": "M29 43 C29 25 71 25 71 43 C69 37 64 33 57 33 C52 36 44 37 36 36 C33 38 30 40 29 43Z",
        "long": "M29 44 C30 27 70 27 71 44 C64 37 56 34 47 35 C40 36 33 39 29 44Z",
        "buzz": "M30 42 C30 27 70 27 70 42 C66 36 58 33 50 33 C42 33 34 36 30 42Z"
    ]
    static let backs: [String: String] = [
        "bob": "M27 46 C27 24 73 24 73 46 L74 66 C66 70 34 70 26 66Z",
        "long": "M26 46 C26 22 74 22 74 46 L77 92 L23 92Z"
    ]
}

/// The drawn face itself (svg viewBox 0 0 100 100, clipped to a circle).
struct AvatarArt: View {
    let id: String
    var body: some View {
        Canvas { ctx, size in
            let a = Avatars.all[id] ?? Avatars.all["a1"]!
            let s = size.width / 100
            ctx.scaleBy(x: s, y: s)
            ctx.clip(to: Path(ellipseIn: CGRect(x: 0, y: 0, width: 100, height: 100)))
            let hair = Color(hexString: a.hair), skin = Color(hexString: a.skin)
            func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path { Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)) }
            ctx.fill(Path(CGRect(x: 0, y: 0, width: 100, height: 100)), with: .color(Color(hexString: a.bg)))
            ctx.fill(circle(30, 24, 24), with: .color(.white.opacity(0.2)))
            // hair behind the head
            if a.st == "bun" {
                ctx.fill(circle(50, 21, 10), with: .color(hair))
            } else if a.st == "curly" {
                for (x, y) in [(31, 37), (37, 29), (46, 25), (55, 25), (63, 29), (69, 37), (72, 47), (28, 47)] as [(CGFloat, CGFloat)] {
                    ctx.fill(circle(x, y, 8), with: .color(hair))
                }
            } else if let b = Avatars.backs[a.st] {
                ctx.fill(SVG.path(b), with: .color(hair))
            }
            ctx.fill(Path(roundedRect: CGRect(x: 20, y: 72, width: 60, height: 44), cornerRadius: 24), with: .color(Color(hexString: a.shirt)))
            ctx.fill(Path(roundedRect: CGRect(x: 44, y: 61, width: 12, height: 13), cornerRadius: 5), with: .color(skin))
            ctx.fill(circle(50, 46, 21), with: .color(skin))
            if let cap = Avatars.caps[a.st] {
                ctx.fill(SVG.path(cap), with: .color(hair.opacity(a.st == "buzz" ? 0.88 : 1)))
            }
            let ink = Color(hex: 0x2A1A14)
            ctx.fill(circle(42.5, 47.5, 2.6), with: .color(ink))
            ctx.fill(circle(57.5, 47.5, 2.6), with: .color(ink))
            ctx.stroke(SVG.path("M44 55 Q50 60.5 56 55"), with: .color(ink), style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
            let blush = Color(hex: 0xE0767A, alpha: 0.42)
            ctx.fill(Path(ellipseIn: CGRect(x: 33.2, y: 51.1, width: 7.6, height: 4.8)), with: .color(blush))
            ctx.fill(Path(ellipseIn: CGRect(x: 59.2, y: 51.1, width: 7.6, height: 4.8)), with: .color(blush))
            if a.gl {
                var g = circle(42.5, 47.5, 5.6)
                g.addPath(circle(57.5, 47.5, 5.6))
                g.move(to: CGPoint(x: 48.1, y: 47.5)); g.addLine(to: CGPoint(x: 51.9, y: 47.5))
                ctx.stroke(g, with: .color(ink), lineWidth: 1.8)
            }
        }
    }
}

/// `av(p, size, ok)` — a person's avatar with an optional "done" check badge.
struct Av: View {
    @Environment(\.pal) private var c
    @Environment(AppModel.self) private var m
    let p: String
    var size: CGFloat = 30
    var ok = false
    var body: some View {
        AvatarArt(id: m.avId(p))
            .frame(width: size, height: size)
            .overlay(alignment: .bottomTrailing) {
                if ok {
                    let b = max(12, size * 0.42)
                    Circle().fill(c.acc)
                        .overlay(Ico(.check, max(7, size * 0.26)).foregroundStyle(Brand.onWine))
                        .frame(width: b, height: b)
                        .background(Circle().stroke(c.card, lineWidth: 4))
                        .offset(x: 2, y: 2)
                }
            }
            .accessibilityLabel(p == "me" ? "You" : m.person(p).name)
    }
}

/// `avStack(list, size, max, okFn)`.
struct AvStack: View {
    @Environment(\.pal) private var c
    let list: [String]
    var size: CGFloat = 24
    var max = 4
    var ring: Color? = nil
    var ok: ((String) -> Bool)? = nil
    var body: some View {
        let shown = Array(list.prefix(max)), more = list.count - shown.count
        HStack(spacing: -size * 0.3) {
            ForEach(Array(shown.enumerated()), id: \.offset) { _, p in
                Av(p: p, size: size, ok: ok?(p) ?? false)
                    .background(Circle().stroke(ring ?? c.card, lineWidth: 4))
            }
            if more > 0 {
                Text("+\(more)").font(.sans(10, .bold)).foregroundStyle(c.ink2)
                    .frame(width: size, height: size)
                    .background(Circle().fill(c.bg2))
                    .background(Circle().stroke(c.card, lineWidth: 4))
                    .padding(.leading, -8 + size * 0.3)
            }
        }
    }
}
