import SwiftUI

/// Eleven-step native onboarding. Completion is persisted in `AppPreferences`.
struct OnboardingFlow: View {
    enum Step: Int, CaseIterable {
        case welcome, account, name, avatar, interests, quiz, result, firstHabit, friends, preferences, ready
    }

    @Environment(AppModel.self) private var model
    @Environment(\.motionReduced) private var motionReduced

    @State private var step: Step = .welcome
    @State private var forward = true
    @State private var name = ""
    @State private var avatar = AvatarConfig()
    @State private var interests: Set<String> = []
    @State private var quizIndex = 0
    @State private var answers: [PersonalityType] = []
    @State private var draft = HabitDraft(name: "", category: .movement, timeOfDay: .morning, frequency: .daily)
    @State private var keptFriends = Set(DemoSeeder.seededFriendNames)
    @State private var skippedFriends = false
    @State private var remindersOn = true
    @State private var soundsOn = true
    @State private var hapticsOn = true
    @State private var showHabitErrors = false
    @FocusState private var nameFocused: Bool

    private var personality: PersonalityType { Catalog.scorePersonality(answers) }

    var body: some View {
        VStack(spacing: 0) {
            if step != .welcome {
                progressHeader
            }
            ZStack {
                stepView
                    .id(step)
                    .transition(transition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(PaperBackground())
    }

    // MARK: Chrome

    private var progressHeader: some View {
        let total = Step.allCases.count - 1
        return VStack(spacing: 8) {
            HStack {
                Button {
                    back()
                } label: {
                    Image(systemName: "chevron.left").font(.body.weight(.bold)).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Back")
                Spacer()
                Text("Step \(step.rawValue) of \(total)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Palette.inkSecondary)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            HStack(spacing: 4) {
                ForEach(1...total, id: \.self) { index in
                    Capsule()
                        .fill(index <= step.rawValue ? Palette.burgundy : Palette.line)
                        .frame(height: 5)
                }
            }
            .accessibilityHidden(true)
        }
        .foregroundStyle(Palette.burgundy)
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 4)
    }

    private var transition: AnyTransition {
        if motionReduced { return .opacity }
        return .asymmetric(insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                           removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity))
    }

    private func go(_ next: Step) {
        forward = next.rawValue > step.rawValue
        withAnimation(motionReduced ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.88)) { step = next }
        model.feedback(.selection)
    }

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        go(next)
    }

    private func back() {
        if step == .quiz, quizIndex > 0 {
            quizIndex -= 1
            answers.removeLast()
            return
        }
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        go(previous)
    }

    // MARK: Steps

    @ViewBuilder
    private var stepView: some View {
        switch step {
        case .welcome: welcome
        case .account: account
        case .name: nameStep
        case .avatar: avatarStep
        case .interests: interestsStep
        case .quiz: quizStep
        case .result: resultStep
        case .firstHabit: firstHabitStep
        case .friends: friendsStep
        case .preferences: preferencesStep
        case .ready: readyStep
        }
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    StickerView(shape: [StickerShape.scallop, .star, .heart][index], symbol: ["checkmark", "sun.max.fill", "heart.fill"][index],
                                tint: [TintToken.sage, .gold, .rose][index], size: 90)
                        .rotationEffect(.degrees(Double(index * 14 - 14)))
                        .offset(x: CGFloat(index - 1) * 80, y: index == 1 ? -24 : 10)
                }
                InkStamp(text: Brand.name, symbol: Brand.markSymbol, size: 110)
                    .rotationEffect(.degrees(-10))
                    .offset(y: 84)
            }
            .frame(height: 240)
            .padding(.bottom, 36)
            Text(Brand.name)
                .font(.award(.largeTitle))
                .foregroundStyle(Palette.burgundy)
            Text(Brand.tagline)
                .font(.display(.title3, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Text(Brand.pitch)
                .font(.callout)
                .foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Spacer()
            Button("Get started") { advance() }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Metrics.gutter)
            HandNote("no pressure, no shame — just progress", size: 16, rotation: -2)
                .padding(.bottom, 20)
        }
    }

    private var account: some View {
        StepScaffold(title: "How do you want to start?", subtitle: "Everything stays on this device. No sign-up required.") {
            VStack(spacing: 14) {
                Button { advance() } label: {
                    choiceCard(symbol: "person.crop.circle.badge.plus", title: "Create my profile",
                               detail: "Pick a name, an avatar and your first habit. A demo circle of friends comes along so the app isn't empty.", tint: .burgundy)
                }
                .buttonStyle(PressableStyle())
                Button {
                    model.feedback(.complete)
                    model.startDemo()
                } label: {
                    choiceCard(symbol: "sparkles", title: "Explore with demo data",
                               detail: "Jump straight in as Riley, with seven weeks of history, friends, groups and stickers.", tint: .gold)
                }
                .buttonStyle(PressableStyle())
            }
        } footer: { EmptyView() }
    }

    private func choiceCard(symbol: String, title: String, detail: String, tint: TintToken) -> some View {
        HStack(alignment: .top, spacing: 14) {
            SymbolBadge(symbol: symbol, tint: tint, size: 50, filled: true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.display(.headline)).foregroundStyle(Palette.ink)
                Text(detail).font(.subheadline).foregroundStyle(Palette.inkSecondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(Palette.inkFaint)
        }
        .card(tint: tint, emphasized: false)
        .multilineTextAlignment(.leading)
    }

    private var nameStep: some View {
        let cleaned = name.cleaned(max: 30)
        return StepScaffold(title: "What should friends call you?", subtitle: "Your display name. You can change it later.") {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Your name", text: $name)
                    .font(.display(.title2, weight: .bold))
                    .textContentType(.givenName)
                    .submitLabel(.next)
                    .focused($nameFocused)
                    .onSubmit { if !cleaned.isEmpty { advance() } }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Palette.card))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.lineStrong))
                Text("\(name.count)/30").font(.caption).foregroundStyle(name.count > 30 ? Palette.burgundy : Palette.inkFaint)
            }
            .onAppear { nameFocused = true }
        } footer: {
            Button("Continue") { advance() }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(cleaned.isEmpty || name.count > 30)
        }
    }

    private var avatarStep: some View {
        VStack(spacing: 0) {
            Text("Make a little you")
                .font(.display(.title2, weight: .heavy)).foregroundStyle(Palette.ink)
                .padding(.top, 12)
            AvatarPreviewHeader(config: avatar)
            ScrollView {
                AvatarOptionsEditor(config: $avatar, full: false)
                    .padding(Metrics.gutter)
                Text("More hair, outfits, frames and companions unlock as you go.")
                    .font(.caption).foregroundStyle(Palette.inkSecondary)
                    .padding(.bottom, 12)
            }
            Button("Looks like me") { advance() }
                .buttonStyle(PrimaryButtonStyle())
                .padding(Metrics.gutter)
        }
    }

    private var interestsStep: some View {
        StepScaffold(title: "What are you hoping for?", subtitle: "Pick a few. We'll suggest a first habit.") {
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(Catalog.interests) { interest in
                    ChoiceChip(title: interest.label, symbol: interest.symbol, isSelected: interests.contains(interest.id)) {
                        if interests.contains(interest.id) { interests.remove(interest.id) } else { interests.insert(interest.id) }
                        model.feedback(.selection)
                    }
                }
            }
        } footer: {
            Button(interests.isEmpty ? "Skip" : "Continue") { advance() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var quizStep: some View {
        let question = Catalog.personalityQuiz[safe: quizIndex] ?? Catalog.personalityQuiz[0]
        return StepScaffold(title: question.prompt, subtitle: "Habit-personality quiz · \(quizIndex + 1) of \(Catalog.personalityQuiz.count)") {
            VStack(spacing: 10) {
                ForEach(Array(question.answers.enumerated()), id: \.offset) { _, answer in
                    Button {
                        answers.append(answer.type)
                        model.feedback(.selection)
                        if quizIndex + 1 < Catalog.personalityQuiz.count {
                            withAnimation(motionReduced ? nil : .snappy) { quizIndex += 1 }
                        } else {
                            advance()
                        }
                    } label: {
                        HStack {
                            Text(answer.text).font(.display(.body, weight: .semibold)).foregroundStyle(Palette.ink)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "circle").foregroundStyle(Palette.line)
                        }
                        .frame(minHeight: 54)
                        .padding(.horizontal, 16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.card))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.line))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .id(quizIndex)
            .transition(.opacity)
        } footer: { EmptyView() }
    }

    private var resultStep: some View {
        let result = Catalog.personality(personality)
        return StepScaffold(title: "You're a…", subtitle: nil) {
            VStack(spacing: 14) {
                ZStack {
                    StickerView(shape: .ribbon, symbol: result.symbol, tint: result.tint, size: 160)
                    InkStamp(text: "Result", symbol: "sparkles", size: 70).rotationEffect(.degrees(-14)).offset(x: 90, y: -40)
                }
                Text(result.name).font(.award(.largeTitle)).foregroundStyle(Palette.burgundy)
                Text(result.tagline).font(.hand(22)).foregroundStyle(Palette.ink)
                Text(result.summary).font(.callout).foregroundStyle(Palette.inkSecondary).multilineTextAlignment(.center)
                FlowLayout(spacing: 6) {
                    ForEach(result.strengths, id: \.self) { strength in
                        Text(strength).font(.caption.weight(.bold))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(result.tint.color.opacity(0.25)))
                    }
                }
                Label(result.watchOut, systemImage: "lightbulb.fill")
                    .font(.footnote).foregroundStyle(Palette.ink)
                    .card(padding: 12)
            }
            .frame(maxWidth: .infinity)
            .onAppear { model.feedback(.superlativeReveal) }
        } footer: {
            Button("Suggest my first habit") {
                let suggestion = result.suggestedHabit
                let interestPick = Catalog.interests.first { interests.contains($0.id) }
                if let interestPick {
                    draft = HabitDraft(name: interestPick.suggestion, category: interestPick.category, timeOfDay: suggestion.timeOfDay, frequency: .daily)
                } else {
                    draft = HabitDraft(name: suggestion.name, category: suggestion.category, timeOfDay: suggestion.timeOfDay, frequency: suggestion.frequency)
                }
                advance()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var firstHabitStep: some View {
        let suggestions = (Catalog.interests.filter { interests.contains($0.id) }.map(\.suggestion) + [Catalog.personality(personality).suggestedHabit.name]).uniqued()
        return StepScaffold(title: "Your first habit", subtitle: "Start smaller than feels necessary.") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    SymbolBadge(symbol: draft.symbol, tint: draft.tint, size: 50, filled: true)
                    TextField("Habit name", text: $draft.name)
                        .font(.display(.title3, weight: .bold))
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.card))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.lineStrong))
                }
                if showHabitErrors, let error = draft.nameError { FieldError(error) }
                FlowLayout(spacing: 6) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        ChoiceChip(title: suggestion, isSelected: draft.name == suggestion) { draft.name = suggestion }
                    }
                }
                Picker("Category", selection: $draft.category) {
                    ForEach(HabitCategory.allCases) { Label($0.label, systemImage: $0.defaultSymbol).tag($0) }
                }
                .pickerStyle(.menu)
                .onChange(of: draft.category) { _, category in
                    draft.symbol = category.defaultSymbol
                    draft.tint = category.defaultTint
                }
                Text("When?").font(.display(.subheadline, weight: .bold)).foregroundStyle(Palette.ink)
                Picker("Time of day", selection: $draft.timeOfDay) {
                    ForEach(TimeOfDay.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                Text("How often?").font(.display(.subheadline, weight: .bold)).foregroundStyle(Palette.ink)
                Picker("Frequency", selection: $draft.frequency) {
                    ForEach([Frequency.daily, .weekdays, .weekends, .timesPerWeek]) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                if draft.frequency == .timesPerWeek {
                    Stepper("\(draft.timesPerWeek)× a week", value: $draft.timesPerWeek, in: 1...7)
                }
            }
        } footer: {
            Button("Add to my book") {
                guard draft.isValid else {
                    showHabitErrors = true
                    model.feedback(.error)
                    return
                }
                draft.scheduledTime = Day.date(Day.today, atMinutes: draft.timeOfDay.defaultMinutes)
                draft.reminderTime = draft.scheduledTime
                advance()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var friendsStep: some View {
        StepScaffold(title: "Bring your people", subtitle: "These demo contacts are already on \(Brand.name).") {
            VStack(spacing: 8) {
                ForEach(DemoSeeder.circlePreview, id: \.name) { person in
                    let selected = keptFriends.contains(person.name)
                    Button {
                        if selected { keptFriends.remove(person.name) } else { keptFriends.insert(person.name) }
                        model.feedback(.selection)
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(config: person.avatar, size: 44, showsCompanion: false)
                            VStack(alignment: .leading) {
                                Text(person.name).font(.display(.body, weight: .semibold)).foregroundStyle(Palette.ink)
                                Text(person.detail).font(.caption).foregroundStyle(Palette.inkSecondary)
                            }
                            Spacer()
                            Image(systemName: selected ? "checkmark.circle.fill" : "plus.circle")
                                .font(.title2)
                                .foregroundStyle(selected ? Palette.burgundy : Palette.inkFaint)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.card))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
                Text("Mock contacts only — \(Brand.name) never reads your address book.")
                    .font(.caption).foregroundStyle(Palette.inkFaint)
            }
        } footer: {
            VStack(spacing: 8) {
                Button(keptFriends.isEmpty ? "Continue solo" : "Add \(keptFriends.count) friend\(keptFriends.count == 1 ? "" : "s")") {
                    skippedFriends = false
                    advance()
                }
                .buttonStyle(PrimaryButtonStyle())
                Button("Skip for now") {
                    skippedFriends = true
                    advance()
                }
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
            }
        }
    }

    private var preferencesStep: some View {
        StepScaffold(title: "Make it feel right", subtitle: "Change these anytime in Settings.") {
            VStack(spacing: 12) {
                prefRow("Habit reminders", detail: "A gentle nudge at your habit's time. We'll ask iOS for permission when you finish.", symbol: "bell.fill", tint: .gold, isOn: $remindersOn)
                prefRow("Sounds", detail: "Soft, short, and they follow your silent switch.", symbol: "speaker.wave.2.fill", tint: .rose, isOn: $soundsOn)
                prefRow("Haptics", detail: "A little tap when something meaningful happens.", symbol: "iphone.radiowaves.left.and.right", tint: .sage, isOn: $hapticsOn)
                Button {
                    if soundsOn { SoundManager.shared.play(.complete, volume: model.prefs.soundVolume) }
                    if hapticsOn { HapticManager.shared.play(.success, reduced: false, celebrations: true) }
                } label: { Label("Try a check-in", systemImage: "checkmark.seal") }
                    .buttonStyle(SecondaryButtonStyle())
            }
        } footer: {
            Button("Continue") { advance() }.buttonStyle(PrimaryButtonStyle())
        }
    }

    private func prefRow(_ title: String, detail: String, symbol: String, tint: TintToken, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(alignment: .top, spacing: 12) {
                SymbolBadge(symbol: symbol, tint: tint, size: 40, filled: isOn.wrappedValue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.display(.body, weight: .semibold)).foregroundStyle(Palette.ink)
                    Text(detail).font(.caption).foregroundStyle(Palette.inkSecondary).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Palette.burgundy)
        .card(padding: 12)
    }

    private var readyStep: some View {
        StepScaffold(title: "Your book is ready", subtitle: nil) {
            VStack(spacing: 16) {
                AvatarView(config: avatar, size: 130)
                Text("Welcome, \(name.cleaned(max: 30).firstName)!").font(.award(.title)).foregroundStyle(Palette.burgundy)
                VStack(alignment: .leading, spacing: 10) {
                    Label(draft.trimmedName, systemImage: draft.symbol)
                    Label(Catalog.personality(personality).name, systemImage: Catalog.personality(personality).symbol)
                    Label(skippedFriends ? "Demo circle included" : "\(keptFriends.count) friends", systemImage: "person.2.fill")
                }
                .font(.display(.body, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
                HandNote("one missed day a week is always forgiven", size: 17)
            }
        } footer: {
            Button("Open Today") { finish() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private func finish() {
        model.feedback(.complete)
        model.completeOnboarding(OnboardingResult(
            name: name, avatar: avatar, interests: Array(interests), personality: answers.isEmpty ? nil : personality,
            firstHabit: draft, keptFriendNames: skippedFriends ? nil : keptFriends,
            remindersOn: remindersOn, soundsOn: soundsOn, hapticsOn: hapticsOn))
    }
}

/// Title + scrolling content + pinned footer, kept clear of the home indicator.
struct StepScaffold<Content: View, Footer: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.display(.title, weight: .heavy))
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        if let subtitle {
                            Text(subtitle).font(.callout).foregroundStyle(Palette.inkSecondary)
                        }
                    }
                    content()
                }
                .padding(Metrics.gutter)
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            footer()
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 8)
        }
    }
}
