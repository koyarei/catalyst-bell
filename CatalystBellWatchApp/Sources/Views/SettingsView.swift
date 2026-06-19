import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        Form {
            Section("Haptics") {
                Picker("Clicks per Pulse", selection: $sessionManager.clicksPerPulse) {
                    ForEach(SessionManager.clicksPerPulseChoices, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }

                Picker("Pulses per Minute", selection: $sessionManager.pulsesPerMinute) {
                    ForEach(SessionManager.pulsesPerMinuteChoices, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }

                Text("More pulses per minute means a shorter gap between pulse trains.")

                Picker("Max Duration", selection: $sessionManager.maxDurationMinutes) {
                    Text("2 min").tag(2.0)
                    Text("5 min").tag(5.0)
                    Text("10 min").tag(10.0)
                    Text("15 min").tag(15.0)
                }
            }

            Section("Location") {
                Toggle("Coarse Location", isOn: $sessionManager.locationLoggingEnabled)
                    .onChange(of: sessionManager.locationLoggingEnabled) { _, isEnabled in
                        if isEnabled {
                            sessionManager.requestLocationPermission()
                        }
                    }
            }

            Section("History") {
                NavigationLink("Sessions") {
                    HistoryView()
                }

                Button("Delete All", role: .destructive) {
                    Task {
                        await sessionManager.deleteAllRecords()
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}
