import Observation
import SwiftUI

enum AppTab: Hashable {
    case today, friends, collection, recap
}

/// Something that can be shared through the Share & Export studio.
enum ShareKind: String, CaseIterable, Identifiable, Hashable {
    case completion, collectible, recap, milestone, invitation, progress

    var id: String { rawValue }

    var label: String {
        switch self {
        case .completion: "Habit completion"
        case .collectible: "Collectible"
        case .recap: "Weekly recap"
        case .milestone: "Group milestone"
        case .invitation: "Invitation"
        case .progress: "Progress report"
        }
    }

    var symbol: String {
        switch self {
        case .completion: "checkmark.seal.fill"
        case .collectible: "seal.fill"
        case .recap: "film.stack.fill"
        case .milestone: "flag.checkered"
        case .invitation: "envelope.open.fill"
        case .progress: "chart.bar.fill"
        }
    }
}

enum SettingsSection: String, Hashable, CaseIterable {
    case account, privacy, blocked, notifications, appearance, accessibility, sound, haptics, connected, data
}

/// Every pushable destination. Models are Hashable, so routes can carry them directly.
enum Route: Hashable {
    case habit(Habit)
    case calendar(Habit?)
    case manageHabits
    case notifications
    case profile
    case avatar
    case gifts
    case settings
    case settingsSection(SettingsSection)
    case friend(Friend)
    case addFriends
    case quizzes
    case groups
    case group(HabitGroup)
    case share(ShareKind?)
    case recapArchive
}

/// Navigation state for each tab, so any view can push without owning a NavigationStack.
@Observable
final class AppRouter {
    var tab: AppTab = .today
    var todayPath: [Route] = []
    var friendsPath: [Route] = []
    var collectionPath: [Route] = []
    var recapPath: [Route] = []

    func push(_ route: Route) {
        switch tab {
        case .today: todayPath.append(route)
        case .friends: friendsPath.append(route)
        case .collection: collectionPath.append(route)
        case .recap: recapPath.append(route)
        }
    }

    /// Switch tabs and push, e.g. from a notification.
    func open(_ route: Route, in tab: AppTab) {
        self.tab = tab
        push(route)
    }

    func popToRoot() {
        switch tab {
        case .today: todayPath.removeAll()
        case .friends: friendsPath.removeAll()
        case .collection: collectionPath.removeAll()
        case .recap: recapPath.removeAll()
        }
    }

    func reset() {
        tab = .today
        todayPath.removeAll()
        friendsPath.removeAll()
        collectionPath.removeAll()
        recapPath.removeAll()
    }
}
