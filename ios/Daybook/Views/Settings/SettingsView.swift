import SwiftData
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmResetDemo = false
    @State private var confirmResetOnboarding = false
    @State private var confirmLogOut = false

    var body: some View {
        List {
            if let me = model.me {
                Section {
                    Button { model.router.push(.profile) } label: {
                        HStack(spacing: 12) {
                            AvatarView(config: me.avatar, size: 52)
                            VStack(alignment: .leading) {
                                Text(me.name).font(.display(.headline)).foregroundStyle(Palette.ink)
                                Text("@\(me.handle)\(me.isDemo ? " · demo account" : "")").font(.caption).foregroundStyle(Palette.inkSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Palette.card)
            }
            Section("Account") {
                row(.account, "Account & profile", "person.crop.circle", .burgundy)
                row(.privacy, "Privacy", "lock.fill", .sage)
                row(.blocked, "Blocked users", "hand.raised.fill", .rose)
            }
            Section("Notifications") {
                row(.notifications, "Notifications & reminders", "bell.badge.fill", .gold)
            }
            Section("Personalize") {
                row(.appearance, "Appearance", "paintpalette.fill", .orange)
                row(.accessibility, "Accessibility & motion", "accessibility", .sky)
                row(.sound, "Sounds", "speaker.wave.2.fill", .rose)
                row(.haptics, "Haptics", "iphone.radiowaves.left.and.right", .sage)
            }
            Section("Data") {
                row(.connected, "Connected services", "link", .ink)
                row(.data, "Data export", "square.and.arrow.up.fill", .gold)
                Button { model.router.push(.share(nil)) } label: { rowLabel("Share & export studio", "photo.on.rectangle.angled", .burgundy) }
            }
            Section {
                Button { confirmResetDemo = true } label: { rowLabel("Reset demo data", "arrow.counterclockwise", .orange) }
                Button { confirmResetOnboarding = true } label: { rowLabel("Reset onboarding", "sparkles", .sky) }
                Button(role: .destructive) { confirmLogOut = true } label: { rowLabel("Log out", "rectangle.portrait.and.arrow.right", .burgundy) }
            } header: { Text("Developer & session") } footer: {
                Text("\(Brand.name) \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0") · Everything is stored on this device.")
            }
        }
        .listRowBackground(Palette.card)
        .scrollContentBackground(.hidden)
        .background(PaperBackground())
        .navigationTitle("Settings")
        .confirmationDialog("Reset demo data?", isPresented: $confirmResetDemo, titleVisibility: .visible) {
            Button("Reset demo data", role: .destructive) { model.resetDemoData() }
        } message: { Text("Habits, friends, groups and your collection are regenerated. Your profile and settings stay.") }
        .confirmationDialog("Show onboarding again?", isPresented: $confirmResetOnboarding, titleVisibility: .visible) {
            Button("Reset onboarding", role: .destructive) { model.resetOnboarding() }
        } message: { Text("Finishing onboarding again will replace your current data with a fresh start.") }
        .confirmationDialog("Log out?", isPresented: $confirmLogOut, titleVisibility: .visible) {
            Button("Log out and clear this device", role: .destructive) { model.logOut() }
        } message: { Text("Local accounts live on this device, so logging out removes your data here.") }
        .onChange(of: confirmResetDemo || confirmResetOnboarding || confirmLogOut) { _, value in if value { model.feedback(.warning) } }
    }

    private func row(_ section: SettingsSection, _ title: String, _ symbol: String, _ tint: TintToken) -> some View {
        Button { model.router.push(.settingsSection(section)) } label: {
            HStack {
                rowLabel(title, symbol, tint)
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Palette.inkFaint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Palette.card)
    }

    private func rowLabel(_ title: String, _ symbol: String, _ tint: TintToken) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint.onColor)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 8).fill(tint.color))
            Text(title).foregroundStyle(Palette.ink)
        }
        .frame(minHeight: 40)
    }
}

