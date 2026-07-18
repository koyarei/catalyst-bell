import Foundation
import WatchKit

enum PulseStyle: String, Codable, CaseIterable, Identifiable {
    case steady
    case varied

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

enum PulseSpacingStyle: String, Codable, CaseIterable, Identifiable {
    case fixed
    case varied

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

enum HapticChoice: String, Codable, CaseIterable, Identifiable {
    case click
    case directionUp
    case directionDown
    case start
    case stop
    case success

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .click:
            return "Click"
        case .directionUp:
            return "Direction Up"
        case .directionDown:
            return "Direction Down"
        case .start:
            return "Start"
        case .stop:
            return "Stop"
        case .success:
            return "Success"
        }
    }

    var hapticType: WKHapticType {
        switch self {
        case .click:
            return .click
        case .directionUp:
            return .directionUp
        case .directionDown:
            return .directionDown
        case .start:
            return .start
        case .stop:
            return .stop
        case .success:
            return .success
        }
    }

    var honorsHitsPerPulse: Bool {
        switch self {
        case .click, .directionUp, .directionDown:
            return true
        case .start, .stop, .success:
            return false
        }
    }
}

struct HapticSettings: Equatable {
    static let defaultVariedChoices: Set<HapticChoice> = [.success, .directionUp, .directionDown]
    static let defaultSteadyChoice: HapticChoice = .directionUp
    static let allowedGapRange = 2.0...10.0
    static let defaultMinimumGap = 3.5
    static let defaultMaximumGap = 5.0

    var pulseStyle: PulseStyle
    var spacingStyle: PulseSpacingStyle
    var steadyChoice: HapticChoice
    var selectedChoices: Set<HapticChoice>
    var minimumGap: TimeInterval
    var maximumGap: TimeInterval

    init(
        pulseStyle: PulseStyle = .steady,
        spacingStyle: PulseSpacingStyle = .fixed,
        steadyChoice: HapticChoice = HapticSettings.defaultSteadyChoice,
        selectedChoices: Set<HapticChoice> = HapticSettings.defaultVariedChoices,
        minimumGap: TimeInterval = HapticSettings.defaultMinimumGap,
        maximumGap: TimeInterval = HapticSettings.defaultMaximumGap
    ) {
        self.pulseStyle = pulseStyle
        self.spacingStyle = spacingStyle
        self.steadyChoice = steadyChoice
        self.selectedChoices = selectedChoices.isEmpty ? [.click] : selectedChoices
        let normalizedRange = Self.normalizedGapRange(minimum: minimumGap, maximum: maximumGap)
        self.minimumGap = normalizedRange.lowerBound
        self.maximumGap = normalizedRange.upperBound
    }

    static func normalizedGapRange(
        minimum: TimeInterval,
        maximum: TimeInterval
    ) -> ClosedRange<TimeInterval> {
        let clampedMinimum = clampedGap(minimum, fallback: defaultMinimumGap)
        let clampedMaximum = clampedGap(maximum, fallback: defaultMaximumGap)
        return min(clampedMinimum, clampedMaximum)...max(clampedMinimum, clampedMaximum)
    }

    static func clampedGap(_ value: TimeInterval, fallback: TimeInterval) -> TimeInterval {
        guard value.isFinite else { return fallback }
        return min(max(value, allowedGapRange.lowerBound), allowedGapRange.upperBound)
    }

    static func load(from defaults: UserDefaults, keys: Keys = Keys()) -> HapticSettings {
        let pulseStyle = defaults.string(forKey: keys.pulseStyle)
            .flatMap(PulseStyle.init(rawValue:)) ?? .steady
        let spacingStyle = defaults.string(forKey: keys.spacingStyle)
            .flatMap(PulseSpacingStyle.init(rawValue:)) ?? .fixed
        let steadyChoice = defaults.string(forKey: keys.steadyChoice)
            .flatMap(HapticChoice.init(rawValue:)) ?? defaultSteadyChoice

        let selectedChoices: Set<HapticChoice>
        if defaults.object(forKey: keys.selectedChoices) == nil {
            selectedChoices = defaultVariedChoices
        } else {
            let savedValues = defaults.stringArray(forKey: keys.selectedChoices) ?? []
            let validChoices = Set(savedValues.compactMap(HapticChoice.init(rawValue:)))
            selectedChoices = validChoices.isEmpty ? [.click] : validChoices
        }

        let minimumGap = defaults.object(forKey: keys.minimumGap) == nil
            ? defaultMinimumGap
            : defaults.double(forKey: keys.minimumGap)
        let maximumGap = defaults.object(forKey: keys.maximumGap) == nil
            ? defaultMaximumGap
            : defaults.double(forKey: keys.maximumGap)

        return HapticSettings(
            pulseStyle: pulseStyle,
            spacingStyle: spacingStyle,
            steadyChoice: steadyChoice,
            selectedChoices: selectedChoices,
            minimumGap: minimumGap,
            maximumGap: maximumGap
        )
    }

