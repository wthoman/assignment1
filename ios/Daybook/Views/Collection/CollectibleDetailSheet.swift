import SwiftData
import SwiftUI

/// Inspect a collectible. Drag the sticker to tilt it in 3D.
struct CollectibleDetailSheet: View {
    let item: Collectible
    @Environment(AppModel.self) private var model
    @Environment(\.motionReduced) private var motionReduced
    @State private var tilt: CGSize = .zero
    @State private var shareImage: Image?

    var body: some View {
        let pinned = model.me?.showcaseKeys.contains(item.key) == true
        let giver = model.friend(item.giftedByID)
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    StickerView(item, size: 190)
                        .rotation3DEffect(.degrees(Double(tilt.width) / 6), axis: (x: 0, y: 1, z: 0))
                        .rotation3DEffect(.degrees(Double(-tilt.height) / 6), axis: (x: 1, y: 0, z: 0))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    guard !motionReduced else { return }
                                    tilt = CGSize(width: max(-120, min(120, value.translation.width)), height: max(-120, min(120, value.translation.height)))
                                }
                                .onEnded { _ in withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { tilt = .zero } }
                        )
                        .padding(.top, 20)
                        .accessibilityLabel(item.isUnlocked ? item.name : "Locked sticker")

                    VStack(spacing: 6) {
                        Text(item.isUnlocked ? item.name : "Not yet earned")
                            .font(.award(.title, weight: .heavy))
                            .foregroundStyle(Palette.burgundy)
                            .multilineTextAlignment(.center)
                        HStack(spacing: 8) {
                            RarityDots(rarity: item.rarity)
                            Text("\(item.rarity.label) \(item.form.rawValue)").font(.caption.weight(.bold)).foregroundStyle(Palette.inkSecondary)
                            Text("·").foregroundStyle(Palette.inkFaint)
                            Text(item.category.label).font(.caption).foregroundStyle(Palette.inkSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        if item.isUnlocked {
                            Text("“\(item.blurb)”").font(.hand(19)).foregroundStyle(Palette.ink)
                            Divider()
                            infoRow("Earned for", item.earnedFor.isEmpty ? item.howToEarn : item.earnedFor, symbol: "sparkles")
                            if let date = item.earnedAt {
                                infoRow("Date", date.formatted(date: .long, time: .omitted), symbol: "calendar")
                            }
                            if let giver {
                                infoRow("Gift from", giver.name, symbol: "gift.fill")
                            }
                        } else {
                            infoRow("How to earn", item.howToEarn, symbol: "lock.open")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    if item.isUnlocked {
                        HStack(spacing: 10) {
                            Button { model.toggleFavorite(item) } label: {
                                Label(item.isFavorite ? "Favorited" : "Favorite", systemImage: item.isFavorite ? "heart.fill" : "heart")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            Button { model.toggleShowcase(item) } label: {
                                Label(pinned ? "Pinned" : "Showcase", systemImage: pinned ? "pin.fill" : "pin")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        if let shareImage {
                            ShareLink(item: shareImage, preview: SharePreview(item.name, image: shareImage)) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                }
                .padding(Metrics.gutter)
            }
            .background(PaperBackground())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !item.isSeen { item.isSeen = true; model.save() }
                if item.isUnlocked {
                    shareImage = ShareRenderer.image(for: CollectibleShareCard(item: item, ownerName: model.me?.name ?? "", hideName: model.prefs.shareHidesPrivateDetails))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func infoRow(_ title: String, _ value: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol).foregroundStyle(Palette.burgundy).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.weight(.bold)).foregroundStyle(Palette.inkSecondary)
                Text(value).font(.subheadline).foregroundStyle(Palette.ink)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Full-screen unlock moment. Intensity scales with rarity; motion respects Reduce Motion.
struct CollectibleRevealView: View {
    let item: Collectible
    @Environment(AppModel.self) private var model
    @Environment(\.motionReduced) private var motionReduced
    @State private var landed = false
    @State private var burst = false

    var body: some View {
        let rare = item.rarity >= .rare
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { close() }
            VStack(spacing: 18) {
                Text(rare ? "A rare find!" : "New \(item.form.rawValue)!")
                    .font(.eyebrow).tracking(1.4)
                    .foregroundStyle(Palette.onAccent.opacity(0.9))
                ZStack {
                    if rare, !motionReduced {
                        ForEach(0..<(item.rarity == .legendary ? 14 : 8), id: \.self) { index in
                            let angle = Double(index) / Double(item.rarity == .legendary ? 14 : 8) * 2 * .pi
                            Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "star.fill")
                                .font(.system(size: index.isMultiple(of: 3) ? 18 : 12))
                                .foregroundStyle(index.isMultiple(of: 2) ? Palette.gold : item.tint.color)
                                .offset(x: burst ? CGFloat(cos(angle)) * 130 : 0, y: burst ? CGFloat(sin(angle)) * 130 : 0)
                                .opacity(burst ? 0 : 1)
                                .scaleEffect(burst ? 1.2 : 0.3)
                        }
                    }
                    if rare {
                        Circle().fill(RadialGradient(colors: [Palette.gold.opacity(0.55), .clear], center: .center, startRadius: 10, endRadius: 150))
                            .frame(width: 300, height: 300)
                            .scaleEffect(landed ? 1 : 0.4)
                    }
                    StickerView(item, size: 180, forceUnlocked: true)
                        .scaleEffect(landed ? 1 : (motionReduced ? 1 : 2.2))
                        .rotationEffect(.degrees(landed ? -6 : (motionReduced ? -6 : -40)))
                        .opacity(landed ? 1 : 0)
                }
                .frame(height: 240)
                VStack(spacing: 6) {
                    Text(item.name).font(.award(.title, weight: .heavy)).foregroundStyle(Palette.onAccent).multilineTextAlignment(.center)
                    RarityDots(rarity: item.rarity)
                    Text(item.earnedFor.isEmpty ? item.blurb : item.earnedFor)
                        .font(.hand(18)).foregroundStyle(Palette.onAccent.opacity(0.9)).multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .opacity(landed ? 1 : 0)
                Button("Stick it in my book") { close() }
                    .buttonStyle(PrimaryButtonStyle(tint: Palette.burgundy, fullWidth: false))
                    .opacity(landed ? 1 : 0)
            }
            .padding(Metrics.gutter)
        }
        .onAppear {
            model.feedback(.unlock(item.rarity))
            if motionReduced {
                landed = true
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { landed = true }
                withAnimation(.easeOut(duration: 0.9).delay(0.2)) { burst = true }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { close() }
    }

    private func close() {
        model.finishReveal()
    }
}
