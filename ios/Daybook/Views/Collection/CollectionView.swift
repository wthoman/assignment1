import SwiftData
import SwiftUI

enum CollectionFilter: String, CaseIterable, Identifiable {
    case all, stickers, stamps, badges, comeback, streak, consistency, social, group, superlative, gifted, favorites, locked

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "Everything"
        case .stickers: "Stickers"
        case .stamps: "Stamps"
        case .badges: "Badges"
        case .comeback: "Comeback awards"
        case .streak: "Streak awards"
        case .consistency: "Consistency awards"
        case .social: "Social awards"
        case .group: "Group awards"
        case .superlative: "Weekly superlatives"
        case .gifted: "Gifted"
        case .favorites: "Favorites"
        case .locked: "Still locked"
        }
    }

    func matches(_ item: Collectible) -> Bool {
        switch self {
        case .all: true
        case .stickers: item.form == .sticker
        case .stamps: item.form == .stamp
        case .badges: item.form == .badge
        case .comeback: item.category == .comeback
        case .streak: item.category == .streak
        case .consistency: item.category == .consistency
        case .social: item.category == .social
        case .group: item.category == .group
        case .superlative: item.category == .superlative
        case .gifted: item.giftedByID != nil || item.category == .gifted
        case .favorites: item.isFavorite
        case .locked: !item.isUnlocked
        }
    }
}

struct CollectionView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \Collectible.sortIndex) private var items: [Collectible]
    @State private var filter: CollectionFilter = .all
    @State private var showGrid = false
    @State private var inspecting: Collectible?
    @AppStorage("collection.grid") private var prefersGrid = false

    var body: some View {
        let shown = items.filter(filter.matches)
        let unlocked = items.filter(\.isUnlocked).count
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summary(unlocked: unlocked, total: items.count)
                    if !showGrid {
                        pageTabs(shown, proxy: proxy)
                    }
                    if shown.isEmpty {
                        EmptyStateView(symbol: "seal", title: "Nothing here yet", message: "Try a different filter — or go stamp a habit.")
                    } else if showGrid {
                        grid(shown)
                    } else {
                        book(shown)
                    }
                }
                .padding(Metrics.gutter)
            }
        }
        .background(PaperBackground())
        .navigationTitle("Collection")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Picker("Filter", selection: $filter) {
                        ForEach(CollectionFilter.allCases) { Text($0.label).tag($0) }
                    }
                } label: {
                    Image(systemName: filter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
                .accessibilityLabel("Filter: \(filter.label)")
                Button {
                    withAnimation(.snappy) { showGrid.toggle() }
                    prefersGrid = showGrid
                    model.feedback(.selection)
                } label: {
                    Image(systemName: showGrid ? "book.closed" : "square.grid.3x3")
                }
                .accessibilityLabel(showGrid ? "Show sticker book" : "Show organized grid")
            }
        }
        .sheet(item: $inspecting) { CollectibleDetailSheet(item: $0) }
        .onAppear { showGrid = prefersGrid }
        .onDisappear { model.markCollectionSeen() }
    }

    private func summary(unlocked: Int, total: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                ProgressRing(progress: total == 0 ? 0 : Double(unlocked) / Double(total), lineWidth: 6)
                Text("\(unlocked)").font(.display(.headline, weight: .heavy)).foregroundStyle(Palette.ink)
            }
            .frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(unlocked) of \(total) collected").font(.display(.headline)).foregroundStyle(Palette.ink)
                Text(filter == .all ? "Long-press any sticker for a closer look." : "Showing \(filter.label.lowercased())")
                    .font(.caption).foregroundStyle(Palette.inkSecondary)
            }
            Spacer()
        }
        .card(padding: 12)
        .accessibilityElement(children: .combine)
    }

    /// Paper page tabs to jump between book pages.
    private func pageTabs(_ shown: [Collectible], proxy: ScrollViewProxy) -> some View {
        let categories = CollectibleCategory.allCases.filter { category in shown.contains { $0.category == category } }
        return FlowLayout(spacing: 6, lineSpacing: 6) {
            ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                Button {
                    withAnimation(.snappy) { proxy.scrollTo(category, anchor: .top) }
                    model.feedback(.selection)
                } label: {
                    Text(category.shortLabel)
                        .font(.display(.caption, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 32)
                        .background(
                            UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: 8)
                                .fill(tabColor(index).opacity(0.5))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Jump to \(category.label)")
            }
        }
    }

    private func tabColor(_ index: Int) -> Color {
        [Palette.rose, Palette.gold, Palette.sage, Palette.sky, Palette.orange][index % 5]
    }

    // MARK: Book

    private func book(_ shown: [Collectible]) -> some View {
        VStack(spacing: 22) {
            ForEach(CollectibleCategory.allCases) { category in
                let pageItems = shown.filter { $0.category == category }
                if !pageItems.isEmpty {
                    BookPage(category: category, items: pageItems) { item in
                        inspecting = item
                        model.feedback(.cardPress)
                    }
                    .id(category)
                }
            }
        }
    }

    // MARK: Grid

    private func grid(_ shown: [Collectible]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 14) {
            ForEach(shown) { item in
                Button {
                    inspecting = item
                    model.feedback(.cardPress)
                } label: {
                    VStack(spacing: 6) {
                        StickerView(item, size: 72)
                        Text(item.isUnlocked ? item.name : "Locked")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(item.isUnlocked ? Palette.ink : Palette.inkFaint)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        RarityDots(rarity: item.rarity)
                    }
                    .frame(maxWidth: .infinity, minHeight: 140)
                    .card(padding: 8)
                    .overlay(alignment: .topTrailing) {
                        if item.isFavorite { Image(systemName: "heart.fill").font(.caption).foregroundStyle(Palette.rose).padding(8) }
                    }
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(item.isUnlocked ? "\(item.name), \(item.rarity.label)" : "Locked: \(item.name)")
                .contextMenu { CollectibleMenu(item: item) } preview: { CollectiblePreview(item: item) }
            }
        }
    }
}

