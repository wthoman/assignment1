import SwiftData
import SwiftUI

/// Full avatar & cosmetics editor (Profile → avatar).
struct AvatarEditorView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Query private var cosmetics: [CosmeticItem]
    @State private var config = AvatarConfig()
    @State private var original = AvatarConfig()
    @State private var didLoad = false

    var body: some View {
        VStack(spacing: 0) {
            AvatarPreviewHeader(config: config)
            ScrollView {
                AvatarOptionsEditor(config: $config, cosmetics: cosmetics, full: true)
                    .padding(Metrics.gutter)
            }
        }
        .background(PaperBackground())
        .navigationTitle("Avatar & cosmetics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    model.updateAvatar(config)
                    original = config
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(config == original)
            }
        }
        .onAppear {
            guard !didLoad, let me = model.me else { return }
            didLoad = true
            config = me.avatar
            original = me.avatar
        }
    }
}

struct AvatarPreviewHeader: View {
    let config: AvatarConfig
    @Environment(\.motionReduced) private var motionReduced

    var body: some View {
        ZStack {
            Palette.spotlight.ignoresSafeArea(edges: .horizontal)
            AvatarView(config: config, size: 150)
                .animation(motionReduced ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: config)
                .padding(.vertical, 18)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottom) { Rectangle().fill(Palette.line).frame(height: 1) }
        .accessibilityElement()
        .accessibilityLabel("Avatar preview")
    }
}

