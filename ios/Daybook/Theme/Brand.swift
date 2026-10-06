import Foundation

/// Temporary product identity. Every user-facing mention of the app name reads from here,
/// so renaming the product is a one-file change (plus `INFOPLIST_KEY_CFBundleDisplayName`).
enum Brand {
    static let name = "Daybook"
    static let tagline = "Small habits, kept together."
    static let pitch = "A habit tracker you share with the people who cheer you on."
    static let shareDomain = "daybook.app"
    /// Symbol used as the app mark inside the UI.
    static let markSymbol = "book.closed.fill"
}
