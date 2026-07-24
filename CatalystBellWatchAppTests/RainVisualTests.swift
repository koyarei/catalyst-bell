import WatchKit
import XCTest
@testable import CatalystBellWatchApp

final class RippleStyleTests: XCTestCase {
    func testSupportedHapticTypesUseExpectedStyles() {
        XCTAssertEqual(RippleStyle.style(for: .click), .click)
        XCTAssertEqual(RippleStyle.style(for: .directionDown), .directionDown)
        XCTAssertEqual(RippleStyle.style(for: .directionUp), .directionUp)
        XCTAssertEqual(RippleStyle.style(for: .success), .success)
    }

    func testOtherSupportedTypesUseRestrainedClickFallback() {
        XCTAssertEqual(RippleStyle.style(for: .start), .click)
        XCTAssertEqual(RippleStyle.style(for: .stop), .click)
        XCTAssertEqual(RippleStyle.style(for: .failure), .click)
    }
}

final class RainPositionGeneratorTests: XCTestCase {
    func testPositionIsDeterministicForSeedAndHitIndex() {
        let first = RainPositionGenerator.normalizedPosition(seed: 123_456, hitIndex: 3)
        let second = RainPositionGenerator.normalizedPosition(seed: 123_456, hitIndex: 3)

        XCTAssertEqual(first.x, second.x, accuracy: 0.000_001)
        XCTAssertEqual(first.y, second.y, accuracy: 0.000_001)
    }

    func testHitsInPulseUseDistinctNormalizedPositions() {
        let positions = (0..<6).map {
            RainPositionGenerator.normalizedPosition(seed: 0xA11CE, hitIndex: $0)
        }

        XCTAssertEqual(Set(positions.map { "\($0.x),\($0.y)" }).count, 6)
        XCTAssertTrue(positions.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
    }
}

@MainActor
final class RainParticleStoreTests: XCTestCase {
    func testMaximumParticleCountRemovesOldestParticle() {
        let store = RainParticleStore(maximumParticleCount: 3)
        let now = Date()
        let events = (0..<5).map { event(hitIndex: $0, date: now, seed: UInt64($0)) }

        store.consume(
            events,
            visualStyle: .stillRain,
            reduceMotion: false,
            now: now
        )

        XCTAssertEqual(store.particles.count, 3)
        XCTAssertEqual(store.particles.map(\.id), events.suffix(3).map(\.id))
    }

    func testClearRemovesEveryParticleImmediately() {
        let store = RainParticleStore()
        let now = Date()
        store.consume(
            [event(date: now)],
            visualStyle: .stillRain,
            reduceMotion: false,
            now: now
        )

        store.clearParticles()

        XCTAssertTrue(store.particles.isEmpty)
    }

    func testDarkModeCreatesNoParticles() {
        let store = RainParticleStore()
        let now = Date()

        store.consume(
            [event(date: now)],
            visualStyle: .dark,
            reduceMotion: false,
            now: now
        )

        XCTAssertTrue(store.particles.isEmpty)
    }

    func testLatestParticleRemainsAvailableForAlwaysOnPresentation() {
        let store = RainParticleStore()
        let now = Date()
        let latestEvent = event(date: now)
        store.consume(
            [latestEvent],
            visualStyle: .stillRain,
            reduceMotion: false,
            now: now
        )
        store.clearParticles()

        XCTAssertTrue(store.particles.isEmpty)
        XCTAssertEqual(store.latestParticle?.id, latestEvent.id)
    }

    private func event(
        hitIndex: Int = 0,
        date: Date,
        seed: UInt64 = 17
    ) -> HapticVisualEvent {
        HapticVisualEvent(
            pulseID: UUID(),
            hitIndex: hitIndex,
            hapticType: .click,
            occurredAt: date,
            positionSeed: seed
        )
    }
}

final class RainVisualIntensityTests: XCTestCase {
    func testIntensityClampsToSupportedCrownRange() {
        XCTAssertEqual(RainVisualIntensity.clamped(-0.4), 0)
        XCTAssertEqual(RainVisualIntensity.clamped(0.65), 0.65)
        XCTAssertEqual(RainVisualIntensity.clamped(1.4), 1)
    }

    func testZeroIntensityProducesTrueBlackAndInvisibleRipples() {
        XCTAssertEqual(RainVisualIntensity.surfaceOpacity(for: 0), 0)
        XCTAssertEqual(RainVisualIntensity.rippleOpacityMultiplier(for: 0), 0)
    }

    func testDefaultIntensityPreservesOriginalAppearance() {
        XCTAssertEqual(
            RainVisualIntensity.surfaceOpacity(for: RainVisualIntensity.defaultValue),
            1
        )
        XCTAssertEqual(
            RainVisualIntensity.rippleOpacityMultiplier(for: RainVisualIntensity.defaultValue),
            1
        )
    }

    func testMaximumIntensityStrengthensRipples() {
        XCTAssertEqual(
            RainVisualIntensity.rippleOpacityMultiplier(for: 1),
            RainVisualIntensity.maximumRippleOpacityMultiplier
        )
    }

    func testUpperHalfProvidesAdditionalContrastBeyondOriginalMaximum() {
        XCTAssertGreaterThan(
            RainVisualIntensity.rippleOpacityMultiplier(for: 0.75),
            2
        )
    }

    func testDefaultIntensityKeepsOriginalStrokeAndNoGlow() {
        XCTAssertEqual(
            RainVisualIntensity.lineWidthMultiplier(for: RainVisualIntensity.defaultValue),
            1
        )
        XCTAssertEqual(
            RainVisualIntensity.glowStrength(for: RainVisualIntensity.defaultValue),
            0
        )
    }

    func testMaximumIntensityUsesThickerStrokeAndGlow() {
        XCTAssertEqual(
            RainVisualIntensity.lineWidthMultiplier(for: 1),
            RainVisualIntensity.maximumLineWidthMultiplier
        )
        XCTAssertEqual(
            RainVisualIntensity.glowStrength(for: 1),
            RainVisualIntensity.maximumGlowStrength
        )
    }
}