/// Every settings sub-page.
struct SettingsSectionView: View {
    let section: SettingsSection
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            switch section {
            case .account: AccountSettings()
            case .privacy: PrivacySettings()
            case .blocked: BlockedUsersView()
            case .notifications: NotificationSettings()
            case .appearance: AppearanceSettings()
            case .accessibility: AccessibilitySettings()
            case .sound: SoundSettings()
            case .haptics: HapticSettings()
            case .connected: ConnectedServicesView()
            case .data: DataSettings()
            }
        }
        .scrollContentBackground(.hidden)
        .background(PaperBackground())
        .tint(Palette.burgundy)
    }
}

// MARK: - Account

private struct AccountSettings: View {
    @Environment(AppModel.self) private var model
    @State private var editing = false
    @State private var confirmDelete = false
    @State private var confirmDeleteFinal = false

    var body: some View {
        Form {
            if let me = model.me {
                Section("Profile") {
                    LabeledContent("Name", value: me.name)
                    LabeledContent("Handle", value: "@\(me.handle)")
                    LabeledContent("Member since", value: me.joinedAt.formatted(date: .abbreviated, time: .omitted))
                    Button("Edit profile") { editing = true }
                    Button("Customize avatar") { model.router.push(.avatar) }
                }
                .sheet(isPresented: $editing) { EditProfileSheet(profile: me) }
            }
            Section {
                LabeledContent("Account type", value: "Local only")
                LabeledContent("Sign-in", value: "Not required")
            } footer: {
                Text("\(Brand.name) keeps your account on this device. No password is stored, and nothing is sent to a server.")
            }
            Section {
                Button("Delete account…", role: .destructive) { confirmDelete = true }
            } footer: {
                Text("Deletes your profile, habits, history, collection and settings from this device.")
            }
        }
        .navigationTitle("Account")
        .confirmationDialog("Delete your account?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Continue", role: .destructive) { confirmDeleteFinal = true }
        } message: { Text("This permanently removes everything.") }
        .alert("Are you absolutely sure?", isPresented: $confirmDeleteFinal) {
            Button("Delete everything", role: .destructive) { model.deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This can't be undone.") }
        .onChange(of: confirmDelete) { _, value in if value { model.feedback(.warning) } }
    }
}

// MARK: - Privacy

private struct PrivacySettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var prefs = model.prefs
        Form {
            Section {
                Picker("Profile visible to", selection: $prefs.profileVisibilityRaw) {
                    ForEach(Visibility.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Picker("Weekly recap visible to", selection: $prefs.recapVisibilityRaw) {
                    ForEach(Visibility.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Toggle("Show my activity in friends' feeds", isOn: $prefs.activityInFeed)
                Toggle("Show consistency on my profile", isOn: $prefs.showConsistencyOnProfile)
            } header: { Text("Visibility") }
            Section {
                Toggle("Friends may send me reminders", isOn: $prefs.allowFriendReminders)
            } footer: { Text("Reminders from friends are always supportive. You can turn them off anytime.") }
            Section {
                Toggle("Hide private details in shared images", isOn: $prefs.shareHidesPrivateDetails)
            } footer: { Text("On by default. Share cards leave out your name, notes and photos.") }
            Section {
                Button("Blocked users") { model.router.push(.settingsSection(.blocked)) }
            }
        }
        .navigationTitle("Privacy")
        .onChange(of: prefs.activityInFeed) { _, _ in model.save() }
        .onChange(of: prefs.allowFriendReminders) { _, _ in model.save() }
        .onChange(of: prefs.shareHidesPrivateDetails) { _, _ in model.save() }
        .onChange(of: prefs.profileVisibilityRaw) { _, _ in model.save() }
        .onChange(of: prefs.recapVisibilityRaw) { _, _ in model.save() }
        .onChange(of: prefs.showConsistencyOnProfile) { _, _ in model.save() }
    }
}

private struct BlockedUsersView: View {
    @Environment(AppModel.self) private var model
    @Query(filter: #Predicate<Friend> { $0.statusRaw == "blocked" }, sort: \Friend.name) private var blocked: [Friend]

    var body: some View {
        List {
            if blocked.isEmpty {
                Text("No one is blocked.").foregroundStyle(Palette.inkSecondary).listRowBackground(Palette.card)
            }
            ForEach(blocked) { friend in
                HStack {
                    AvatarView(config: friend.avatar, size: 36, showsCompanion: false)
                    Text(friend.name)
                    Spacer()
                    Button("Unblock") { model.unblock(friend) }.buttonStyle(InlineActionStyle())
                }
                .listRowBackground(Palette.card)
            }
        }
        .navigationTitle("Blocked users")
    }
}

// MARK: - Notifications

private struct NotificationSettings: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query(filter: #Predicate<HabitGroup> { $0.isMember }) private var groups: [HabitGroup]
    @State private var status: UNAuthorizationStatus = .notDetermined
    @State private var reminderSheet: Habit?

    var body: some View {
        @Bindable var prefs = model.prefs
        Form {
            Section {
                Toggle("Allow notifications", isOn: $prefs.notificationsEnabled)
                LabeledContent("iOS permission", value: statusText)
                if status == .notDetermined {
                    Button("Allow reminder notifications") { model.requestNotificationPermissionThenReschedule(); refresh() }
                } else if status == .denied {
                    Button("Open iOS Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                }
            } footer: {
                Text("Turning this off silences every notification from \(Brand.name), including habit reminders.")
            }
            if prefs.notificationsEnabled {
                Section("Types") {
                    Toggle("Habit reminders", isOn: $prefs.notifyReminders)
                    Toggle("Friend requests, reminders & gifts", isOn: $prefs.notifyFriends)
                    Toggle("Reactions & comments", isOn: $prefs.notifyReactions)
                    Toggle("Groups & challenges", isOn: $prefs.notifyGroups)
                    Toggle("Awards", isOn: $prefs.notifyAwards)
                    Toggle("Weekly recap", isOn: $prefs.notifyRecap)
                    Toggle("Friend quizzes", isOn: $prefs.notifyQuizzes)
                }
                Section {
                    Toggle("Quiet hours", isOn: $prefs.quietHoursEnabled)
                    if prefs.quietHoursEnabled {
                        DatePicker("From", selection: minutesBinding(\.quietStartMinutes), displayedComponents: .hourAndMinute)
                        DatePicker("Until", selection: minutesBinding(\.quietEndMinutes), displayedComponents: .hourAndMinute)
                    }
                } footer: { Text("Reminders that fall in quiet hours wait until they end.") }
                Section("Per-habit reminders") {
                    ForEach(habits.filter { $0.status == .active }) { habit in
                        Button { reminderSheet = habit } label: {
                            HStack {
                                SymbolBadge(symbol: habit.symbol, tint: habit.tint, size: 28)
                                Text(habit.name).foregroundStyle(Palette.ink)
                                Spacer()
                                Text(habit.reminderEnabled ? Day.timeText(minutes: habit.reminderMinutes) : "Off")
                                    .foregroundStyle(Palette.inkSecondary)
                            }
                        }
                    }
                }
                if !groups.isEmpty {
                    Section("Per-group") {
                        ForEach(groups) { group in
                            Picker(group.name, selection: Binding(get: { group.notify }, set: { model.setNotify($0, for: group) })) {
                                ForEach(GroupNotifyLevel.allCases) { Text($0.label).tag($0) }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .sheet(item: $reminderSheet) { ReminderSheet(habit: $0) }
        .onAppear(perform: refresh)
        .onChange(of: prefs.notificationsEnabled) { _, _ in apply() }
        .onChange(of: prefs.notifyReminders) { _, _ in apply() }
        .onChange(of: prefs.quietHoursEnabled) { _, _ in apply() }
        .onChange(of: prefs.quietStartMinutes) { _, _ in apply() }
        .onChange(of: prefs.quietEndMinutes) { _, _ in apply() }
        .onChange(of: [prefs.notifyFriends, prefs.notifyReactions, prefs.notifyGroups, prefs.notifyAwards, prefs.notifyRecap, prefs.notifyQuizzes]) { _, _ in model.save() }
    }

    private var statusText: String {
        switch status {
        case .authorized: "Allowed"
        case .denied: "Off in iOS Settings"
        case .provisional: "Delivered quietly"
        case .ephemeral: "Temporary"
        case .notDetermined: "Not asked yet"
        @unknown default: "Unknown"
        }
    }

    private func minutesBinding(_ keyPath: ReferenceWritableKeyPath<AppPreferences, Int>) -> Binding<Date> {
        Binding(
            get: { Day.date(Day.today, atMinutes: model.prefs[keyPath: keyPath]) },
            set: { model.prefs[keyPath: keyPath] = Day.minutesOfDay($0) })
    }

    private func apply() {
        model.save()
        if model.prefs.notificationsEnabled {
            model.rescheduleReminders()
        } else {
            NotificationScheduler.shared.removeAll()
        }
    }

    private func refresh() {
        Task {
            let value = await NotificationScheduler.shared.authorizationStatus()
            await MainActor.run { status = value }
        }
    }
}

// MARK: - Appearance

private struct AppearanceSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var prefs = model.prefs
        Form {
            Section {
                Picker("Theme", selection: $prefs.appearanceRaw) {
                    ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
            } header: { Text("Theme") } footer: { Text("Light is the default. Dark mode is optional.") }
            Section("Accent color") {
                HStack(spacing: 14) {
                    ForEach(AccentChoice.allCases) { choice in
                        Button {
                            prefs.accent = choice
                            model.feedback(.selection)
                        } label: {
                            VStack(spacing: 4) {
                                Circle().fill(choice.color).frame(width: 36, height: 36)
                                    .overlay(Circle().strokeBorder(Palette.ink, lineWidth: prefs.accent == choice ? 2.5 : 0).padding(-4))
                                Text(choice.label).font(.caption2).foregroundStyle(Palette.inkSecondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 60)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(choice.label)
                        .accessibilityAddTraits(prefs.accent == choice ? .isSelected : [])
                    }
                }
            }
            Section("Layout") {
                Picker("Card density", selection: $prefs.densityRaw) {
                    ForEach(CardDensity.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Picker("First day of the week", selection: $prefs.firstWeekday) {
                    Text("Sunday").tag(1)
                    Text("Monday").tag(2)
                    Text("Saturday").tag(7)
                }
            }
            Section {
                Picker("Encouragement style", selection: $prefs.encouragementRaw) {
                    ForEach(EncouragementStyle.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Text(Encouragement.dayMessage(style: prefs.encouragement, done: 2, total: 4))
                    .font(.hand(17))
                    .foregroundStyle(Palette.burgundy)
                Toggle("Show streaks", isOn: $prefs.showStreaks)
                Picker("Celebrations", selection: $prefs.celebrationRaw) {
                    ForEach(CelebrationIntensity.allCases) { Text($0.label).tag($0.rawValue) }
                }
            } header: { Text("Tone") } footer: {
                Text("Streaks always stay secondary to consistency. Subtle celebrations swap full-screen reveals for a quick note.")
            }
        }
        .navigationTitle("Appearance")
        .onChange(of: prefs.appearanceRaw) { _, _ in model.preferencesChanged() }
        .onChange(of: prefs.accentRaw) { _, _ in model.preferencesChanged() }
        .onChange(of: prefs.densityRaw) { _, _ in model.preferencesChanged() }
        .onChange(of: prefs.firstWeekday) { _, _ in model.preferencesChanged() }
        .onChange(of: prefs.encouragementRaw) { _, _ in model.preferencesChanged() }
        .onChange(of: prefs.showStreaks) { _, _ in model.preferencesChanged() }
        .onChange(of: prefs.celebrationRaw) { _, _ in model.preferencesChanged() }
    }
}

// MARK: - Accessibility

private struct AccessibilitySettings: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        @Bindable var prefs = model.prefs
        Form {
            Section {
                Picker("Motion", selection: $prefs.motionRaw) {
                    ForEach(MotionPreference.allCases) { Text($0.label).tag($0.rawValue) }
                }
                LabeledContent("System Reduce Motion", value: systemReduceMotion ? "On" : "Off")
            } header: { Text("Motion") } footer: {
                Text("Reduced motion replaces stamps, sticker drops and page flips with simple fades.")
            }
            Section {
                Toggle("Reduced haptic intensity", isOn: $prefs.reducedHaptics)
                Toggle("Celebration haptics", isOn: $prefs.celebrationHaptics)
            } header: { Text("Touch") }
            Section {
                LabeledContent("Text size", value: typeSize.isAccessibilitySize ? "Accessibility size" : "Standard")
                LabeledContent("Increase Contrast", value: contrast == .increased ? "On" : "Off")
            } header: { Text("Follows iOS") } footer: {
                Text("\(Brand.name) follows your Dynamic Type size and Increase Contrast setting from iOS Settings → Accessibility.")
            }
        }
        .navigationTitle("Accessibility")
        .onChange(of: prefs.motionRaw) { _, _ in model.save() }
        .onChange(of: prefs.reducedHaptics) { _, _ in model.save() }
        .onChange(of: prefs.celebrationHaptics) { _, _ in model.save() }
    }
}

// MARK: - Sound

private struct SoundSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var prefs = model.prefs
        Form {
            Section {
                Toggle("App sounds", isOn: $prefs.soundsEnabled)
                Toggle("Completion sounds", isOn: $prefs.completionSounds).disabled(!prefs.soundsEnabled)
                Toggle("Recap sounds", isOn: $prefs.recapSounds).disabled(!prefs.soundsEnabled)
                HStack {
                    Image(systemName: "speaker.fill").foregroundStyle(Palette.inkSecondary)
                    Slider(value: $prefs.soundVolume, in: 0...1) { Text("Volume") }
                        .accessibilityValue(prefs.soundVolume.percentText)
                    Image(systemName: "speaker.wave.3.fill").foregroundStyle(Palette.inkSecondary)
                }
                .disabled(!prefs.soundsEnabled)
            } footer: {
                Text("Sounds are short and soft, follow the Ring/Silent switch, mix with your music, and never play in the background.")
            }
            Section("Preview") {
                ForEach(SoundEffect.allCases) { effect in
                    Button {
                        SoundManager.shared.play(effect, volume: max(prefs.soundVolume, 0.3))
                    } label: {
                        Label(effect.label, systemImage: "play.circle")
                    }
                }
            }
        }
        .navigationTitle("Sounds")
        .onChange(of: prefs.soundsEnabled) { _, _ in model.save() }
        .onChange(of: prefs.completionSounds) { _, _ in model.save() }
        .onChange(of: prefs.recapSounds) { _, _ in model.save() }
        .onChange(of: prefs.soundVolume) { _, _ in model.save() }
    }
}

// MARK: - Haptics

private struct HapticSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var prefs = model.prefs
        Form {
            Section {
                Toggle("Haptics", isOn: $prefs.hapticsEnabled)
                Toggle("Reduced intensity", isOn: $prefs.reducedHaptics).disabled(!prefs.hapticsEnabled)
                Toggle("Celebration patterns", isOn: $prefs.celebrationHaptics).disabled(!prefs.hapticsEnabled)
            } footer: {
                Text("Haptics mark meaningful moments — completing, unlocking, celebrating — not every tap. Unsupported devices simply skip them.")
            }
            Section("Try them") {
                preview("Selection", .selection)
                preview("Complete a habit", .success)
                preview("Undo", .undo)
                preview("Reaction received", .reactionReceived)
                preview("Before deleting", .warning)
                preview("Rare sticker", .unlock(.legendary))
                preview("Award reveal", .awardReveal)
                preview("Group goal", .groupCelebration)
            }
            .disabled(!prefs.hapticsEnabled)
        }
        .navigationTitle("Haptics")
        .onChange(of: prefs.hapticsEnabled) { _, _ in model.save() }
        .onChange(of: prefs.reducedHaptics) { _, _ in model.save() }
        .onChange(of: prefs.celebrationHaptics) { _, _ in model.save() }
    }

    private func preview(_ title: String, _ event: HapticEvent) -> some View {
        Button {
            HapticManager.shared.play(event, reduced: model.prefs.reducedHaptics, celebrations: model.prefs.celebrationHaptics)
        } label: { Label(title, systemImage: "hand.tap") }
    }
}

// MARK: - Connected services

private struct ConnectedServicesView: View {
    @Environment(AppModel.self) private var model

    private let services: [(key: String, name: String, symbol: String, tint: TintToken, detail: String)] = [
        ("health", "Apple Health", "heart.fill", .rose, "Auto-complete movement habits from steps and workouts."),
        ("calendar", "Calendar", "calendar", .burgundy, "Suggest reminder times around busy blocks."),
        ("screentime", "Screen Time", "hourglass", .sky, "Count phone-free evenings."),
        ("weather", "Weather", "cloud.sun.fill", .gold, "Swap outdoor habits on rainy days."),
    ]

    var body: some View {
        Form {
            Section {
                ForEach(services, id: \.key) { service in
                    let connected = model.prefs.connectedServices.contains(service.key)
                    HStack(spacing: 12) {
                        SymbolBadge(symbol: service.symbol, tint: service.tint, size: 36, filled: connected)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(service.name).font(.body.weight(.semibold))
                            Text(connected ? "Connected (demo)" : service.detail).font(.caption).foregroundStyle(Palette.inkSecondary)
                        }
                        Spacer()
                        Button(connected ? "Disconnect" : "Connect") {
                            if connected {
                                model.prefs.connectedServices.removeAll { $0 == service.key }
                            } else {
                                model.prefs.connectedServices.append(service.key)
                            }
                            model.save()
                            model.feedback(.selection)
                        }
                        .buttonStyle(InlineActionStyle(filled: !connected))
                    }
                }
            } footer: {
                Text("Demo only: these toggles show how integrations would look. No data is read from other apps.")
            }
        }
        .navigationTitle("Connected services")
    }
}

// MARK: - Data

private struct DataSettings: View {
    @Environment(AppModel.self) private var model
    @State private var exportURL: URL?

    var body: some View {
        Form {
            Section {
                if let exportURL {
                    ShareLink(item: exportURL) { Label("Share export (JSON)", systemImage: "square.and.arrow.up") }
                } else {
                    Button { exportURL = model.exportData() } label: { Label("Prepare data export", systemImage: "doc.badge.gearshape") }
                }
            } footer: {
                Text("Exports your habits, check-ins and collection as JSON. Photos are not included.")
            }
            Section {
                Button { model.router.push(.share(.progress)) } label: { Label("Visual progress report", systemImage: "chart.bar.doc.horizontal") }
            }
            Section("Optional sound files") {
                Text("Add any of these to the app target (as .caf, .wav or .m4a) to replace the built-in synthesized sounds:")
                    .font(.footnote).foregroundStyle(Palette.inkSecondary)
                ForEach(SoundEffect.allCases) { effect in
                    LabeledContent(effect.fileName, value: effect.label).font(.caption.monospaced())
                }
            }
        }
        .navigationTitle("Data")
    }
}
