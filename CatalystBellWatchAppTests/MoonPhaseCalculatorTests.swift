import XCTest
@testable import CatalystBellWatchApp

final class MoonPhaseCalculatorTests: XCTestCase {
    func testPhaseNameBoundaries() {
        XCTAssertEqual(MoonPhaseCalculator.phaseName(forFraction: 0), .newMoon)
        XCTAssertEqual(MoonPhaseCalculator.phaseName(forFraction: 0.10), .waxingCrescent)
        XCTAssertEqual(MoonPhaseCalculator.phaseName(forFraction: 0.25), .firstQuarter)
        XCTAssertEqual(MoonPhaseCalculator.phaseName(forFraction: 0.35), .waxingGibbous)
        XCTAssertEqual(MoonPhaseCalculator.phaseName(forFraction: 0.50), .fullMoon)
        XCTAssertEqual(MoonPhaseCalculator.phaseName(forFraction: 0.60), .waningGibbous)
        XCTAssertEqual(MoonPhaseCalculator.phaseName(forFraction: 0.75), .lastQuarter)
        XCTAssertEqual(MoonPhaseCalculator.phaseName(forFraction: 0.85), .waningCrescent)
        XCTAssertEqual(MoonPhaseCalculator.phaseName(forFraction: 0.98), .newMoon)
    }
}
