import Foundation
import WatchKit

@MainActor
final class SessionManager: NSObject, ObservableObject {
    @Published private(set) var state: SessionState = .idle
    @Published private(set) var records: [SessionRecord] = []
    @Published var locationLoggingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(locationLoggingEnabled, forKey: Self.locationLoggingKey)
        }
    }
    @Published var clicksPerPulse: Int {
        didSet {
            UserDefaults.standard.set(clicksPerPulse, forKey: Self.clicksPerPulseKey)
        }
    }
    @Published var pulsesPerMinute: Int {
        didSet {
            UserDefaults.standard.set(pulsesPerMinute, forKey: Self.pulsesPerMinuteKey)
        }
    }
    @Published var maxDurationMinutes: Double {
        didSet {
            UserDefaults.standard.set(maxDurationMinutes, forKey: Self.maxDurationKey)
        }
    }

    private static let locationLoggingKey = "locationLoggingEnabled"
    private static let clicksPerPulseKey = "clicksPerPulse"
    private static let pulsesPerMinuteKey = "pulsesPerMinute"
    private static let maxDurationKey = "maxDurationMinutes"
    static let clicksPerPulseChoices = Array(1...8)
    static let pulsesPerMinuteChoices = [6, 8, 10, 12, 15, 20]

    private let store: SessionStoring
    private let hapticEngine: HapticEngine
    private let locationProvider: LocationProvider
    private var currentDraft: SessionDraft?
    private var maxDurationTimer: Timer?
    private var runtimeSession: WKExtendedRuntimeSession?
    private var isStopping = false

    init(
        store: SessionStoring = SessionStore(),
        hapticEngine: HapticEngine? = nil,
        locationProvider: LocationProvider? = nil
    ) {
        self.store = store
        self.hapticEngine = hapticEngine ?? HapticEngine()
        self.locationProvider = locationProvider ?? LocationProvider()
        locationLoggingEnabled = UserDefaults.standard.bool(forKey: Self.locationLoggingKey)
        clicksPerPulse = Self.savedInt(forKey: Self.clicksPerPulseKey, defaultValue: 6, choices: Self.clicksPerPulseChoices)
        pulsesPerMinute = Self.savedInt(forKey: Self.pulsesPerMinuteKey, defaultValue: 15, choices: Self.pulsesPerMinuteChoices)

        let savedMaxDuration = UserDefaults.standard.double(forKey: Self.maxDurationKey)
        maxDurationMinutes = savedMaxDuration > 0 ? savedMaxDuration : 10
        super.init()

        Task {
            records = await store.loadRecords()
        }
    }

    func start(launchSource: LaunchSource) {
        guard state == .idle || state == .ended || state == .interrupted else {
            return
        }

        isStopping = false
        state = .starting
        currentDraft = SessionDraft(launchSource: launchSource)
        startExtendedRuntimeSession()
        hapticEngine.start(clicksPerPulse: clicksPerPulse, pulsesPerMinute: pulsesPerMinute)
        scheduleMaxDurationTimer()
        state = .active
    }

    func stop(reason: EndReason) {
        guard !isStopping, let draft = currentDraft else {
            return
        }

        guard state == .starting || state == .active || state == .interrupted else {
            return
        }

        isStopping = true
        state = reason == .runtimeExpired || reason == .systemInterrupted ? .interrupted : .stopping
        hapticEngine.stop()
        maxDurationTimer?.invalidate()
        maxDurationTimer = nil
        runtimeSession?.invalidate()
        runtimeSession = nil

        Task {
            await save(draft: draft, reason: reason)
        }
    }

    func deleteAllRecords() async {
        try? await store.deleteAll()
        records = []
    }

    func requestLocationPermission() {
        locationProvider.requestPermission()
    }

    private func save(draft: SessionDraft, reason: EndReason) async {
        state = .saving

        let endDate = Date()
        let location = await locationProvider.requestOneCoarseLocationIfAllowed(enabled: locationLoggingEnabled)
        let record = SessionRecord(
            id: draft.id,
            schemaVersion: 1,
            startDate: draft.startDate,
            endDate: endDate,
            durationSeconds: max(0, endDate.timeIntervalSince(draft.startDate)),
            endReason: reason,
            launchSource: draft.launchSource,
            moonPhase: MoonPhaseCalculator.phase(for: draft.startDate),
            location: location,
            createdAt: Date(),
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
        )

        try? await store.append(record)
        records = await store.loadRecords()
        currentDraft = nil
        isStopping = false
        state = .idle
    }

    private func scheduleMaxDurationTimer() {
        maxDurationTimer?.invalidate()
        maxDurationTimer = Timer.scheduledTimer(withTimeInterval: maxDurationMinutes * 60, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stop(reason: .maxDurationReached)
            }
        }
    }

    private func startExtendedRuntimeSession() {
        runtimeSession?.invalidate()
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        runtimeSession = session
        session.start()
    }

    private static func savedInt(forKey key: String, defaultValue: Int, choices: [Int]) -> Int {
        guard UserDefaults.standard.object(forKey: key) != nil else {
            return defaultValue
        }

        return nearestValidChoice(UserDefaults.standard.integer(forKey: key), in: choices)
    }

    private static func nearestValidChoice(_ value: Int, in choices: [Int]) -> Int {
        choices.min { abs($0 - value) < abs($1 - value) } ?? value
    }
}

extension SessionManager: WKExtendedRuntimeSessionDelegate {
    nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in
            stop(reason: .runtimeExpired)
        }
    }

    nonisolated func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        Task { @MainActor in
            guard state == .active || state == .starting else {
                return
            }

            stop(reason: .systemInterrupted)
        }
    }
}
