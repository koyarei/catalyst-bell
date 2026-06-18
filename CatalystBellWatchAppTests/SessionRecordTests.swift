import XCTest
@testable import CatalystBellWatchApp

final class SessionRecordTests: XCTestCase {
    func testRecordEncodingRoundTripPreservesRequiredFields() throws {
        let startDate = Date(timeIntervalSince1970: 1_781_747_132)
        let endDate = startDate.addingTimeInterval(259)
        let record = SessionRecord(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            schemaVersion: 1,
            startDate: startDate,
            endDate: endDate,
            durationSeconds: endDate.timeIntervalSince(startDate),
            endReason: .userStopped,
            launchSource: .complication,
            moonPhase: MoonPhase(name: .waxingCrescent, fraction: 0.23, calculationMethod: "offlineSynodicApproximation"),
            location: nil,
            createdAt: endDate.addingTimeInterval(1),
            appVersion: "0.1.0"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SessionRecord.self, from: data)

        XCTAssertEqual(decoded, record)
        XCTAssertEqual(decoded.durationSeconds, 259)
        XCTAssertNil(decoded.location)
    }
}
