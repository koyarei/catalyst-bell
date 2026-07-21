import SwiftUI
import WatchKit

enum RainVisualTuning {
    static let surfaceColor = Color(red: 0.018, green: 0.035, blue: 0.045)
    static let rippleColor = Color(red: 0.62, green: 0.78, blue: 0.81)
    static let maximumParticleCount = 4
    static let reducedMotionLifetime: TimeInterval = 0.46
    static let impactPointLifetime: TimeInterval = 0.24
    static let minimumFrameInterval: TimeInterval = 1.0 / 30.0
}

struct RippleStyle: Equatable {
    let ringCount: Int
    let initialRadius: CGFloat
    let finalRadius: CGFloat
    let lifetime: TimeInterval
    let peakOpacity: Double
    let secondaryRingDelay: TimeInterval
    let lineWidth: CGFloat
    let impactPointRadius: CGFloat
    let verticalDrift: CGFloat

    static let click = RippleStyle(
        ringCount: 1,
        initialRadius: 3,
        finalRadius: 26,
        lifetime: 1.10,
        peakOpacity: 0.27,
        secondaryRingDelay: 0,
        lineWidth: 1.15,
        impactPointRadius: 1.2,
        verticalDrift: 0
    )

    static let directionDown = RippleStyle(
        ringCount: 1,
        initialRadius: 3,
        finalRadius: 25,
        lifetime: 1.12,
        peakOpacity: 0.30,
        secondaryRingDelay: 0,
        lineWidth: 1.2,
        impactPointRadius: 1.5,
        verticalDrift: 0
    )

    static let directionUp = RippleStyle(
        ringCount: 1,
        initialRadius: 3,
        finalRadius: 35,
        lifetime: 1.32,
        peakOpacity: 0.24,
        secondaryRingDelay: 0,
        lineWidth: 1.05,
        impactPointRadius: 1.1,
        verticalDrift: -2.5
    )

    static let success = RippleStyle(
        ringCount: 2,
        initialRadius: 3,
        finalRadius: 31,
        lifetime: 1.26,
        peakOpacity: 0.28,
        secondaryRingDelay: 0.13,
        lineWidth: 1.15,
        impactPointRadius: 1.25,
        verticalDrift: 0
    )

    static func style(for hapticType: WKHapticType) -> RippleStyle {
        if hapticType == .directionDown { return .directionDown }
        if hapticType == .directionUp { return .directionUp }
        if hapticType == .success { return .success }
        return .click
    }
}

struct RainPositionGenerator {
    static func normalizedPosition(seed: UInt64, hitIndex: Int) -> CGPoint {
        var generator = SplitMix64(state: seed)
        let edgeValue = generator.next()
        let baseX = unit(generator.next())
        let baseY = unit(generator.next())

        var x = 0.14 + (baseX * 0.72)
        var y = 0.16 + (baseY * 0.68)

        if edgeValue.isMultiple(of: 7) {
            switch (edgeValue >> 8) % 4 {
            case 0: x = 0.05
            case 1: x = 0.95
            case 2: y = 0.06
            default: y = 0.94
            }
        }

        if hitIndex > 0 {
            var clusterGenerator = SplitMix64(
                state: seed &+ UInt64(truncatingIfNeeded: hitIndex) &* 0x9E3779B97F4A7C15
            )
            let angle = unit(clusterGenerator.next()) * .pi * 2
            let distance = 0.035 + unit(clusterGenerator.next()) * 0.075
            x += cos(angle) * distance
            y += sin(angle) * distance
        }

        if hypot(x - 0.5, y - 0.5) < 0.08 {
            x += x < 0.5 ? -0.12 : 0.12
            y += y < 0.5 ? 0.07 : -0.07
        }

        return CGPoint(x: min(max(x, 0.03), 0.97), y: min(max(y, 0.03), 0.97))
    }

    private static func unit(_ value: UInt64) -> CGFloat {
        CGFloat(Double(value >> 11) / Double(1 << 53))
    }

    private struct SplitMix64 {
        var state: UInt64

        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var value = state
            value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
            value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
            return value ^ (value >> 31)
        }
    }
}

struct RainParticle: Identifiable, Equatable {
    let id: UUID
    let position: CGPoint
    let style: RippleStyle
    let startedAt: Date
    let usesReducedMotion: Bool

