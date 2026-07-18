import WatchKit
import XCTest
@testable import CatalystBellWatchApp

final class HapticSettingsTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "HapticSettingsTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testMissingSelectionUsesMigrationDefaults() {
        let settings = HapticSettings.load(from: defaults)

        XCTAssertEqual(settings.selectedChoices, HapticSettings.defaultVariedChoices)
        XCTAssertEqual(settings.steadyChoice, HapticSettings.defaultSteadyChoice)
    }

    func testEmptyOrInvalidPersistedSelectionFallsBackToClick() {
        let keys = HapticSettings.Keys()
        defaults.set(["failure", "notification"], forKey: keys.selectedChoices)

        XCTAssertEqual(HapticSettings.load(from: defaults).selectedChoices, [.click])
    }

    func testInvalidPersistedGapBoundsAreClampedAndOrdered() {
        let keys = HapticSettings.Keys()
        defaults.set(12.0, forKey: keys.minimumGap)
        defaults.set(1.0, forKey: keys.maximumGap)

        let settings = HapticSettings.load(from: defaults)

        XCTAssertEqual(settings.minimumGap, 2.0)
        XCTAssertEqual(settings.maximumGap, 10.0)
    }

    func testNonfinitePersistedGapsUseSafeDefaults() {
        let keys = HapticSettings.Keys()
        defaults.set(Double.nan, forKey: keys.minimumGap)
        defaults.set(Double.infinity, forKey: keys.maximumGap)

        let settings = HapticSettings.load(from: defaults)

        XCTAssertEqual(settings.minimumGap, HapticSettings.defaultMinimumGap)
        XCTAssertEqual(settings.maximumGap, HapticSettings.defaultMaximumGap)
    }
}

final class HapticShuffleBagTests: XCTestCase {
    func testEmitsEverySelectedChoiceBeforeRefilling() {
        let choices: Set<HapticChoice> = [.click, .directionUp, .success]
        var bag = HapticShuffleBag(choices: choices, shuffle: { _ in })

        let firstCycle = Set((0..<choices.count).map { _ in bag.next() })

        XCTAssertEqual(firstCycle, choices)
    }

    func testAvoidsImmediateRepeatAcrossRefillBoundary() {
        let choices: Set<HapticChoice> = [.click, .directionUp, .directionDown]
        var bag = HapticShuffleBag(choices: choices, shuffle: { _ in })
        let firstCycle = (0..<choices.count).map { _ in bag.next() }

        XCTAssertNotEqual(bag.next(), firstCycle.last)
    }

    func testSingleChoiceCanRefillRepeatedly() {
        var bag = HapticShuffleBag(choices: [.success], shuffle: { _ in })

        XCTAssertEqual((0..<10).map { _ in bag.next() }, Array(repeating: .success, count: 10))
    }
}

@MainActor
final class HapticEngineTests: XCTestCase {
    func testPreviewPlaysExactlyOneHapticWithoutStartingSession() {
        let harness = Harness()

        harness.engine.preview(.success)

        XCTAssertEqual(harness.played, [.success])
        XCTAssertTrue(harness.scheduler.tasks.isEmpty)
    }

    func testSteadyModeRepeatsSelectedHapticType() {
        let harness = Harness()
        harness.engine.start(configuration: configuration(
            pulseStyle: .steady,
            steadyChoice: .click,
            hits: 3
        ))

        harness.scheduler.fireTasks(at: [0.12, 0.24])
        XCTAssertEqual(harness.played, [.click, .click, .click])

        harness.scheduler.fireFirstTask(at: 4.0)
        XCTAssertEqual(harness.played.last, .click)
    }

    func testSteadyCompoundHapticPlaysOncePerPulse() {
        let harness = Harness()
        harness.engine.start(configuration: configuration(
            pulseStyle: .steady,
            steadyChoice: .success,
            hits: 6
        ))

        XCTAssertEqual(harness.played, [.success])
        XCTAssertFalse(harness.scheduler.intervals.contains(0.12))
    }

    func testCompoundHapticsPlayOncePerPulse() {
        for choice in [HapticChoice.start, .stop, .success] {
            let harness = Harness()
            harness.engine.start(configuration: configuration(choice: choice, hits: 6))

            XCTAssertEqual(harness.played, [choice.hapticType])
            XCTAssertFalse(harness.scheduler.intervals.contains(0.12))
        }
    }

    func testShortHapticsHonorHitsPerPulse() {
        for choice in [HapticChoice.click, .directionUp, .directionDown] {
            let harness = Harness()
            harness.engine.start(configuration: configuration(choice: choice, hits: 3))
            harness.scheduler.fireTasks(at: [0.12, 0.24])

            XCTAssertEqual(harness.played, Array(repeating: choice.hapticType, count: 3))
        }
    }

