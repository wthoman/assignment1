import SwiftUI

@main
struct DaybookApp: App {
    @State private var model = AppModel()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var m
    var body: some View {
        let pal = Palette.of(m.theme)
        let lightStatus = pal.isStage || (m.mode == .onboard && m.step == 0) || isRecap
        ZStack {
            pal.bg.ignoresSafeArea()
            Grain().ignoresSafeArea()
            if m.mode == .onboard {
                OnboardingView()
            } else {
                MainView()
            }
            SheetHost()
            OverlayHost()
            ToastHost()
        }
        .environment(\.pal, pal)
        .tint(pal.acc)
        .preferredColorScheme(lightStatus ? .dark : .light)
    }
    private var isRecap: Bool { if case .recap = m.overlay { return true }; return false }
}

// MARK: - App shell

struct MainView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                // tab roots stay alive so each keeps its scroll position
                ForEach(Tab.allCases, id: \.self) { t in
                    let visible = m.tab == t && m.stack.isEmpty
                    tabRoot(t)
                        .opacity(visible ? 1 : 0)
                        .allowsHitTesting(visible)
                        .accessibilityHidden(!visible)
                }
                ForEach(Array(m.stack.enumerated()), id: \.element.uid) { i, r in
                    let visible = i == m.stack.count - 1
                    RouteView(route: r)
                        .opacity(visible ? 1 : 0)
                        .allowsHitTesting(visible)
                        .accessibilityHidden(!visible)
                }
            }
            // the status-bar fade (content scrolls under it)
            VStack {
                LinearGradient(stops: [.init(color: c.bg, location: 0.7), .init(color: c.bg.opacity(0), location: 1)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 8)
                    .background(c.bg.ignoresSafeArea(edges: .top))
                    .allowsHitTesting(false)
                Spacer()
            }
            TabBar()
        }
    }

    @ViewBuilder func tabRoot(_ t: Tab) -> some View {
        switch t {
        case .today: TodayView()
        case .groups: GroupsView()
        case .trophies: TrophiesView()
        case .recap: RecapHubView()
        }
    }
}

struct RouteView: View {
    let route: Route
    var body: some View {
        switch route.r {
        case .profile: ProfileView()
        case .settings: SettingsView()
        case .notifs: NotificationsView()
        case .friends: FriendsView()
        case .friend: FriendProfileView(p: route.id ?? "")
        case .addfriends: AddFriendsView()
        case .discover: DiscoverView()
        case .group: GroupPageView(id: route.id ?? "")
        }
    }
}

/// Scrolling page body: 16pt sides, room for the floating tab bar.
struct Page<Content: View>: View {
    var content: (ScrollViewProxy) -> Content
    init(@ViewBuilder content: @escaping (ScrollViewProxy) -> Content) { self.content = content }
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) { content(proxy) }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 112)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

struct TabBar: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        HStack(spacing: 0) {
            item(.today, "Today", .sun, dot: false)
            item(.groups, "Groups", .groups, dot: false)
            item(.trophies, "Trophies", .trophy, dot: m.trophies.contains { $0.fresh })
            item(.recap, "Recap", .film, dot: !m.recapSeen)
        }
        .padding(.horizontal, 6).padding(.vertical, 8)
        .frame(height: 68)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(c.tabBg).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous)))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(c.line, lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 14, y: 12)
        .padding(.horizontal, 10)
        .padding(.bottom, 4)
    }

    func item(_ t: Tab, _ label: String, _ icon: UIIcon, dot: Bool) -> some View {
        let on = m.tab == t
        return Button { m.selectTab(t) } label: {
            VStack(spacing: 3) {
                Ico(icon, 21)
                Text(label).font(.sans(11, .semibold))
            }
            .foregroundStyle(on ? c.acc : c.ink3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(on ? c.yelSoft : .clear))
            .overlay(alignment: .top) {
                if dot {
                    Circle().fill(c.acc).frame(width: 8, height: 8)
                        .background(Circle().stroke(c.tabBg, lineWidth: 4))
                        .offset(x: 14, y: 6)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

// MARK: - Toast

struct ToastHost: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        VStack {
            Spacer()
            if let t = m.toast {
                HStack(spacing: 10) {
                    Ico(t.icon, 15).foregroundStyle(Brand.onWine)
                        .frame(width: 30, height: 30).background(Circle().fill(c.acc))
                    Text(t.msg).font(.sans(14, .semibold)).foregroundStyle(c.ink).lineLimit(2)
                    if t.undo != nil {
                        Button("Undo") { withAnimation(.easeOut(duration: 0.25)) { m.runUndo() } }
                            .font(.sans(14, .bold)).foregroundStyle(c.acc).padding(.leading, 6)
                    }
                }
                .padding(.vertical, 10).padding(.leading, 10).padding(.trailing, 12)
                .frame(maxWidth: 350)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(c.card).shadow(color: .black.opacity(0.35), radius: 15, y: 14))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(c.acc.opacity(0.4), lineWidth: 1))
                .id(t.id)
                .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 16)), removal: .opacity.combined(with: .offset(y: 8))))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, m.mode == .app ? 82 : 24)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: m.toast?.id)
    }
}

