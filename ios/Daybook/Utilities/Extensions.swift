import Foundation
import SwiftUI

extension Collection {
    /// Returns the element at `index`, or nil when out of bounds.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension String {
    /// Trims whitespace, strips control characters and caps the length of user-entered text.
    func cleaned(max: Int = 280) -> String {
        let filtered = unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) || $0 == "\n" }
        let trimmed = String(String.UnicodeScalarView(filtered)).trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(max))
    }

    var initials: String {
        let parts = split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first.map(String.init) }.joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }

    var firstName: String {
        split(separator: " ").first.map(String.init) ?? self
    }
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension Double {
    var percentText: String { "\(Int((self * 100).rounded()))%" }
}

extension View {
    /// Applies a modifier only when `condition` is true.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

extension Binding where Value == Bool {
    /// A boolean binding that is true when the optional is non-nil; setting false clears it.
    init<T>(isPresent optional: Binding<T?>) {
        self.init(
            get: { optional.wrappedValue != nil },
            set: { if !$0 { optional.wrappedValue = nil } })
    }
}
