import Foundation
import WatchKit

@MainActor
final class HapticEngine {
    private var timer: Timer?
    private var pulseTimers: [Timer] = []
    private let pulseSpacing: TimeInterval = 0.12

    func start(clicksPerPulse: Int, pulsesPerMinute: Int) {
        stop()
        playPulseTrain(clicksPerPulse: clicksPerPulse, firstPulse: .start)

        let repeatInterval = 60.0 / Double(pulsesPerMinute)
        timer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) { _ in
            Task { @MainActor in
                self.playPulseTrain(clicksPerPulse: clicksPerPulse, firstPulse: .directionUp)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        pulseTimers.forEach { $0.invalidate() }
        pulseTimers.removeAll()
    }

    private func playPulseTrain(clicksPerPulse: Int, firstPulse: WKHapticType) {
        pulseTimers.forEach { $0.invalidate() }
        pulseTimers.removeAll()

        WKInterfaceDevice.current().play(firstPulse)

        for pulseIndex in 1..<clicksPerPulse {
            let delay = pulseSpacing * Double(pulseIndex)
            let pulseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
                WKInterfaceDevice.current().play(.directionUp)
            }
            pulseTimers.append(pulseTimer)
        }
    }
}
