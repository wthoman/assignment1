import SwiftData
import SwiftUI

/// Pick something to share, preview the generated card, and send it through the share sheet.
struct ShareStudioView: View {
    let initialKind: ShareKind
    @Environment(AppModel.self) private var model
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query(filter: #Predicate<Collectible> { $0.isUnlocked }, sort: \Collectible.sortIndex) private var collectibles: [Collectible]
    @Query(filter: #Predicate<HabitGroup> { $0.isMember }) private var groups: [HabitGroup]

    @State private var kind: ShareKind = .progress
    @State private var habitID: UUID?
    @State private var collectibleKey: String?
    @State private var challengeID: UUID?
    @State private var hidePrivate = true
    @State private var rendered: UIImage?
    @State private var didLoad = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                    ForEach(ShareKind.allCases) { option in
                        ChoiceChip(title: option.label, symbol: option.symbol, isSelected: kind == option) {
                            kind = option
                            model.feedback(.selection)
                        }
                    }
                }
                picker
                Toggle("Hide private details", isOn: $hidePrivate)
                    .tint(Palette.burgundy)
                    .card(padding: 12)
                VStack(spacing: 12) {
                    if let rendered {
                        Image(uiImage: rendered)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 420)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: Palette.shadow.opacity(2), radius: 8, y: 4)
                            .rotationEffect(.degrees(-1))
                            .accessibilityLabel("Preview of the \(kind.label.lowercased()) card")
                        let image = Image(uiImage: rendered)
                        ShareLink(item: image, preview: SharePreview(kind.label, image: image)) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        EmptyStateView(symbol: "photo", title: "Nothing to share yet", message: "Pick an item above.")
                    }
                }
                .frame(maxWidth: .infinity)
                Text("Cards are drawn fresh for sharing — never screenshots of your screen.")
                    .font(.caption).foregroundStyle(Palette.inkSecondary)
            }
            .padding(Metrics.gutter)
        }
        .background(PaperBackground())
        .navigationTitle("Share & export")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            kind = initialKind
            hidePrivate = model.prefs.shareHidesPrivateDetails
            habitID = habits.first { $0.isCompleted(on: Day.today) }?.id ?? habits.first?.id
            collectibleKey = collectibles.last?.key
            challengeID = groups.flatMap(\.challenges).first { $0.kind == .collective }?.id
            render()
        }
        .onChange(of: kind) { _, _ in render() }
        .onChange(of: habitID) { _, _ in render() }
        .onChange(of: collectibleKey) { _, _ in render() }
        .onChange(of: challengeID) { _, _ in render() }
        .onChange(of: hidePrivate) { _, _ in render() }
    }

    @ViewBuilder
    private var picker: some View {
        switch kind {
        case .completion:
            Picker("Habit", selection: $habitID) {
                ForEach(habits.filter { $0.status == .active }) { Text($0.name).tag(Optional($0.id)) }
            }
            .card(padding: 8)
        case .collectible:
            Picker("Collectible", selection: $collectibleKey) {
                ForEach(collectibles) { Text($0.name).tag(Optional($0.key)) }
            }
            .card(padding: 8)
        case .milestone:
            Picker("Challenge", selection: $challengeID) {
                ForEach(groups.flatMap(\.challenges).filter { $0.kind == .collective }) { Text("\($0.group?.name ?? "") · \($0.title)").tag(Optional($0.id)) }
            }
            .card(padding: 8)
        case .recap, .invitation, .progress:
            EmptyView()
        }
    }

    private func render() {
        let me = model.me
        let name = me?.name ?? "Me"
        let view: AnyView?
        switch kind {
        case .completion:
            guard let habit = habits.first(where: { $0.id == habitID }) else { view = nil; break }
            let streak = habit.currentStreak
            view = AnyView(CompletionShareCard(habitName: hidePrivate && habit.privacy == .onlyMe ? "A private habit" : habit.name, symbol: habit.symbol, tint: habit.tint,
                                               streakText: model.prefs.showStreaks && streak.count > 1 ? "\(streak.label) in a row" : nil,
                                               ownerName: name, hidePrivate: hidePrivate))
        case .collectible:
            guard let item = collectibles.first(where: { $0.key == collectibleKey }) else { view = nil; break }
            view = AnyView(CollectibleShareCard(item: item, ownerName: name, hideName: hidePrivate))
        case .recap:
            let data = model.buildRecap()
            view = AnyView(RecapCardView(page: .finale, data: data, me: hidePrivate ? nil : me, appeared: true, reduceMotion: true).frame(width: 360, height: 640))
        case .milestone:
            guard let challenge = groups.flatMap(\.challenges).first(where: { $0.id == challengeID }) else { view = nil; break }
            view = AnyView(MilestoneShareCard(groupName: challenge.group?.name ?? "", challengeTitle: challenge.title, total: challenge.total,
                                              goal: challenge.goal, unit: challenge.unit, tint: challenge.group?.tint ?? .sage))
        case .invitation:
            view = AnyView(InvitationShareCard(name: name, avatar: me?.avatar ?? AvatarConfig(), hideName: hidePrivate))
        case .progress:
            let week = Day.lastDays(7, endingOn: Day.today)
            let active = habits.filter(\.countsTowardConsistency)
            let days = week.map { day -> (String, Double) in
                let scheduled = active.filter { $0.isScheduled(on: day) }
                let done = scheduled.filter { $0.isCompleted(on: day) }.count
                return (day.formatted(.dateTime.weekday(.narrow)), scheduled.isEmpty ? 0 : Double(done) / Double(scheduled.count))
            }
            view = AnyView(ProgressShareCard(ownerName: name, consistency: habits.overallConsistency(), totalCheckIns: habits.flatMap(\.myCheckIns).count,
                                             comebacks: habits.reduce(0) { $0 + $1.comebackCount }, weekDays: days, hidePrivate: hidePrivate))
        }
        rendered = view.flatMap { ShareRenderer.uiImage(for: $0) }
    }
}
