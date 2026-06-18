import Foundation

struct MoonPhaseCalculator {
    private static let synodicMonth = 29.530588853
    private static let knownNewMoonJulianDay = 2451550.1

    static func phase(for date: Date) -> MoonPhase {
        let age = lunarAge(for: date)
        let fraction = age / synodicMonth

        return MoonPhase(
            name: phaseName(forFraction: fraction),
            fraction: fraction,
            calculationMethod: "offlineSynodicApproximation"
        )
    }

    static func phaseName(forFraction rawFraction: Double) -> MoonPhaseName {
        let fraction = normalized(rawFraction)

        switch fraction {
        case 0..<0.0625, 0.9375...1:
            return .newMoon
        case 0.0625..<0.1875:
            return .waxingCrescent
        case 0.1875..<0.3125:
            return .firstQuarter
        case 0.3125..<0.4375:
            return .waxingGibbous
        case 0.4375..<0.5625:
            return .fullMoon
        case 0.5625..<0.6875:
            return .waningGibbous
        case 0.6875..<0.8125:
            return .lastQuarter
        default:
            return .waningCrescent
        }
    }

    private static func lunarAge(for date: Date) -> Double {
        let julianDay = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let daysSinceKnownNewMoon = julianDay - knownNewMoonJulianDay
        let cycles = daysSinceKnownNewMoon / synodicMonth
        return normalized(cycles) * synodicMonth
    }

    private static func normalized(_ value: Double) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: 1)
        return remainder >= 0 ? remainder : remainder + 1
    }
}
