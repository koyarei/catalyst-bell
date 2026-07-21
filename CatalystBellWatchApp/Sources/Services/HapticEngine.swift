import Foundation
import WatchKit

@MainActor
protocol HapticScheduledTask: AnyObject {
    func cancel()
}

@MainActor
protocol HapticScheduling {
    func schedule(
        after interval: TimeInterval,
        repeats: Bool,
        action: @escaping @MainActor () -> Void
    ) -> HapticScheduledTask
}

@MainActor
private final class TimerHapticTask: HapticScheduledTask {
    private let timer: Timer

    init(timer: Timer) {
        self.timer = timer
    }

    func cancel() {
        timer.invalidate()
    }
}

@MainActor
private final class TimerHapticScheduler: HapticScheduling {
    func schedule(
        after interval: TimeInterval,
        repeats: Bool,
        action: @escaping @MainActor () -> Void
    ) -> HapticScheduledTask {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats) { _ in
            Task { @MainActor in
                action()
            }
        }
        return TimerHapticTask(timer: timer)
    }
}

struct HapticShuffleBag {
    typealias Shuffle = (inout [HapticChoice]) -> Void

    private let choices: [HapticChoice]
    private let shuffle: Shuffle
    private var queue: [HapticChoice] = []
    private var lastChoice: HapticChoice?

    init(choices: Set<HapticChoice>, shuffle: @escaping Shuffle = { $0.shuffle() }) {
        let safeChoices = choices.isEmpty ? Set([HapticChoice.click]) : choices
        self.choices = HapticChoice.allCases.filter(safeChoices.contains)
        self.shuffle = shuffle
    }

    mutating func next() -> HapticChoice {
        if queue.isEmpty {
            queue = choices
            shuffle(&queue)

            if queue.count > 1, queue.first == lastChoice,
               let differentIndex = queue.firstIndex(where: { $0 != lastChoice }) {
                queue.swapAt(0, differentIndex)
            }
        }

        let choice = queue.removeFirst()
        lastChoice = choice
        return choice
    }
}

@MainActor
final class HapticEngine {
    typealias RandomGap = (ClosedRange<TimeInterval>) -> TimeInterval
    typealias PositionSeed = () -> UInt64

    var visualEventHandler: ((HapticVisualEvent) -> Void)?

    private var pulseTask: HapticScheduledTask?
    private var hitTasks: [HapticScheduledTask] = []
    private let pulseSpacing: TimeInterval = 0.12
    private let scheduler: HapticScheduling
    private let playHaptic: (WKHapticType) -> Void
    private let randomGap: RandomGap
    private let shuffle: HapticShuffleBag.Shuffle
    private let positionSeed: PositionSeed
    private var configuration: HapticSessionConfiguration?
    private var shuffleBag: HapticShuffleBag?
    private var generation = 0
    private var isActive = false

    init(
        scheduler: HapticScheduling? = nil,
        playHaptic: @escaping (WKHapticType) -> Void = { WKInterfaceDevice.current().play($0) },
        randomGap: @escaping RandomGap = { Double.random(in: $0) },
        shuffle: @escaping HapticShuffleBag.Shuffle = { $0.shuffle() },
        positionSeed: @escaping PositionSeed = { UInt64.random(in: .min ... .max) }
    ) {
        self.scheduler = scheduler ?? TimerHapticScheduler()
        self.playHaptic = playHaptic
        self.randomGap = randomGap
        self.shuffle = shuffle
        self.positionSeed = positionSeed
    }

    func start(configuration: HapticSessionConfiguration) {
        stop()
        self.configuration = configuration
        shuffleBag = HapticShuffleBag(
            choices: configuration.settings.selectedChoices,
            shuffle: shuffle
        )
        isActive = true
        let currentGeneration = generation
        let pulseDuration = playPulse(generation: currentGeneration)

        switch configuration.settings.spacingStyle {
        case .fixed:
            let repeatInterval = 60.0 / Double(configuration.pulsesPerMinute)
            pulseTask = scheduler.schedule(after: repeatInterval, repeats: true) { [weak self] in
                guard let self, self.isCurrent(generation: currentGeneration) else { return }
                _ = self.playPulse(generation: currentGeneration)
            }
        case .varied:
            scheduleVariedPulse(afterPulseDuration: pulseDuration, generation: currentGeneration)
        }
    }

