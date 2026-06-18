import Foundation
import WatchKit

@MainActor
final class HapticEngine {
    private var timer: Timer?
    private var pulseTimers: [Timer] = []
    private var pattern: HapticPattern = .gentle

    func start(pattern: HapticPattern) {
        stop()
        self.pattern = pattern
        playPulseTrain(pattern: pattern, firstPulse: .start)

        timer = Timer.scheduledTimer(withTimeInterval: pattern.interval, repeats: true) { _ in
            Task { @MainActor in
                self.playPulseTrain(pattern: pattern, firstPulse: .directionUp)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        pulseTimers.forEach { $0.invalidate() }
        pulseTimers.removeAll()
    }

    private func playPulseTrain(pattern: HapticPattern, firstPulse: WKHapticType) {
        pulseTimers.forEach { $0.invalidate() }
        pulseTimers.removeAll()

        WKInterfaceDevice.current().play(firstPulse)

        for pulseIndex in 1..<pattern.pulsesPerCycle {
            let delay = pattern.pulseSpacing * Double(pulseIndex)
            let pulseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
                WKInterfaceDevice.current().play(.directionUp)
            }
            pulseTimers.append(pulseTimer)
        }
    }
}
