import SwiftData
import SwiftUI

/// Chooses onboarding or the main app, and hosts app-wide overlays (toasts, reveals, celebrations).
struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let prefs = model.prefs
        let inApp = prefs.hasCompletedOnboarding && model.me != nil
        ZStack {
            if inApp {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingFlow()
                    .transition(.opacity)
            }
        }
        .animation(model.motionReduced ? nil : .easeInOut(duration: 0.35), value: inApp)
        .overlay(alignment: .bottom) {
            if let toast = model.toast {
                ToastView(toast: toast, onAction: {
                    model.undoFromToast(toast)
                }, onDismiss: {
                    model.dismissToast()
                })
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, inApp ? 58 : 16)
                .transition(model.motionReduced ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                .zIndex(5)
            }
        }
        .overlay {
            if let item = model.revealing {
                CollectibleRevealView(item: item)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .overlay {
            if let challenge = model.celebratingChallenge {
                GroupCelebrationView(challenge: challenge)
                    .transition(.opacity)
                    .zIndex(11)
            }
        }
        .animation(model.motionReduced ? nil : .easeInOut(duration: 0.25), value: model.revealing?.key)
        .animation(model.motionReduced ? nil : .easeInOut(duration: 0.25), value: model.celebratingChallenge?.id)
        .environment(\.accent, prefs.accent.color)
        .environment(\.cardDensity, prefs.density)
        .environment(\.motionReduced, model.motionReduced)
        .tint(prefs.accent.color)
        .preferredColorScheme(colorScheme(for: prefs.appearance))
        .onAppear {
            model.systemReduceMotion = systemReduceMotion
            #if DEBUG
            DebugLaunch.apply(to: model)
            #endif
        }
        .onChange(of: systemReduceMotion) { _, value in model.systemReduceMotion = value }
        .onChange(of: scenePhase) { _, phase in model.handleScenePhase(phase) }
    }

    private func colorScheme(for mode: AppearanceMode) -> ColorScheme? {
        switch mode {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}

#if DEBUG
/// Debug-only launch arguments for screenshots and UI checks:
/// `-seedDemo` skips onboarding with demo data, `-tab friends|collection|recap` picks a tab,
/// `-route profile|settings|notifications|groups|calendar|quizzes` pushes a screen.
enum DebugLaunch {
    @MainActor
    static func apply(to model: AppModel) {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-resetAll") { model.deleteAccount() }
        if args.contains("-seedDemo"), !model.prefs.hasCompletedOnboarding || model.me == nil { model.startDemo() }
        if args.contains("-dark") { model.prefs.appearance = .dark } else if args.contains("-light") { model.prefs.appearance = .light }
        if let index = args.firstIndex(of: "-tab"), let value = args[safe: index + 1] {
            switch value {
            case "friends": model.router.tab = .friends
            case "collection": model.router.tab = .collection
            case "recap": model.router.tab = .recap
            default: model.router.tab = .today
            }
        }
        if let index = args.firstIndex(of: "-route"), let value = args[safe: index + 1] {
            let route: Route? = switch value {
            case "profile": .profile
            case "settings": .settings
            case "notifications": .notifications
            case "groups": .groups
            case "calendar": .calendar(nil)
            case "quizzes": .quizzes
            case "avatar": .avatar
            case "share": .share(nil)
            case "habit": model.allHabits().first.map { .habit($0) }
            case "group": model.group((try? model.context.fetch(FetchDescriptor<HabitGroup>()))?.first?.id).map { .group($0) }
            case "friend": model.friends().first.map { .friend($0) }
            default: nil
            }
            if let route { model.router.push(route) }
        }
    }
}
#endif