    func preview(_ choice: HapticChoice) {
        playHaptic(choice.hapticType)
    }

    func stop() {
        isActive = false
        generation += 1
        pulseTask?.cancel()
        pulseTask = nil
        hitTasks.forEach { $0.cancel() }
        hitTasks.removeAll()
        configuration = nil
        shuffleBag = nil
    }

    @discardableResult
    private func playPulse(generation: Int) -> TimeInterval {
        guard isCurrent(generation: generation), let configuration else { return 0 }
        hitTasks.forEach { $0.cancel() }
        hitTasks.removeAll()
        let pulseID = UUID()
        let pulsePositionSeed = positionSeed()

        if configuration.settings.pulseStyle == .steady {
            let choice = configuration.settings.steadyChoice
            let eventCount = choice.honorsHitsPerPulse ? configuration.hitsPerPulse : 1
            playScheduledHit(
                choice.hapticType,
                pulseID: pulseID,
                hitIndex: 0,
                positionSeed: pulsePositionSeed
            )
            scheduleAdditionalHits(
                count: eventCount - 1,
                hapticType: choice.hapticType,
                pulseID: pulseID,
                positionSeed: pulsePositionSeed,
                generation: generation
            )
            return pulseSpacing * Double(max(0, eventCount - 1))
        }

        var bag = shuffleBag ?? HapticShuffleBag(choices: [.click], shuffle: shuffle)
        let choice = bag.next()
        shuffleBag = bag
        let eventCount = choice.honorsHitsPerPulse ? configuration.hitsPerPulse : 1
        playScheduledHit(
            choice.hapticType,
            pulseID: pulseID,
            hitIndex: 0,
            positionSeed: pulsePositionSeed
        )
        scheduleAdditionalHits(
            count: eventCount - 1,
            hapticType: choice.hapticType,
            pulseID: pulseID,
            positionSeed: pulsePositionSeed,
            generation: generation
        )
        return pulseSpacing * Double(max(0, eventCount - 1))
    }

    private func scheduleAdditionalHits(
        count: Int,
        hapticType: WKHapticType,
        pulseID: UUID,
        positionSeed: UInt64,
        generation: Int
    ) {
        guard count > 0 else { return }

        for hitIndex in 1...count {
            let task = scheduler.schedule(after: pulseSpacing * Double(hitIndex), repeats: false) { [weak self] in
                guard let self, self.isCurrent(generation: generation) else { return }
                self.playScheduledHit(
                    hapticType,
                    pulseID: pulseID,
                    hitIndex: hitIndex,
                    positionSeed: positionSeed
                )
            }
            hitTasks.append(task)
        }
    }

    private func scheduleVariedPulse(afterPulseDuration pulseDuration: TimeInterval, generation: Int) {
        guard isCurrent(generation: generation), let configuration else { return }
        let gapRange = configuration.settings.minimumGap...configuration.settings.maximumGap
        let nextGap = min(max(randomGap(gapRange), gapRange.lowerBound), gapRange.upperBound)
        pulseTask?.cancel()
        pulseTask = scheduler.schedule(after: pulseDuration + nextGap, repeats: false) { [weak self] in
            guard let self, self.isCurrent(generation: generation) else { return }
            let duration = self.playPulse(generation: generation)
            self.scheduleVariedPulse(afterPulseDuration: duration, generation: generation)
        }
    }

    private func isCurrent(generation: Int) -> Bool {
        isActive && self.generation == generation
    }

    private func playScheduledHit(
        _ hapticType: WKHapticType,
        pulseID: UUID,
        hitIndex: Int,
        positionSeed: UInt64
    ) {
        playHaptic(hapticType)
        visualEventHandler?(HapticVisualEvent(
            pulseID: pulseID,
            hitIndex: hitIndex,
            hapticType: hapticType,
            positionSeed: positionSeed
        ))
    }
}
