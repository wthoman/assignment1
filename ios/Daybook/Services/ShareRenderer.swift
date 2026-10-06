import SwiftUI

/// Renders dedicated share cards (never screenshots of the UI) into images.
@MainActor
enum ShareRenderer {
    static func image<V: View>(for view: V, scale: CGFloat = 3) -> Image? {
        guard let uiImage = uiImage(for: view, scale: scale) else { return nil }
        return Image(uiImage: uiImage)
    }

    static func uiImage<V: View>(for view: V, scale: CGFloat = 3) -> UIImage? {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, .light))
        renderer.scale = scale
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

/// Shared chrome for share cards: cream paper, brand footer.
struct ShareCardFrame<Content: View>: View {
    var width: CGFloat = 360
    var height: CGFloat = 450
    var tint: TintToken = .burgundy
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Palette.spotlight
            RuledLines(spacing: 30, margin: false).opacity(0.5)
            VStack(spacing: 0) {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                HStack(spacing: 6) {
                    Image(systemName: Brand.markSymbol)
                    Text(Brand.name).font(.system(.footnote, design: .rounded, weight: .heavy))
                    Spacer()
                    Text(Brand.shareDomain).font(.caption2.weight(.semibold))
                }
                .foregroundStyle(Palette.burgundy)
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
            }
        }
        .frame(width: width, height: height)
        .overlay(Rectangle().strokeBorder(tint.color.opacity(0.6), lineWidth: 6))
        .environment(\.colorScheme, .light)
    }
}

struct CompletionShareCard: View {
    let habitName: String
    let symbol: String
    let tint: TintToken
    let streakText: String?
    let ownerName: String
    let hidePrivate: Bool

    var body: some View {
        ShareCardFrame(tint: tint) {
            VStack(spacing: 14) {
                Text(hidePrivate ? "A habit, kept." : "\(ownerName.firstName) kept a habit")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy)).tracking(1).textCase(.uppercase)
                    .foregroundStyle(Palette.burgundy)
                ZStack {
                    SymbolBadge(symbol: symbol, tint: tint, size: 110, filled: true)
                    InkStamp(text: "Done", color: Palette.burgundy, size: 84)
                        .rotationEffect(.degrees(-14))
                        .offset(x: 70, y: 50)
                }
                Text(habitName).font(.award(.title, weight: .heavy)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                Text(Date().formatted(.dateTime.weekday(.wide).month().day())).font(.hand(20)).foregroundStyle(Palette.inkSecondary)
                if let streakText { Text(streakText).font(.system(.callout, design: .rounded, weight: .bold)).foregroundStyle(Palette.orange) }
            }
            .padding(24)
        }
    }
}

struct CollectibleShareCard: View {
    let item: Collectible
    let ownerName: String
    let hideName: Bool

    var body: some View {
        ShareCardFrame(tint: item.tint) {
            VStack(spacing: 14) {
                Text(hideName ? "New in the sticker book" : "\(ownerName.firstName)'s new sticker")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy)).tracking(1).textCase(.uppercase)
                    .foregroundStyle(Palette.burgundy)
                StickerView(item, size: 170, forceUnlocked: true).rotationEffect(.degrees(-5))
                Text(item.name).font(.award(.title, weight: .heavy)).foregroundStyle(Palette.burgundy).multilineTextAlignment(.center)
                Text(item.blurb).font(.hand(19)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                RarityDots(rarity: item.rarity)
            }
            .padding(24)
        }
    }
}

struct MilestoneShareCard: View {
    let groupName: String
    let challengeTitle: String
    let total: Int
    let goal: Int
    let unit: String
    let tint: TintToken

    var body: some View {
        ShareCardFrame(tint: tint) {
            VStack(spacing: 14) {
                Text(groupName).font(.system(.subheadline, design: .rounded, weight: .heavy)).tracking(1).textCase(.uppercase).foregroundStyle(Palette.burgundy)
                ZStack {
                    Circle().fill(tint.color.opacity(0.3)).frame(width: 160)
                    VStack(spacing: 0) {
                        Text("\(total)").font(.award(.largeTitle, weight: .black)).foregroundStyle(Palette.burgundy)
                        Text("of \(goal) \(unit)").font(.caption.weight(.semibold)).foregroundStyle(Palette.ink)
                    }
                    if total >= goal {
                        InkStamp(text: "Goal", symbol: "flag.checkered", size: 80).rotationEffect(.degrees(-16)).offset(x: 70, y: -60)
                    }
                }
                Text(challengeTitle).font(.award(.title2, weight: .heavy)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                Text("Done together.").font(.hand(20)).foregroundStyle(Palette.inkSecondary)
            }
            .padding(24)
        }
    }
}

struct InvitationShareCard: View {
    let name: String
    let avatar: AvatarConfig
    let hideName: Bool

    var body: some View {
        ShareCardFrame(tint: .rose) {
            VStack(spacing: 14) {
                Text("You're invited").font(.award(.largeTitle, weight: .black)).foregroundStyle(Palette.burgundy)
                AvatarView(config: avatar, size: 120)
                Text(hideName ? "Join me on \(Brand.name)" : "\(name.firstName) wants to keep habits with you")
                    .font(.system(.title3, design: .rounded, weight: .bold)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                Text(Brand.tagline).font(.hand(20)).foregroundStyle(Palette.inkSecondary)
            }
            .padding(24)
        }
    }
}

struct ProgressShareCard: View {
    let ownerName: String
    let consistency: Double?
    let totalCheckIns: Int
    let comebacks: Int
    let weekDays: [(label: String, value: Double)]
    let hidePrivate: Bool

    var body: some View {
        ShareCardFrame(tint: .sage) {
            VStack(spacing: 16) {
                Text(hidePrivate ? "My progress report" : "\(ownerName.firstName)'s progress report")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy)).tracking(1).textCase(.uppercase).foregroundStyle(Palette.burgundy)
                Text(consistency?.percentText ?? "—").font(.award(.largeTitle, weight: .black)).foregroundStyle(Palette.burgundy)
                    .font(.system(size: 72))
                Text("28-day consistency").font(.hand(20)).foregroundStyle(Palette.inkSecondary)
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { _, day in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 5).fill(Palette.burgundy.opacity(0.25 + 0.75 * day.value))
                                .frame(width: 26, height: 20 + 70 * day.value)
                            Text(day.label).font(.caption2.weight(.bold)).foregroundStyle(Palette.inkSecondary)
                        }
                    }
                }
                HStack(spacing: 28) {
                    VStack { Text("\(totalCheckIns)").font(.system(.title2, design: .rounded, weight: .heavy)); Text("check-ins").font(.caption) }
                    VStack { Text("\(comebacks)").font(.system(.title2, design: .rounded, weight: .heavy)); Text("comebacks").font(.caption) }
                }
                .foregroundStyle(Palette.ink)
            }
            .padding(24)
        }
    }
}