/// One themed page of the sticker book with loose, overlapping placement.
struct BookPage: View {
    let category: CollectibleCategory
    let items: [Collectible]
    let onTap: (Collectible) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(category.label)
                    .font(.display(.title3, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                Spacer()
                HandNote(category.annotation, size: 16, rotation: -4)
            }
            let columns = [GridItem(.flexible(), spacing: -8), GridItem(.flexible(), spacing: -8), GridItem(.flexible(), spacing: -8)]
            LazyVGrid(columns: columns, spacing: -4) {
                ForEach(items) { item in
                    let hash = item.key.stableHash
                    let rotation = Double(Int(hash % 17)) - 8
                    let dx = CGFloat(Int((hash >> 8) % 13)) - 6
                    let dy = CGFloat(Int((hash >> 16) % 11)) - 5
                    Button { onTap(item) } label: {
                        VStack(spacing: 2) {
                            StickerView(item, size: 82)
                                .overlay(alignment: .top) {
                                    if item.isUnlocked, hash % 4 == 0 {
                                        TapeStrip(tint: .gold, width: 40, rotation: Double(Int(hash % 20)) - 10).offset(y: -6)
                                    }
                                }
                                .overlay(alignment: .topTrailing) {
                                    if item.isUnlocked, !item.isSeen {
                                        Text("NEW").font(.system(size: 9, weight: .black, design: .rounded))
                                            .foregroundStyle(Palette.onAccent)
                                            .padding(.horizontal, 5).padding(.vertical, 2)
                                            .background(RoundedRectangle(cornerRadius: 4).fill(Palette.orange))
                                            .rotationEffect(.degrees(12))
                                    }
                                }
                            Text(item.isUnlocked ? item.name : "???")
                                .font(.hand(13, relativeTo: .caption))
                                .foregroundStyle(item.isUnlocked ? Palette.burgundy : Palette.inkFaint)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 100)
                        }
                        .rotationEffect(.degrees(rotation))
                        .offset(x: dx, y: dy)
                        .frame(maxWidth: .infinity, minHeight: 124)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel(item.isUnlocked ? "\(item.name), \(item.rarity.label)\(item.isFavorite ? ", favorite" : "")" : "Locked sticker. \(item.howToEarn)")
                    .accessibilityHint("Opens details")
                    .contextMenu { CollectibleMenu(item: item) } preview: { CollectiblePreview(item: item) }
                }
            }
        }
        .padding(16)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(Palette.cardRaised)
                RuledLines(spacing: 30, margin: true).clipShape(RoundedRectangle(cornerRadius: 6)).opacity(0.7)
            }
            .shadow(color: Palette.shadow, radius: 5, x: 2, y: 4)
        }
        .overlay(alignment: .topLeading) { TapeStrip(tint: .rose, width: 60, rotation: -24).offset(x: -14, y: -4) }
        .overlay(alignment: .topTrailing) { TapeStrip(tint: .sage, width: 52, rotation: 20).offset(x: 12, y: -4) }
    }
}

struct CollectibleMenu: View {
    let item: Collectible
    @Environment(AppModel.self) private var model

    var body: some View {
        if item.isUnlocked {
            Button { model.toggleFavorite(item) } label: {
                Label(item.isFavorite ? "Unfavorite" : "Favorite", systemImage: item.isFavorite ? "heart.slash" : "heart")
            }
            Button { model.toggleShowcase(item) } label: {
                let pinned = model.me?.showcaseKeys.contains(item.key) == true
                Label(pinned ? "Remove from showcase" : "Add to profile showcase", systemImage: pinned ? "pin.slash" : "pin")
            }
        } else {
            Text(item.howToEarn)
        }
    }
}

struct CollectiblePreview: View {
    let item: Collectible

    var body: some View {
        VStack(spacing: 10) {
            StickerView(item, size: 150)
            Text(item.isUnlocked ? item.name : "Locked").font(.display(.headline)).foregroundStyle(Palette.ink)
            Text(item.isUnlocked ? item.blurb : item.howToEarn).font(.caption).foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(width: 260)
        .background(Palette.card)
    }
}