    func testVariedGapIsClampedToConfiguredRange() {
        let harness = Harness(randomGap: { _ in 100 })
        harness.engine.start(configuration: configuration(
            choice: .success,
            spacingStyle: .varied,
            minimumGap: 3.5,
            maximumGap: 5.0
        ))

        XCTAssertEqual(harness.scheduler.intervals, [5.0])
    }

    func testStoppingCancelsPendingPulseAndHits() {
        let harness = Harness()
        harness.engine.start(configuration: configuration(choice: .click, spacingStyle: .varied, hits: 3))

        harness.engine.stop()

        XCTAssertTrue(harness.scheduler.tasks.allSatisfy(\.isCancelled))
    }

    func testStaleScheduledCallbackCannotPlayAfterStop() {
        let harness = Harness()
        harness.engine.start(configuration: configuration(choice: .success, spacingStyle: .varied))
        let staleAction = harness.scheduler.tasks.last!.action
        harness.engine.stop()

        staleAction()

        XCTAssertEqual(harness.played, [.success])
    }

    func testStartingNewSessionResetsShuffleBag() {
        let harness = Harness(shuffle: { _ in })
        let config = configuration(choices: [.success, .directionUp, .directionDown])

        harness.engine.start(configuration: config)
        let firstSessionChoice = harness.played.first
        harness.engine.start(configuration: config)

        XCTAssertEqual(harness.played.last, firstSessionChoice)
    }

    func testActiveSessionUsesStableSettingsSnapshot() {
        let harness = Harness()
        var settings = HapticSettings(
            pulseStyle: .varied,
            spacingStyle: .fixed,
            selectedChoices: [.success]
        )
        let snapshot = HapticSessionConfiguration(settings: settings, hitsPerPulse: 5, pulsesPerMinute: 15)
        harness.engine.start(configuration: snapshot)
        settings.selectedChoices = [.click]

        harness.scheduler.fireFirstTask(at: 4.0)

        XCTAssertEqual(harness.played, [.success, .success])
    }

    private func configuration(
        pulseStyle: PulseStyle = .varied,
        steadyChoice: HapticChoice = HapticSettings.defaultSteadyChoice,
        choice: HapticChoice = .success,
        choices: Set<HapticChoice>? = nil,
        spacingStyle: PulseSpacingStyle = .fixed,
        hits: Int = 6,
        minimumGap: Double = 3.5,
        maximumGap: Double = 5.0
    ) -> HapticSessionConfiguration {
        HapticSessionConfiguration(
            settings: HapticSettings(
                pulseStyle: pulseStyle,
                spacingStyle: spacingStyle,
                steadyChoice: steadyChoice,
                selectedChoices: choices ?? [choice],
                minimumGap: minimumGap,
                maximumGap: maximumGap
            ),
            hitsPerPulse: hits,
            pulsesPerMinute: 15
        )
    }
}

@MainActor
private final class Harness {
    let scheduler = TestHapticScheduler()
    var played: [WKHapticType] = []
    lazy var engine = HapticEngine(
        scheduler: scheduler,
        playHaptic: { [weak self] in self?.played.append($0) },
        randomGap: randomGap,
        shuffle: shuffle
    )
    private let randomGap: HapticEngine.RandomGap
    private let shuffle: HapticShuffleBag.Shuffle

    init(
        randomGap: @escaping HapticEngine.RandomGap = { $0.lowerBound },
        shuffle: @escaping HapticShuffleBag.Shuffle = { $0.shuffle() }
    ) {
        self.randomGap = randomGap
        self.shuffle = shuffle
    }
}

@MainActor
private final class TestHapticScheduler: HapticScheduling {
    final class Task: HapticScheduledTask {
        let interval: TimeInterval
        let repeats: Bool
        let action: @MainActor () -> Void
        private(set) var isCancelled = false

        init(interval: TimeInterval, repeats: Bool, action: @escaping @MainActor () -> Void) {
            self.interval = interval
            self.repeats = repeats
            self.action = action
        }

        func cancel() {
            isCancelled = true
        }
    }

    private(set) var tasks: [Task] = []
    var intervals: [TimeInterval] { tasks.map(\.interval) }

    func schedule(
        after interval: TimeInterval,
        repeats: Bool,
        action: @escaping @MainActor () -> Void
    ) -> HapticScheduledTask {
        let task = Task(interval: interval, repeats: repeats, action: action)
        tasks.append(task)
        return task
    }

    func fireTasks(at intervals: [TimeInterval]) {
        for interval in intervals {
            fireFirstTask(at: interval)
        }
    }

    func fireFirstTask(at interval: TimeInterval) {
        tasks.first { !$0.isCancelled && $0.interval == interval }?.action()
    }
}
