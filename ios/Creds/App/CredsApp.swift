import SwiftUI

@main
struct CredsApp: App {
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
        .alert("Undo this check-in?", isPresented: Binding(get: { m.pendingUncheck != nil }, set: { if !$0 { m.pendingUncheck = nil } }),
               presenting: m.pendingUncheck.flatMap { m.H($0) }) { _ in
            Button("Undo check-in", role: .destructive) { withAnimation { m.confirmUncheck() } }
            Button("Keep it", role: .cancel) { m.pendingUncheck = nil }
        } message: { h in
            Text("\(h.name) will be marked as not done for today.")
        }
        .alert("Remove this photo?", isPresented: Binding(get: { m.pendingRemovePhoto != nil }, set: { if !$0 { m.pendingRemovePhoto = nil } }),
               presenting: m.pendingRemovePhoto.flatMap { m.H($0) }) { _ in
            Button("Remove photo", role: .destructive) { withAnimation { m.confirmRemovePhoto() } }
            Button("Keep it", role: .cancel) { m.pendingRemovePhoto = nil }
        } message: { h in
            Text("A check-in needs its photo, so \(h.name) will be marked as not done for today.")
        }
        .alert("Leave this group?", isPresented: Binding(get: { m.pendingLeave != nil }, set: { if !$0 { m.pendingLeave = nil } }),
               presenting: m.pendingLeave.flatMap { m.G($0) }) { g in
            Button(g.type == "community" ? "Leave community" : "Leave group", role: .destructive) { withAnimation { m.confirmLeave() } }
            Button("Stay", role: .cancel) { m.pendingLeave = nil }
        } message: { g in
            Text(g.type == "community"
                 ? "You’ll leave \(g.name) and its task comes off your Today page."
                 : "You’ll leave \(g.name). Its tasks stay on your Today page as your own.")
        }
    }
    private var isRecap: Bool {
        switch m.overlay { case .recap, .story: return true; default: return false }
    }
}

// MARK: - App shell

struct MainView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    /// The page the swipeable pager is showing; kept in step with `m.tab`.
    @State private var page: Tab? = .today
    @State private var jumping = false
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                // swipe between tabs; not lazy, so tab roots stay alive and each keeps its scroll position
                let tabsVisible = m.stack.isEmpty
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Tab.allCases, id: \.self) { t in
                            tabRoot(t)
                                .containerRelativeFrame(.horizontal)
                                .id(t)
                                .accessibilityHidden(m.tab != t)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $page)
                .scrollDisabled(!tabsVisible)
                .onAppear { page = m.tab }
                // a swipe on the pages picks the tab…
                .onChange(of: page) { _, p in if let p, p != m.tab, !jumping { m.selectTab(p) } }
                // …and a tab picked from the bar jumps straight there; animating would pass through (and report) the pages between
                .onChange(of: m.tab) { _, t in
                    guard page != t else { return }
                    jumping = true
                    var tx = Transaction(); tx.disablesAnimations = true
                    withTransaction(tx) { page = t }
                    DispatchQueue.main.async { jumping = false }
                }
                .opacity(tabsVisible ? 1 : 0)
                .allowsHitTesting(tabsVisible)
                .accessibilityHidden(!tabsVisible)
                ForEach(Array(m.stack.enumerated()), id: \.element.uid) { i, r in
                    let visible = i == m.stack.count - 1
                    RouteView(route: r)
                        .opacity(visible ? 1 : 0)
                        .allowsHitTesting(visible)
                        .accessibilityHidden(!visible)
                }
            }
            // the status-bar fade (content scrolls under it), in the showing page's colour
            let top = m.stack.isEmpty && m.tab == .today ? c.today.bg : c.bg
            VStack {
                LinearGradient(stops: [.init(color: top, location: 0.7), .init(color: top.opacity(0), location: 1)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 8)
                    .background(top.ignoresSafeArea(edges: .top))
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
    @State private var barWidth: CGFloat = 0
    /// Set while a finger slides along the bar, so lifting it doesn't also "tap" the tab it started on.
    @State private var scrubbing = false
    var body: some View {
        HStack(spacing: 0) {
            item(.today, "Today", .sun, dot: false)
            item(.groups, "Groups", .groups, dot: false)
            item(.trophies, "Trophies", .trophy, dot: m.trophies.contains { $0.fresh })
            item(.recap, "Recap", .film, dot: !m.recapSeen)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { barWidth = $0 }
        // slide a finger along the bar to move between tabs; taps still go to the buttons
        .simultaneousGesture(
            DragGesture(minimumDistance: 6)
                .onChanged { v in
                    scrubbing = true
                    let tabs = Tab.allCases
                    guard barWidth > 0 else { return }
                    let i = min(max(Int(v.location.x / (barWidth / CGFloat(tabs.count))), 0), tabs.count - 1)
                    if tabs[i] != m.tab || !m.stack.isEmpty {
                        m.selectTab(tabs[i])
                        Feedback.tabTick(m)
                    }
                }
                .onEnded { _ in DispatchQueue.main.async { scrubbing = false } }
        )
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
        return Button { if !scrubbing { m.selectTab(t) } } label: {
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
                    // capped so a tall sheet never runs up under the status bar
                    SheetPanel(type: s.type, tall: s.tall, maxH: min((g.size.height + g.safeAreaInsets.top) * 0.93, g.size.height - 12))
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
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let type: SheetType
    let tall: Bool
    let maxH: CGFloat
    @State private var drag: CGFloat = 0
    var body: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .continuous)
        // tall sheets fill maxH; the rest hug their content up to maxH (a plain maxHeight frame would always fill it)
        HugUpTo(maxHeight: maxH) {
            VStack(spacing: 0) {
                Capsule().fill(c.line2).frame(width: 38, height: 5).padding(.top, 9).padding(.bottom, 2)
                SheetContent(type: type)
            }
            .frame(maxWidth: .infinity)
            .frame(height: tall ? maxH : nil)
        }
        // Inspect Task shares the Today page's warm paper
        .background(ZStack { type == .details ? c.today.bg : c.bg; Grain() }.clipShape(shape).ignoresSafeArea(edges: .bottom))
        .offset(y: drag)
        // drag down to dismiss (scrolling content keeps its own pan; the grabber/header always work)
        .gesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .global)
                .onChanged { v in drag = v.translation.height > 0 ? v.translation.height : v.translation.height / 8 }
                .onEnded { v in
                    if v.translation.height > 110 || v.predictedEndTranslation.height > 260 {
                        m.closeSheet()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { drag = 0 }
                    }
                }
        )
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

/// Offers its content `maxHeight` and takes only the height the content uses.
struct HugUpTo: Layout {
    var maxHeight: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let h = min(proposal.height ?? maxHeight, maxHeight)
        let s = subviews.first?.sizeThatFits(ProposedViewSize(width: proposal.width, height: h)) ?? .zero
        return CGSize(width: proposal.width ?? s.width, height: min(s.height, h))
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
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
                // measured directly: a preference set inside the ScrollView doesn't reliably reach it
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { h = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .frame(maxHeight: h > 0 ? h : nil)
    }
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
            case .story(let id):
                StoryViewer().id(id).transition(.opacity)
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
