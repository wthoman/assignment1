import SwiftUI

/// A simple, fully drawn avatar. Stored inline on `UserProfile` and `Friend`.
struct AvatarConfig: Codable, Hashable {
    enum Head: String, Codable, CaseIterable { case round, bean, square, tall }
    enum Hair: String, Codable, CaseIterable { case none, buzz, bob, curly, bun, long, swoop }
    enum Eyes: String, Codable, CaseIterable { case dot, happy, sleepy, wink }
    enum Mouth: String, Codable, CaseIterable { case smile, grin, flat, o }
    enum Outfit: String, Codable, CaseIterable { case tee, hoodie, stripe, overalls, sweater }
    enum Accessory: String, Codable, CaseIterable { case none, glasses, beanie, flower, headphones, cap, bandana }
    enum Frame: String, Codable, CaseIterable { case none, stamp, scallop, tape, gold }
    enum Companion: String, Codable, CaseIterable { case none, sprout, cat, snail, bird }

    var head: Head = .round
    var skin: Int = 1
    var hair: Hair = .bob
    var hairColor: Int = 1
    var eyes: Eyes = .dot
    var mouth: Mouth = .smile
    var cheeks: Bool = true
    var outfit: Outfit = .tee
    var outfitColor: Int = 0
    var accessory: Accessory = .none
    var background: TintToken = .rose
    var frame: Frame = .none
    var companion: Companion = .none

    static let skinTones: [UInt32] = [0xF6D5B8, 0xEBC09C, 0xD29F76, 0xB07B53, 0x8A5A3B, 0x5E3B27]
    static let hairColors: [UInt32] = [0x271C1B, 0x5B3424, 0x9A5B32, 0xD9A95B, 0xB4473A, 0x8E8A84]
    static let outfitColors: [UInt32] = [0x6F1725, 0x8FA382, 0xE09A5F, 0xA9C3D4, 0xC9A24A, 0xD9A3A0]

    var skinColor: Color { Color(uiColor: UIColor(hex: Self.skinTones[safe: skin] ?? Self.skinTones[1])) }
    var hairUIColor: Color { Color(uiColor: UIColor(hex: Self.hairColors[safe: hairColor] ?? Self.hairColors[0])) }
    var outfitUIColor: Color { Color(uiColor: UIColor(hex: Self.outfitColors[safe: outfitColor] ?? Self.outfitColors[0])) }

    static func random<G: RandomNumberGenerator>(using rng: inout G) -> AvatarConfig {
        AvatarConfig(
            head: Head.allCases.randomElement(using: &rng) ?? .round,
            skin: Int.random(in: 0..<skinTones.count, using: &rng),
            hair: [Hair.bob, .curly, .bun, .long, .buzz].randomElement(using: &rng) ?? .bob,
            hairColor: Int.random(in: 0..<hairColors.count, using: &rng),
            eyes: [Eyes.dot, .happy].randomElement(using: &rng) ?? .dot,
            mouth: [Mouth.smile, .grin].randomElement(using: &rng) ?? .smile,
            cheeks: Bool.random(using: &rng),
            outfit: [Outfit.tee, .hoodie, .sweater].randomElement(using: &rng) ?? .tee,
            outfitColor: Int.random(in: 0..<outfitColors.count, using: &rng),
            accessory: .none,
            background: [TintToken.rose, .sage, .sky, .gold, .orange].randomElement(using: &rng) ?? .rose)
    }
}
