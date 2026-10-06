import SwiftUI

enum RecapPage: Hashable {
    case intro, total, consistency, strongestDay, mostConsistent, mostImproved, interactions, goals, pattern, collectible, predictions, ranking
    case superlative(Int)
    case finale

    /// Big award moments get the stronger reveal sound and haptic.
    var isMajor: Bool {
        switch self {
        case .superlative, .collectible, .finale: true
        default: false
        }
    }

    static func pages(for data: RecapData) -> [RecapPage] {
        var pages: [RecapPage] = [.intro, .total, .consistency, .strongestDay]
        if data.mostConsistent != nil { pages.append(.mostConsistent) }
        if data.mostImproved != nil { pages.append(.mostImproved) }
        pages.append(.interactions)
        if !data.goals.isEmpty { pages.append(.goals) }
        pages.append(.pattern)
        if data.collectibleKey != nil { pages.append(.collectible) }
        if !data.predictions.isEmpty { pages.append(.predictions) }
        pages.append(.ranking)
        pages += data.superlatives.indices.map { .superlative($0) }
        pages.append(.finale)
        return pages
    }
}

/// One full-bleed recap card. `appeared` drives entrance animations (false when rendering for sharing).
struct RecapCardView: View {
    let page: RecapPage
    let data: RecapData
    let me: UserProfile?
    var collectible: Collectible?
    var appeared = true
    var reduceMotion = false

    private var weekLabel: String {
        "\(data.weekStart.formatted(.dateTime.month(.abbreviated).day())) – \(data.weekEnd.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var body: some View {
        ZStack {
            background
            content
                .padding(.horizontal, 28)
                .padding(.vertical, 40)
        }
        .clipped()
    }

    // MARK: Background

