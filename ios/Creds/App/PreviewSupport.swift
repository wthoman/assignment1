import SwiftUI

/// Xcode previews (Editor → Canvas, ⌥⌘↩): the whole app with the demo data, opened on one screen,
/// so a preview shows the real tab bar, theme and sheets. Used by the `#Preview` blocks at the bottom of each screen file.
struct CredsPreview: View {
    @State private var model: AppModel

    /// `setup` moves the app to the screen to show, e.g. `{ $0.selectTab(.groups) }` or `{ $0.push(.group, "hydration") }`.
    init(theme: ThemeName = .paper, onboarding: Bool = false, _ setup: (AppModel) -> Void = { _ in }) {
        let m = AppModel()
        m.mode = onboarding ? .onboard : .app
        m.theme = theme
        setup(m)
        _model = State(initialValue: m)
    }

    var body: some View {
        RootView().environment(model)
    }
}
