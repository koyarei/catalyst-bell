import XCTest
@testable import CatalystBellWatchApp

final class SessionStoreTests: XCTestCase {
    func testAppendAndDeleteAll() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("sessions.json")
        let store = SessionStore(fileURL: url)
        let record = SessionRecord(
            id: UUID(),
            schemaVersion: 1,
            startDate: Date(timeIntervalSince1970: 10),
            endDate: Date(timeIntervalSince1970: 20),
            durationSeconds: 10,
            endReason: .maxDurationReached,
            launchSource: .debug,
            moonPhase: MoonPhase(name: .fullMoon, fraction: 0.5, calculationMethod: "offlineSynodicApproximation"),
            location: nil,
            createdAt: Date(timeIntervalSince1970: 21),
            appVersion: "0.1.0"
        )

        try await store.append(record)
        let savedRecords = await store.loadRecords()
        XCTAssertEqual(savedRecords, [record])

        try await store.deleteAll()
        let recordsAfterDelete = await store.loadRecords()
        XCTAssertTrue(recordsAfterDelete.isEmpty)
    }
}
