import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        NavigationStack {
            ZStack {
                StillRainPalette.background
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    Button("Start") {
                        sessionManager.start(launchSource: .appIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(StillRainPalette.primaryButton)

                    NavigationLink("Settings") {
                        SettingsView()
                    }
                    .buttonStyle(.bordered)
                    .tint(StillRainPalette.accent)
                }
                .padding(.horizontal, 6)
            }
        }
    }
}
