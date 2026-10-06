import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(AppModel.self) private var model
    @Query(filter: #Predicate<Collectible> { $0.isUnlocked && !$0.isSeen }) private var unseen: [Collectible]
    @Query(filter: #Predicate<NotificationItem> { !$0.isRead }) private var unread: [NotificationItem]

    var body: some View {
        @Bindable var router = model.router
        TabView(selection: $router.tab) {
            NavigationStack(path: $router.todayPath) {
                TodayView().withRoutes()
            }
            .tabItem { Label("Today", systemImage: "sun.max.fill") }
            .tag(AppTab.today)
            .badge(unread.count)

            NavigationStack(path: $router.friendsPath) {
                FriendsView().withRoutes()
            }
            .tabItem { Label("Friends", systemImage: "person.2.fill") }
            .tag(AppTab.friends)

            NavigationStack(path: $router.collectionPath) {
                CollectionView().withRoutes()
            }
            .tabItem { Label("Collection", systemImage: "seal.fill") }
            .tag(AppTab.collection)
            .badge(unseen.count)

            NavigationStack(path: $router.recapPath) {
                RecapHubView().withRoutes()
            }
            .tabItem { Label("Recap", systemImage: "film.stack.fill") }
            .tag(AppTab.recap)
        }
        .onChange(of: router.tab) { _, _ in model.feedback(.selection) }
    }
}

extension View {
    /// Registers every pushable destination on a NavigationStack.
    func withRoutes() -> some View {
        navigationDestination(for: Route.self) { route in
            RouteDestination(route: route)
        }
    }
}

struct RouteDestination: View {
    let route: Route

    var body: some View {
        switch route {
        case .habit(let habit): HabitDetailView(habit: habit)
        case .calendar(let habit): MonthCalendarView(focusHabit: habit)
        case .manageHabits: ManageHabitsView()
        case .notifications: NotificationCenterView()
        case .profile: ProfileView()
        case .avatar: AvatarEditorView()
        case .gifts: GiftsInboxView()
        case .settings: SettingsView()
        case .settingsSection(let section): SettingsSectionView(section: section)
        case .friend(let friend): FriendProfileView(friend: friend)
        case .addFriends: AddFriendsView()
        case .quizzes: QuizzesView()
        case .groups: GroupsListView()
        case .group(let group): GroupDetailView(group: group)
        case .share(let kind): ShareStudioView(initialKind: kind ?? .progress)
        case .recapArchive: RecapArchiveView()
        }
    }
}

/// UIKit bar styling so native tab and navigation bars match the paper palette.
enum AppearanceConfigurator {
    static func apply() {
        let card = UIColor.dynamic(light: 0xFBF6EC, dark: 0x2B211F)
        let ink = UIColor.dynamic(light: 0x271C1B, dark: 0xF3E8D2)
        let paper = UIColor.dynamic(light: 0xF3E8D2, dark: 0x1C1514)

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = card
        tab.shadowColor = UIColor.dynamic(light: 0xDCC9B4, dark: 0x4A3936)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        func rounded(_ style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
            let base = UIFont.preferredFont(forTextStyle: style)
            let system = UIFont.systemFont(ofSize: base.pointSize, weight: weight)
            guard let descriptor = system.fontDescriptor.withDesign(.rounded) else { return system }
            return UIFontMetrics(forTextStyle: style).scaledFont(for: UIFont(descriptor: descriptor, size: base.pointSize))
        }

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = .clear
        nav.largeTitleTextAttributes = [.font: rounded(.largeTitle, weight: .heavy), .foregroundColor: ink]
        nav.titleTextAttributes = [.font: rounded(.headline, weight: .bold), .foregroundColor: ink]
        let scrolled = UINavigationBarAppearance()
        scrolled.configureWithOpaqueBackground()
        scrolled.backgroundColor = paper
        scrolled.shadowColor = UIColor.dynamic(light: 0xDCC9B4, dark: 0x4A3936)
        scrolled.largeTitleTextAttributes = nav.largeTitleTextAttributes
        scrolled.titleTextAttributes = nav.titleTextAttributes
        UINavigationBar.appearance().standardAppearance = scrolled
        UINavigationBar.appearance().compactAppearance = scrolled
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }
}
