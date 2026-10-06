import Foundation
import SwiftData

/// Award engine: decides which collectibles a moment unlocks, and handles gifts and cosmetics.
extension AppModel {
    /// Cosmetics that unlock alongside certain collectibles.
    private static let cosmeticRewards: [String: String] = [
        "week-unbroken": "acc-cap",
        "back-again": "acc-flower",
        "weekend-warrior": "acc-beanie",
        "housewarming": "acc-headphones",
        "goal-reached": "out-overalls",
        "bounce-back": "comp-snail",
        "four-good-weeks": "comp-cat",
    ]

    /// Unlocks a collectible once. Returns true if it was newly unlocked.
    @discardableResult
    func unlock(_ key: String, reason: String, reveal: Bool = true, giftedBy: UUID? = nil) -> Bool {
        guard let item = collectible(key), !item.isUnlocked else { return false }
        item.isUnlocked = true
        item.earnedAt = Date()
        item.earnedFor = reason
        item.isSeen = false
        item.giftedByID = giftedBy
        addNotification(.award, title: "New \(item.form.rawValue): \(item.name)", body: reason)
        if let cosmetic = Self.cosmeticRewards[key] { unlockCosmetic(cosmetic) }
        if item.rarity == .rare { unlockCosmetic("bg-gold") }
        if item.rarity == .legendary { unlockCosmetic("frame-gold") }
        let unlockedCount = ((try? context.fetch(FetchDescriptor<Collectible>())) ?? []).filter(\.isUnlocked).count
        if unlockedCount >= 5 { unlockCosmetic("frame-scallop") }
        save()
        if reveal {
            // Let the completion stamp land before the sticker appears.
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(650))
                await MainActor.run { self?.queueReveal(item) }
            }
        }
        return true
    }

    func unlockCosmetic(_ key: String, giftedBy: UUID? = nil) {
        var descriptor = FetchDescriptor<CosmeticItem>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        guard let item = try? context.fetch(descriptor).first, !item.isUnlocked else { return }
        item.isUnlocked = true
        item.giftedByID = giftedBy
    }

    /// Picks at most one new collectible per check-in, most special first.
    func evaluateCheckInAwards(habit: Habit, checkIn: CheckIn, missedBefore: Int) {
        let allMine = ((try? context.fetch(FetchDescriptor<CheckIn>())) ?? []).filter { $0.friendID == nil }
        let day = checkIn.day
        var candidates: [(String, String)] = []

        if allMine.count == 1 { candidates.append(("first-stamp", "First check-in: \(habit.name)")) }

        if checkIn.isComeback {
            if missedBefore >= 7 { candidates.append(("fresh-page", "Returned to \(habit.name) after \(missedBefore) missed days")) }
            let monthAgo = Day.add(-30, to: day)
            let recentComebacks = allMine.filter { $0.isComeback && $0.day >= monthAgo }.count
            if recentComebacks >= 3 { candidates.append(("bounce-back", "Your \(recentComebacks)rd comeback this month — on \(habit.name)")) }
            candidates.append(("back-again", "Came back to \(habit.name) after \(missedBefore) missed days"))
        }

        let streak = habit.currentStreak
        if streak.unit == "day" {
            if streak.count >= 50 { candidates.append(("long-haul", "\(streak.count) in a row on \(habit.name)")) }
            if streak.count >= 21 { candidates.append(("groove-found", "\(streak.count) in a row on \(habit.name)")) }
            if streak.count >= 7 { candidates.append(("week-unbroken", "\(streak.count) in a row on \(habit.name)")) }
        }

        if habit.isShared, habit.participantIDs.contains(where: { habit.friendCompleted($0, on: day) }) {
            let partner = habit.participantIDs.first { habit.friendCompleted($0, on: day) }.flatMap { friend($0)?.firstName } ?? "a friend"
            candidates.append(("in-sync", "Matched \(partner) on \(habit.name)"))
        }

        let hour = Day.calendar.component(.hour, from: checkIn.completedAt)
        if hour >= 22 { candidates.append(("night-owl", "\(habit.name) at \(checkIn.completedAt.formatted(date: .omitted, time: .shortened))")) }

        if Day.isWeekend(day) {
            let other = Day.weekday(day) == 1 ? Day.add(-1, to: day) : Day.add(1, to: day)
            if allMine.contains(where: { $0.day == other }) { candidates.append(("weekend-warrior", "Checked in on Saturday and Sunday")) }
        }

        let habits = allHabits().filter { $0.status == .active && !$0.isOptional && !$0.rule.isFlexible && $0.isScheduled(on: day) }
        if !habits.isEmpty, habits.allSatisfy({ $0.isCompleted(on: day) }) {
            candidates.append(("full-page", "Every scheduled habit stamped on \(day.formatted(.dateTime.weekday(.wide).month().day()))"))
        }

        let week = Day.week(containing: day)
        let activeDays = Set(allMine.map(\.day)).intersection(week)
        if activeDays.count == 7 { candidates.append(("all-seven", "Checked in all seven days of the week")) }

        if allMine.count >= 100 { candidates.append(("hundred-club", "Your \(allMine.count)th check-in")) }
        if allMine.count >= 25 { unlockCosmetic("hair-swoop") }

        let weekTally = allHabits().filter(\.countsTowardConsistency).map { $0.tally(from: week[0], to: day) }.reduce(Tally.zero, +)
        if Day.between(week[0], day) >= 4, let value = weekTally.consistency, value >= 0.8 {
            candidates.append(("steady-week", "\(value.percentText) consistency this week"))
        }

        if let overall = allHabits().overallConsistency(), overall >= 0.8 { unlockCosmetic("comp-cat") }

        for (key, reason) in candidates where collectible(key)?.isUnlocked == false {
            unlock(key, reason: reason)
            return
        }
    }

    // MARK: Collection management

    func toggleFavorite(_ item: Collectible) {
        item.isFavorite.toggle()
        feedback(.selection)
        save()
    }

    static let showcaseLimit = 6

    func toggleShowcase(_ item: Collectible) {
        guard let me else { return }
        if let index = me.showcaseKeys.firstIndex(of: item.key) {
            me.showcaseKeys.remove(at: index)
            showToast("Removed from your showcase.", symbol: "rectangle.stack.badge.minus", tint: .cream)
        } else if me.showcaseKeys.count >= Self.showcaseLimit {
            feedback(.warning)
            showToast("Your showcase holds \(Self.showcaseLimit). Remove one first.", symbol: "exclamationmark.circle.fill", tint: .orange)
            return
        } else {
            me.showcaseKeys.append(item.key)
            showToast("Pinned to your profile.", symbol: "pin.fill", tint: item.tint)
        }
        feedback(.selection)
        save()
    }

    func markCollectionSeen() {
        let items = (try? context.fetch(FetchDescriptor<Collectible>())) ?? []
        for item in items where !item.isSeen && item.isUnlocked && revealing?.key != item.key { item.isSeen = true }
        save()
    }

    // MARK: Gifts

    func sendGift(_ kind: GiftKind, to friend: Friend, itemKey: String?, message: String) {
        context.insert(Gift(kind: kind, fromID: nil, toID: friend.id, itemKey: itemKey, message: message.cleaned(max: 120)))
        if prefs.activityInFeed {
            context.insert(ActivityItem(kind: .gift, actorID: nil, title: "Sent \(friend.firstName) a \(kind.label.lowercased())",
                                        detail: message.cleaned(max: 120), symbol: kind.symbol, tint: kind.tint))
        }
        save()
        feedback(.send)
        showToast("\(kind.label) sent to \(friend.firstName).", symbol: "gift.fill", tint: kind.tint)
        unlock("care-package", reason: "Sent \(friend.firstName) a \(kind.label.lowercased())")
    }

    func open(_ gift: Gift) {
        guard !gift.opened else { return }
        gift.opened = true
        let sender = friend(gift.fromID)
        switch gift.kind {
        case .reminderPass: me?.reminderPasses += 1
        case .comebackBoost: me?.comebackBoosts += 1
        case .doubleReaction: me?.doubleReactionTokens += 1
        case .cosmetic:
            if let key = gift.itemKey { unlockCosmetic(key, giftedBy: gift.fromID) }
        case .sticker:
            if let key = gift.itemKey { unlock(key, reason: "A gift from \(sender?.firstName ?? "a friend")", reveal: false, giftedBy: gift.fromID) }
        }
        save()
        feedback(.unlock(.uncommon))
        showToast("Opened: \(gift.kind.label) from \(sender?.firstName ?? "a friend").", symbol: "gift.fill", tint: gift.kind.tint)
    }
}