    private var background: some View {
        ZStack {
            Palette.spotlight
            RuledLines(spacing: 34, margin: false).opacity(0.35)
            // Spotlight beams
            ForEach(0..<2, id: \.self) { index in
                Ellipse()
                    .fill(RadialGradient(colors: [Color(uiColor: .dynamic(light: 0xFFF6E2, dark: 0x5A3A2E)).opacity(0.9), .clear], center: .center, startRadius: 0, endRadius: 220))
                    .frame(width: 320, height: 520)
                    .rotationEffect(.degrees(index == 0 ? 24 : -24))
                    .offset(x: index == 0 ? -120 : 120, y: -260)
                    .blendMode(.plusLighter)
                    .opacity(0.5)
            }
            VStack {
                Spacer()
                ribbonBand
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var ribbonBand: some View {
        HStack(spacing: 0) {
            ForEach(0..<12, id: \.self) { index in
                Rectangle().fill(index.isMultiple(of: 2) ? Palette.burgundy : Palette.burgundy.opacity(0.8)).frame(height: 14)
            }
        }
        .overlay(Rectangle().fill(Palette.gold).frame(height: 3), alignment: .top)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch page {
        case .intro:
            VStack(spacing: 18) {
                eyebrow("The weekly")
                bigText("\(Brand.name)\nAwards", size: 58)
                Text(weekLabel).font(.hand(24)).foregroundStyle(Palette.ink)
                if let me { AvatarView(config: me.avatar, size: 120).modifier(Entrance(appeared: appeared, delay: 0.3, reduce: reduceMotion)) }
                Text("Starring you, and the friends who cheered you on.").font(.award(.title3, weight: .semibold)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
            }
        case .total:
            VStack(spacing: 14) {
                eyebrow("Total habits completed")
                bigText("\(data.totalCompletions)", size: 140)
                    .modifier(Entrance(appeared: appeared, delay: 0.1, reduce: reduceMotion))
                Text(comparison(data.totalCompletions, data.previousCompletions, noun: "check-in"))
                    .font(.award(.title2, weight: .semibold)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                stamp("Counted", symbol: "checkmark")
            }
        case .consistency:
            VStack(spacing: 14) {
                eyebrow("Consistency")
                bigText(data.consistency?.percentText ?? "—", size: 120)
                    .modifier(Entrance(appeared: appeared, delay: 0.1, reduce: reduceMotion))
                Text("One missed day per habit, per week, was forgiven. Because life.")
                    .font(.award(.title3, weight: .semibold)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                if let previous = data.previousConsistency {
                    Text("Last week: \(previous.percentText)").font(.hand(22)).foregroundStyle(Palette.inkSecondary)
                }
            }
        case .strongestDay:
            VStack(spacing: 16) {
                eyebrow("Strongest day")
                bigText(Day.longName(forWeekday: data.strongestWeekday), size: 64)
                Text("\(data.strongestCount) stamps in one day").font(.award(.title3, weight: .semibold)).foregroundStyle(Palette.ink)
                HStack(alignment: .bottom, spacing: 8) {
                    let maxCount = max(1, data.dailyCounts.map(\.count).max() ?? 1)
                    ForEach(Array(data.dailyCounts.enumerated()), id: \.offset) { index, entry in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Day.weekday(entry.day) == data.strongestWeekday ? Palette.burgundy : Palette.rose.opacity(0.6))
                                .frame(width: 28, height: appeared || reduceMotion ? 18 + 120 * CGFloat(entry.count) / CGFloat(maxCount) : 18)
                                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.06), value: appeared)
                            Text(entry.day.formatted(.dateTime.weekday(.narrow))).font(.caption.weight(.bold)).foregroundStyle(Palette.inkSecondary)
                        }
                    }
                }
                .frame(height: 160, alignment: .bottom)
            }
        case .mostConsistent:
            if let line = data.mostConsistent {
                habitAward(eyebrow: "Most consistent habit", line: line, valueText: line.value.percentText, caption: line.detail)
            }
        case .mostImproved:
            if let line = data.mostImproved {
                habitAward(eyebrow: "Most improved", line: line, valueText: "+\(Int((line.value * 100).rounded())) pts", caption: line.detail)
            }
        case .interactions:
            VStack(spacing: 18) {
                eyebrow("Friend interactions")
                bigText("\(data.reactionsSent + data.commentsSent + data.remindersSent)", size: 110)
                VStack(alignment: .leading, spacing: 10) {
                    statLine("hands.clap.fill", "\(data.reactionsSent) reactions sent", .rose)
                    statLine("text.bubble.fill", "\(data.commentsSent) comments left", .gold)
                    statLine("bell.fill", "\(data.remindersSent) supportive reminders", .sky)
                    statLine("heart.fill", "\(data.reactionsReceived) cheers received", .burgundy)
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 14).fill(Palette.card.opacity(0.85)))
            }
        case .goals:
            VStack(spacing: 18) {
                eyebrow("Shared goals")
                bigText("Team effort", size: 52)
                ForEach(data.goals.prefix(3), id: \.self) { goal in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(goal.group).font(.caption.weight(.heavy)).foregroundStyle(Palette.burgundy).textCase(.uppercase)
                        Text(goal.title).font(.award(.headline)).foregroundStyle(Palette.ink)
                        ProgressBar(progress: appeared || reduceMotion ? goal.progress : 0, tint: goal.tint.color, height: 12)
                        Text("\(goal.total) of \(goal.goal)").font(.caption.monospacedDigit()).foregroundStyle(Palette.inkSecondary)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.card.opacity(0.9)))
                }
            }
        case .pattern:
            VStack(spacing: 18) {
                eyebrow("Funniest pattern")
                Image(systemName: data.pattern.symbol).font(.system(size: 70)).foregroundStyle(Palette.burgundy)
                    .modifier(Entrance(appeared: appeared, delay: 0.1, reduce: reduceMotion))
                bigText(data.pattern.title, size: 54)
                Text(data.pattern.detail).font(.award(.title3, weight: .semibold)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                Text("— calculated from your activity").font(.hand(18)).foregroundStyle(Palette.inkSecondary)
            }
        case .collectible:
            VStack(spacing: 16) {
                eyebrow("Unlocked this week")
                if let collectible {
                    StickerView(collectible, size: 200, forceUnlocked: true)
                        .rotationEffect(.degrees(appeared || reduceMotion ? -6 : -40))
                        .scaleEffect(appeared || reduceMotion ? 1 : 1.8)
                        .opacity(appeared || reduceMotion ? 1 : 0)
                        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.6).delay(0.15), value: appeared)
                    bigText(collectible.name, size: 44)
                    Text(collectible.earnedFor.isEmpty ? collectible.blurb : collectible.earnedFor).font(.hand(22)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                }
            }
        case .predictions:
            VStack(spacing: 18) {
                eyebrow("Prediction results")
                Image(systemName: "wand.and.stars").font(.system(size: 60)).foregroundStyle(Palette.inkBlue)
                ForEach(data.predictions.prefix(3), id: \.self) { line in
                    Text(line).font(.award(.title3, weight: .semibold)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                }
                Text("Voted by friends · decided by activity").font(.caption.weight(.bold)).foregroundStyle(Palette.inkSecondary)
            }
        case .ranking:
            VStack(spacing: 14) {
                eyebrow("The credits")
                bigText("Everyone\nshowed up", size: 46)
                VStack(spacing: 8) {
                    ForEach(Array(data.ranking.prefix(6).enumerated()), id: \.offset) { index, line in
                        HStack(spacing: 10) {
                            AvatarView(config: line.avatar, size: 34, showsCompanion: false)
                            Text(line.name).font(.award(.headline)).foregroundStyle(line.isMe ? Palette.burgundy : Palette.ink)
                            Text(line.label).font(.caption).foregroundStyle(Palette.inkSecondary)
                            Spacer()
                            Text("\(line.count)").font(.system(.headline, design: .rounded, weight: .heavy)).foregroundStyle(Palette.ink)
                        }
                        .modifier(Entrance(appeared: appeared, delay: 0.1 + Double(index) * 0.08, reduce: reduceMotion))
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Palette.card.opacity(0.9)))
            }
        case .superlative(let index):
            if let award = data.superlatives[safe: index] {
                superlativeCard(award)
            }
        case .finale:
            VStack(spacing: 14) {
                eyebrow("That's a wrap")
                bigText(data.headline, size: 44)
                HStack(spacing: 22) {
                    finaleStat("\(data.totalCompletions)", "check-ins")
                    finaleStat(data.consistency?.percentText ?? "—", "consistency")
                    finaleStat("\(data.comebacks)", "comebacks")
                }
                if let mine = data.superlatives.first(where: \.isMe) {
                    Text("Your award: \(mine.title)").font(.hand(24)).foregroundStyle(Palette.burgundy)
                }
                if let me { AvatarView(config: me.avatar, size: 96) }
                Text(weekLabel).font(.caption.weight(.bold)).foregroundStyle(Palette.inkSecondary)
            }
        }
    }

