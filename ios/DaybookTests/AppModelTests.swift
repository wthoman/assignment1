import SwiftData
import SwiftUI
import XCTest
@testable import Daybook

@MainActor
final class AppModelTests: XCTestCase {
    private var model: AppModel!
    private var container: ModelContainer!

    override func setUp() async throws {
        container = PersistenceController.makeContainer(inMemory: true)
        model = AppModel(context: container.mainContext)
        model.prefs.soundsEnabled = false
        model.prefs.hapticsEnabled = false
        model.startDemo()
    }

    override func tearDown() async throws {
        model = nil
        container = nil
    }

    func testDemoSeedPopulatesEveryArea() throws {
        let context = container.mainContext
        XCTAssertNotNil(model.me)
        XCTAssertTrue(model.prefs.hasCompletedOnboarding)
        XCTAssertGreaterThanOrEqual(try context.fetchCount(FetchDescriptor<Habit>()), 8)
        XCTAssertGreaterThan(try context.fetchCount(FetchDescriptor<CheckIn>()), 100)
        XCTAssertEqual(model.friends().count, 6)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<HabitGroup>()), 3)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Collectible>()), Catalog.collectibles.count)
        XCTAssertGreaterThan(try context.fetchCount(FetchDescriptor<ActivityItem>()), 10)
        XCTAssertGreaterThan(try context.fetchCount(FetchDescriptor<NotificationItem>()), 5)
        XCTAssertGreaterThan(try context.fetchCount(FetchDescriptor<Quiz>()), 3)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WeeklyRecap>()), 4)
        XCTAssertNotNil(model.allHabits().overallConsistency())
    }

    func testCompleteAndUndo() throws {
        let habit = try XCTUnwrap(model.allHabits().first { $0.status == .active && !$0.isCompleted(on: Day.today) && $0.isScheduled(on: Day.today) })
        XCTAssertTrue(model.toggleCompletion(habit))
        XCTAssertTrue(habit.isCompleted(on: Day.today))
        XCTAssertNotNil(model.toast)
        XCTAssertFalse(model.toggleCompletion(habit))
        XCTAssertFalse(habit.isCompleted(on: Day.today))
    }

    func testFutureDaysCannotBeCompleted() throws {
        let habit = try XCTUnwrap(model.allHabits().first)
        XCTAssertNil(model.complete(habit, on: Day.add(2, to: Day.today)))
    }

    func testNoteAlsoChecksIn() throws {
        let habit = try XCTUnwrap(model.allHabits().first { $0.status == .active && !$0.isCompleted(on: Day.today) })
        model.saveNote("Felt great", for: habit, on: Day.today)
        XCTAssertEqual(habit.myCheckIn(on: Day.today)?.note, "Felt great")
    }

    func testCreateEditPauseDeleteHabit() throws {
        var draft = HabitDraft(name: "Stretch", category: .mind, timeOfDay: .morning, frequency: .weekdays)
        draft.notes = "Five minutes"
        let habit = model.createHabit(from: draft)
        XCTAssertEqual(habit.rule.frequency, .weekdays)
        XCTAssertEqual(habit.notes, "Five minutes")

        var edit = HabitDraft(habit: habit)
        edit.name = "Long stretch"
        edit.frequency = .custom
        edit.weekdays = [1, 7]
        model.updateHabit(habit, from: edit)
        XCTAssertEqual(habit.name, "Long stretch")
        XCTAssertEqual(habit.rule.activeWeekdays, [1, 7])

        model.setStatus(.paused, for: habit)
        XCTAssertEqual(habit.status, .paused)
        XCTAssertFalse(habit.countsTowardConsistency)

        model.delete(habit)
        XCTAssertFalse(model.allHabits().contains { $0.name == "Long stretch" })
    }

    func testGroupGoalTriggersCelebration() throws {
        let groups = try container.mainContext.fetch(FetchDescriptor<HabitGroup>())
        let challenge = try XCTUnwrap(groups.flatMap(\.challenges).first { $0.title.hasPrefix("Drink water") })
        let remaining = challenge.goal - challenge.total
        XCTAssertGreaterThan(remaining, 0)
        for _ in 0..<remaining { model.logContribution(challenge) }
        XCTAssertTrue(challenge.isComplete)
        XCTAssertNotNil(challenge.completedAt)
        XCTAssertEqual(model.celebratingChallenge?.id, challenge.id)
        XCTAssertEqual(model.collectible("goal-reached")?.isUnlocked, true)
    }

    func testSocialActions() throws {
        let items = try container.mainContext.fetch(FetchDescriptor<ActivityItem>())
        let item = try XCTUnwrap(items.first { $0.kind == .comeback && !$0.celebratedByMe && $0.actorID != nil })
        model.celebrateComeback(item)
        XCTAssertTrue(item.celebratedByMe)
        XCTAssertEqual(model.collectible("welcome-committee")?.isUnlocked, true)

        model.react(.fire, to: item)
        XCTAssertEqual(item.myReaction()?.kind, .fire)
        model.react(.fire, to: item)
        XCTAssertNil(item.myReaction(), "Reacting twice with the same kind removes it")

        model.comment("Proud of you", on: item)
        XCTAssertTrue(item.comments.contains { $0.text == "Proud of you" && $0.authorID == nil })
    }

    func testGiftOpeningUnlocksCosmetic() throws {
        let gift = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<Gift>()).first { $0.kind == .cosmetic && !$0.opened })
        model.open(gift)
        XCTAssertTrue(gift.opened)
        let key = try XCTUnwrap(gift.itemKey)
        let cosmetic = try container.mainContext.fetch(FetchDescriptor<CosmeticItem>()).first { $0.key == key }
        XCTAssertEqual(cosmetic?.isUnlocked, true)
    }

    func testInvitationAcceptance() throws {
        let note = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<NotificationItem>()).first { $0.kind == .groupInvite && $0.refID != nil })
        model.respond(to: note, accept: true)
        let group = try XCTUnwrap(model.group(note.refID))
        XCTAssertTrue(group.isMember)
        XCTAssertEqual(note.resolution, "accepted")
    }

    func testRecapHasAwardsForTheCircle() {
        let recap = model.buildRecap()
        XCTAssertGreaterThan(recap.totalCompletions, 0)
        XCTAssertGreaterThanOrEqual(recap.superlatives.count, 5)
        XCTAssertEqual(Set(recap.superlatives.map(\.winnerID)).count, recap.superlatives.count, "Each person wins at most one award")
        XCTAssertTrue(recap.superlatives.contains { $0.source == .votes || $0.source == .both })
        XCTAssertFalse(RecapPage.pages(for: recap).isEmpty)
    }

    func testResetDemoKeepsProfile() throws {
        let name = model.me?.name
        let habit = try XCTUnwrap(model.allHabits().first)
        model.delete(habit)
        model.resetDemoData()
        XCTAssertEqual(model.me?.name, name)
        XCTAssertGreaterThanOrEqual(model.allHabits().count, 8)
    }

    func testOnboardingCreatesProfileAndFirstHabit() throws {
        let result = OnboardingResult(name: "Sam", avatar: AvatarConfig(), interests: ["move"], personality: .gentleBuilder,
                                      firstHabit: HabitDraft(name: "Tiny walk", category: .movement, timeOfDay: .morning, frequency: .daily),
                                      keptFriendNames: ["Maya Okafor"], remindersOn: false, soundsOn: false, hapticsOn: false)
        model.completeOnboarding(result)
        XCTAssertEqual(model.me?.name, "Sam")
        XCTAssertEqual(model.allHabits().first?.name, "Tiny walk")
        XCTAssertEqual(model.friends().map(\.name), ["Maya Okafor"])
        XCTAssertTrue(model.allHabits().allSatisfy { habit in habit.participantIDs.allSatisfy { id in model.friend(id)?.status == .friend } })
    }

    func testDeleteAccountWipesEverything() throws {
        model.deleteAccount()
        XCTAssertNil(model.me)
        XCTAssertFalse(model.prefs.hasCompletedOnboarding)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<Habit>()), 0)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<AppPreferences>()), 1)
    }

    func testExportProducesJSON() throws {
        let url = try XCTUnwrap(model.exportData())
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json?["habits"])
    }

    func testSynthesizedSoundsRender() throws {
        let format = try XCTUnwrap(AVAudioFormatFactory.mono())
        for effect in SoundEffect.allCases {
            let buffer = ToneSynth.render(effect, format: format)
            XCTAssertNotNil(buffer, "\(effect) should synthesize")
            XCTAssertGreaterThan(buffer?.frameLength ?? 0, 0)
        }
    }

    /// Renders every recap card and share card to PNGs for visual review.
    func testRenderRecapAndShareCards() throws {
        let recap = model.buildRecap()
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("daybook-cards", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for (index, page) in RecapPage.pages(for: recap).enumerated() {
            let collectible = recap.collectibleKey.flatMap { model.collectible($0) }
            let view = RecapCardView(page: page, data: recap, me: model.me, collectible: collectible, appeared: true, reduceMotion: true)
                .frame(width: 390, height: 844)
            let image = try XCTUnwrap(ShareRenderer.uiImage(for: view, scale: 1))
            try image.pngData()?.write(to: dir.appendingPathComponent(String(format: "recap-%02d.png", index)))
        }
        if let item = model.collectible("back-again") {
            let card = try XCTUnwrap(ShareRenderer.uiImage(for: CollectibleShareCard(item: item, ownerName: "Riley", hideName: false), scale: 1))
            try card.pngData()?.write(to: dir.appendingPathComponent("share-collectible.png"))
        }
        print("DAYBOOK_CARDS_DIR=\(dir.path)")
    }
}

import AVFoundation

enum AVAudioFormatFactory {
    static func mono() -> AVAudioFormat? { AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) }
}
