import Foundation

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

enum HapticPattern: String, CaseIterable, Identifiable {
    case gentle
    case slowBreath
    case steady

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gentle:
            return "Gentle"
        case .slowBreath:
            return "Slow Breath"
        case .steady:
            return "Steady"
        }
    }

    var interval: TimeInterval {
        switch self {
        case .gentle:
            return 5
        case .slowBreath:
            return 6
        case .steady:
            return 4
        }
    }

    var pulsesPerCycle: Int {
        switch self {
        case .gentle:
            return 4
        case .slowBreath:
            return 6
        case .steady:
            return 5
        }
    }

    var pulseSpacing: TimeInterval {
        switch self {
        case .gentle:
            return 0.24
        case .slowBreath:
            return 0.32
        case .steady:
            return 0.2
        }
    }
}
