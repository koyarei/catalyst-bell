import Foundation
import WatchKit

@MainActor
final class HapticEngine {
    private var timer: Timer?
    private var pattern: HapticPattern = .gentle

    func start(pattern: HapticPattern) {
        stop()
        self.pattern = pattern
        WKInterfaceDevice.current().play(.start)

        timer = Timer.scheduledTimer(withTimeInterval: pattern.interval, repeats: true) { _ in
            WKInterfaceDevice.current().play(.click)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
