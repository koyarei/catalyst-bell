import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        List {
            ForEach(sessionManager.records.reversed()) { record in
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.startDate, style: .date)
                    Text("\(Int(record.durationSeconds)) sec")
                        .foregroundStyle(.secondary)
                    Text(record.moonPhase.name.rawValue)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Sessions")
    }
}