    var totalLifetime: TimeInterval {
        usesReducedMotion
            ? RainVisualTuning.reducedMotionLifetime
            : style.lifetime + (style.secondaryRingDelay * Double(max(0, style.ringCount - 1)))
    }
}

@MainActor
final class RainParticleStore: ObservableObject {
    @Published private(set) var particles: [RainParticle] = []

    private var seenEventIDs: Set<UUID> = []
    private var seenEventOrder: [UUID] = []
    private var removalTasks: [UUID: Task<Void, Never>] = [:]
    private let maximumParticleCount: Int

    init(maximumParticleCount: Int = RainVisualTuning.maximumParticleCount) {
        self.maximumParticleCount = max(1, maximumParticleCount)
    }

    func consume(
        _ events: [HapticVisualEvent],
        visualStyle: ActiveVisualStyle,
        isLuminanceReduced: Bool,
        reduceMotion: Bool,
        now: Date = Date()
    ) {
        for event in events where !seenEventIDs.contains(event.id) {
            markSeen(event.id)
            guard visualStyle == .stillRain, !isLuminanceReduced else { continue }

            var position = RainPositionGenerator.normalizedPosition(
                seed: event.positionSeed,
                hitIndex: event.hitIndex
            )
            if let previous = particles.last?.position,
               hypot(position.x - previous.x, position.y - previous.y) < 0.13 {
                position.x = position.x < 0.62 ? position.x + 0.27 : position.x - 0.27
                position.y = position.y < 0.58 ? position.y + 0.18 : position.y - 0.18
            }

            let particle = RainParticle(
                id: event.id,
                position: position,
                style: RippleStyle.style(for: event.hapticType),
                startedAt: event.occurredAt,
                usesReducedMotion: reduceMotion
            )
            guard now.timeIntervalSince(particle.startedAt) < particle.totalLifetime else { continue }
            append(particle, now: now)
        }
    }

    func clearParticles() {
        removalTasks.values.forEach { $0.cancel() }
        removalTasks.removeAll()
        particles.removeAll()
    }

    func reset() {
        clearParticles()
        seenEventIDs.removeAll()
        seenEventOrder.removeAll()
    }

    private func append(_ particle: RainParticle, now: Date) {
        if particles.count == maximumParticleCount, let oldest = particles.first {
            removalTasks[oldest.id]?.cancel()
            removalTasks[oldest.id] = nil
            particles.removeFirst()
        }

        particles.append(particle)
        let remainingLifetime = max(
            0,
            particle.totalLifetime - now.timeIntervalSince(particle.startedAt)
        )
        removalTasks[particle.id] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(remainingLifetime))
            guard !Task.isCancelled else { return }
            self?.removeParticle(id: particle.id)
        }
    }

    private func removeParticle(id: UUID) {
        particles.removeAll { $0.id == id }
        removalTasks[id] = nil
    }

    private func markSeen(_ id: UUID) {
        seenEventIDs.insert(id)
        seenEventOrder.append(id)
        if seenEventOrder.count > 64 {
            let expired = seenEventOrder.removeFirst()
            seenEventIDs.remove(expired)
        }
    }
}

struct RainSurfaceView: View {
    let events: [HapticVisualEvent]
    let isSessionActive: Bool

    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var store = RainParticleStore()