    // MARK: Pieces

    private func eyebrow(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(.footnote, design: .rounded, weight: .heavy))
            .tracking(2)
            .foregroundStyle(Palette.burgundy)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .overlay(Capsule().strokeBorder(Palette.burgundy.opacity(0.5), lineWidth: 1))
    }

    private func bigText(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .serif))
            .foregroundStyle(Palette.burgundy)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.4)
            .lineLimit(3)
            .shadow(color: Palette.gold.opacity(0.35), radius: 0, x: 3, y: 3)
    }

    private func stamp(_ text: String, symbol: String) -> some View {
        InkStamp(text: text, symbol: symbol, size: 90)
            .rotationEffect(.degrees(appeared || reduceMotion ? -12 : -50))
            .scaleEffect(appeared || reduceMotion ? 1 : 2.2)
            .opacity(appeared || reduceMotion ? 0.9 : 0)
            .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.55).delay(0.45), value: appeared)
    }

    private func statLine(_ symbol: String, _ text: String, _ tint: TintToken) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).foregroundStyle(tint.color).frame(width: 24)
            Text(text).font(.award(.headline, weight: .semibold)).foregroundStyle(Palette.ink)
        }
    }

    private func finaleStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(.title, design: .serif, weight: .black)).foregroundStyle(Palette.burgundy)
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(Palette.inkSecondary)
        }
    }

    private func comparison(_ now: Int, _ before: Int, noun: String) -> String {
        if before == 0 { return "\(now) \(noun)s stamped this week." }
        let diff = now - before
        if diff > 0 { return "\(diff) more than last week. Look at you." }
        if diff == 0 { return "Same as last week. Steady is beautiful." }
        return "A lighter week than last. Still \(now) times you showed up."
    }

    private func habitAward(eyebrow text: String, line: RecapData.HabitLine, valueText: String, caption: String) -> some View {
        VStack(spacing: 16) {
            eyebrow(text)
            SymbolBadge(symbol: line.symbol, tint: line.tint, size: 120, filled: true)
                .modifier(Entrance(appeared: appeared, delay: 0.1, reduce: reduceMotion))
            bigText(line.name, size: 46)
            Text(valueText).font(.system(size: 54, weight: .black, design: .serif)).foregroundStyle(Palette.ink)
            Text(caption).font(.hand(22)).foregroundStyle(Palette.inkSecondary)
        }
    }

    private func superlativeCard(_ award: Superlative) -> some View {
        VStack(spacing: 14) {
            eyebrow("And the award goes to…")
            ZStack {
                RibbonShape().fill(award.tint.color).frame(width: 190, height: 230)
                    .shadow(color: Palette.shadow.opacity(2), radius: 6, y: 4)
                AvatarView(config: award.avatar, size: 112, showsCompanion: false)
                    .offset(y: -32)
            }
            .modifier(Entrance(appeared: appeared, delay: 0.2, reduce: reduceMotion))
            bigText(award.title, size: 42)
            Text(award.winnerName).font(.system(.title, design: .serif, weight: .heavy)).foregroundStyle(Palette.ink)
            Text(award.explanation).font(.award(.headline, weight: .semibold)).foregroundStyle(Palette.ink.opacity(0.85)).multilineTextAlignment(.center)
            Label(award.source.rawValue, systemImage: award.source == .activity ? "chart.bar.fill" : "hand.raised.fill")
                .font(.caption.weight(.heavy))
                .foregroundStyle(award.source == .activity ? Palette.sage : Palette.sky)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 6).fill(Palette.card))
        }
    }
}

/// Fade-and-rise entrance that respects Reduce Motion.
struct Entrance: ViewModifier {
    let appeared: Bool
    var delay: Double = 0
    var reduce = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared || reduce ? 1 : 0)
            .offset(y: appeared || reduce ? 0 : 24)
            .scaleEffect(appeared || reduce ? 1 : 0.92)
            .animation(reduce ? nil : .spring(response: 0.5, dampingFraction: 0.75).delay(delay), value: appeared)
    }
}
