import SwiftUI

/// Ring around the profile avatar when there are photos on the story.
struct StoryRing: View {
    @Environment(\.pal) private var c
    var body: some View {
        Circle()
            .strokeBorder(AngularGradient(colors: [c.acc, Brand.gold2, c.acc2, c.acc], center: .center), lineWidth: 3)
            .padding(-7)
            .allowsHitTesting(false)
    }
}

/// Full-screen, Instagram-style viewer for the user's story photos.
struct StoryViewer: View {
    @Environment(AppModel.self) private var m
    @State private var index = 0
    @State private var progress: CGFloat = 0
    @State private var timer: Task<Void, Never>? = nil
    private let duration: Double = 5

    var body: some View {
        let items = m.story
        GeometryReader { g in
            ZStack {
                Brand.stage.ignoresSafeArea()
                if items.indices.contains(index) {
                    let item = items[index]
                    StoryPhoto(item: item)
                        .frame(width: g.size.width, height: g.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(alignment: .top) {
                            LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom).frame(height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .overlay(alignment: .bottom) {
                            LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom).frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                    // tap zones: back on the left third, forward on the rest
                    HStack(spacing: 0) {
                        Color.clear.contentShape(Rectangle()).frame(width: g.size.width * 0.32).onTapGesture { go(index - 1) }
                        Color.clear.contentShape(Rectangle()).onTapGesture { go(index + 1) }
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 4) {
                            ForEach(items.indices, id: \.self) { k in
                                GeometryReader { bar in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(.white.opacity(0.3))
                                        Capsule().fill(.white).frame(width: bar.size.width * (k < index ? 1 : k == index ? progress : 0))
                                    }
                                }
                                .frame(height: 2.5)
                            }
                        }
                        .padding(.top, 10)
                        HStack(spacing: 10) {
                            Av(p: "me", size: 34).overlay(Circle().strokeBorder(.white, lineWidth: 1.5).padding(-3))
                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 6) {
                                    Text("Your story").font(.sans(14, .semibold))
                                    Text(item.time).font(.sans(13)).opacity(0.75)
                                }
                                Text(item.habitName).font(.sans(12.5)).opacity(0.85)
                            }
                            Spacer()
                            Button { close() } label: {
                                Ico(.x).frame(width: 34, height: 34).background(Circle().fill(.black.opacity(0.35)))
                            }
                            .accessibilityLabel("Close")
                        }
                        .padding(.top, 12)
                        Spacer()
                        Text(item.place).font(.mono(9.5)).tracking(1.33).textCase(.uppercase).foregroundStyle(Color(hex: 0xF6E6E0))
                            .padding(.vertical, 4).padding(.horizontal, 7)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color(red: 20 / 255, green: 8 / 255, blue: 10 / 255).opacity(0.7)))
                        if let cap = item.caption {
                            Text("“\(cap)”").font(.serif(24)).italic().shadow(color: .black.opacity(0.5), radius: 8).padding(.top, 10)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.bottom, 28)
                    .allowsHitTesting(true)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Next photo") { go(index + 1) }
        .accessibilityAction(named: "Previous photo") { go(index - 1) }
        .onAppear { start() }
        .onDisappear { timer?.cancel() }
    }

    private func go(_ i: Int) {
        if i >= m.story.count { close(); return }
        index = max(0, i)
        start()
    }

    private func start() {
        timer?.cancel()
        progress = 0
        withAnimation(.linear(duration: duration)) { progress = 1 }
        let at = index
        timer = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled && index == at { go(at + 1) }
        }
    }

    private func close() {
        timer?.cancel()
        m.closeOverlay()
    }
}

private struct StoryPhoto: View {
    @Environment(AppModel.self) private var m
    let item: StoryItem
    var body: some View {
        if let img = m.storyImage(item) {
            Image(uiImage: img).resizable().scaledToFill()
                .accessibilityLabel("Photo for \(item.habitName)")
        } else {
            PhotoFill(floorCell: 36, floorHeight: 130, floorOpacity: 0.35)
        }
    }
}
