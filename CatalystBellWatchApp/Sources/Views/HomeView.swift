import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Button("Start") {
                    sessionManager.start(launchSource: .appIcon)
                }
                .buttonStyle(.borderedProminent)

                NavigationLink("Settings") {
                    SettingsView()
                }
            }
            .navigationTitle("Catalyst Bell")
        }
    }
}