    var body: some View {
        ZStack {
            RainVisualTuning.surfaceColor

            if !store.particles.isEmpty {
                TimelineView(.animation(
                    minimumInterval: RainVisualTuning.minimumFrameInterval,
                    paused: false
                )) { timeline in
                    Canvas { context, size in
                        drawParticles(store.particles, at: timeline.date, in: size, context: &context)
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            store.reset()
            consumeEvents()
        }
        .onChange(of: events) { _, _ in
            consumeEvents()
        }
        .onChange(of: isLuminanceReduced) { _, isReduced in
            if isReduced {
                store.clearParticles()
            }
            consumeEvents()
        }
        .onChange(of: reduceMotion) { _, _ in
            store.clearParticles()
            consumeEvents()
        }
        .onChange(of: isSessionActive) { _, isActive in
            if !isActive {
                store.reset()
            }
        }
        .accessibilityHidden(true)
    }

    private func consumeEvents() {
        store.consume(
            events,
            visualStyle: .stillRain,
            isLuminanceReduced: isLuminanceReduced,
            reduceMotion: reduceMotion
        )
    }

    private func drawParticles(
        _ particles: [RainParticle],
        at date: Date,
        in size: CGSize,
        context: inout GraphicsContext
    ) {
        for particle in particles {
            let elapsed = date.timeIntervalSince(particle.startedAt)
            guard elapsed >= 0, elapsed <= particle.totalLifetime else { continue }

            let center = CGPoint(
                x: particle.position.x * size.width,
                y: particle.position.y * size.height
            )

            if particle.usesReducedMotion {
                drawReducedMotionParticle(particle, elapsed: elapsed, center: center, context: &context)
            } else {
                drawAnimatedParticle(particle, elapsed: elapsed, center: center, context: &context)
            }
        }
    }

    private func drawAnimatedParticle(
        _ particle: RainParticle,
        elapsed: TimeInterval,
        center: CGPoint,
        context: inout GraphicsContext
    ) {
        let style = particle.style
        for ringIndex in 0..<style.ringCount {
            let ringElapsed = elapsed - (Double(ringIndex) * style.secondaryRingDelay)
            guard ringElapsed >= 0, ringElapsed <= style.lifetime else { continue }

            let progress = min(max(ringElapsed / style.lifetime, 0), 1)
            let easedProgress = 1 - pow(1 - progress, 2)
            let radius = style.initialRadius
                + ((style.finalRadius - style.initialRadius) * CGFloat(easedProgress))
            let fadeIn = min(ringElapsed / 0.07, 1)
            let secondaryStrength = ringIndex == 0 ? 1.0 : 0.58
            let opacity = style.peakOpacity * fadeIn * pow(1 - progress, 0.92) * secondaryStrength
            let drift = style.verticalDrift * CGFloat(progress)
            let rect = CGRect(
                x: center.x - radius,
                y: center.y + drift - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(RainVisualTuning.rippleColor.opacity(opacity)),
                lineWidth: style.lineWidth
            )
        }

        if elapsed <= RainVisualTuning.impactPointLifetime {
            let progress = elapsed / RainVisualTuning.impactPointLifetime
            let opacity = style.peakOpacity * 0.9 * (1 - progress)
            let radius = style.impactPointRadius
            let rect = CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(RainVisualTuning.rippleColor.opacity(opacity))
            )
        }
    }

    private func drawReducedMotionParticle(
        _ particle: RainParticle,
        elapsed: TimeInterval,
        center: CGPoint,
        context: inout GraphicsContext
    ) {
        let progress = min(max(elapsed / RainVisualTuning.reducedMotionLifetime, 0), 1)
        let opacity = particle.style.peakOpacity * 0.72 * sin(.pi * progress)
        let radius = particle.style.initialRadius + 2
        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        context.stroke(
            Path(ellipseIn: rect),
            with: .color(RainVisualTuning.rippleColor.opacity(opacity)),
            lineWidth: particle.style.lineWidth
        )
    }
}

#if DEBUG
struct RainSurfaceDebugHarness: View {
    @State private var events: [HapticVisualEvent] = []

    var body: some View {
        RainSurfaceView(events: events, isSessionActive: true)
            .ignoresSafeArea()
            .task {
                guard events.isEmpty else { return }
                let sequence: [WKHapticType] = [
                    .success, .directionUp, .directionDown,
                    .click, .click, .click, .click
                ]
                while !Task.isCancelled {
                    let pulseID = UUID()
                    for (index, type) in sequence.enumerated() {
                        events.append(HapticVisualEvent(
                            pulseID: pulseID,
                            hitIndex: index,
                            hapticType: type,
                            positionSeed: UInt64.random(in: .min ... .max)
                        ))
                        if events.count > 16 {
                            events.removeFirst(events.count - 16)
                        }
                        try? await Task.sleep(for: .milliseconds(index < 3 ? 420 : 120))
                    }
                    try? await Task.sleep(for: .seconds(1))
                }
            }
    }
}

#Preview("Still Rain") {
    RainSurfaceDebugHarness()
}
#endif
