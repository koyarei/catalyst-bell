import Foundation

protocol SessionStoring {
    func loadRecords() async -> [SessionRecord]
    func append(_ record: SessionRecord) async throws
    func deleteAll() async throws
}

actor SessionStore: SessionStoring {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        self.fileURL = fileURL ?? documentsURL!.appendingPathComponent("sessions.json")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadRecords() async -> [SessionRecord] {
        (try? loadEnvelope().records) ?? []
    }

    func append(_ record: SessionRecord) async throws {
        var envelope = try loadEnvelope()
        envelope.records.append(record)
        try save(envelope)
    }

    func deleteAll() async throws {
        try save(.empty)
    }

    private func loadEnvelope() throws -> SessionEnvelope {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .empty
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(SessionEnvelope.self, from: data)
    }

    private func save(_ envelope: SessionEnvelope) throws {
        let folderURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let data = try encoder.encode(envelope)
        try data.write(to: fileURL, options: [.atomic])
    }
}