/// Option grids for each avatar part. `full` adds cosmetics with lock states.
struct AvatarOptionsEditor: View {
    @Binding var config: AvatarConfig
    var cosmetics: [CosmeticItem] = []
    var full = true
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            group("Face shape") {
                ForEach(AvatarConfig.Head.allCases, id: \.self) { head in
                    option(selected: config.head == head, label: head.rawValue) {
                        var c = config; c.head = head; return c
                    } apply: { config.head = head }
                }
            }
            swatches("Skin", colors: AvatarConfig.skinTones, selected: config.skin) { config.skin = $0 }
            if full {
                group("Eyes") {
                    ForEach(AvatarConfig.Eyes.allCases, id: \.self) { eyes in
                        option(selected: config.eyes == eyes, label: eyes.rawValue) { var c = config; c.eyes = eyes; return c } apply: { config.eyes = eyes }
                    }
                }
                group("Mouth") {
                    ForEach(AvatarConfig.Mouth.allCases, id: \.self) { mouth in
                        option(selected: config.mouth == mouth, label: mouth.rawValue) { var c = config; c.mouth = mouth; return c } apply: { config.mouth = mouth }
                    }
                }
            }
            cosmeticGroup(.hair, values: AvatarConfig.Hair.allCases.map(\.rawValue), current: config.hair.rawValue) { value in
                var c = config; c.hair = AvatarConfig.Hair(rawValue: value) ?? .bob; return c
            } apply: { config.hair = AvatarConfig.Hair(rawValue: $0) ?? .bob }
            swatches("Hair color", colors: AvatarConfig.hairColors, selected: config.hairColor) { config.hairColor = $0 }
            if full {
                cosmeticGroup(.outfit, values: AvatarConfig.Outfit.allCases.map(\.rawValue), current: config.outfit.rawValue) { value in
                    var c = config; c.outfit = AvatarConfig.Outfit(rawValue: value) ?? .tee; return c
                } apply: { config.outfit = AvatarConfig.Outfit(rawValue: $0) ?? .tee }
                swatches("Outfit color", colors: AvatarConfig.outfitColors, selected: config.outfitColor) { config.outfitColor = $0 }
                cosmeticGroup(.accessory, values: AvatarConfig.Accessory.allCases.map(\.rawValue), current: config.accessory.rawValue) { value in
                    var c = config; c.accessory = AvatarConfig.Accessory(rawValue: value) ?? .none; return c
                } apply: { config.accessory = AvatarConfig.Accessory(rawValue: $0) ?? .none }
            }
            cosmeticGroup(.background, values: ["rose", "sage", "orange", "cream", "sky", "gold"], current: config.background.rawValue) { value in
                var c = config; c.background = TintToken(rawValue: value) ?? .rose; return c
            } apply: { config.background = TintToken(rawValue: $0) ?? .rose }
            if full {
                cosmeticGroup(.frame, values: AvatarConfig.Frame.allCases.map(\.rawValue), current: config.frame.rawValue) { value in
                    var c = config; c.frame = AvatarConfig.Frame(rawValue: value) ?? .none; return c
                } apply: { config.frame = AvatarConfig.Frame(rawValue: $0) ?? .none }
                cosmeticGroup(.companion, values: AvatarConfig.Companion.allCases.map(\.rawValue), current: config.companion.rawValue) { value in
                    var c = config; c.companion = AvatarConfig.Companion(rawValue: value) ?? .none; return c
                } apply: { config.companion = AvatarConfig.Companion(rawValue: $0) ?? .none }
                Toggle("Rosy cheeks", isOn: $config.cheeks).tint(Palette.burgundy)
            }
            Button {
                var rng = SystemRandomNumberGenerator()
                var next = AvatarConfig.random(using: &rng)
                next.frame = config.frame
                next.companion = config.companion
                config = next
                model.feedback(.selection)
            } label: { Label("Shuffle", systemImage: "shuffle") }
                .buttonStyle(SecondaryButtonStyle())
        }
    }

    // MARK: Builders

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.display(.subheadline, weight: .bold)).foregroundStyle(Palette.ink)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], spacing: 8) { content() }
        }
    }

    private func option(selected: Bool, label: String, locked: Bool = false, hint: String? = nil, preview: () -> AvatarConfig, apply: @escaping () -> Void) -> some View {
        let previewConfig = preview()
        return Button {
            if locked {
                model.feedback(.warning)
                model.showToast("Locked: \(hint ?? "keep checking in")", symbol: "lock.fill", tint: .cream)
            } else {
                apply()
                model.feedback(.selection)
            }
        } label: {
            VStack(spacing: 2) {
                AvatarView(config: previewConfig, size: 52, showsCompanion: true)
                    .opacity(locked ? 0.35 : 1)
                    .overlay {
                        if locked { Image(systemName: "lock.fill").font(.caption.weight(.bold)).foregroundStyle(Palette.ink) }
                    }
                Text(label.capitalized).font(.caption2).foregroundStyle(Palette.inkSecondary).lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 74)
            .background(RoundedRectangle(cornerRadius: 12).fill(selected ? Palette.burgundy.opacity(0.12) : Palette.card))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? Palette.burgundy : Palette.line, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)\(locked ? ", locked. \(hint ?? "")" : "")")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func cosmeticGroup(_ slot: CosmeticSlot, values: [String], current: String, preview: @escaping (String) -> AvatarConfig, apply: @escaping (String) -> Void) -> some View {
        group(slot.label) {
            ForEach(values, id: \.self) { value in
                let item = cosmetics.first { $0.slot == slot && $0.value == value }
                // Cosmetics without a catalog entry (e.g. onboarding before seeding) are starters.
                let starter = Catalog.cosmetics.first { $0.slot == slot && $0.value == value }?.starter ?? true
                let locked = full ? !(item?.isUnlocked ?? starter) : !starter
                option(selected: current == value, label: item?.name ?? value, locked: locked, hint: item?.unlockHint ?? Catalog.cosmetics.first { $0.slot == slot && $0.value == value }?.unlockHint) {
                    preview(value)
                } apply: { apply(value) }
                    .overlay(alignment: .topTrailing) {
                        if item?.giftedByID != nil {
                            Image(systemName: "gift.fill").font(.caption2).foregroundStyle(Palette.gold).padding(5)
                        }
                    }
            }
        }
    }

    private func swatches(_ title: String, colors: [UInt32], selected: Int, onSelect: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.display(.subheadline, weight: .bold)).foregroundStyle(Palette.ink)
            HStack(spacing: 8) {
                ForEach(colors.indices, id: \.self) { index in
                    Button {
                        onSelect(index)
                        model.feedback(.selection)
                    } label: {
                        Circle().fill(Color(uiColor: UIColor(hex: colors[index])))
                            .frame(width: 34, height: 34)
                            .overlay(Circle().strokeBorder(selected == index ? Palette.burgundy : Palette.line, lineWidth: selected == index ? 3 : 1))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) option \(index + 1)")
                    .accessibilityAddTraits(selected == index ? .isSelected : [])
                }
            }
        }
    }
}