    struct Keys {
        let pulseStyle = "pulseStyle"
        let spacingStyle = "pulseSpacingStyle"
        let steadyChoice = "steadyHapticChoice"
        let selectedChoices = "selectedVariedHapticChoices"
        let minimumGap = "minimumVariedGap"
        let maximumGap = "maximumVariedGap"
    }
}

struct HapticSessionConfiguration: Equatable {
    let settings: HapticSettings
    let hitsPerPulse: Int
    let pulsesPerMinute: Int

    init(settings: HapticSettings, hitsPerPulse: Int, pulsesPerMinute: Int) {
        self.settings = HapticSettings(
            pulseStyle: settings.pulseStyle,
            spacingStyle: settings.spacingStyle,
            steadyChoice: settings.steadyChoice,
            selectedChoices: settings.selectedChoices,
            minimumGap: settings.minimumGap,
            maximumGap: settings.maximumGap
        )
        self.hitsPerPulse = max(1, hitsPerPulse)
        self.pulsesPerMinute = max(1, pulsesPerMinute)
    }
}

enum SessionState: String {
    case idle
    case starting
    case active
    case stopping
    case saving
    case ended
    case interrupted
}

enum EndReason: String, Codable, CaseIterable {
    case userStopped
    case maxDurationReached
    case runtimeExpired
    case systemInterrupted
    case appTerminated
    case unknown
}

enum LaunchSource: String, Codable, CaseIterable {
    case complication
    case appIcon
    case shortcut
    case debug
    case unknown
}

enum MoonPhaseName: String, Codable, CaseIterable {
    case newMoon = "New Moon"
    case waxingCrescent = "Waxing Crescent"
    case firstQuarter = "First Quarter"
    case waxingGibbous = "Waxing Gibbous"
    case fullMoon = "Full Moon"
    case waningGibbous = "Waning Gibbous"
    case lastQuarter = "Last Quarter"
    case waningCrescent = "Waning Crescent"
}

struct MoonPhase: Codable, Equatable {
    let name: MoonPhaseName
    let fraction: Double
    let calculationMethod: String
}

enum LocationPermissionStatus: String, Codable {
    case notRequested
    case denied
    case allowed
    case unavailable
}

enum LocationGranularity: String, Codable {
    case none
    case coarseRoundedCoordinate
    case localityOnly
}

struct CoarseLocation: Codable, Equatable {
    let permissionStatus: LocationPermissionStatus
    let granularity: LocationGranularity
    let latitudeRounded: Double?
    let longitudeRounded: Double?
    let locality: String?
    let administrativeArea: String?
    let countryCode: String?
}

struct SessionRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let schemaVersion: Int
    let startDate: Date
    let endDate: Date
    let durationSeconds: TimeInterval
    let endReason: EndReason
    let launchSource: LaunchSource
    let moonPhase: MoonPhase
    let location: CoarseLocation?
    let createdAt: Date
    let appVersion: String
}

struct SessionEnvelope: Codable, Equatable {
    var schemaVersion: Int
    var records: [SessionRecord]

    static let empty = SessionEnvelope(schemaVersion: 1, records: [])
}

struct SessionDraft {
    let id: UUID
    let startDate: Date
    let launchSource: LaunchSource

    init(id: UUID = UUID(), startDate: Date = Date(), launchSource: LaunchSource) {
        self.id = id
        self.startDate = startDate
        self.launchSource = launchSource
    }
}
