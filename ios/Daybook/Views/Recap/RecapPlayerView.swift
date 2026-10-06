import SwiftUI

/// Full-screen, swipeable weekly recap with an award-show feel.
struct RecapPlayerView: View {
    let data: RecapData
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var progress: Double = 0
    @State private var paused = false
    @State private var appeared = false
    @State private var localReduceMotion = false
    @State private var shareImage: Image?
    @State private var forward = true

    private let pageDuration: Double = 6.5

    private var pages: [RecapPage] { RecapPage.pages(for: data) }
    private var reduce: Bool { localReduceMotion || model.motionReduced }
    private var collectible: Collectible? { data.collectibleKey.flatMap { model.collectible($0) } }

    var body: some View {
        let page = pages[safe: index] ?? .finale
        ZStack {
            RecapCardView(page: page, data: data, me: model.me, collectible: collectible, appeared: appeared, reduceMotion: reduce)
                .id(index)
                .transition(transition)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.updatesFrequently)

            // Tap zones: left third goes back, the rest goes forward. Hold to pause.
            HStack(spacing: 0) {
                Color.clear.contentShape(Rectangle())
                    .frame(maxWidth: .infinity)
                    .onTapGesture { go(-1) }
                    .accessibilityHidden(true)
                Color.clear.contentShape(Rectangle())
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1)
                    .onTapGesture { go(1) }
                    .accessibilityHidden(true)
                Color.clear.contentShape(Rectangle())
                    .frame(maxWidth: .infinity)
                    .onTapGesture { go(1) }
                    .accessibilityHidden(true)
            }
            .onLongPressGesture(minimumDuration: 0.3, maximumDistance: 30, perform: {}, onPressingChanged: { pressing in
                paused = pressing
            })
            .gesture(DragGesture(minimumDistance: 24).onEnded { value in
                if value.translation.width < -50 { go(1) } else if value.translation.width > 50 { go(-1) } else if value.translation.height > 120 { dismiss() }
            })

            VStack {
                topBar
                Spacer()
                bottomBar(page)
            }
        }
        .background(Palette.paper.ignoresSafeArea())
        .statusBarHidden()
        .task(id: index) { await runTimer() }
        .onAppear { arrive(at: 0) }
        .accessibilityAction(named: "Next card") { go(1) }
        .accessibilityAction(named: "Previous card") { go(-1) }
        .accessibilityAction(.escape) { dismiss() }
    }

    // MARK: Chrome

    private var topBar: some View {
        VStack(spacing: 10) {
            // Film-strip progress ticks
            HStack(spacing: 3) {
                ForEach(pages.indices, id: \.self) { i in
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(Palette.burgundy.opacity(0.2))
                            RoundedRectangle(cornerRadius: 2).fill(Palette.burgundy)
                                .frame(width: proxy.size.width * (i < index ? 1 : (i == index ? progress : 0)))
                        }
                    }
                    .frame(height: 4)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Card \(index + 1) of \(pages.count)")
            HStack(spacing: 6) {
                chromeButton(paused ? "play.fill" : "pause.fill", paused ? "Play" : "Pause") { paused.toggle() }
                chromeButton(model.prefs.recapSounds && model.prefs.soundsEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                             model.prefs.recapSounds ? "Mute recap sounds" : "Unmute recap sounds") {
                    model.prefs.recapSounds.toggle()
                    model.save()
                }
                chromeButton(reduce ? "figure.stand" : "figure.walk.motion", reduce ? "Allow motion" : "Reduce motion") {
                    localReduceMotion.toggle()
                }
                Spacer()
                chromeButton("xmark", "Close recap") { dismiss() }
            }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 8)
    }

    private func bottomBar(_ page: RecapPage) -> some View {
        HStack(spacing: 10) {
            if index > 0 {
                chromeButton("chevron.left", "Previous card") { go(-1) }
            }
            Spacer()
            if page == .finale {
                Button {
                    model.feedback(.recapPage)
                    arrive(at: 0)
                } label: { Label("Replay", systemImage: "arrow.counterclockwise") }
                    .buttonStyle(SecondaryButtonStyle(fullWidth: false))
            }
            if let shareImage {
                ShareLink(item: shareImage, preview: SharePreview(page == .finale ? "My week on \(Brand.name)" : "\(Brand.name) recap card", image: shareImage)) {
                    Label(page == .finale ? "Share summary" : "Share card", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                .simultaneousGesture(TapGesture().onEnded { paused = true })
            }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 26)
    }

    private func chromeButton(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.burgundy)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Palette.card.opacity(0.9)))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Navigation

    private var transition: AnyTransition {
        if reduce { return .opacity }
        let insertion = AnyTransition.move(edge: forward ? .trailing : .leading).combined(with: .opacity)
            .combined(with: .modifier(active: PaperTilt(angle: forward ? 8 : -8), identity: PaperTilt(angle: 0)))
        let removal = AnyTransition.move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }

    private func go(_ delta: Int) {
        let next = index + delta
        guard pages.indices.contains(next) else {
            if delta > 0 { paused = true }
            return
        }
        forward = delta > 0
        arrive(at: next)
    }

    private func arrive(at newIndex: Int) {
        appeared = false
        progress = 0
        withAnimation(reduce ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.85)) {
            index = newIndex
        }
        let page = pages[safe: newIndex] ?? .finale
        model.feedback(page.isMajor ? .superlativeReveal : .recapPage)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            appeared = true
            shareImage = ShareRenderer.image(for: RecapCardView(page: page, data: data, me: model.me, collectible: collectible, appeared: true, reduceMotion: true)
                .frame(width: 360, height: 640))
        }
    }

    private func runTimer() async {
        let step = 0.05
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(step))
            if Task.isCancelled { return }
            if paused || index == pages.count - 1 { continue }
            progress += step / pageDuration
            if progress >= 1 {
                go(1)
                return
            }
        }
    }
}

private struct PaperTilt: ViewModifier {
    let angle: Double
    func body(content: Content) -> some View {
        content.rotationEffect(.degrees(angle), anchor: .bottom)
    }
}