// MARK: - Bottom sheets

struct SheetHost: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .bottom) {
                if let s = m.sheet {
                    Color(red: 18 / 255, green: 8 / 255, blue: 10 / 255).opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture { m.closeSheet() }
                        .transition(.opacity)
                    SheetPanel(type: s.type, tall: s.tall, maxH: (g.size.height + g.safeAreaInsets.top) * 0.93)
                        .id(s.presentID)
                        .transition(.move(edge: .bottom))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .animation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.38), value: m.sheet?.presentID)
    }
}

struct SheetPanel: View {
    @Environment(\.pal) private var c
    let type: SheetType
    let tall: Bool
    let maxH: CGFloat
    var body: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .continuous)
        VStack(spacing: 0) {
            Capsule().fill(c.line2).frame(width: 38, height: 5).padding(.top, 9).padding(.bottom, 2)
            SheetContent(type: type)
        }
        .frame(maxWidth: .infinity)
        .frame(height: tall ? maxH : nil)
        .frame(maxHeight: maxH, alignment: .top)
        .background(ZStack { c.bg; Grain() }.clipShape(shape).ignoresSafeArea(edges: .bottom))
        .accessibilityAddTraits(.isModal)
    }
}

struct SheetContent: View {
    let type: SheetType
    var body: some View {
        switch type {
        case .details: DetailsSheet()
        case .create: CreateHabitSheet()
        case .group: CreateGroupSheet()
        case .community: CommunitySheet()
        case .trophy: TrophySheet()
        case .askphoto: AskPhotoSheet()
        case .proof: ProofSheet()
        case .post: PostSheet()
        case .react: ReactSheet()
        case .comments: CommentsSheet()
        case .avatar: AvatarSheet()
        case .editprofile: EditProfileSheet()
        case .groupmenu: GroupMenuSheet()
        case .invitefriends: InviteFriendsSheet()
        case .friendmenu: FriendMenuSheet()
        case .invitehabit: InviteHabitSheet()
        }
    }
}

/// Sheet header row (.sheet-head).
struct SheetHead<Content: View>: View {
    @Environment(AppModel.self) private var m
    @ViewBuilder var content: Content
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            content.frame(maxWidth: .infinity, alignment: .leading)
            CloseX { m.closeSheet() }
        }
        .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 8)
    }
}

/// Sheet body: scrolls when taller than the sheet, otherwise hugs its content.
struct SheetBody<Content: View>: View {
    var top: CGFloat = 6
    @ViewBuilder var content: Content
    @State private var h: CGFloat = 0
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) { content }
                .padding(.horizontal, 18).padding(.top, top).padding(.bottom, 32)
                .background(GeometryReader { g in Color.clear.preference(key: HeightKey.self, value: g.size.height) })
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .frame(maxHeight: h > 0 ? h : nil)
        .onPreferenceChange(HeightKey.self) { h = $0 }
    }
}

struct HeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

// MARK: - Overlays (recap curtain, goal celebration)

struct OverlayHost: View {
    @Environment(AppModel.self) private var m
    var body: some View {
        ZStack {
            switch m.overlay {
            case .recap(let id):
                RecapCurtain().id(id).transition(.opacity)
            case .celebrate(let gid):
                CelebrateView(gid: gid).transition(.opacity)
            case nil:
                EmptyView()
            }
        }
        .animation(.easeOut(duration: 0.3), value: m.overlay)
    }
}

struct CelebrateView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let gid: String
    @State private var slam = false
    var body: some View {
        ZStack {
            Color(red: 10 / 255, green: 4 / 255, blue: 6 / 255).opacity(0.5).ignoresSafeArea()
            if let g = m.G(gid), let ch = g.ch {
                VStack(spacing: 0) {
                    Eyebrow(g.name, acc: true)
                    EmTitle(lead: "Goal ", em: "reached!").padding(.top, 8)
                    Text("\(ch.goal.formatted()) \(ch.unit) together").font(.sans(15, .semibold)).foregroundStyle(c.ink).padding(.top, 8)
                    Text(ch.title).font(.serif(17)).italic().foregroundStyle(c.acc).multilineTextAlignment(.center).padding(.top, 6)
                    AvStack(list: g.members, size: 40, max: 6).padding(.top, 14)
                    Button("Hooray!") { m.closeOverlay() }.buttonStyle(.btn).padding(.top, 16)
                }
                .multilineTextAlignment(.center)
                .padding(.top, 26).padding(.horizontal, 20).padding(.bottom, 18)
                .frame(maxWidth: 330)
                .background(Ruled(color: c.acc.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 18)))
                .card(0)
                .overlay(alignment: .topTrailing) {
                    Stamp(size: 96, color: c.acc, fill: c.card) { Ico(.trophy, 18); Text("Together") }
                        .rotationEffect(.degrees(slam ? -14 : -40))
                        .scaleEffect(slam ? 1 : 2.4)
                        .opacity(slam ? 0.92 : 0)
                        .offset(x: 10, y: -26)
                }
                .padding(24)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { m.closeOverlay() }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) { slam = true } }
    }
}
